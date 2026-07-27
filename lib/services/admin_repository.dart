import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import 'audit_log_service.dart';
import 'firebase_auth_service.dart';

/// Everything to do with the Firestore `admins` collection: resolving a
/// signed-in Firebase user to their admin profile & role, bootstrapping
/// the very first Super Admin, and full CRUD for Super-Admin-managed
/// admin accounts.
class AdminRepository {
  AdminRepository._internal();
  static final AdminRepository instance = AdminRepository._internal();

  final _col = FirebaseFirestore.instance.collection('admins');

  /// Called right after a successful Firebase Auth sign-in. Looks up the
  /// matching `admins/{uid}` document and returns the resolved [AppUser].
  ///
  /// - If no `admins` documents exist at all yet, this is a brand-new
  ///   deployment: the signed-in user is bootstrapped as the first
  ///   **Super Admin** automatically.
  /// - If admin documents exist but none match this uid, the user is not
  ///   registered — they are signed out and an [AuthException] is thrown,
  ///   matching the existing "contact the owner" UX.
  /// - If the matching admin is deactivated, they are signed out too.
  Future<AppUser> resolveOrBootstrap(User firebaseUser) async {
    final docRef = _col.doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      final user = AppUser.fromMap(doc.id, doc.data()!);
      if (!user.isActive) {
        await FirebaseAuthService.instance.signOut();
        throw AuthException('This account has been deactivated. Contact your Super Admin.');
      }
      await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
      return user.copyWith(lastLogin: DateTime.now(), emailVerified: firebaseUser.emailVerified);
    }

    // No profile yet for this uid — check the one-time bootstrap flag.
    // A dedicated `admins_meta/bootstrap` doc (rather than "is the admins
    // collection empty") is what lets firestore.rules actually enforce
    // "only the very first sign-in may self-provision as Super Admin" —
    // a plain collection-emptiness check can't be expressed safely in
    // security rules.
    final metaRef = FirebaseFirestore.instance.collection('admins_meta').doc('bootstrap');
    final meta = await metaRef.get();
    final alreadyBootstrapped = meta.exists && (meta.data()?['bootstrapped'] == true);

    if (!alreadyBootstrapped) {
      // First ever login on a fresh Firebase project -> bootstrap Super Admin.
      final bootstrap = AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName?.trim().isNotEmpty == true
            ? firebaseUser.displayName!.trim()
            : (firebaseUser.email ?? 'Super Admin'),
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
        role: UserRole.superAdmin,
        active: true,
      );
      final batch = FirebaseFirestore.instance.batch();
      batch.set(docRef, {
        ...bootstrap.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': firebaseUser.uid,
        'createdByName': bootstrap.name,
        'lastLogin': FieldValue.serverTimestamp(),
      });
      batch.set(metaRef, {
        'bootstrapped': true,
        'bootstrappedBy': firebaseUser.uid,
        'bootstrappedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await AuditLogService.instance.log(
        collection: 'admins',
        docId: firebaseUser.uid,
        action: AuditAction.create,
        summary: '${bootstrap.name} bootstrapped as the first Super Admin',
        performedByUid: firebaseUser.uid,
        performedByName: bootstrap.name,
      );
      return bootstrap.copyWith(lastLogin: DateTime.now(), emailVerified: firebaseUser.emailVerified);
    }

    // Admins exist, but this account isn't one of them.
    await FirebaseAuthService.instance.signOut();
    throw AuthException(
        'No admin account found for this Mail ID. Contact your Super Admin to get registered.');
  }

  /// Real-time list of every admin — used by the "Manage Admins" screen.
  Stream<List<AppUser>> watchAll() {
    return _col.orderBy('createdAt', descending: false).snapshots().map(
        (s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  /// Creates a brand-new Admin (or Super Admin) account: a real Firebase
  /// Auth user PLUS its `admins/{uid}` Firestore profile — all without
  /// signing the current Super Admin out of their own session.
  ///
  /// Client apps can't call `createUserWithEmailAndPassword` for someone
  /// else without replacing the current session — Firebase's client SDK
  /// always signs in as the newly created user. The standard workaround
  /// (used here) is a short-lived secondary [FirebaseApp] instance: the
  /// new account is created on that throwaway app, its profile is written
  /// to Firestore using the *primary* app (still signed in as the acting
  /// Super Admin), and the secondary app is torn down immediately after.
  Future<void> createAdmin({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    required AppUser actingAdmin,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'AdminCreation-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      late final UserCredential cred;
      try {
        cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw AuthException(_mapCreateError(e));
      }

      final newUid = cred.user!.uid;
      await cred.user!.updateDisplayName(name.trim());
      // Kick off email verification for the new admin (per spec).
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {
        // Non-fatal — the admin can request verification again on first login.
      }

      final newUser = AppUser(
        uid: newUid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        active: true,
      );
      await _col.doc(newUid).set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': actingAdmin.uid,
        'createdByName': actingAdmin.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actingAdmin.uid,
        'updatedByName': actingAdmin.name,
      });

      await AuditLogService.instance.log(
        collection: 'admins',
        docId: newUid,
        action: AuditAction.create,
        summary: '${actingAdmin.name} created ${role.label} account for ${newUser.name}',
        performedByUid: actingAdmin.uid,
        performedByName: actingAdmin.name,
      );

      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Edits an existing admin's profile fields (name / phone / role).
  Future<void> updateAdmin({
    required AppUser target,
    required AppUser actingAdmin,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    };
    if (name != null) updates['name'] = name.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (role != null) updates['role'] = role.firestoreValue;

    await _col.doc(target.uid).update(updates);
    await AuditLogService.instance.log(
      collection: 'admins',
      docId: target.uid,
      action: AuditAction.update,
      summary: '${actingAdmin.name} updated admin profile for ${target.name}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  /// Activates / deactivates an admin. A Super Admin account can never be
  /// deactivated through this app — only another Super Admin managing the
  /// underlying Firebase project could do that.
  Future<void> setActive({
    required AppUser target,
    required AppUser actingAdmin,
    required bool active,
  }) async {
    if (target.isSuperAdmin) {
      throw AuthException('A Super Admin account cannot be deactivated.');
    }
    await _col.doc(target.uid).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });
    await AuditLogService.instance.log(
      collection: 'admins',
      docId: target.uid,
      action: AuditAction.update,
      summary:
          '${actingAdmin.name} ${active ? 'activated' : 'deactivated'} admin account for ${target.name}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  /// Removes an admin's Firestore profile, revoking their access to the
  /// app. (Their underlying Firebase Auth account is untouched — deleting
  /// another user's Auth account requires the Firebase Admin SDK / Cloud
  /// Functions, which is outside what a client app can do. Revoking the
  /// Firestore profile is what actually gates access to every screen in
  /// this app, so the effect for this app is the same as a delete.)
  ///
  /// Super Admin accounts can never be deleted from this app.
  Future<void> deleteAdmin({required AppUser target, required AppUser actingAdmin}) async {
    if (target.isSuperAdmin) {
      throw AuthException('A Super Admin account cannot be deleted.');
    }
    await _col.doc(target.uid).delete();
    await AuditLogService.instance.log(
      collection: 'admins',
      docId: target.uid,
      action: AuditAction.delete,
      summary: '${actingAdmin.name} removed admin account for ${target.name}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  String _mapCreateError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      default:
        return e.message ?? 'Could not create the admin account. Please try again.';
    }
  }
}
