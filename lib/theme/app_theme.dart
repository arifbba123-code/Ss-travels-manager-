import 'package:flutter/material.dart';

/// Central Black & Gold theme for SS Tours & Travels
class AppColors {
  static const Color black = Color(0xFF0B0B0B);
  static const Color panel = Color(0xFF161616);
  static const Color panel2 = Color(0xFF1E1E1E);
  static const Color gold = Color(0xFFF2B705);
  static const Color goldDark = Color(0xFFC98E03);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFAFAFAF);
  static const Color green = Color(0xFF2ECC71);
  static const Color orange = Color(0xFFE67E22);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF9B59B6);
  static const Color teal = Color(0xFF16A085);
  static const Color red = Color(0xFFE84C6B);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      primaryColor: AppColors.gold,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.gold,
        surface: AppColors.panel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        foregroundColor: AppColors.white,
        titleTextStyle: TextStyle(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.grey),
        hintStyle: const TextStyle(color: AppColors.grey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.white),
        bodyLarge: TextStyle(color: AppColors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.black,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2A2A)),
    );
  }
}
