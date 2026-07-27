import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../models/vehicle.dart';
import 'audit_log_service.dart';

/// Real-time CRUD for the Firestore `vehicles` collection. Every admin,
/// on every device, is subscribed to the same [watchAll] stream, so a
/// create/edit/delete on one phone appears instantly on every other.
class VehicleRepository {
  VehicleRepository._internal();
  static final VehicleRepository instance = VehicleRepository._internal();

  final _col = FirebaseFirestore.instance.collection('vehicles');

  Stream<List<Vehicle>> watchAll() {
    return _col.orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());
  }

  Future<void> create(Vehicle v, AppUser actingAdmin) async {
    final doc = _col.doc();
    await doc.set({
      'name': v.name,
      'number': v.number,
      'active': v.active,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': actingAdmin.uid,
      'createdByName': actingAdmin.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });
    await AuditLogService.instance.log(
      collection: 'vehicles',
      docId: doc.id,
      action: AuditAction.create,
      summary: '${actingAdmin.name} added vehicle "${v.name}" (${v.number})',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> update(Vehicle v, AppUser actingAdmin) async {
    if (v.id == null) return;
    await _col.doc(v.id).update({
      'name': v.name,
      'number': v.number,
      'active': v.active,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    });
    await AuditLogService.instance.log(
      collection: 'vehicles',
      docId: v.id!,
      action: AuditAction.update,
      summary: '${actingAdmin.name} updated vehicle "${v.name}" (${v.number})',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }

  Future<void> delete(Vehicle v, AppUser actingAdmin) async {
    if (v.id == null) return;
    await _col.doc(v.id).delete();
    await AuditLogService.instance.log(
      collection: 'vehicles',
      docId: v.id!,
      action: AuditAction.delete,
      summary: '${actingAdmin.name} deleted vehicle "${v.name}"',
      performedByUid: actingAdmin.uid,
      performedByName: actingAdmin.name,
    );
  }
}
