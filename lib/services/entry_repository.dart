import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/entry.dart';
import '../models/expense.dart';
import 'audit_log_service.dart';

/// Real-time CRUD for the Firestore `daily_collections` collection (the
/// app's core "daily entry" records). Every write also mirrors the
/// expense breakdown into the `expenses` collection and appends an
/// `audit_logs` entry, so all three collections stay in sync.
class EntryRepository {
  EntryRepository._internal();
  static final EntryRepository instance = EntryRepository._internal();

  final _col = FirebaseFirestore.instance.collection('daily_collections');
  final _expenseCol = FirebaseFirestore.instance.collection('expenses');

  /// All entries, most recent date first. Filtering/search for the
  /// History screen is done client-side over this same live stream so
  /// every filter combination stays fully real-time without needing a
  /// matching composite Firestore index for each combination.
  Stream<List<DailyEntry>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map(
        (s) => s.docs.map((d) => DailyEntry.fromMap(d.id, d.data())).toList());
  }

  Future<void> create(DailyEntry e, AppUser actingAdmin) async {
    final doc = _col.doc();
    final batch = FirebaseFirestore.instance.batch();

    batch.set(doc, {
      ..._fields(e),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': actingAdmin.uid,
      'createdByName': actingAdmin.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });

    final expense = ExpenseRecord.fromEntry(e.copyWith(id: doc.id));
    batch.set(_expenseCol.doc(doc.id), {
      ..._expenseFields(expense),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': actingAdmin.uid,
      'createdByName': actingAdmin.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });

    await batch.commit();
    await AuditLogService.instance.log(
      collection: 'daily_collections',
      docId: doc.id,
      action: AuditAction.create,
      summary:
          '${actingAdmin.name} added a daily entry for ${e.vehicleName} on ${e.date}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> update(DailyEntry e, AppUser actingAdmin) async {
    if (e.id == null) return;
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(e.id), {
      ..._fields(e),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });

    final expense = ExpenseRecord.fromEntry(e);
    batch.set(
      _expenseCol.doc(e.id),
      {
        ..._expenseFields(expense),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actingAdmin.uid,
        'updatedByName': actingAdmin.name,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await AuditLogService.instance.log(
      collection: 'daily_collections',
      docId: e.id!,
      action: AuditAction.update,
      summary:
          '${actingAdmin.name} updated the daily entry for ${e.vehicleName} on ${e.date}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> delete(DailyEntry e, AppUser actingAdmin) async {
    if (e.id == null) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_col.doc(e.id));
    batch.delete(_expenseCol.doc(e.id));
    await batch.commit();

    await AuditLogService.instance.log(
      collection: 'daily_collections',
      docId: e.id!,
      action: AuditAction.delete,
      summary:
          '${actingAdmin.name} deleted the daily entry for ${e.vehicleName} on ${e.date}',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  /// Latest carried-forward balance for [vehicleId], used to auto-fill
  /// "Old Balance" on the daily entry form. Looked up from a snapshot of
  /// this vehicle's entries rather than a live stream since it's a
  /// one-off value read at form-open time.
  Future<double> getLastBalanceForVehicle(String vehicleId, {String? excludeEntryId}) async {
    final snap = await _col
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .limit(10)
        .get();
    for (final d in snap.docs) {
      if (excludeEntryId != null && d.id == excludeEntryId) continue;
      return DailyEntry.fromMap(d.id, d.data()).balance;
    }
    return 0;
  }

  Map<String, dynamic> _fields(DailyEntry e) => {
        'date': e.date,
        'vehicleId': e.vehicleId,
        'driverId': e.driverId,
        'vehicleName': e.vehicleName,
        'driverName': e.driverName,
        'onlineCollection': e.onlineCollection,
        'cashCollection': e.cashCollection,
        'cng': e.cng,
        'petrol': e.petrol,
        'driverSalary': e.driverSalary,
        'rental': e.rental,
        'otherExpense': e.otherExpense,
        'oldBalance': e.oldBalance,
        'notes': e.notes,
      };

  Map<String, dynamic> _expenseFields(ExpenseRecord ex) => {
        'date': ex.date,
        'vehicleId': ex.vehicleId,
        'vehicleName': ex.vehicleName,
        'driverId': ex.driverId,
        'driverName': ex.driverName,
        'cng': ex.cng,
        'petrol': ex.petrol,
        'driverSalary': ex.driverSalary,
        'rental': ex.rental,
        'otherExpense': ex.otherExpense,
        'total': ex.total,
      };
}

/// Pure aggregate helpers over an already-fetched list of entries — kept
/// free of Firestore so the dashboard can derive them straight from its
/// live [EntryRepository.watchAll] stream with zero extra reads.
class EntryStats {
  static Map<String, double> todayStats(List<DailyEntry> all) {
    final today = _fmt(DateTime.now());
    return _sum(all.where((e) => e.date == today));
  }

  static Map<String, double> thisMonthStats(List<DailyEntry> all) {
    final now = DateTime.now();
    return _sum(all.where((e) {
      final parts = e.date.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == now.year && m == now.month;
    }));
  }

  static Map<String, double> _sum(Iterable<DailyEntry> entries) {
    double collection = 0, profit = 0;
    for (final e in entries) {
      collection += e.totalCollection;
      profit += e.profit;
    }
    return {'collection': collection, 'profit': profit};
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
