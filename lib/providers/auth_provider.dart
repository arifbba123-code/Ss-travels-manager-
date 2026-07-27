import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/admin_repository.dart';
import '../services/firebase_auth_service.dart';

enum AuthStatus { unknown, signedOut, signedIn, deactivated }

/// App-wide auth state, exposed via Provider. Wraps Firebase's own
/// `authStateChanges` (this is what gives us "remember me" / auto-login
/// for free — Firebase persists the session on disk) and layers the
/// live `admins/{uid}` Firestore document on top, so a role change or a
/// deactivation made by a Super Admin on another device takes effect on
/// this device immediately, without needing to log out and back in.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSub = FirebaseAuthService.instance.authStateChanges.listen(_onAuthChanged);
  }

  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentAdmin;
  String? lastError;

  bool get isSignedIn => status == AuthStatus.signedIn && currentAdmin != null;

  Future<void> _onAuthChanged(fb.User? user) async {
    await _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      currentAdmin = null;
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    try {
      final admin = await AdminRepository.instance.resolveOrBootstrap(user);
      currentAdmin = admin;
      status = AuthStatus.signedIn;
      notifyListeners();

      // Stay subscribed so a role/active change from another device (or
      // another admin) is reflected here in real time.
      _profileSub = FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .snapshots()
          .listen((snap) async {
        if (!snap.exists) {
          status = AuthStatus.deactivated;
          currentAdmin = null;
          notifyListeners();
          await FirebaseAuthService.instance.signOut();
          return;
        }
        final updated = AppUser.fromMap(snap.id, snap.data()!);
        if (!updated.isActive) {
          status = AuthStatus.deactivated;
          currentAdmin = null;
          notifyListeners();
          await FirebaseAuthService.instance.signOut();
          return;
        }
        currentAdmin = updated.copyWith(emailVerified: user.emailVerified);
        notifyListeners();
      });
    } on AuthException catch (e) {
      currentAdmin = null;
      status = AuthStatus.signedOut;
      lastError = e.message;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuthService.instance.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
