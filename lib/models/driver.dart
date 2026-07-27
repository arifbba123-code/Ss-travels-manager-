import 'audit_fields.dart';

/// Firestore document in the `drivers` collection.
class Driver {
  final String? id; // Firestore document ID
  final String name;
  final String phone;
  final bool active;
  final AuditFields audit;

  Driver({
    this.id,
    required this.name,
    required this.phone,
    this.active = true,
    this.audit = const AuditFields(),
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'active': active,
        ...audit.toMap(),
      };

  factory Driver.fromMap(String id, Map<String, dynamic> m) => Driver(
        id: id,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        active: m['active'] as bool? ?? true,
        audit: AuditFields.fromMap(m),
      );

  Driver copyWith({String? name, String? phone, bool? active}) => Driver(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        active: active ?? this.active,
        audit: audit,
      );
}
