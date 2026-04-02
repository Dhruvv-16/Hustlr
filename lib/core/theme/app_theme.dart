import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Organic Atelier (Light Mode) ────────────────────────────────────────────
  static const Color _lightCanvas  = Color(0xFFFAFAF5);
  static const Color _lightSurface = Color(0xFFF4F4EF);
  static const Color _lightCard    = Color(0xFFFFFFFF);
  static const Color _lightPrimary = Color(0xFF125117);
  static const Color _lightAccent  = Color(0xFFB0F3A6); // Mint
  static const Color _lightText    = Color(0xFF1A1C19);
  static const Color _lightSubtext = Color(0xFF91938D);

  // ── Ethereal Night Atelier (Dark Mode) ──────────────────────────────────────
  static const Color _darkCanvas    = Color(0xFF0A0B0A);
  static const Color _darkSurface   = Color(0xFF141614);
  static const Color _darkCard      = Color(0xFF1C1F1C);
  static const Color _darkPrimary   = Color(0xFF3FFF8B); // Electric Mint
  static const Color _darkContainer = Color(0xFF004734); // Deep Forest
  static const Color _darkText      = Color(0xFFE1E3DE);
  static const Color _darkSubtext   = Color(0xFF91938D);

  // ── Custom Extension Data (if needed) ───────────────────────────────────────
  
  // SHARED — Semantic colors same in both modes
  static const Color rain      = Color(0xFF1976D2);
  static const Color rainSurf  = Color(0xFFE3F2FD);
  static const Color heat      = Color(0xFFE65100);
  static const Color heatSurf  = Color(0xFFFFF3E0);
  static const Color platform  = Color(0xFF00695C);
  static const Color platSurf  = Color(0xFFE0F2F1);
  static const Color fraud     = Color(0xFF4A148C);
  static const Color fraudSurf = Color(0xFFF3E5F5);
  static const Color pending   = Color(0xFFE65100);
  static const Color pendSurf  = Color(0xFFFFF8E1);
  static const Color approved  = Color(0xFF1B5E20);
  static const Color appSurf   = Color(0xFFE8F5E9);
  static const Color danger    = Color(0xFFB71C1C);
  static const Color dangerSurf= Color(0xFFFFEBEE);

  // GRADIENT helpers
  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF3FFF8B), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient primaryGradient(bool isDark) =>
    isDark ? primaryGradientDark : primaryGradientLight;

  // SHADOW helpers
  // Light mode: standard subtle shadow
  // Dark mode: Electric Mint tinted ambient glow
  static List<BoxShadow> cardShadow(bool isDark) => isDark
    ? [BoxShadow(
        color: const Color(0xFF3FFF8B).withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
      )]
    : [BoxShadow(
        color: const Color(0xFF0D1B0F).withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      )];

  static List<BoxShadow> floatingButtonShadow(bool isDark) => isDark
    ? [BoxShadow(
        color: const Color(0xFF3FFF8B).withOpacity(0.25),
        blurRadius: 20,
        offset: const Offset(0, 8),
      )]
    : [BoxShadow(
        color: const Color(0xFF1B5E20).withOpacity(0.40),
        blurRadius: 16,
        offset: const Offset(0, 4),
      )];
  
  // ── Typography ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color textPrimary, Color textSecondary, Color accent) {
    return GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(fontSize: 52, fontWeight: FontWeight.w800, color: textPrimary),
      displayMedium: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary),
      displaySmall: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
      headlineLarge: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
      headlineMedium: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
      headlineSmall: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
      titleSmall: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6),
      bodyMedium: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
      bodySmall: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      labelLarge: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      labelMedium: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
      labelSmall: GoogleFonts.manrope(
        fontSize: 11, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.8,
      ),
    );
  }

  // ── LIGHT THEME ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: _lightCard,
        secondary: _lightAccent,
        onSecondary: _lightPrimary,
        surface: _lightSurface,
        onSurface: _lightText,
      ),
      scaffoldBackgroundColor: _lightCanvas,
      canvasColor: _lightCanvas,
      cardColor: _lightCard,
      dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0, space: 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      textTheme: _buildTextTheme(_lightText, _lightSubtext, _lightPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: _lightCard,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // 56px height -> 28px radius (pill)
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  // ── DARK THEME ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkSurface,
        secondary: _darkContainer, // used for icon backdrops
        onSecondary: _darkPrimary,
        surface: _darkSurface,
        onSurface: _darkText,
      ),
      scaffoldBackgroundColor: _darkCanvas,
      canvasColor: _darkCanvas,
      cardColor: _darkCard,
      dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0, space: 0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      textTheme: _buildTextTheme(_darkText, _darkSubtext, _darkPrimary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkSurface, // text color on dark primary button should be dark
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Pill
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard, // Text fields in dark mode use #1c1f1c background
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // 1.5rem (24px) radius
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: _darkContainer, width: 0.5), // Ghost border
        ),
      ),
    );
  }
}
