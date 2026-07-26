import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/entry.dart';

/// Singleton SQLite database helper. Fully offline — no network calls.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sstours_travels.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vehicles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            number TEXT NOT NULL,
            active INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE drivers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            active INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            vehicleId INTEGER NOT NULL,
            driverId INTEGER NOT NULL,
            vehicleName TEXT NOT NULL,
            driverName TEXT NOT NULL,
            onlineCollection REAL NOT NULL DEFAULT 0,
            cashCollection REAL NOT NULL DEFAULT 0,
            cng REAL NOT NULL DEFAULT 0,
            petrol REAL NOT NULL DEFAULT 0,
            driverSalary REAL NOT NULL DEFAULT 0,
            rental REAL NOT NULL DEFAULT 0,
            otherExpense REAL NOT NULL DEFAULT 0,
            oldBalance REAL NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );
  }

  // ---------------- VEHICLES ----------------
  Future<int> insertVehicle(Vehicle v) async {
    final db = await database;
    return db.insert('vehicles', v.toMap()..remove('id'));
  }

  Future<int> updateVehicle(Vehicle v) async {
    final db = await database;
    return db.update('vehicles', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'name ASC');
    return rows.map((e) => Vehicle.fromMap(e)).toList();
  }

  // ---------------- DRIVERS ----------------
  Future<int> insertDriver(Driver d) async {
    final db = await database;
    return db.insert('drivers', d.toMap()..remove('id'));
  }

  Future<int> updateDriver(Driver d) async {
    final db = await database;
    return db.update('drivers', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<int> deleteDriver(int id) async {
    final db = await database;
    return db.delete('drivers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Driver>> getDrivers() async {
    final db = await database;
    final rows = await db.query('drivers', orderBy: 'name ASC');
    return rows.map((e) => Driver.fromMap(e)).toList();
  }

  // ---------------- ENTRIES ----------------
  Future<int> insertEntry(DailyEntry e) async {
    final db = await database;
    return db.insert('entries', e.toMap()..remove('id'));
  }

  Future<int> updateEntry(DailyEntry e) async {
    final db = await database;
    return db.update('entries', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DailyEntry>> getEntries() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'date DESC, id DESC');
    return rows.map((e) => DailyEntry.fromMap(e)).toList();
  }

  Future<List<DailyEntry>> searchEntries({
    String? query,
    int? vehicleId,
    int? driverId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (vehicleId != null) {
      where.add('vehicleId = ?');
      args.add(vehicleId);
    }
    if (driverId != null) {
      where.add('driverId = ?');
      args.add(driverId);
    }
    if (from != null) {
      where.add('date >= ?');
      args.add(_fmt(from));
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(_fmt(to));
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('(vehicleName LIKE ? OR driverName LIKE ? OR notes LIKE ? OR date LIKE ?)');
      final like = '%${query.trim()}%';
      args.addAll([like, like, like, like]);
    }

    final rows = await db.query(
      'entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((e) => DailyEntry.fromMap(e)).toList();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Latest balance for a given vehicle, used to auto-fill "Old Balance"
  Future<double> getLastBalanceForVehicle(int vehicleId, {int? excludeEntryId}) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: excludeEntryId != null ? 'vehicleId = ? AND id != ?' : 'vehicleId = ?',
      whereArgs: excludeEntryId != null ? [vehicleId, excludeEntryId] : [vehicleId],
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    final e = DailyEntry.fromMap(rows.first);
    return e.balance;
  }

  // ---------------- DASHBOARD AGGREGATES ----------------
  Future<Map<String, double>> getTodayStats() async {
    final today = _fmt(DateTime.now());
    final all = await getEntries();
    final todays = all.where((e) => e.date == today);
    double collection = 0, profit = 0;
    for (final e in todays) {
      collection += e.totalCollection;
      profit += e.profit;
    }
    return {'collection': collection, 'profit': profit};
  }

  Future<Map<String, double>> getThisMonthStats() async {
    final now = DateTime.now();
    final all = await getEntries();
    final monthly = all.where((e) {
      final parts = e.date.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return y == now.year && m == now.month;
    });
    double collection = 0, profit = 0;
    for (final e in monthly) {
      collection += e.totalCollection;
      profit += e.profit;
    }
    return {'collection': collection, 'profit': profit};
  }
}
