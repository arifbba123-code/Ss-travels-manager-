import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'owner_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'driver_dashboard_screen.dart';

/// SCREEN 2 — Loading
///
/// Shown right after the user taps Login. Verifies the email/password,
/// looks up the account's role in the `users` table, then routes to the
/// matching dashboard — Owner, Admin, or Driver.
class AuthLoadingScreen extends StatefulWidget {
  final String email;
  final String password;
  const AuthLoadingScreen({super.key, required this.email, required this.password});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  String _status = 'Verifying credentials…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final user = await AuthService.instance.login(
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;
      setState(() => _status = 'Checking account role…');
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      setState(() => _status = 'Setting up ${user.role.label} dashboard…');
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      _routeByRole(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      _fail(e.message);
    } catch (_) {
      if (!mounted) return;
      _fail('Something went wrong. Please try again.');
    }
  }

  void _routeByRole(AppUser user) {
    late final Widget dashboard;
    switch (user.role) {
      case UserRole.owner:
        dashboard = OwnerDashboardScreen(user: user);
        break;
      case UserRole.admin:
        dashboard = AdminDashboardScreen(user: user);
        break;
      case UserRole.driver:
        dashboard = DriverDashboardScreen(user: user);
        break;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }

  void _fail(String message) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.panel2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.panel,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text('SS Tours & Travels',
                style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _status,
                key: ValueKey(_status),
                style: const TextStyle(color: AppColors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
