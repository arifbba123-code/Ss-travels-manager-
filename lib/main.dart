import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Core app data (vehicles, drivers, daily entries, PDF/PNG reports)
    // lives entirely in the local SQLite database and never depends on
    // Firebase. If Firebase initialization fails — no network on first
    // launch, missing Play services, etc. — the app should still start
    // normally rather than crashing on the splash screen.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SS Tours & Travels',
      home: const SplashScreen(),
    );
  }
}
