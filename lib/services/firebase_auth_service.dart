import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around FirebaseAuth. This is the ONLY file that talks to
/// the Firebase Auth SDK directly — every screen goes through here so the
/// sign-in flow stays consistent everywhere.
///
/// NOTE: Google Sign-In is temporarily removed (email/password only).
///
/// NOTE: Friendly error mapping is TEMPORARILY DISABLED for debugging.
/// `_mapError` below now surfaces the raw FirebaseAuthException `code` and
/// `message` verbatim instead of a user-friendly string. Restore the
/// previous switch-based mapping before shipping to end users.
class FirebaseAuthService {
  FirebaseAuthService._internal();
  static final FirebaseAuthService instance = FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firebase Auth on Android always persists the session to disk, which is
  /// what gives us "auto login" for free after the app is reopened. This
  /// stream is how the app listens for that restored session (and for
  /// sign-out) anywhere in the widget tree.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw AuthException('Sign in failed. Please try again.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() => _auth.currentUser?.reload() ?? Future.value();

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // TEMPORARY: friendly-message mapping disabled — surfaces the raw
  // FirebaseAuthException code + message as-is so the exact Firebase
  // error can be seen while debugging (e.g. invalid-credential,
  // user-not-found, invalid-api-key, network-request-failed,
  // operation-not-allowed).
  String _mapError(FirebaseAuthException e) {
    return '${e.code}\n${e.message}';
  }
}
