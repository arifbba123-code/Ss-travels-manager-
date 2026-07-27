import 'audit_fields.dart';

/// Roles supported by SS Tours & Travels Manager's multi-admin system.
///
/// Maps 1:1 to the `role` field on the Firestore `admins/{uid}` document.
enum UserRole { superAdmin, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get tagline {
    switch (this) {
      case UserRole.superAdmin:
        return 'Full access — manage admins & everything else';
      case UserRole.admin:
        return 'Manage vehicles, drivers, entries & reports';
    }
  }

  /// Firestore stores the human label directly (e.g. "Super Admin"),
  /// which is what the spec's `admins` collection schema calls for.
  String get firestoreValue => label;

  static UserRole fromFirestore(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'super admin':
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.admin;
    }
  }
}

/// Mirrors a document in the Firestore `admins` collection:
///   admins/{uid} -> { uid, name, email, phone, role, active, createdAt, lastLogin }
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.active = true,
    this.createdAt,
    this.lastLogin,
    this.emailVerified = false,
  });

  bool get isActive => active;
  bool get isSuperAdmin => role == UserRole.superAdmin;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.firestoreValue,
        'active': active,
        'lastLogin': lastLogin == null ? null : lastLogin!.toIso8601String(),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        role: UserRoleX.fromFirestore(m['role'] as String?),
        active: m['active'] as bool? ?? true,
        createdAt: tsToDate(m['createdAt']),
        lastLogin: tsToDate(m['lastLogin']),
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? active,
    DateTime? lastLogin,
    bool? emailVerified,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
