import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp();

    // Enable Firestore's offline cache so admins keep working (reading
    // cached data, queueing writes) even with a flaky connection — writes
    // sync automatically the moment connectivity returns. This is on by
    // default on Android/iOS, but set explicitly for clarity and to size
    // the cache generously for a growing fleet dataset.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // The whole app is now backed by Firebase (Auth + Firestore) — if it
    // fails to initialize (missing/invalid google-services.json, no Play
    // Services, etc.) the app cannot function, so surface a clear error
    // screen instead of silently continuing into a broken UI.
    initError = e.toString();
  }

  runApp(MyApp(initError: initError));
}

class MyApp extends StatelessWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: _FirebaseInitErrorScreen(error: initError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SS Tours & Travels',
        theme: AppTheme.dark,
        home: const SplashScreen(),
      ),
    );
  }
}

class _FirebaseInitErrorScreen extends StatelessWidget {
  final String error;
  const _FirebaseInitErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.red, size: 56),
                const SizedBox(height: 16),
                const Text('Could not connect to Firebase',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Check your internet connection and that google-services.json is correctly configured, then restart the app.',
                  style: TextStyle(color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: AppColors.grey, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
