import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/admin_repository.dart';
import '../services/firebase_auth_service.dart';
import 'auth/login_screen.dart';
import 'auth/role_router.dart';

/// Simple branded splash screen. Gives the app its polished first
/// impression, and — if Firebase already has a remembered session
/// (auto-login) — quietly resolves the admin's role and jumps straight
/// to their dashboard instead of requiring another login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? true;
    final user = FirebaseAuthService.instance.currentUser;

    if (user == null) {
      setState(() => _checking = false);
      return;
    }

    if (!rememberMe) {
      // The admin unchecked "Remember me" last time — honor that by not
      // auto-restoring their session on a fresh app launch.
      await FirebaseAuthService.instance.signOut();
      if (!mounted) return;
      setState(() => _checking = false);
      return;
    }

    try {
      final admin = await AdminRepository.instance.resolveOrBootstrap(user);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboardForRole(admin)),
      );
    } catch (_) {
      // Session no longer valid (deactivated / removed) — fall back to
      // showing the normal splash + login flow.
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.gold, size: 56),
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'SS ',
                      style: TextStyle(
                          color: AppColors.gold, fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Text(
                'TOURS & TRAVELS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 4),
              const Text('Manager', style: TextStyle(color: AppColors.gold, fontSize: 14)),
              const SizedBox(height: 40),
              const Text(
                'Welcome Back!',
                style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage your fleet, drivers & daily accounts —\nsynced live across every admin device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _checking
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.login),
                  label: Text(_checking ? 'CHECKING SESSION…' : 'CONTINUE'),
                  onPressed: _checking
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                ),
              ),
              const SizedBox(height: 24),
              const Text('SS Tours & Travels Manager',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
              const Text('Version 1.0.0',
                  style: TextStyle(color: AppColors.grey, fontSize: 11)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
