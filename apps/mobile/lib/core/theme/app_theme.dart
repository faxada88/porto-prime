import 'package:flutter/material.dart';

abstract final class AppColors {
  // Identidade visual original Porto Prime.
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

  // Tokens adicionais mantidos apenas para compatibilidade das telas funcionais
  // (cadastro, checkout, candidatura etc.), sem alterar a identidade original.
  static const coralStrong = Color(0xFFE95F45);
  static const orange = Color(0xFFFFA95C);
  static const peach = Color(0xFFFFE9DD);
  static const cream = Color(0xFFFFFAF3);
  static const mintStrong = Color(0xFFCDEDDD);
  static const lavender = Color(0xFFE9E4FF);
  static const sky = Color(0xFFDDEEFF);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE9ECE7);
  static const success = Color(0xFF3CA57E);

  static const primary = ocean;
  static const primaryDark = oceanDeep;
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
      color: const Color(0xFF17201E).withValues(alpha: .07),
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
      seedColor: AppColors.ocean,
      primary: AppColors.ocean,
      secondary: AppColors.coral,
      surface: AppColors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 31,
        height: 1.05,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.1,
        color: AppColors.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.08,
        fontWeight: FontWeight.w900,
        letterSpacing: -.7,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -.4,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.4,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: AppColors.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.ink,
      size: 22,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.oceanDeep,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA5A1),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: AppColors.ocean, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: AppColors.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: AppColors.coralStrong, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.oceanDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.oceanDeep,
        side: const BorderSide(color: AppColors.stroke),
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -.1,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF17332E),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
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
