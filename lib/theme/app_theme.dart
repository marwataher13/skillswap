import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFE6DED5); // Light Beige
  static const Color inputFill = Color(0xFFF0EBE6); // Lighter Soft Beige
  static const Color primary = Color(0xFFC9A892); // Warm Beige
  static const Color textPrimary = Color(0xFF4B3F39); // Dark Brown
  static const Color textSecondary = Color(0xFF5A4A42); // Dark Brown
  static const Color textHint = Color(0xFF9C9087); // Gray Brown
  static const Color divider = Color(0xFFD8D0C8); // Light Gray
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color border = Color(0xFFCBB8A7); // Light Beige Border

  // Using existing primary and textPrimary for these
  static const Color primaryDark = Color(0xFF4B3F39);
  static const Color primaryLight = Color(0xFFD7C4B7);

  static const Color surfaceVariant = Color(0xFFF9F5F1); // Kept from previous
  static const Color shadow = Color(0xFF4B3F39); // Using textPrimary for shadow

  // Gradient stops derived from new primary colors
  static const Color gradientStart = Color(0xFFC9A892);
  static const Color gradientEnd = Color(0xFFB09D8B);
}

// ─── Spacing / Radius Tokens ─────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusFull = 100.0;
}

// ─── Text Style Tokens ────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );
}

// ─── Shadows ──────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadow.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.shadow.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        error: Color(0xFFB00020),
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
      ),

      scaffoldBackgroundColor: AppColors.background,

      textTheme: base.copyWith(
        displayLarge:
            base.displayLarge?.merge(AppTextStyles.displayLarge),

        displayMedium:
            base.displayMedium?.merge(AppTextStyles.displayMedium),

        headlineLarge:
            base.headlineLarge?.merge(AppTextStyles.headlineLarge),

        headlineMedium:
            base.headlineMedium?.merge(AppTextStyles.headlineMedium),

        titleMedium:
            base.titleMedium?.merge(AppTextStyles.titleMedium),

        bodyLarge:
            base.bodyLarge?.merge(AppTextStyles.bodyLarge),

        bodyMedium:
            base.bodyMedium?.merge(AppTextStyles.bodyMedium),

        labelMedium:
            base.labelMedium?.merge(AppTextStyles.labelMedium),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusMd,
            ),
          ),

          padding: const EdgeInsets.symmetric(
            vertical: 18,
          ),

          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),

          minimumSize: const Size(
            double.infinity,
            56,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,

        hintStyle: GoogleFonts.poppins(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.radiusMd,
          ),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.radiusMd,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppSpacing.radiusMd,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
    );
  }
}