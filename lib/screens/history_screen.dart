import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../services/driver_repository.dart';
import '../services/entry_repository.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const HistoryScreen({super.key, required this.onChanged});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();

  List<DailyEntry> _allEntries = [];
  List<DailyEntry> _entries = [];
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];

  Vehicle? _filterVehicle;
  Driver? _filterDriver;
  DateTimeRange? _range;

  StreamSubscription<List<DailyEntry>>? _entriesSub;
  StreamSubscription<List<Vehicle>>? _vehiclesSub;
  StreamSubscription<List<Driver>>? _driversSub;

  @override
  void initState() {
    super.initState();
    // Every filter combination below runs client-side over this one live
    // stream, so search/filter results stay real-time without needing a
    // dedicated Firestore query (and matching index) per combination.
    _entriesSub = EntryRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      _allEntries = all;
      _applyFilters();
    });
    _vehiclesSub = VehicleRepository.instance.watchAll().listen((v) {
      if (!mounted) return;
      setState(() => _vehicles = v);
    });
    _driversSub = DriverRepository.instance.watchAll().listen((d) {
      if (!mounted) return;
      setState(() => _drivers = d);
    });
  }

  @override
  void dispose() {
    _entriesSub?.cancel();
    _vehiclesSub?.cancel();
    _driversSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final results = _allEntries.where((e) {
      if (_filterVehicle != null && e.vehicleId != _filterVehicle!.id) return false;
      if (_filterDriver != null && e.driverId != _filterDriver!.id) return false;
      if (_range != null) {
        final d = DateTime.tryParse(e.date);
        if (d == null) return false;
        final startOk = !d.isBefore(DateTime(_range!.start.year, _range!.start.month, _range!.start.day));
        final endOk = !d.isAfter(DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59));
        if (!startOk || !endOk) return false;
      }
      if (query.isNotEmpty) {
        final haystack = '${e.vehicleName} ${e.driverName} ${e.notes} ${e.date}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
    if (!mounted) return;
    setState(() => _entries = results);
  }

  @override
  Widget build(BuildContext context) {
    double totalCollection = 0, totalProfit = 0;
    for (final e in _entries) {
      totalCollection += e.totalCollection;
      totalProfit += e.profit;
    }

    return Scaffold(
      appBar: const AppScaffoldBar(title: 'Reports & History', subtitle: 'Search & filter entries'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by vehicle, driver, notes, date...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: _filterVehicle?.name ?? 'Vehicle',
                    active: _filterVehicle != null,
                    onTap: _pickVehicleFilter,
                    onClear: _filterVehicle == null ? null : () {
                      setState(() => _filterVehicle = null);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _filterDriver?.name ?? 'Driver',
                    active: _filterDriver != null,
                    onTap: _pickDriverFilter,
                    onClear: _filterDriver == null ? null : () {
                      setState(() => _filterDriver = null);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _range == null
                        ? 'Date Range'
                        : '${DateFormat('dd/MM').format(_range!.start)}-${DateFormat('dd/MM').format(_range!.end)}',
                    active: _range != null,
                    onTap: _pickRange,
                    onClear: _range == null ? null : () {
                      setState(() => _range = null);
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _totalStat('Entries', '${_entries.length}', AppColors.gold),
                _totalStat('Collection', '₹${NumberFormat('#,##0').format(totalCollection)}', AppColors.green),
                _totalStat('Profit', '₹${NumberFormat('#,##0').format(totalProfit)}', AppColors.orange),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text('No entries found', style: TextStyle(color: AppColors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return _entryTile(e);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _totalStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(color: active ? Colors.black : Colors.white, fontSize: 12)),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: active ? Colors.black : AppColors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _entryTile(DailyEntry e) {
    final positive = e.profit >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () async {
          final changed = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: e)),
          );
          if (changed == true) {
            // The Firestore stream already pushed the update — just notify
            // any listeners (e.g. dashboard) that something changed.
            widget.onChanged();
          }
        },
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: positive ? AppColors.green : AppColors.red,
          child: Icon(positive ? Icons.trending_up : Icons.trending_down, color: Colors.white),
        ),
        title: Text('${e.vehicleName} • ${e.driverName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${DateFormat('dd MMM yyyy').format(DateTime.parse(e.date))}\n'
            'Collection ₹${e.totalCollection.toStringAsFixed(0)}  •  Expense ₹${e.totalExpense.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ),
        isThreeLine: true,
        trailing: Text('₹${e.profit.toStringAsFixed(0)}',
            style: TextStyle(
                color: positive ? AppColors.green : AppColors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ),
    );
  }

  Future<void> _pickVehicleFilter() async {
    final selected = await showModalBottomSheet<Vehicle?>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (_) => _pickerSheet(
        title: 'Filter by Vehicle',
        items: _vehicles.map((v) => ListTile(
              title: Text(v.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(v.number, style: const TextStyle(color: AppColors.grey)),
              onTap: () => Navigator.pop(context, v),
            )),
      ),
    );
    if (selected != null) {
      setState(() => _filterVehicle = selected);
      _applyFilters();
    }
  }

  Future<void> _pickDriverFilter() async {
    final selected = await showModalBottomSheet<Driver?>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (_) => _pickerSheet(
        title: 'Filter by Driver',
        items: _drivers.map((d) => ListTile(
              title: Text(d.name, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, d),
            )),
      ),
    );
    if (selected != null) {
      setState(() => _filterDriver = selected);
      _applyFilters();
    }
  }

  Widget _pickerSheet({required String title, required Iterable<Widget> items}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() => _range = picked);
      _applyFilters();
    }
  }
}
