import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Porto Prime — oceano, areia e pôr do sol em doses controladas.
  static const ocean900 = Color(0xFF0A312D);
  static const ocean800 = Color(0xFF0C4E47);
  static const ocean700 = Color(0xFF08685D);
  static const ocean600 = Color(0xFF0A8173);
  static const ocean500 = Color(0xFF14A08E);
  static const ocean300 = Color(0xFF83D7C8);
  static const ocean100 = Color(0xFFDFF5EF);
  static const ocean50 = Color(0xFFF0FAF7);

  static const sun500 = Color(0xFFFFB84D);
  static const sun200 = Color(0xFFFFE1A9);
  static const sand100 = Color(0xFFFFF3DD);
  static const sand50 = Color(0xFFFFFAF2);

  static const coral600 = Color(0xFFE85F48);
  static const coral100 = Color(0xFFFFEAE4);
  static const lavender100 = Color(0xFFEDE9FF);
  static const sky100 = Color(0xFFE5F3FB);

  static const ink = Color(0xFF15201D);
  static const inkSoft = Color(0xFF34413D);
  static const muted = Color(0xFF697773);
  static const subtle = Color(0xFF94A09C);
  static const canvas = Color(0xFFF6F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFBFCFA);
  static const stroke = Color(0xFFE4E9E5);
  static const strokeStrong = Color(0xFFD3DDD8);
  static const success = Color(0xFF2D9B70);
  static const warning = Color(0xFFB97918);
  static const danger = coral600;

  // Compatibilidade com telas existentes.
  static const ocean = ocean600;
  static const oceanDeep = ocean800;
  static const turquoise = ocean500;
  static const sun = sun500;
  static const coral = coral600;
  static const coralStrong = coral600;
  static const orange = Color(0xFFFFA95C);
  static const peach = coral100;
  static const cream = sand50;
  static const mint = ocean100;
  static const mintStrong = Color(0xFFCBEADF);
  static const lavender = lavender100;
  static const sky = sky100;
  static const white = surface;
  static const sand = sand100;

  static const primary = ocean600;
  static const primaryDark = ocean800;
  static const accent = coral600;
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

abstract final class AppRadius {
  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

abstract final class AppControl {
  static const minTap = 44.0;
  static const inputHeight = 56.0;
  static const buttonHeight = 54.0;
  static const navHeight = 70.0;
  static const maxContentWidth = 1180.0;
}

abstract final class AppIconSize {
  static const xs = 14.0;
  static const sm = 18.0;
  static const md = 22.0;
  static const lg = 26.0;
  static const xl = 32.0;
  static const hero = 42.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 190);
  static const emphasized = Duration(milliseconds: 260);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class AppBreakpoints {
  static const compact = 380.0;
  static const tablet = 720.0;
  static const desktop = 1024.0;
}

abstract final class AppShadows {
  static final soft = [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: .055),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static final elevated = [
    BoxShadow(
      color: AppColors.ocean900.withValues(alpha: .12),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];

  static final floating = [
    BoxShadow(
      color: AppColors.ocean900.withValues(alpha: .16),
      blurRadius: 38,
      offset: const Offset(0, 18),
    ),
  ];
}

abstract final class AppTypography {
  static TextTheme build(TextTheme base) {
    final manrope = GoogleFonts.manropeTextTheme(base);
    return manrope.copyWith(
      displaySmall: manrope.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: AppColors.ink,
      ),
      headlineLarge: manrope.headlineLarge?.copyWith(
        fontSize: 30,
        height: 1.06,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.ink,
      ),
      headlineMedium: manrope.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -.65,
        color: AppColors.ink,
      ),
      titleLarge: manrope.titleLarge?.copyWith(
        fontSize: 19,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -.35,
        color: AppColors.ink,
      ),
      titleMedium: manrope.titleMedium?.copyWith(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w750,
        color: AppColors.ink,
      ),
      bodyLarge: manrope.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSoft,
      ),
      bodyMedium: manrope.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.muted,
      ),
      bodySmall: manrope.bodySmall?.copyWith(
        fontSize: 11,
        height: 1.4,
        fontWeight: FontWeight.w550,
        color: AppColors.muted,
      ),
      labelLarge: manrope.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w750,
        letterSpacing: -.05,
        color: AppColors.ink,
      ),
      labelMedium: manrope.labelMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .05,
        color: AppColors.muted,
      ),
      labelSmall: manrope.labelSmall?.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w750,
        letterSpacing: .7,
        color: AppColors.muted,
      ),
    );
  }
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ocean700,
        onPrimary: Colors.white,
        secondary: AppColors.sun500,
        onSecondary: AppColors.ink,
        error: AppColors.danger,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.stroke,
      ),
    );

    final textTheme = AppTypography.build(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: AppColors.ocean100.withValues(alpha: .55),
      hoverColor: AppColors.ocean50,
      focusColor: AppColors.ocean100,
      dividerColor: AppColors.stroke,
      iconTheme: const IconThemeData(
        color: AppColors.ink,
        size: AppIconSize.md,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: textTheme.titleMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        constraints: const BoxConstraints(minHeight: AppControl.inputHeight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w650,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ocean700,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.subtle,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w650,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.ocean600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.coral600, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ocean800,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.stroke,
          disabledForegroundColor: AppColors.subtle,
          minimumSize: const Size(AppControl.minTap, AppControl.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ocean800,
          side: const BorderSide(color: AppColors.strokeStrong),
          minimumSize: const Size(AppControl.minTap, AppControl.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ocean700,
          minimumSize: const Size(AppControl.minTap, AppControl.minTap),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.ocean100,
        side: const BorderSide(color: AppColors.stroke),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ocean900,
        contentTextStyle: textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w650,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ocean700,
        linearTrackColor: AppColors.ocean100,
      ),
    );
  }
}
