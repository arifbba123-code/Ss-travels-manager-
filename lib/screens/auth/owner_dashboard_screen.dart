import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../models/driver.dart';
import '../../models/entry.dart';
import '../../models/vehicle.dart';
import '../../services/driver_repository.dart';
import '../../services/entry_repository.dart';
import '../../services/vehicle_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../home_shell.dart';
import 'admin_management_screen.dart';
import 'audit_log_screen.dart';
import 'role_dashboard_widgets.dart';

/// SCREEN 3a — Super Admin Dashboard
///
/// Super Admin gets full access: business-wide real-time stats, admin
/// management (create / edit / deactivate / delete Admins), and the
/// full fleet manager below.
class OwnerDashboardScreen extends StatefulWidget {
  final AppUser user;
  const OwnerDashboardScreen({super.key, required this.user});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
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

  String _money(double v) => '₹${NumberFormat('#,##0.##').format(v)}';

  void _openFullManager() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  void _openManageAdmins() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminManagementScreen(actingAdmin: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RoleHeaderCard(
                    user: widget.user,
                    dateLabel: dateLabel,
                    badgeColor: AppColors.gold,
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
                  const SizedBox(height: 20),
                  const SectionTitle('Business Management'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      QuickTile(
                        icon: Icons.bar_chart,
                        label: 'Reports',
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
                        icon: Icons.receipt_long,
                        label: 'Expenses',
                        color: AppColors.orange,
                        onTap: _openFullManager,
                      ),
                      QuickTile(
                        icon: Icons.admin_panel_settings,
                        label: 'Manage Admins',
                        color: AppColors.gold,
                        onTap: _openManageAdmins,
                      ),
                      QuickTile(
                        icon: Icons.history,
                        label: 'Audit Log',
                        color: AppColors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                        ),
                      ),
                      QuickTile(
                        icon: Icons.account_balance_wallet,
                        label: 'Daily Entry',
                        color: AppColors.red,
                        onTap: _openFullManager,
                      ),
                      QuickTile(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: AppColors.grey,
                        onTap: _openFullManager,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
