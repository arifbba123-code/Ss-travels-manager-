import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';

/// Simple branded splash screen. Gives the app its polished first
/// impression before dropping into the authentication flow.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                'Manage your fleet, drivers & daily accounts —\nfully offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('CONTINUE'),
                  onPressed: () {
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
