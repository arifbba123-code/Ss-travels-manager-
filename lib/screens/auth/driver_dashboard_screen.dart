import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../models/entry.dart';
import '../../services/entry_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import 'role_dashboard_widgets.dart';

/// SCREEN 3c — Driver Dashboard
///
/// Driver permissions: Daily Entry, Fuel Entry, Mileage Entry, Own Reports.
/// A driver can only ever see entries tied to their own name/id — never
/// other drivers' data.
class DriverDashboardScreen extends StatefulWidget {
  final AppUser user;
  const DriverDashboardScreen({super.key, required this.user});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<DailyEntry> _myEntries = [];
  bool _loading = true;
  StreamSubscription<List<DailyEntry>>? _sub;

  @override
  void initState() {
    super.initState();
    // Scoped strictly to this driver's own name — never the full fleet.
    // Real-time: any entry an admin adds/edits for this driver, on any
    // device, appears here instantly.
    _sub = EntryRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      setState(() {
        _myEntries = all.where((e) => e.driverName == widget.user.name).toList();
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {} // kept for RefreshIndicator compatibility; stream keeps data live

  String _money(double v) => '₹${NumberFormat('#,##0.##').format(v)}';

  double get _todayCollection {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _myEntries.where((e) => e.date == today).fold(0.0, (s, e) => s + e.totalCollection);
  }

  double get _todayFuel {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _myEntries.where((e) => e.date == today).fold(0.0, (s, e) => s + e.cng + e.petrol);
  }

  double get _monthCollection {
    final now = DateTime.now();
    return _myEntries.where((e) {
      final p = e.date.split('-');
      if (p.length != 3) return false;
      return int.tryParse(p[0]) == now.year && int.tryParse(p[1]) == now.month;
    }).fold(0.0, (s, e) => s + e.totalCollection);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy').format(DateTime.now());
    final recent = _myEntries.take(4).toList();

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
                      badgeColor: AppColors.green,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            titleEn: "Today's Collection",
                            icon: Icons.savings,
                            iconColor: AppColors.green,
                            value: _money(_todayCollection),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            titleEn: "Today's Fuel Spend",
                            icon: Icons.local_gas_station,
                            iconColor: AppColors.orange,
                            value: _money(_todayFuel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatCard(
                      titleEn: 'This Month Collection (You)',
                      icon: Icons.calendar_month,
                      iconColor: AppColors.teal,
                      value: _money(_monthCollection),
                      subtitle: 'Till Date',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => showComingSoon(context, 'Daily Entry'),
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
                              child: Text('Add Today\'s Entry',
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
                    const SectionTitle('Driver Menu'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        QuickTile(
                          icon: Icons.edit_calendar,
                          label: 'Daily Entry',
                          color: AppColors.green,
                          onTap: () => showComingSoon(context, 'Daily Entry'),
                        ),
                        QuickTile(
                          icon: Icons.local_gas_station,
                          label: 'Fuel Entry',
                          color: AppColors.orange,
                          onTap: () => showComingSoon(context, 'Fuel Entry'),
                        ),
                        QuickTile(
                          icon: Icons.speed,
                          label: 'Mileage Entry',
                          color: AppColors.blue,
                          onTap: () => showComingSoon(context, 'Mileage Entry'),
                        ),
                        QuickTile(
                          icon: Icons.bar_chart,
                          label: 'My Reports',
                          color: AppColors.purple,
                          onTap: () => showComingSoon(context, 'My Reports'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle('Recent Entries'),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text('No entries yet — add your first daily entry.',
                              style: TextStyle(color: AppColors.grey, fontSize: 13)),
                        ),
                      )
                    else
                      ...recent.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.panel,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_long,
                                      color: AppColors.green, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.vehicleName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      Text(e.date,
                                          style: const TextStyle(
                                              color: AppColors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(_money(e.totalCollection),
                                    style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ],
                            ),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Fuel'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
