import 'package:cloud_firestore/cloud_firestore.dart';

/// Every Firestore document in this app carries the same four audit
/// fields so any admin, on any device, can see who created/last-changed
/// a record and when. Kept as free functions (not a mixin) so the plain
/// model classes below can stay simple, immutable data classes.
class AuditFields {
  final String createdBy; // uid of the admin who created the record
  final String createdByName;
  final DateTime? createdAt;
  final String updatedBy; // uid of the admin who last edited the record
  final String updatedByName;
  final DateTime? updatedAt;

  const AuditFields({
    this.createdBy = '',
    this.createdByName = '',
    this.createdAt,
    this.updatedBy = '',
    this.updatedByName = '',
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedBy': updatedBy,
        'updatedByName': updatedByName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AuditFields.fromMap(Map<String, dynamic> m) => AuditFields(
        createdBy: m['createdBy'] as String? ?? '',
        createdByName: m['createdByName'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        updatedBy: m['updatedBy'] as String? ?? '',
        updatedByName: m['updatedByName'] as String? ?? '',
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      );
}

/// Converts a Firestore [Timestamp], [DateTime] or ISO string safely.
DateTime? tsToDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
