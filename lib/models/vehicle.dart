import 'audit_fields.dart';

/// Firestore document in the `vehicles` collection.
class Vehicle {
  final String? id; // Firestore document ID
  final String name; // e.g. "Toyota Innova"
  final String number; // e.g. "TN 10 AB 1234"
  final bool active;
  final AuditFields audit;

  Vehicle({
    this.id,
    required this.name,
    required this.number,
    this.active = true,
    this.audit = const AuditFields(),
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'number': number,
        'active': active,
        ...audit.toMap(),
      };

  factory Vehicle.fromMap(String id, Map<String, dynamic> m) => Vehicle(
        id: id,
        name: m['name'] as String? ?? '',
        number: m['number'] as String? ?? '',
        active: m['active'] as bool? ?? true,
        audit: AuditFields.fromMap(m),
      );

  Vehicle copyWith({String? name, String? number, bool? active}) => Vehicle(
        id: id,
        name: name ?? this.name,
        number: number ?? this.number,
        active: active ?? this.active,
        audit: audit,
      );
}
