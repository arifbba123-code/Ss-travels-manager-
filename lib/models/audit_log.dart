import 'package:cloud_firestore/cloud_firestore.dart';
import 'audit_fields.dart';

enum AuditAction { create, update, delete }

extension AuditActionX on AuditAction {
  String get value => toString().split('.').last;
  static AuditAction fromValue(String? v) => AuditAction.values.firstWhere(
        (a) => a.value == v,
        orElse: () => AuditAction.update,
      );
}

/// Firestore document in the `audit_logs` collection. One entry is written
/// for every create / update / delete across every collection so any
/// admin can audit "who changed what, when" from any device.
class AuditLogEntry {
  final String? id;
  final String collection; // e.g. 'vehicles', 'daily_collections'
  final String docId;
  final AuditAction action;
  final String summary; // short human-readable description
  final String performedByUid;
  final String performedByName;
  final DateTime? timestamp;

  AuditLogEntry({
    this.id,
    required this.collection,
    required this.docId,
    required this.action,
    required this.summary,
    required this.performedByUid,
    required this.performedByName,
    this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'collection': collection,
        'docId': docId,
        'action': action.value,
        'summary': summary,
        'performedByUid': performedByUid,
        'performedByName': performedByName,
        'timestamp': FieldValue.serverTimestamp(),
      };

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> m) => AuditLogEntry(
        id: id,
        collection: m['collection'] as String? ?? '',
        docId: m['docId'] as String? ?? '',
        action: AuditActionX.fromValue(m['action'] as String?),
        summary: m['summary'] as String? ?? '',
        performedByUid: m['performedByUid'] as String? ?? '',
        performedByName: m['performedByName'] as String? ?? '',
        timestamp: tsToDate(m['timestamp']),
      );
}
