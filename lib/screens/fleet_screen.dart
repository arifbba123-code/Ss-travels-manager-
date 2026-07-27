import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../services/vehicle_repository.dart';
import '../services/driver_repository.dart';
import '../theme/app_theme.dart';

class FleetScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const FleetScreen({super.key, required this.onChanged});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
    return StreamBuilder<List<Vehicle>>(
      stream: VehicleRepository.instance.watchAll(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final vehicles = snap.data!;
        if (vehicles.isEmpty) {
          return const Center(
              child: Text('No vehicles yet. Tap + to add one.', style: TextStyle(color: AppColors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, i) {
            final v = vehicles[i];
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
      final acting = context.read<AuthProvider>().currentAdmin!;
      if (existing == null) {
        await VehicleRepository.instance
            .create(Vehicle(name: nameCtrl.text.trim(), number: numberCtrl.text.trim()), acting);
      } else {
        await VehicleRepository.instance.update(
            existing.copyWith(name: nameCtrl.text.trim(), number: numberCtrl.text.trim()), acting);
      }
      widget.onChanged();
    }
  }

  Future<void> _deleteVehicle(Vehicle v) async {
    final ok = await _confirmDelete('vehicle "${v.name}"');
    if (ok && v.id != null) {
      final acting = context.read<AuthProvider>().currentAdmin!;
      await VehicleRepository.instance.delete(v, acting);
      widget.onChanged();
    }
  }

  // ---------------- DRIVERS ----------------
  Widget _driverTab() {
    return StreamBuilder<List<Driver>>(
      stream: DriverRepository.instance.watchAll(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }
        final drivers = snap.data!;
        if (drivers.isEmpty) {
          return const Center(
              child: Text('No drivers yet. Tap + to add one.', style: TextStyle(color: AppColors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, i) {
            final d = drivers[i];
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
      final acting = context.read<AuthProvider>().currentAdmin!;
      if (existing == null) {
        await DriverRepository.instance
            .create(Driver(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim()), acting);
      } else {
        await DriverRepository.instance.update(
            existing.copyWith(name: nameCtrl.text.trim(), phone: phoneCtrl.text.trim()), acting);
      }
      widget.onChanged();
    }
  }

  Future<void> _deleteDriver(Driver d) async {
    final ok = await _confirmDelete('driver "${d.name}"');
    if (ok && d.id != null) {
      final acting = context.read<AuthProvider>().currentAdmin!;
      await DriverRepository.instance.delete(d, acting);
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
