import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

/// Writes an entry to the `audit_logs` Firestore collection for every
/// create / update / delete performed anywhere in the app, so any admin
/// on any device can see a full history of who changed what and when.
class AuditLogService {
  AuditLogService._internal();
  static final AuditLogService instance = AuditLogService._internal();

  final _col = FirebaseFirestore.instance.collection('audit_logs');

  Future<void> log({
    required String collection,
    required String docId,
    required AuditAction action,
    required String summary,
    required String performedByUid,
    required String performedByName,
  }) async {
    final entry = AuditLogEntry(
      collection: collection,
      docId: docId,
      action: action,
      summary: summary,
      performedByUid: performedByUid,
      performedByName: performedByName,
    );
    // Audit logging must never block or break the main operation it is
    // recording, so failures here are swallowed after being logged to
    // the console (e.g. transient offline write — Firestore's offline
    // persistence queues it locally and syncs once back online anyway).
    try {
      await _col.add(entry.toMap());
    } catch (e) {
      // ignore: avoid_print
      print('AuditLogService: failed to write audit log — $e');
    }
  }

  /// Real-time stream of the most recent audit log entries, newest first.
  Stream<List<AuditLogEntry>> watchRecent({int limit = 200}) {
    return _col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AuditLogEntry.fromMap(d.id, d.data())).toList());
  }
}
