import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/admin_repository.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/app_theme.dart';
import 'role_router.dart';

/// SCREEN 2 — Loading
///
/// Shown right after the user taps Login.
/// Authenticates with Firebase, resolves the account's role from the
/// Firestore `admins` collection, then routes to the matching dashboard.
///
/// NOTE: Google Sign-In is temporarily removed (email/password only).
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
      final firebaseUser = await FirebaseAuthService.instance
          .signInWithEmail(email: widget.email, password: widget.password);

      if (!mounted) return;
      setState(() => _status = 'Checking account role…');

      final user = await AdminRepository.instance.resolveOrBootstrap(firebaseUser);

      if (!mounted) return;
      setState(() => _status = 'Setting up ${user.role.label} dashboard…');
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;
      _routeByRole(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      _fail(e.message);
    } catch (e) {
      if (!mounted) return;
      _fail('Something went wrong. Please try again.');
    }
  }

  void _routeByRole(AppUser user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboardForRole(user)),
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
