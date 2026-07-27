import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../models/entry.dart';
import '../providers/auth_provider.dart';
import '../services/entry_repository.dart';
import '../services/reports_log_repository.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'daily_entry_screen.dart';

/// View a single entry, with Edit / Delete / Share (PDF & PNG) actions.
class EntryDetailScreen extends StatefulWidget {
  final DailyEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  final _screenshotController = ScreenshotController();
  late DailyEntry _entry;
  bool _busy = false;
  bool _changed = false;
  StreamSubscription<List<DailyEntry>>? _sub;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    // Real-time: if another admin edits this exact entry on another
    // device while this screen is open, it updates here instantly too.
    _sub = EntryRepository.instance.watchAll().listen((all) {
      if (!mounted) return;
      final match = all.where((e) => e.id == _entry.id);
      if (match.isNotEmpty) setState(() => _entry = match.first);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyEntryScreen(existing: _entry, onSaved: () {}),
      ),
    );
    if (result == true) {
      // The live stream in initState already refreshes `_entry`.
      _changed = true;
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone. Delete this entry?',
            style: TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true && _entry.id != null) {
      final acting = context.read<AuthProvider>().currentAdmin!;
      await EntryRepository.instance.delete(_entry, acting);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      await ReportService.sharePdf(_entry);
      final acting = context.read<AuthProvider>().currentAdmin;
      if (acting != null) {
        await ReportsLogRepository.instance.logGenerated(entry: _entry, format: 'pdf', actingAdmin: acting);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePng() async {
    setState(() => _busy = true);
    try {
      final file = await ReportService.generatePng(_screenshotController);
      await ReportService.sharePng(file, _entry);
      final acting = context.read<AuthProvider>().currentAdmin;
      if (acting != null) {
        await ReportsLogRepository.instance.logGenerated(entry: _entry, format: 'png', actingAdmin: acting);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entry Details'),
          actions: [
            IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: ReportService.buildReportWidget(_entry),
                  ),
                ),
                const SizedBox(height: 20),
                if (_entry.notes.trim().isNotEmpty) ...[
                  const Text('Notes', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_entry.notes, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Share PDF'),
                        onPressed: _busy ? null : _sharePdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Share PNG'),
                        onPressed: _busy ? null : _sharePng,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the system share sheet to send the report via WhatsApp or any other app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
            if (_busy)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              ),
          ],
        ),
      ),
    );
  }
}
