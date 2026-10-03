import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ocean = Color(0xFF007F73);
  static const oceanDeep = Color(0xFF075B54);
  static const turquoise = Color(0xFF16AA9B);
  static const sun = Color(0xFFFFB84D);
  static const coral = Color(0xFFFF6F52);
  static const ink = Color(0xFF14201D);
  static const muted = Color(0xFF687771);
  static const canvas = Color(0xFFF6F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const stroke = Color(0xFFE4EAE6);
  static const sand = Color(0xFFFFF0D2);
  static const mint = Color(0xFFE6F5F0);
  static const mintStrong = Color(0xFFD5EEE7);
  static const success = Color(0xFF148568);
  static const white = Colors.white;
  static const primary = ocean;
  static const primaryDark = oceanDeep;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
}

abstract final class AppSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class AppShadows {
  static final soft = [
    BoxShadow(
      color: const Color(0xFF0E2923).withValues(alpha: .055),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
  static final elevated = [
    BoxShadow(
      color: const Color(0xFF0E2923).withValues(alpha: .11),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ocean,
      surface: AppColors.surface,
    ),
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 31, height: 1.04, fontWeight: FontWeight.w900, letterSpacing: -1.15, color: AppColors.ink),
      headlineMedium: TextStyle(fontSize: 25, height: 1.08, fontWeight: FontWeight.w900, letterSpacing: -.75, color: AppColors.ink),
      titleLarge: TextStyle(fontSize: 20, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.45, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -.2, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.stroke)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.stroke)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.ocean, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.oceanDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
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
