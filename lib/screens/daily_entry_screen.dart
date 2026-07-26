import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

/// Daily Entry form. Also reused for Edit Entry when [existing] is passed.
class DailyEntryScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final DailyEntry? existing;
  const DailyEntryScreen({super.key, required this.onSaved, this.existing});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  final _db = DBHelper.instance;
  final _formKey = GlobalKey<FormState>();

  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];

  DateTime _date = DateTime.now();
  Vehicle? _vehicle;
  Driver? _driver;

  final _online = TextEditingController(text: '0');
  final _cash = TextEditingController(text: '0');
  final _cng = TextEditingController(text: '0');
  final _petrol = TextEditingController(text: '0');
  final _salary = TextEditingController(text: '0');
  final _rental = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _oldBalance = TextEditingController(text: '0');
  final _notes = TextEditingController();

  bool _oldBalanceAuto = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
    for (final c in [_online, _cash, _cng, _petrol, _salary, _rental, _other, _oldBalance]) {
      c.addListener(() => setState(() {}));
    }
    final e = widget.existing;
    if (e != null) {
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
      _online.text = _n(e.onlineCollection);
      _cash.text = _n(e.cashCollection);
      _cng.text = _n(e.cng);
      _petrol.text = _n(e.petrol);
      _salary.text = _n(e.driverSalary);
      _rental.text = _n(e.rental);
      _other.text = _n(e.otherExpense);
      _oldBalance.text = _n(e.oldBalance);
      _notes.text = e.notes;
      _oldBalanceAuto = false;
    }
  }

  String _n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _loadLists() async {
    final vs = await _db.getVehicles();
    final ds = await _db.getDrivers();
    setState(() {
      _vehicles = vs;
      _drivers = ds;
      if (widget.existing != null) {
        _vehicle = vs.where((v) => v.id == widget.existing!.vehicleId).cast<Vehicle?>().firstOrNull;
        _driver = ds.where((d) => d.id == widget.existing!.driverId).cast<Driver?>().firstOrNull;
      } else {
        _vehicle = vs.isNotEmpty ? vs.first : null;
        _driver = ds.isNotEmpty ? ds.first : null;
      }
    });
    if (_oldBalanceAuto && _vehicle != null) _autoFillOldBalance();
  }

  Future<void> _autoFillOldBalance() async {
    if (_vehicle?.id == null) return;
    final bal = await _db.getLastBalanceForVehicle(_vehicle!.id!, excludeEntryId: widget.existing?.id);
    if (!mounted) return;
    setState(() => _oldBalance.text = _n(bal));
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  double get _totalCollection => _d(_online) + _d(_cash);
  double get _totalExpense => _d(_cng) + _d(_petrol) + _d(_salary) + _d(_rental) + _d(_other);
  double get _profit => _totalCollection - _totalExpense;
  double get _balance => _d(_oldBalance) + _profit;

  @override
  void dispose() {
    for (final c in [_online, _cash, _cng, _petrol, _salary, _rental, _other, _oldBalance, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_vehicle == null || _driver == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add a Vehicle and Driver first (Fleet tab).')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final entry = DailyEntry(
      id: widget.existing?.id,
      date: DateFormat('yyyy-MM-dd').format(_date),
      vehicleId: _vehicle!.id!,
      driverId: _driver!.id!,
      vehicleName: _vehicle!.name,
      driverName: _driver!.name,
      onlineCollection: _d(_online),
      cashCollection: _d(_cash),
      cng: _d(_cng),
      petrol: _d(_petrol),
      driverSalary: _d(_salary),
      rental: _d(_rental),
      otherExpense: _d(_other),
      oldBalance: _d(_oldBalance),
      notes: _notes.text.trim(),
    );

    if (widget.existing != null) {
      await _db.updateEntry(entry);
    } else {
      await _db.insertEntry(entry);
    }

    if (!mounted) return;
    if (widget.existing != null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry saved')));
      _resetForm();
    }
    widget.onSaved();
  }

  void _resetForm() {
    for (final c in [_online, _cash, _cng, _petrol, _salary, _rental, _other]) {
      c.text = '0';
    }
    _notes.clear();
    _oldBalanceAuto = true;
    _autoFillOldBalance();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    final body = _vehicles.isEmpty || _drivers.isEmpty
        ? _emptyState()
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionLabel('Trip Details'),
                _dateField(),
                const SizedBox(height: 12),
                _vehicleDropdown(),
                const SizedBox(height: 12),
                _driverDropdown(),
                const SizedBox(height: 20),
                _sectionLabel('Collection'),
                _numField(_online, 'Online Collection', Icons.qr_code_scanner),
                const SizedBox(height: 12),
                _numField(_cash, 'Cash Collection', Icons.money),
                const SizedBox(height: 20),
                _sectionLabel('Expenses'),
                _numField(_cng, 'CNG', Icons.local_gas_station),
                const SizedBox(height: 12),
                _numField(_petrol, 'Petrol', Icons.local_gas_station_outlined),
                const SizedBox(height: 12),
                _numField(_salary, 'Driver Salary', Icons.badge),
                const SizedBox(height: 12),
                _numField(_rental, 'Rental', Icons.home_work),
                const SizedBox(height: 12),
                _numField(_other, 'Other Expense', Icons.receipt_long),
                const SizedBox(height: 20),
                _sectionLabel('Balance'),
                _numField(_oldBalance, 'Old Balance', Icons.account_balance_wallet, onChangedManual: () {
                  _oldBalanceAuto = false;
                }),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 20),
                _summaryCard(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(isEdit ? Icons.save : Icons.check_circle),
                  label: Text(isEdit ? 'UPDATE ENTRY' : 'SAVE ENTRY'),
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
              ],
            ),
          );

    if (isEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Entry')),
        body: body,
      );
    }

    return Scaffold(
      appBar: const AppScaffoldBar(title: 'New Daily Entry', subtitle: 'Add today\'s account'),
      body: body,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline, color: AppColors.gold, size: 48),
            SizedBox(height: 12),
            Text('Add at least one Vehicle and Driver in the Fleet tab before creating a daily entry.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(data: Theme.of(context), child: child!),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.gold),
        ),
        child: Text(DateFormat('dd MMM yyyy (EEEE)').format(_date),
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _vehicleDropdown() {
    return DropdownButtonFormField<Vehicle>(
      value: _vehicle,
      decoration: const InputDecoration(
        labelText: 'Vehicle',
        prefixIcon: Icon(Icons.directions_car, color: AppColors.gold),
      ),
      dropdownColor: AppColors.panel2,
      items: _vehicles
          .map((v) => DropdownMenuItem(value: v, child: Text('${v.name} (${v.number})')))
          .toList(),
      onChanged: (v) {
        setState(() => _vehicle = v);
        if (_oldBalanceAuto) _autoFillOldBalance();
      },
      validator: (v) => v == null ? 'Select a vehicle' : null,
    );
  }

  Widget _driverDropdown() {
    return DropdownButtonFormField<Driver>(
      value: _driver,
      decoration: const InputDecoration(
        labelText: 'Driver',
        prefixIcon: Icon(Icons.person, color: AppColors.gold),
      ),
      dropdownColor: AppColors.panel2,
      items: _drivers.map((d) => DropdownMenuItem(value: d, child: Text(d.name))).toList(),
      onChanged: (d) => setState(() => _driver = d),
      validator: (d) => d == null ? 'Select a driver' : null,
    );
  }

  Widget _numField(TextEditingController c, String label, IconData icon, {VoidCallback? onChangedManual}) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChangedManual?.call(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.gold),
        prefixText: '₹ ',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        if (double.tryParse(v.trim()) == null) return 'Invalid number';
        return null;
      },
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _summaryRow('Total Collection', _totalCollection, AppColors.green),
          _summaryRow('Total Expense', _totalExpense, AppColors.red),
          const Divider(),
          _summaryRow('Profit', _profit, _profit >= 0 ? AppColors.green : AppColors.red, bold: true),
          _summaryRow('Balance (carry forward)', _balance, AppColors.gold, bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.bold : null)),
          Text('₹${value.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
