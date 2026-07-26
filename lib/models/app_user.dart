/// Roles supported by SS Tours & Travels Manager.
///
/// Maps 1:1 to the `role` column on the `users` table:
///   users(uid, name, email, role, status)
enum UserRole { owner, admin, driver }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.driver:
        return 'Driver';
    }
  }

  String get tagline {
    switch (this) {
      case UserRole.owner:
        return 'Full business access';
      case UserRole.admin:
        return 'Manage reports, drivers, vehicles & expenses';
      case UserRole.driver:
        return 'Add daily entries, mileage & fuel updates';
    }
  }
}

/// Lightweight user record returned after a successful login.
/// Mirrors the `users` table: uid, name, email, role, status.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String status; // e.g. 'active', 'suspended'

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'active',
  });

  bool get isActive => status.toLowerCase() == 'active';
}
