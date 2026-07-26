class DailyEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final int vehicleId;
  final int driverId;
  final String vehicleName; // denormalized for easy display / report
  final String driverName; // denormalized for easy display / report
  final double onlineCollection;
  final double cashCollection;
  final double cng;
  final double petrol;
  final double driverSalary;
  final double rental;
  final double otherExpense;
  final double oldBalance;
  final String notes;

  DailyEntry({
    this.id,
    required this.date,
    required this.vehicleId,
    required this.driverId,
    required this.vehicleName,
    required this.driverName,
    this.onlineCollection = 0,
    this.cashCollection = 0,
    this.cng = 0,
    this.petrol = 0,
    this.driverSalary = 0,
    this.rental = 0,
    this.otherExpense = 0,
    this.oldBalance = 0,
    this.notes = '',
  });

  /// Total money collected (online + cash)
  double get totalCollection => onlineCollection + cashCollection;

  /// Total of all expense fields
  double get totalExpense => cng + petrol + driverSalary + rental + otherExpense;

  /// Profit = Collection - Expense
  double get profit => totalCollection - totalExpense;

  /// Balance = Old balance carried forward + today's profit
  double get balance => oldBalance + profit;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'vehicleId': vehicleId,
        'driverId': driverId,
        'vehicleName': vehicleName,
        'driverName': driverName,
        'onlineCollection': onlineCollection,
        'cashCollection': cashCollection,
        'cng': cng,
        'petrol': petrol,
        'driverSalary': driverSalary,
        'rental': rental,
        'otherExpense': otherExpense,
        'oldBalance': oldBalance,
        'notes': notes,
      };

  factory DailyEntry.fromMap(Map<String, dynamic> m) => DailyEntry(
        id: m['id'] as int?,
        date: m['date'] as String,
        vehicleId: m['vehicleId'] as int,
        driverId: m['driverId'] as int,
        vehicleName: m['vehicleName'] as String? ?? '',
        driverName: m['driverName'] as String? ?? '',
        onlineCollection: (m['onlineCollection'] as num?)?.toDouble() ?? 0,
        cashCollection: (m['cashCollection'] as num?)?.toDouble() ?? 0,
        cng: (m['cng'] as num?)?.toDouble() ?? 0,
        petrol: (m['petrol'] as num?)?.toDouble() ?? 0,
        driverSalary: (m['driverSalary'] as num?)?.toDouble() ?? 0,
        rental: (m['rental'] as num?)?.toDouble() ?? 0,
        otherExpense: (m['otherExpense'] as num?)?.toDouble() ?? 0,
        oldBalance: (m['oldBalance'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String? ?? '',
      );

  DailyEntry copyWith({
    int? id,
    String? date,
    int? vehicleId,
    int? driverId,
    String? vehicleName,
    String? driverName,
    double? onlineCollection,
    double? cashCollection,
    double? cng,
    double? petrol,
    double? driverSalary,
    double? rental,
    double? otherExpense,
    double? oldBalance,
    String? notes,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      vehicleName: vehicleName ?? this.vehicleName,
      driverName: driverName ?? this.driverName,
      onlineCollection: onlineCollection ?? this.onlineCollection,
      cashCollection: cashCollection ?? this.cashCollection,
      cng: cng ?? this.cng,
      petrol: petrol ?? this.petrol,
      driverSalary: driverSalary ?? this.driverSalary,
      rental: rental ?? this.rental,
      otherExpense: otherExpense ?? this.otherExpense,
      oldBalance: oldBalance ?? this.oldBalance,
      notes: notes ?? this.notes,
    );
  }
}
