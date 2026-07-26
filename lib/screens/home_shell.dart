import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'daily_entry_screen.dart';
import 'history_screen.dart';
import 'fleet_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation shell: Home / Entry / Reports / Fleet / Settings
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _refreshTick = 0; // bump to force dashboard/history to reload

  void _refresh() => setState(() => _refreshTick++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(key: ValueKey('dash-$_refreshTick'), onNavigate: _go, onChanged: _refresh),
      DailyEntryScreen(key: ValueKey('entry-$_refreshTick'), onSaved: () {
        _refresh();
        _go(0);
      }),
      HistoryScreen(key: ValueKey('hist-$_refreshTick'), onChanged: _refresh),
      FleetScreen(key: ValueKey('fleet-$_refreshTick'), onChanged: _refresh),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _go,
        selectedFontSize: 12,
        unselectedFontSize: 12,
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

  void _go(int i) => setState(() => _index = i);
}

class AppScaffoldBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const AppScaffoldBar({super.key, required this.title, this.subtitle = '', this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.black,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);
}
