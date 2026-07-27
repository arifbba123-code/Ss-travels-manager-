import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/admin_management_screen.dart';
import '../screens/auth/audit_log_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/firebase_auth_service.dart';
import '../services/settings_repository.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sendingVerification = false;

  Future<void> _resendVerification() async {
    setState(() => _sendingVerification = true);
    try {
      await FirebaseAuthService.instance.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Verification email sent.')));
      }
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        // Reset the ENTIRE navigator stack to the login screen — settings
        // can be reached several screens deep (Dashboard -> HomeShell ->
        // Settings tab), and simply popping back would strand the user on
        // a now-signed-out dashboard instead of returning them to login.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AuthProvider>().currentAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<Map<String, dynamic>>(
            stream: SettingsRepository.instance.watch(),
            builder: (context, snap) {
              final companyName = snap.data?['companyName'] as String? ?? 'SS Tours & Travels';
              return Container(
                padding: const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.gold,
                        child: Icon(Icons.directions_car, color: Colors.black, size: 30)),
                    const SizedBox(height: 12),
                    Text(companyName,
                        style: const TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text('Manager App', style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 6),
                    const Text('Version 1.0.0', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          if (admin != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: admin.isSuperAdmin ? AppColors.gold : AppColors.blue,
                  child: Icon(admin.isSuperAdmin ? Icons.shield : Icons.person, color: Colors.black),
                ),
                title: Text(admin.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${admin.email}\n${admin.role.label}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                isThreeLine: true,
              ),
            ),
            if (!admin.emailVerified) ...[
              const SizedBox(height: 10),
              Card(
                color: AppColors.orange.withValues(alpha: 0.15),
                child: ListTile(
                  leading: const Icon(Icons.mark_email_unread_outlined, color: AppColors.orange),
                  title: const Text('Email not verified', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Verify your email to secure your account.',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  trailing: _sendingVerification
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                      : TextButton(onPressed: _resendVerification, child: const Text('Resend')),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          _tile(Icons.cloud_done, 'Cloud Sync', 'All data is stored in real time on Firebase Cloud Firestore — changes sync instantly across every admin device.'),
          _tile(Icons.share, 'Reports', 'Generate PDF & PNG reports, share via WhatsApp or any app'),
          _tile(Icons.security, 'Multi-Admin Access', 'Multiple admins can work at the same time from different phones — every change is logged in the Audit Log.'),
          if (admin != null && admin.isSuperAdmin)
            _actionTile(
              Icons.admin_panel_settings,
              'Manage Admins',
              'Create, edit, deactivate or remove admin accounts',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AdminManagementScreen(actingAdmin: admin)),
              ),
            ),
          _actionTile(
            Icons.history,
            'Audit Log',
            'See every create / edit / delete across the app',
            () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
          ),
          _tile(Icons.info_outline, 'About', 'Built for fleet & daily account management'),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.red),
            label: const Text('Log Out', style: TextStyle(color: AppColors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
            onPressed: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
        onTap: onTap,
      ),
    );
  }
}
