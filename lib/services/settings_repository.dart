import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// A single shared document (`settings/app`) holding business-wide
/// settings such as the company display name. Every device reads the
/// same live document, so an update from one admin's Settings screen
/// appears everywhere instantly.
class SettingsRepository {
  SettingsRepository._internal();
  static final SettingsRepository instance = SettingsRepository._internal();

  final _doc = FirebaseFirestore.instance.collection('settings').doc('app');

  Stream<Map<String, dynamic>> watch() {
    return _doc.snapshots().map((s) => s.data() ?? const {'companyName': 'SS Tours & Travels'});
  }

  Future<void> updateCompanyName(String name, AppUser actingAdmin) async {
    await _doc.set({
      'companyName': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actingAdmin.uid,
      'updatedByName': actingAdmin.name,
    }, SetOptions(merge: true));
  }
}
