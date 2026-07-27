import 'audit_fields.dart';
import 'entry.dart';

/// Firestore document in the `expenses` collection.
///
/// The existing UI records expenses as part of each daily entry (CNG,
/// petrol, driver salary, rental, other). Rather than invent a brand new
/// "Add Expense" screen (which would change the UI you asked to keep
/// untouched), every daily entry automatically mirrors its expense
/// breakdown into its own `expenses/{entryId}` document. This keeps a
/// normalized, query-able expenses collection — ready for a dedicated
/// expenses report screen later — while the app surface stays identical.
class ExpenseRecord {
  final String? id; // same ID as the source daily_collections entry
  final String date;
  final String vehicleId;
  final String vehicleName;
  final String driverId;
  final String driverName;
  final double cng;
  final double petrol;
  final double driverSalary;
  final double rental;
  final double otherExpense;
  final AuditFields audit;

  ExpenseRecord({
    this.id,
    required this.date,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverId,
    required this.driverName,
    this.cng = 0,
    this.petrol = 0,
    this.driverSalary = 0,
    this.rental = 0,
    this.otherExpense = 0,
    this.audit = const AuditFields(),
  });

  double get total => cng + petrol + driverSalary + rental + otherExpense;

  factory ExpenseRecord.fromEntry(DailyEntry e) => ExpenseRecord(
        id: e.id,
        date: e.date,
        vehicleId: e.vehicleId,
        vehicleName: e.vehicleName,
        driverId: e.driverId,
        driverName: e.driverName,
        cng: e.cng,
        petrol: e.petrol,
        driverSalary: e.driverSalary,
        rental: e.rental,
        otherExpense: e.otherExpense,
        audit: e.audit,
      );

  Map<String, dynamic> toMap() => {
        'date': date,
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'driverId': driverId,
        'driverName': driverName,
        'cng': cng,
        'petrol': petrol,
        'driverSalary': driverSalary,
        'rental': rental,
        'otherExpense': otherExpense,
        'total': total,
        ...audit.toMap(),
      };

  factory ExpenseRecord.fromMap(String id, Map<String, dynamic> m) => ExpenseRecord(
        id: id,
        date: m['date'] as String? ?? '',
        vehicleId: m['vehicleId'] as String? ?? '',
        vehicleName: m['vehicleName'] as String? ?? '',
        driverId: m['driverId'] as String? ?? '',
        driverName: m['driverName'] as String? ?? '',
        cng: (m['cng'] as num?)?.toDouble() ?? 0,
        petrol: (m['petrol'] as num?)?.toDouble() ?? 0,
        driverSalary: (m['driverSalary'] as num?)?.toDouble() ?? 0,
        rental: (m['rental'] as num?)?.toDouble() ?? 0,
        otherExpense: (m['otherExpense'] as num?)?.toDouble() ?? 0,
        audit: AuditFields.fromMap(m),
      );
}
