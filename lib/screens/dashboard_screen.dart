import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/driver.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../services/driver_repository.dart';
import '../services/entry_repository.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import 'home_shell.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  final VoidCallback onChanged;
  const DashboardScreen({super.key, required this.onNavigate, required this.onChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _today = {'collection': 0, 'profit': 0};
  Map<String, double> _month = {'collection': 0, 'profit': 0};
  int _vehicleCount = 0;
  int _driverCount = 0;

  StreamSubscription<List<DailyEntry>>? _entriesSub;
  StreamSubscription<List<Vehicle>>? _vehiclesSub;
  StreamSubscription<List<Driver>>? _driversSub;

  @override
  void initState() {
    super.initState();
    // Firestore streams keep this dashboard live across every admin's
    // device automatically — no manual refresh needed.
    _entriesSub = EntryRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      setState(() {
        _today = EntryStats.todayStats(all);
        _month = EntryStats.thisMonthStats(all);
      });
    });
    _vehiclesSub = VehicleRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      setState(() => _vehicleCount = all.where((v) => v.active).length);
    });
    _driversSub = DriverRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      setState(() => _driverCount = all.where((d) => d.active).length);
    });
  }

  @override
  void dispose() {
    _entriesSub?.cancel();
    _vehiclesSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {} // kept for RefreshIndicator compatibility; streams keep data live

  String _money(double v) => '₹${NumberFormat('#,##0.##').format(v)}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);
    final dayStr = DateFormat('EEEE').format(now);

    return Scaffold(
      appBar: const AppScaffoldBar(title: 'SS Tours & Travels', subtitle: 'Manager'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Welcome back!',
                        style: TextStyle(
                            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(dayStr, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    titleEn: "Today's Collection",
                    icon: Icons.savings,
                    iconColor: AppColors.green,
                    value: _money(_today['collection'] ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    titleEn: "Today's Profit",
                    icon: Icons.show_chart,
                    iconColor: AppColors.orange,
                    value: _money(_today['profit'] ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    titleEn: 'Total Cars',
                    icon: Icons.directions_car,
                    iconColor: AppColors.blue,
                    value: '$_vehicleCount',
                    subtitle: 'Active',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    titleEn: 'Active Drivers',
                    icon: Icons.groups,
                    iconColor: AppColors.purple,
                    value: '$_driverCount',
                    subtitle: 'Active',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    titleEn: 'This Month Collection',
                    icon: Icons.calendar_month,
                    iconColor: AppColors.teal,
                    value: _money(_month['collection'] ?? 0),
                    subtitle: 'Till Date',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    titleEn: 'This Month Profit',
                    icon: Icons.credit_card,
                    iconColor: AppColors.red,
                    value: _money(_month['profit'] ?? 0),
                    subtitle: 'Till Date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => widget.onNavigate(1),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(Icons.add, color: AppColors.gold),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('New Daily Entry',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick Menu', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _quickMenu(Icons.bar_chart, 'Reports', AppColors.green, () => widget.onNavigate(2)),
                _quickMenu(Icons.directions_car, 'Vehicles', AppColors.blue, () => widget.onNavigate(3)),
                _quickMenu(Icons.groups, 'Drivers', AppColors.purple, () => widget.onNavigate(3)),
                _quickMenu(Icons.settings, 'Settings', AppColors.grey, () => widget.onNavigate(4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickMenu(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
