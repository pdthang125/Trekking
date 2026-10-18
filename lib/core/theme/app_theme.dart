import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TrekGuard AI Design System — Material 3
/// High-contrast outdoor UI, Dark Mode first
class AppTheme {
  AppTheme._();

  // ─── Color Palette ────────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2ECC71);
  static const Color _primaryDark = Color(0xFF27AE60);
  static const Color _accentOrange = Color(0xFFF39C12);
  static const Color _dangerRed = Color(0xFFE74C3C);
  static const Color _warningYellow = Color(0xFFF1C40F);
  static const Color _safeBlue = Color(0xFF3498DB);

  static const Color _darkSurface = Color(0xFF1A1F2E);
  static const Color _darkCard = Color(0xFF242A38);
  static const Color _darkBackground = Color(0xFF0F1320);
  static const Color _darkBorder = Color(0xFF2D3547);

  static const Color _lightSurface = Color(0xFFF8FFFE);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightBackground = Color(0xFFF0F7F4);

  // ─── Semantic Colors (exported for use in widgets) ────────────────
  static const Color dangerColor = _dangerRed;
  static const Color warningColor = _warningYellow;
  static const Color safeColor = _primaryGreen;
  static const Color infoColor = _safeBlue;
  static const Color accentColor = _accentOrange;

  // ─── Typography ───────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 57, fontWeight: FontWeight.w700, color: textColor,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 45, fontWeight: FontWeight.w600, color: textColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w600, color: textColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: textColor,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: textColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, color: textColor),
        bodySmall: TextStyle(fontSize: 12, color: textColor),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ─── Dark Theme (Primary — outdoor use) ───────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: _primaryGreen,
      onPrimary: Colors.black,
      primaryContainer: _primaryDark,
      secondary: _accentOrange,
      onSecondary: Colors.black,
      error: _dangerRed,
      surface: _darkSurface,
      onSurface: const Color(0xFFE8EDF2),
      surfaceContainerHighest: _darkCard,
      outline: _darkBorder,
      shadow: Colors.black.withAlpha(100),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(const Color(0xFFE8EDF2)),
      cardTheme: CardTheme(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: const Color(0xFFE8EDF2),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: const Color(0xFFE8EDF2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkCard,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: Color(0xFF6B7A99),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
      ),
      dividerColor: _darkBorder,
    );
  }

  // ─── Light Theme (Outdoor daytime) ────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: _primaryDark,
      onPrimary: Colors.white,
      primaryContainer: _primaryGreen.withAlpha(30),
      secondary: _accentOrange,
      error: _dangerRed,
      surface: _lightSurface,
      onSurface: const Color(0xFF1A2332),
      surfaceContainerHighest: _lightCard,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(const Color(0xFF1A2332)),
      cardTheme: CardTheme(
        color: _lightCard,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: const Color(0xFF1A2332),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: const Color(0xFF1A2332),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
