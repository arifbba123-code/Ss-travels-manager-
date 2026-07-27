import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log_service.dart';
import '../../theme/app_theme.dart';

/// Real-time "who changed what, when" view across every collection —
/// vehicles, drivers, daily entries and admins. Every admin sees the
/// exact same log the instant a change happens on any device.
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  Color _actionColor(AuditAction a) {
    switch (a) {
      case AuditAction.create:
        return AppColors.green;
      case AuditAction.update:
        return AppColors.orange;
      case AuditAction.delete:
        return AppColors.red;
    }
  }

  IconData _actionIcon(AuditAction a) {
    switch (a) {
      case AuditAction.create:
        return Icons.add_circle_outline;
      case AuditAction.update:
        return Icons.edit_outlined;
      case AuditAction.delete:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: StreamBuilder<List<AuditLogEntry>>(
        stream: AuditLogService.instance.watchRecent(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          final logs = snap.data!;
          if (logs.isEmpty) {
            return const Center(
                child: Text('No activity yet.', style: TextStyle(color: AppColors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_actionIcon(log.action), color: _actionColor(log.action)),
                  title: Text(log.summary, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    log.timestamp != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(log.timestamp!)
                        : 'Just now',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
