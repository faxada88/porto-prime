import 'package:flutter/material.dart';

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
  static const violet600 = Color(0xFF6D5AA8);
  static const sky100 = Color(0xFFE5F3FB);
  static const sky700 = Color(0xFF356D8D);

  static const ink = Color(0xFF15201D);
  static const inkSoft = Color(0xFF34413D);
  static const muted = Color(0xFF697773);
  static const subtle = Color(0xFF94A09C);
  static const canvas = Color(0xFFF6F7F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFBFCFA);
  static const surfaceMuted = Color(0xFFF1F4F1);
  static const surfaceSun = Color(0xFFFFFBF3);
  static const surfaceOcean = Color(0xFFF3FBF8);
  static const overlay = Color(0x99061210);
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
  static const none = 0.0;
  static const micro = 2.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
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
  static const comfortableTap = 48.0;
  static const inputHeight = 56.0;
  static const buttonHeight = 54.0;
  static const compactButtonHeight = 40.0;
  static const navHeight = 72.0;
  static const maxContentWidth = 1180.0;
  static const productCardMinWidth = 164.0;
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
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const emphasized = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve entrance = Curves.easeOutQuart;

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

abstract final class AppBreakpoints {
  static const compact = 380.0;
  static const tablet = 720.0;
  static const desktop = 1024.0;
}

abstract final class AppBorder {
  static const hairline = 1.0;
  static const focus = 1.5;
}

abstract final class AppLayer {
  static const content = 0;
  static const sticky = 10;
  static const navigation = 20;
  static const overlay = 40;
  static const modal = 60;
  static const toast = 80;
}

abstract final class AppResponsive {
  static double metricHeight(BuildContext context) =>
      146 +
      (MediaQuery.textScalerOf(context).scale(12) - 12)
              .clamp(0, 32)
              .toDouble() *
          5;
  static int categoryColumns(double width) {
    if (width >= 460) return 5;
    if (width >= 352) return 4;
    return 3;
  }

  static double categoryHeight(BuildContext context) =>
      120.0 +
      (MediaQuery.textScalerOf(context).scale(12) - 12)
              .clamp(0, 32)
              .toDouble() *
          4;

  static double productHeight(BuildContext context, double width) =>
      width.clamp(140, 240).toDouble() +
      176 +
      (MediaQuery.textScalerOf(context).scale(14) - 14)
              .clamp(0, 32)
              .toDouble() *
          12;

  static int productColumns(double width) {
    if (width >= 1080) return 5;
    if (width >= 820) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  static EdgeInsets pagePadding(double width) => EdgeInsets.symmetric(
    horizontal: width >= AppBreakpoints.tablet ? 28 : 20,
  );
}

abstract final class AppFontSize {
  static const caption = 11.0;
  static const label = 12.0;
  static const body = 14.0;
  static const input = 16.0;
  static const title = 20.0;
  static const headline = 28.0;
}

abstract final class AppFontWeight {
  static const regular = FontWeight.w500;
  static const medium = FontWeight.w600;
  static const strong = FontWeight.w700;
  static const display = FontWeight.w800;
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
    final manrope = base.apply(fontFamily: 'Manrope');
    return manrope.copyWith(
      displaySmall: manrope.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.04,
        fontWeight: AppFontWeight.display,
        letterSpacing: -1.2,
        color: AppColors.ink,
      ),
      headlineLarge: manrope.headlineLarge?.copyWith(
        fontSize: 30,
        height: 1.06,
        fontWeight: AppFontWeight.display,
        letterSpacing: -1.0,
        color: AppColors.ink,
      ),
      headlineMedium: manrope.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.08,
        fontWeight: AppFontWeight.display,
        letterSpacing: -.65,
        color: AppColors.ink,
      ),
      titleLarge: manrope.titleLarge?.copyWith(
        fontSize: 19,
        height: 1.15,
        fontWeight: AppFontWeight.display,
        letterSpacing: -.35,
        color: AppColors.ink,
      ),
      titleMedium: manrope.titleMedium?.copyWith(
        fontSize: 15,
        height: 1.2,
        fontWeight: AppFontWeight.strong,
        color: AppColors.ink,
      ),
      bodyLarge: manrope.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.45,
        fontWeight: AppFontWeight.regular,
        color: AppColors.inkSoft,
      ),
      bodyMedium: manrope.bodyMedium?.copyWith(
        fontSize: AppFontSize.body,
        height: 1.45,
        fontWeight: AppFontWeight.regular,
        color: AppColors.muted,
      ),
      bodySmall: manrope.bodySmall?.copyWith(
        fontSize: AppFontSize.label,
        height: 1.4,
        fontWeight: AppFontWeight.regular,
        color: AppColors.muted,
      ),
      labelLarge: manrope.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: AppFontWeight.strong,
        letterSpacing: -.05,
        color: AppColors.ink,
      ),
      labelMedium: manrope.labelMedium?.copyWith(
        fontSize: AppFontSize.label,
        fontWeight: AppFontWeight.strong,
        letterSpacing: .05,
        color: AppColors.muted,
      ),
      labelSmall: manrope.labelSmall?.copyWith(
        fontSize: AppFontSize.caption,
        fontWeight: AppFontWeight.strong,
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
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.ocean100.withValues(alpha: .42),
      hoverColor: AppColors.ocean50,
      focusColor: AppColors.ocean100.withValues(alpha: .82),
      dividerColor: AppColors.stroke,
      disabledColor: AppColors.subtle.withValues(alpha: .45),
      visualDensity: VisualDensity.standard,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: AppFontWeight.medium,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ocean700,
          fontWeight: AppFontWeight.display,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
          fontWeight: AppFontWeight.medium,
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
          borderSide: const BorderSide(color: AppColors.ocean600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral600, width: 1.5),
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
            fontWeight: AppFontWeight.display,
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
            fontWeight: AppFontWeight.display,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ocean700,
          minimumSize: const Size(AppControl.minTap, AppControl.minTap),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: AppFontWeight.display,
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
          fontWeight: AppFontWeight.medium,
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
