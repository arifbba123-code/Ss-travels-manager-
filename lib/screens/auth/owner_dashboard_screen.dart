import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/db_helper.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import 'role_dashboard_widgets.dart';

/// SCREEN 3a — Owner Dashboard
///
/// Owner logs in directly and gets full access: business-wide stats,
/// admin management, and every module below.
class OwnerDashboardScreen extends StatefulWidget {
  final AppUser user;
  const OwnerDashboardScreen({super.key, required this.user});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _db = DBHelper.instance;
  Map<String, double> _today = {'collection': 0, 'profit': 0};
  Map<String, double> _month = {'collection': 0, 'profit': 0};
  int _vehicleCount = 0;
  int _driverCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await _db.getTodayStats();
    final month = await _db.getThisMonthStats();
    final vehicles = await _db.getVehicles();
    final drivers = await _db.getDrivers();
    if (!mounted) return;
    setState(() {
      _today = today;
      _month = month;
      _vehicleCount = vehicles.where((v) => v.active).length;
      _driverCount = drivers.where((d) => d.active).length;
      _loading = false;
    });
  }

  String _money(double v) => '₹${NumberFormat('#,##0.##').format(v)}';

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
                          onTap: () => showComingSoon(context, 'Reports'),
                        ),
                        QuickTile(
                          icon: Icons.directions_car,
                          label: 'Vehicles',
                          color: AppColors.blue,
                          onTap: () => showComingSoon(context, 'Vehicles'),
                        ),
                        QuickTile(
                          icon: Icons.groups,
                          label: 'Drivers',
                          color: AppColors.purple,
                          onTap: () => showComingSoon(context, 'Drivers'),
                        ),
                        QuickTile(
                          icon: Icons.receipt_long,
                          label: 'Expenses',
                          color: AppColors.orange,
                          onTap: () => showComingSoon(context, 'Expenses'),
                        ),
                        QuickTile(
                          icon: Icons.admin_panel_settings,
                          label: 'Manage Admins',
                          color: AppColors.gold,
                          onTap: () => showComingSoon(context, 'Manage Admins'),
                        ),
                        QuickTile(
                          icon: Icons.person_pin_circle,
                          label: 'Driver Accounts',
                          color: AppColors.teal,
                          onTap: () => showComingSoon(context, 'Driver Accounts'),
                        ),
                        QuickTile(
                          icon: Icons.account_balance_wallet,
                          label: 'Business Ledger',
                          color: AppColors.red,
                          onTap: () => showComingSoon(context, 'Business Ledger'),
                        ),
                        QuickTile(
                          icon: Icons.settings,
                          label: 'Owner Settings',
                          color: AppColors.grey,
                          onTap: () => showComingSoon(context, 'Owner Settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _OwnerNavBar(),
    );
  }
}

class _OwnerNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (_) {},
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Fleet'),
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admins'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
