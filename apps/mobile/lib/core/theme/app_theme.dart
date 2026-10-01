import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ocean = Color(0xFF007F73);
  static const oceanDeep = Color(0xFF00675E);
  static const turquoise = Color(0xFF17B7A6);
  static const sun = Color(0xFFFFB84D);
  static const coral = Color(0xFFFF7456);
  static const ink = Color(0xFF17201E);
  static const muted = Color(0xFF6E7A76);
  static const canvas = Color(0xFFF7F8F4);
  static const sand = Color(0xFFFFF1D5);
  static const mint = Color(0xFFE8F7F2);
  static const white = Colors.white;
  static const primary = ocean;
  static const primaryDark = oceanDeep;
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ocean, surface: AppColors.white),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 31, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: AppColors.ink),
      headlineMedium: TextStyle(fontSize: 25, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.7, color: AppColors.ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.4, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.mint,
      height: 70,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
