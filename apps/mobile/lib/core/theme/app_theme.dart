import 'package:flutter/material.dart';

abstract final class AppColors {
  static const coral = Color(0xFFFF3D4F);
  static const coralStrong = Color(0xFFE91F36);
  static const orange = Color(0xFFFF8A3D);
  static const sun = Color(0xFFFFC64B);
  static const peach = Color(0xFFFFE2D1);
  static const cream = Color(0xFFFFF8F1);
  static const mint = Color(0xFFEAF7F1);
  static const mintStrong = Color(0xFFD9F0E7);
  static const ocean = Color(0xFFFF5B50);
  static const oceanDeep = coralStrong;
  static const turquoise = Color(0xFFFF8A62);
  static const ink = Color(0xFF202329);
  static const muted = Color(0xFF777A80);
  static const canvas = Color(0xFFFFFAF5);
  static const surface = Color(0xFFFFFFFF);
  static const stroke = Color(0xFFF0E9E3);
  static const sand = Color(0xFFFFEDC9);
  static const success = Color(0xFF22A06B);
  static const white = Colors.white;
  static const primary = coral;
  static const primaryDark = coralStrong;
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
      color: const Color(0xFF7B4B34).withValues(alpha: .07),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
  static final elevated = [
    BoxShadow(
      color: AppColors.coral.withValues(alpha: .16),
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
      seedColor: AppColors.coral,
      surface: AppColors.surface,
      brightness: Brightness.light,
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.coral, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.peach,
      height: 70,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
