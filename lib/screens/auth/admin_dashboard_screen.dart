import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/driver.dart';
import '../../models/entry.dart';
import '../../models/vehicle.dart';
import '../../models/app_user.dart';
import '../../services/driver_repository.dart';
import '../../services/entry_repository.dart';
import '../../services/vehicle_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../home_shell.dart';
import 'role_dashboard_widgets.dart';

/// SCREEN 3b — Admin Dashboard
///
/// Admin permissions: Daily Reports, Vehicles, Drivers, Expenses, Reports.
/// No Owner-only settings are shown.
class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, double> _today = {'collection': 0, 'profit': 0};
  Map<String, double> _month = {'collection': 0, 'profit': 0};
  int _vehicleCount = 0;
  int _driverCount = 0;
  bool _loading = true;

  StreamSubscription<List<DailyEntry>>? _entriesSub;
  StreamSubscription<List<Vehicle>>? _vehiclesSub;
  StreamSubscription<List<Driver>>? _driversSub;

  @override
  void initState() {
    super.initState();
    _entriesSub = EntryRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      setState(() {
        _today = EntryStats.todayStats(all);
        _month = EntryStats.thisMonthStats(all);
        _loading = false;
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

  void _openFullManager() {
    // The existing offline fleet manager (daily entry, reports, fleet,
    // settings) doubles as the Admin's day-to-day workspace.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.gold,
          backgroundColor: AppColors.panel,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    RoleHeaderCard(
                      user: widget.user,
                      dateLabel: dateLabel,
                      badgeColor: AppColors.blue,
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
                      onTap: _openFullManager,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
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
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle('Admin Menu'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        QuickTile(
                          icon: Icons.receipt_long,
                          label: 'Daily Reports',
                          color: AppColors.green,
                          onTap: _openFullManager,
                        ),
                        QuickTile(
                          icon: Icons.directions_car,
                          label: 'Vehicles',
                          color: AppColors.blue,
                          onTap: _openFullManager,
                        ),
                        QuickTile(
                          icon: Icons.groups,
                          label: 'Drivers',
                          color: AppColors.purple,
                          onTap: _openFullManager,
                        ),
                        QuickTile(
                          icon: Icons.account_balance_wallet,
                          label: 'Expenses',
                          color: AppColors.orange,
                          onTap: _openFullManager,
                        ),
                        QuickTile(
                          icon: Icons.bar_chart,
                          label: 'Reports',
                          color: AppColors.teal,
                          onTap: _openFullManager,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i != 0) _openFullManager();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Fleet'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
