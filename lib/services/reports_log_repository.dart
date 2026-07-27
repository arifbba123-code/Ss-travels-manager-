import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/entry.dart';

/// Every time a PDF/PNG daily report is generated & shared, a lightweight
/// record is logged to the `reports` collection: which entry, which
/// format, and who generated it — so there's a shared, real-time history
/// of report activity across all admin devices.
class ReportsLogRepository {
  ReportsLogRepository._internal();
  static final ReportsLogRepository instance = ReportsLogRepository._internal();

  final _col = FirebaseFirestore.instance.collection('reports');

  Future<void> logGenerated({
    required DailyEntry entry,
    required String format, // 'pdf' | 'png'
    required AppUser actingAdmin,
  }) async {
    try {
      await _col.add({
        'entryId': entry.id,
        'vehicleName': entry.vehicleName,
        'driverName': entry.driverName,
        'date': entry.date,
        'format': format,
        'generatedAt': FieldValue.serverTimestamp(),
        'createdBy': actingAdmin.uid,
        'createdByName': actingAdmin.name,
        'updatedBy': actingAdmin.uid,
        'updatedByName': actingAdmin.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Report sharing itself must never fail because of logging.
      // ignore: avoid_print
      print('ReportsLogRepository: failed to log report — $e');
    }
  }

  Stream<List<Map<String, dynamic>>> watchRecent({int limit = 100}) {
    return _col
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
