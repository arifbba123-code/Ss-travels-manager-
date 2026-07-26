import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../theme/app_theme.dart';

class FleetScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const FleetScreen({super.key, required this.onChanged});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> with SingleTickerProviderStateMixin {
  final _db = DBHelper.instance;
  late TabController _tab;
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final v = await _db.getVehicles();
    final d = await _db.getDrivers();
    if (!mounted) return;
    setState(() {
      _vehicles = v;
      _drivers = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.grey,
          tabs: const [
            Tab(text: 'Vehicles', icon: Icon(Icons.directions_car)),
            Tab(text: 'Drivers', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_vehicleTab(), _driverTab()],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _tab.index == 0 ? _addEditVehicle() : _addEditDriver(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ---------------- VEHICLES ----------------
  Widget _vehicleTab() {
    if (_vehicles.isEmpty) {
      return const Center(child: Text('No vehicles yet. Tap + to add one.', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vehicles.length,
      itemBuilder: (context, i) {
        final v = _vehicles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.blue, child: Icon(Icons.directions_car, color: Colors.white)),
            title: Text(v.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(v.number, style: const TextStyle(color: AppColors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: AppColors.gold), onPressed: () => _addEditVehicle(existing: v)),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.red), onPressed: () => _deleteVehicle(v)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addEditVehicle({Vehicle? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final numberCtrl = TextEditingController(text: existing?.number ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Vehicle Name (e.g. Toyota Innova)')),
            const SizedBox(height: 12),
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Registration Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      if (existing == null) {
        await _db.insertVehicle(Vehicle(name: nameCtrl.text.trim(), number: numberCtrl.text.trim()));
      } else {
        await _db.updateVehicle(Vehicle(id: existing.id, name: nameCtrl.text.trim(), number: numberCtrl.text.trim(), active: existing.active));
      }
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _deleteVehicle(Vehicle v) async {
    final ok = await _confirmDelete('vehicle "${v.name}"');
    if (ok && v.id != null) {
      await _db.deleteVehicle(v.id!);
      await _load();
      widget.onChanged();
    }
  }

  // ---------------- DRIVERS ----------------
  Widget _driverTab() {
    if (_drivers.isEmpty) {
      return const Center(child: Text('No drivers yet. Tap + to add one.', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, i) {
        final d = _drivers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.purple, child: Icon(Icons.person, color: Colors.white)),
            title: Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(d.phone, style: const TextStyle(color: AppColors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: AppColors.gold), onPressed: () => _addEditDriver(existing: d)),
                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.red), onPressed: () => _deleteDriver(d)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addEditDriver({Driver? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text(existing == null ? 'Add Driver' : 'Edit Driver', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      if (existing == null) {
        await _db.insertDriver(Driver(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim()));
      } else {
        await _db.updateDriver(Driver(id: existing.id, name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim(), active: existing.active));
      }
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _deleteDriver(Driver d) async {
    final ok = await _confirmDelete('driver "${d.name}"');
    if (ok && d.id != null) {
      await _db.deleteDriver(d.id!);
      await _load();
      widget.onChanged();
    }
  }

  Future<bool> _confirmDelete(String what) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text('Delete $what? Existing entries will keep their recorded name.',
            style: const TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    return ok ?? false;
  }
}
