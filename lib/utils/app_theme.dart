import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppTheme {
  // --- 2026 Research-Backed Color Palette ---
  // Neo-mint + digital pastels (Zeenesia 2026)
  // Responsible glassmorphism + soft UI (index.dev 2026)
  // Vivid saturation for CTAs (Figma 2026)

  // Primary: Dynamic from ThemeService
  static Color get primaryColor => ThemeService().primaryColor;
  static Color get primaryLight => ThemeService().primaryColor.withValues(alpha: 0.7);

  // Secondary: Dynamic from ThemeService
  static Color get secondaryColor => ThemeService().secondaryColor;

  // Neo-mint: THE color of 2026 – optimism, tech-forward
  static const Color accentMint = Color(0xFF6EE7B7);
  static const Color accentMintStrong = Color(0xFF34D399);

  // Supporting accents
  static const Color accentPeach = Color(0xFFFFB088);
  static const Color accentSky = Color(0xFF67C3F3);

  // Surfaces – airy, breathable (strategic minimalism)
  static const Color surfaceLight = Color(0xFFF8F7FC);
  static const Color surfaceDark = Color(0xFF0B0F1E);
  static const Color cardDark = Color(0xFF151A30);

  // Text – high contrast for readability (responsible glassmorphism)
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF1F1F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Soft UI shadow colors
  static const Color softShadowLight = Color(0x1A7C5CFC);
  static const Color softShadowDark = Color(0x33000000);

  // Gradients – soft ombré transitions (2026 gradient revival)
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get auroraGradient => LinearGradient(
    colors: [primaryColor, const Color(0xFF67C3F3), ThemeService().accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF6EE7B7), Color(0xFF67C3F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFFB088)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1F3D), Color(0xFF151A30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft UI box shadows – tactile depth (neumorphism 2.0)
  static List<BoxShadow> softShadow({Color? color}) => [
    BoxShadow(
      color: color?.withValues(alpha: 0.12) ?? softShadowLight,
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      blurRadius: 20,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> softShadowDarkMode({Color? color}) => [
    BoxShadow(
      color: color?.withValues(alpha: 0.2) ?? softShadowDark,
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Avatar palette – soft muted tones
  static final List<Color> avatarColors = [
    const Color(0xFFFF6B8A),
    const Color(0xFFA78BFA),
    const Color(0xFF67C3F3),
    const Color(0xFF6EE7B7),
    const Color(0xFFFFB088),
    const Color(0xFFF472B6),
    const Color(0xFF818CF8),
    const Color(0xFF34D399),
    const Color(0xFFFBBF24),
    const Color(0xFFF87171),
    const Color(0xFF38BDF8),
    const Color(0xFFC084FC),
  ];

  static Color getAvatarColor(String? colorHex, String name) {
    if (colorHex != null) {
      try {
        return Color(int.parse(colorHex));
      } catch (_) {}
    }
    return avatarColors[name.hashCode.abs() % avatarColors.length];
  }

  // --- Light Theme ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: surfaceLight,
    fontFamily: '.SF Pro Rounded',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withValues(alpha: 0.75),
      surfaceTintColor: Colors.transparent,
      shadowColor: softShadowLight,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withValues(alpha: 0.08),
      selectedColor: primaryColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textPrimaryLight),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textPrimaryLight),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: textPrimaryLight),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: textPrimaryLight),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: textSecondaryLight),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      space: 0,
      thickness: 0,
      color: Colors.transparent,
    ),
  );

  // --- Dark Theme ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: surfaceDark,
    fontFamily: '.SF Pro Rounded',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: Colors.white.withValues(alpha: 0.07),
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark.withValues(alpha: 0.9),
      selectedItemColor: primaryLight,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withValues(alpha: 0.12),
      selectedColor: primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textPrimaryDark),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textPrimaryDark),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: textPrimaryDark),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: textPrimaryDark),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: textSecondaryDark),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: cardDark,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: cardDark,
    ),
    dividerTheme: const DividerThemeData(
      space: 0,
      thickness: 0,
      color: Colors.transparent,
    ),
  );
}
