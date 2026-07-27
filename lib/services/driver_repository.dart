import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/driver.dart';
import 'audit_log_service.dart';

/// Real-time CRUD for the Firestore `drivers` collection.
class DriverRepository {
  DriverRepository._internal();
  static final DriverRepository instance = DriverRepository._internal();

  final _col = FirebaseFirestore.instance.collection('drivers');

  Stream<List<Driver>> watchAll() {
    return _col.orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => Driver.fromMap(d.id, d.data())).toList());
  }

  Future<void> create(Driver d, AppUser actingAdmin) async {
    final doc = _col.doc();
    await doc.set({
      'name': d.name,
      'phone': d.phone,
      'active': d.active,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': actingAdmin.uid,
      'createdByName': actingAdmin.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });
    await AuditLogService.instance.log(
      collection: 'drivers',
      docId: doc.id,
      action: AuditAction.create,
      summary: '${actingAdmin.name} added driver "${d.name}"',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> update(Driver d, AppUser actingAdmin) async {
    if (d.id == null) return;
    await _col.doc(d.id).update({
      'name': d.name,
      'phone': d.phone,
      'active': d.active,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });
    await AuditLogService.instance.log(
      collection: 'drivers',
      docId: d.id!,
      action: AuditAction.update,
      summary: '${actingAdmin.name} updated driver "${d.name}"',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> delete(Driver d, AppUser actingAdmin) async {
    if (d.id == null) return;
    await _col.doc(d.id).delete();
    await AuditLogService.instance.log(
      collection: 'drivers',
      docId: d.id!,
      action: AuditAction.delete,
      summary: '${actingAdmin.name} deleted driver "${d.name}"',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }
}
