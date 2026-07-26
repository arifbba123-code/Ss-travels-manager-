import '../models/app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Simulates the `users` collection/table lookup used to resolve a
/// logged-in account to its role (Owner / Admin / Driver).
///
/// Only registered mail IDs are allowed — there is intentionally no
/// sign-up flow. Replace [_registeredUsers] with a real backend call
/// (Firebase Auth + Firestore, or a REST/SQL lookup) when ready; the
/// rest of the auth flow (loading screen + role routing) stays the same.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  // uid -> (user, password) — stand-in for the `users` table.
  final Map<String, _StubAccount> _registeredUsers = {
    'owner@sstours.com': _StubAccount(
      password: 'owner123',
      user: const AppUser(
        uid: 'u-owner-1',
        name: 'Suresh S',
        email: 'owner@sstours.com',
        role: UserRole.owner,
        status: 'active',
      ),
    ),
    'admin1@sstours.com': _StubAccount(
      password: 'admin123',
      user: const AppUser(
        uid: 'u-admin-1',
        name: 'Admin 1',
        email: 'admin1@sstours.com',
        role: UserRole.admin,
        status: 'active',
      ),
    ),
    'driver@sstours.com': _StubAccount(
      password: 'driver123',
      user: const AppUser(
        uid: 'u-driver-1',
        name: 'Ramesh Kumar',
        email: 'driver@sstours.com',
        role: UserRole.driver,
        status: 'active',
      ),
    ),
  };

  /// Authenticates against the registered-user list and resolves the role.
  Future<AppUser> login({required String email, required String password}) async {
    // Simulated network / DB round-trip.
    await Future.delayed(const Duration(milliseconds: 900));

    final normalized = email.trim().toLowerCase();
    final account = _registeredUsers[normalized];

    if (account == null) {
      throw AuthException('No account found for this Mail ID. Contact owner to get registered.');
    }
    if (account.password != password) {
      throw AuthException('Incorrect password. Please try again.');
    }
    if (!account.user.isActive) {
      throw AuthException('This account has been deactivated. Contact owner.');
    }
    return account.user;
  }
}

class _StubAccount {
  final String password;
  final AppUser user;
  _StubAccount({required this.password, required this.user});
}
