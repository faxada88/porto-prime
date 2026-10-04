import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Porto Prime 2026: vibrante, tropical e claro. Vermelho forte removido.
  static const coral = Color(0xFFFF8A72);
  static const coralStrong = Color(0xFFE96F5B);
  static const orange = Color(0xFFFFAD66);
  static const sun = Color(0xFFFFD76A);
  static const peach = Color(0xFFFFE9DD);
  static const cream = Color(0xFFFFFBF5);
  static const mint = Color(0xFFEAF8F1);
  static const mintStrong = Color(0xFFCDEDDD);
  static const ocean = Color(0xFF53B8A5);
  static const oceanDeep = Color(0xFF238A79);
  static const turquoise = Color(0xFF66C8B5);
  static const lavender = Color(0xFFEDE8FF);
  static const sky = Color(0xFFE5F4FA);
  static const ink = Color(0xFF25312F);
  static const muted = Color(0xFF78827F);
  static const canvas = Color(0xFFFFFBF7);
  static const surface = Color(0xFFFFFFFF);
  static const stroke = Color(0xFFECE9E3);
  static const sand = Color(0xFFFFF0CB);
  static const success = Color(0xFF3CA57E);
  static const white = Colors.white;

  // Ações principais usam verde-petróleo claro para não transformar a UI em vermelho.
  static const primary = oceanDeep;
  static const primaryDark = Color(0xFF1D7467);
  static const accent = coral;
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
      color: const Color(0xFF40534E).withValues(alpha: .07),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
  static final elevated = [
    BoxShadow(
      color: AppColors.oceanDeep.withValues(alpha: .13),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
    splashFactory: NoSplash.splashFactory,
    hoverColor: Colors.transparent,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    focusColor: Colors.transparent,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textTheme: GoogleFonts.manropeTextTheme().copyWith(
      headlineLarge: GoogleFonts.manrope(fontSize: 31, height: 1.04, fontWeight: FontWeight.w800, letterSpacing: -1.15, color: AppColors.ink),
      headlineMedium: GoogleFonts.manrope(fontSize: 25, height: 1.08, fontWeight: FontWeight.w800, letterSpacing: -.75, color: AppColors.ink),
      titleLarge: GoogleFonts.manrope(fontSize: 20, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -.45, color: AppColors.ink),
      titleMedium: GoogleFonts.manrope(fontSize: 16, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -.2, color: AppColors.ink),
      bodyLarge: GoogleFonts.manrope(fontSize: 16, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.ink),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.muted),
      labelLarge: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    fontFamily: GoogleFonts.manrope().fontFamily,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.stroke)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.stroke)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.stroke),
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.mintStrong,
      height: 70,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
