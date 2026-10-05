import 'package:flutter/material.dart';

/// AppColors is the CENTRAL SINGLE SOURCE OF TRUTH for all color palettes in VoicePin.
/// You can easily customize any color, gradient, dark mode, or category theme here,
/// and it will automatically update across all screens in the application.
class AppColors {
  // ==========================================
  // BRAND & ACCENT COLORS (Ana Marka Renkleri)
  // ==========================================
  /// Primary brand color (used for main buttons, active tabs, highlights)
  static const Color primary = Color(0xFF303064);

  /// Primary variant for gradients and dark accents
  static const Color primaryDark = Color(0xFF1F1F45);

  /// Light primary tint for soft backgrounds and chips
  static const Color primaryLight = Color(0xFFEEF2FF);

  /// Secondary accent color (coral / rose for accents)
  static const Color secondary = Color(0xFFF43F5E);

  /// Tertiary accent (electric cyan for highlights)
  static const Color accent = Color(0xFF06B6D4);

  /// Bright primary accent for dark mode high contrast elements
  static const Color darkPrimaryAccent = Color(0xFF818CF8);
  static const Color darkPlayButtonBg = Color(0xFF312E81);

  // ==========================================
  // CATEGORY COLORS (Kategori Renkleri)
  // ==========================================
  /// Shopping category color (Emerald Green)
  static const Color shopping = Color(0xFF10B981);

  /// Work category color (Warm Amber/Orange)
  static const Color work = Color(0xFFF59E0B);

  /// Personal category color (Deep Purple)
  static const Color personal = Color(0xFF8B5CF6);

  /// Other / Miscellaneous category color (Rose Red)
  static const Color others = Color(0xFFEC4899);

  // ==========================================
  // LIGHT MODE COLORS (Açık Mod Renkleri)
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ==========================================
  // DARK MODE COLORS (Karanlık Mod Renkleri)
  // ==========================================
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkCardBackground = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceSubtle = Color(0xFF334155); // Slate 700
  static const Color darkBorder =
      Color(0xFF475569); // Slate 600 - High Contrast
  static const Color darkTextPrimary =
      Color(0xFFF8FAFC); // Slate 50 - High Contrast White
  static const Color darkTextSecondary =
      Color(0xFFCBD5E1); // Slate 300 - High Contrast Subtitle
  static const Color darkTextMuted = Color(0xFF94A3B8); // Slate 400

  // ==========================================
  // STATUS & FEEDBACK COLORS (Durum Renkleri)
  // ==========================================
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ==========================================
  // DYNAMIC THEME-AWARE HELPERS (Dinamik Renk Getiricileri)
  // ==========================================
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDark(context) ? darkBackground : background;
  }

  static Color getCardBackground(BuildContext context) {
    return isDark(context) ? darkCardBackground : cardBackground;
  }

  static Color getSurfaceSubtle(BuildContext context) {
    return isDark(context) ? darkSurfaceSubtle : surfaceSubtle;
  }

  static Color getBorderColor(BuildContext context) {
    return isDark(context) ? darkBorder : border;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  static Color getTextMuted(BuildContext context) {
    return isDark(context) ? darkTextMuted : textMuted;
  }

  static Color getPrimaryAccent(BuildContext context) {
    return isDark(context) ? darkPrimaryAccent : primary;
  }

  static Color getPlayButtonBg(BuildContext context) {
    return isDark(context) ? darkPlayButtonBg : primaryLight;
  }

  static Color getPlayButtonIcon(BuildContext context) {
    return isDark(context) ? darkPrimaryAccent : primary;
  }

  static List<BoxShadow> getSoftShadow(BuildContext context) {
    return isDark(context) ? darkSoftShadow : softShadow;
  }

  // ==========================================
  // GRADIENTS (Dereceli Renkler)
  // ==========================================
  /// Main modern gradient (Primary to Dark Accent)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Vibrant recording gradient (Red/Rose active pulse)
  static const LinearGradient recordingGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Category gradients helper
  static LinearGradient categoryGradient(Color categoryColor) {
    return LinearGradient(
      colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ==========================================
  // SHADOWS & DECORATIONS (Gölge ve Kenarlıklar)
  // ==========================================
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> darkSoftShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ==========================================
  // THEMEDATA BUILDERS (Tema Yapılandırıcıları)
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: cardBackground,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: border,
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBackground,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: darkPrimaryAccent,
        secondary: secondary,
        surface: darkCardBackground,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: darkBorder,
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCardBackground,
      ),
    );
  }
}
