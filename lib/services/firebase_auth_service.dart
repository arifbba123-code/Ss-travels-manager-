import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around FirebaseAuth + GoogleSignIn. This is the ONLY file
/// that talks to the Firebase Auth / Google Sign-In SDKs directly — every
/// screen goes through here so the sign-in flow stays consistent
/// everywhere.
///
/// Written against google_sign_in ^7.x, which replaced the old
/// `GoogleSignIn()` constructor + `signIn()` API with a singleton
/// (`GoogleSignIn.instance`) that must be explicitly `initialize()`d once,
/// an `authenticate()` call that throws [GoogleSignInException] instead of
/// returning null on cancel, and a separate `authorizationClient` step to
/// obtain an access token (the ID token now comes synchronously off
/// `GoogleSignInAccount.authentication`).
class FirebaseAuthService {
  FirebaseAuthService._internal();
  static final FirebaseAuthService instance = FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  /// Firebase Auth on Android always persists the session to disk, which is
  /// what gives us "auto login" for free after the app is reopened. This
  /// stream is how the app listens for that restored session (and for
  /// sign-out) anywhere in the widget tree.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInReady) return;
    // With a Firebase Android app, no clientId needs to be passed here —
    // it's resolved automatically from google-services.json, provided a
    // web OAuth client entry exists there (which requires the app's SHA-1
    // fingerprint to be registered in the Firebase console).
    await _googleSignIn.initialize();
    _googleSignInReady = true;
  }

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

  Future<User> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount googleUser;
      try {
        googleUser = await _googleSignIn.authenticate();
      } on GoogleSignInException catch (e) {
        throw AuthException(_mapGoogleError(e));
      }

      // Authorize the scopes we need to get an access token alongside the
      // ID token (Firebase accepts an ID-token-only credential too, but
      // including the access token is what the current FlutterFire /
      // google_sign_in v7 guidance recommends).
      final authorization =
          await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: authorization.accessToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) throw AuthException('Google sign-in failed. Please try again.');
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
    try {
      if (_googleSignInReady) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Not signed in with Google — safe to ignore.
    }
    await _auth.signOut();
  }

  String _mapGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was interrupted. Please try again.';
      default:
        return 'Google sign-in failed: ${e.description ?? e.code}';
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this Mail ID. Contact your Super Admin.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been deactivated. Contact your Super Admin.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
