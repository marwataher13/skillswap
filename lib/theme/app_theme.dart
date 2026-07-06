import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ─── Main Brand Colors ───────────────────────────────────────────────────
  static const Color primary = Color(0xFFB08968); // Caramel Roast
  static const Color primaryDark = Color(0xFF3B2A22); // Espresso Shot
  static const Color primaryLight = Color(0xFFF3E9D7); // Creamy Latte

  // ─── Coffee Palette ──────────────────────────────────────────────────────
  static const Color creamyLatte = Color(0xFFF3E9D7);
  static const Color caramelRoast = Color(0xFFB08968);
  static const Color mochaBean = Color(0xFF7A553A);
  static const Color warmCappuccino = Color(0xFF3B2A22);
  static const Color espressoShot = Color(0xFF3B2A22);

  // ─── Gradients (للدوائر والخلفيات) ──────────────────────────────────────
  static const Color gradientStart = Color(0xFFB08968);
  static const Color gradientEnd = Color(0xFF7A553A);

  static const Color gradientDarkStart = Color(0xFF7A553A);
  static const Color gradientDarkEnd = Color(0xFF3B2A22);

  // ─── Backgrounds ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF3E9D7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8D8C7);
  static const Color inputFill = Color(0xFFF7F0E6);
  static const Color chatCard = Color(0xFFF7F0E6);

  // ─── Typography ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3B2A22);
  static const Color textSecondary = Color(0xFF7A553A);
  static const Color textHint = Color(0xFFA38772);
  static const Color badgeText = Colors.white;

  // ─── Borders ─────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE3D3C4);
  static const Color border = Color(0xFFD6BFA6);

  // ─── Functional ──────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF4F6F52);

  static const Color shadow = Color(0x1A3B2A22);
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
  );

  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

// ─── Shadows ──────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─── Dynamic Color Extension (ThemeExtension) ────────────────────────────────
/// All app-specific colors live here so they adapt when themeMode changes.
/// Access via `context.appColors.X` in any widget build method.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.inputFill,
    required this.chatCard,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.caramelRoast,
    required this.mochaBean,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.error,
    required this.success,
    required this.gradientStart,
    required this.gradientEnd,
    required this.gradientDarkStart,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color inputFill;
  final Color chatCard;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color caramelRoast;
  final Color mochaBean;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color error;
  final Color success;
  final Color gradientStart;
  final Color gradientEnd;
  final Color gradientDarkStart;
  final Color shadow;

  static const light = AppColorsExtension(
    background: Color(0xFFF3E9D7),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8D8C7),
    inputFill: Color(0xFFF7F0E6),
    chatCard: Color(0xFFF7F0E6),
    primary: Color(0xFFB08968),
    primaryDark: Color(0xFF3B2A22),
    primaryLight: Color(0xFFF3E9D7),
    caramelRoast: Color(0xFFB08968),
    mochaBean: Color(0xFF7A553A),
    textPrimary: Color(0xFF3B2A22),
    textSecondary: Color(0xFF7A553A),
    textHint: Color(0xFFA38772),
    border: Color(0xFFD6BFA6),
    divider: Color(0xFFE3D3C4),
    error: Color(0xFFBA1A1A),
    success: Color(0xFF4F6F52),
    gradientStart: Color(0xFFB08968),
    gradientEnd: Color(0xFF7A553A),
    gradientDarkStart: Color(0xFF7A553A),
    shadow: Color(0x1A3B2A22),
  );

  static const dark = AppColorsExtension(
    background: Color(0xFF1C1108),
    surface: Color(0xFF2D1D11),
    surfaceVariant: Color(0xFF3B2A1E),
    inputFill: Color(0xFF2D1D11),
    chatCard: Color(0xFF3B2A1E),
    primary: Color(0xFFB08968),
    primaryDark: Color(0xFFD4B896),
    primaryLight: Color(0xFF5C3D28),
    caramelRoast: Color(0xFFB08968),
    mochaBean: Color(0xFFC9A882),
    textPrimary: Color(0xFFF3E9D7),
    textSecondary: Color(0xFFC9A882),
    textHint: Color(0xFF8C6E58),
    border: Color(0xFF5C3D28),
    divider: Color(0xFF5C3D28),
    error: Color(0xFFCF6679),
    success: Color(0xFF6BAD6E),
    gradientStart: Color(0xFFB08968),
    gradientEnd: Color(0xFF7A553A),
    gradientDarkStart: Color(0xFF7A553A),
    shadow: Color(0x40000000),
  );

  @override
  AppColorsExtension copyWith({
    Color? background, Color? surface, Color? surfaceVariant,
    Color? inputFill, Color? chatCard, Color? primary, Color? primaryDark,
    Color? primaryLight, Color? caramelRoast, Color? mochaBean,
    Color? textPrimary, Color? textSecondary, Color? textHint,
    Color? border, Color? divider, Color? error, Color? success,
    Color? gradientStart, Color? gradientEnd, Color? gradientDarkStart,
    Color? shadow,
  }) => AppColorsExtension(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    inputFill: inputFill ?? this.inputFill,
    chatCard: chatCard ?? this.chatCard,
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    primaryLight: primaryLight ?? this.primaryLight,
    caramelRoast: caramelRoast ?? this.caramelRoast,
    mochaBean: mochaBean ?? this.mochaBean,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textHint: textHint ?? this.textHint,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    error: error ?? this.error,
    success: success ?? this.success,
    gradientStart: gradientStart ?? this.gradientStart,
    gradientEnd: gradientEnd ?? this.gradientEnd,
    gradientDarkStart: gradientDarkStart ?? this.gradientDarkStart,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      chatCard: Color.lerp(chatCard, other.chatCard, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      caramelRoast: Color.lerp(caramelRoast, other.caramelRoast, t)!,
      mochaBean: Color.lerp(mochaBean, other.mochaBean, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      gradientDarkStart: Color.lerp(gradientDarkStart, other.gradientDarkStart, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}

// ─── Dark Color Tokens ───────────────────────────────────────────────────────
class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF1C1108);
  static const Color surface = Color(0xFF2D1D11);
  static const Color textPrimary = Color(0xFFF3E9D7);
  static const Color textSecondary = Color(0xFFC9A882);
  static const Color textHint = Color(0xFF8C6E58);
  static const Color border = Color(0xFF5C3D28);
  static const Color error = Color(0xFFCF6679);
}

// ─── Theme Data ───────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsDark.background,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: Color(0xFF5C3D28),
        onSecondary: AppColorsDark.textPrimary,
        error: AppColorsDark.error,
        onError: Colors.white,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        surfaceContainerHighest: Color(0xFF3B2A1E),
        onSurfaceVariant: AppColorsDark.textSecondary,
        outline: AppColorsDark.border,
      ),

      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 34,
          letterSpacing: -0.5,
        ),
        displayMedium: base.displayMedium?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.3,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: base.bodyLarge?.copyWith(
          color: AppColorsDark.textPrimary,
          fontWeight: FontWeight.w400,
          fontSize: 16,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          color: AppColorsDark.textSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        labelMedium: base.labelMedium?.copyWith(
          color: AppColorsDark.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        labelSmall: base.labelSmall?.copyWith(
          color: AppColorsDark.textHint,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          minimumSize: const Size(64, 52),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surface,
        hintStyle: GoogleFonts.poppins(
          color: AppColorsDark.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIconColor: AppColorsDark.textSecondary,
        suffixIconColor: AppColorsDark.textSecondary,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColorsDark.textPrimary,
        unselectedItemColor: AppColorsDark.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: const [AppColorsExtension.dark],
    );
  }

  static ThemeData get lightTheme {
    final base = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

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

      textTheme: base.copyWith(
        displayLarge: base.displayLarge?.merge(AppTextStyles.displayLarge).copyWith(color: AppColors.textPrimary),
        displayMedium: base.displayMedium?.merge(AppTextStyles.displayMedium).copyWith(color: AppColors.textPrimary),
        headlineLarge: base.headlineLarge?.merge(AppTextStyles.headlineLarge).copyWith(color: AppColors.textPrimary),
        headlineMedium: base.headlineMedium?.merge(
          AppTextStyles.headlineMedium,
        ).copyWith(color: AppColors.textPrimary),
        titleMedium: base.titleMedium?.merge(AppTextStyles.titleMedium).copyWith(color: AppColors.textPrimary),
        bodyLarge: base.bodyLarge?.merge(AppTextStyles.bodyLarge).copyWith(color: AppColors.textPrimary),
        bodyMedium: base.bodyMedium?.merge(AppTextStyles.bodyMedium).copyWith(color: AppColors.textSecondary),
        labelMedium: base.labelMedium?.merge(AppTextStyles.labelMedium).copyWith(color: AppColors.textSecondary),
        labelSmall: base.labelSmall?.merge(AppTextStyles.labelSmall).copyWith(color: AppColors.textHint),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          minimumSize: const Size(64, 52),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // إضافة ثيم الـ Bottom Navigation Bar عشان يشتغل أوتوماتيك
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      extensions: const [AppColorsExtension.light],
    );
  }
}
