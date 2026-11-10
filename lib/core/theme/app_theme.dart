import 'package:flutter/material.dart' as material;
import 'package:google_fonts/google_fonts.dart';

/// TrekGuard AI Design System — Material 3
/// High-contrast outdoor UI, Dark Mode first
class AppTheme {
  AppTheme._();

  // ─── Color Palette ────────────────────────────────────────────────
  static const material.Color _primaryGreen = material.Color(0xFF2ECC71);
  static const material.Color _primaryDark = material.Color(0xFF27AE60);
  static const material.Color _accentOrange = material.Color(0xFFF39C12);
  static const material.Color _dangerRed = material.Color(0xFFE74C3C);
  static const material.Color _warningYellow = material.Color(0xFFF1C40F);
  static const material.Color _safeBlue = material.Color(0xFF3498DB);

  static const material.Color _darkSurface = material.Color(0xFF1A1F2E);
  static const material.Color _darkCard = material.Color(0xFF242A38);
  static const material.Color _darkBackground = material.Color(0xFF0F1320);
  static const material.Color _darkBorder = material.Color(0xFF2D3547);

  static const material.Color _lightSurface = material.Color(0xFFF8FFFE);
  static const material.Color _lightCard = material.Color(0xFFFFFFFF);
  static const material.Color _lightBackground = material.Color(0xFFF0F7F4);

  // ─── Semantic Colors (exported for use in widgets) ────────────────
  static const material.Color dangerColor = _dangerRed;
  static const material.Color warningColor = _warningYellow;
  static const material.Color safeColor = _primaryGreen;
  static const material.Color infoColor = _safeBlue;
  static const material.Color accentColor = _accentOrange;

  // ─── Typography ───────────────────────────────────────────────────
  static material.TextTheme _buildTextTheme(material.Color textColor) {
    final baseTheme = material.TextTheme(
        displayLarge: material.TextStyle(
          fontSize: 57, fontWeight: material.FontWeight.w700, color: textColor,
          letterSpacing: -0.25,
        ),
        displayMedium: material.TextStyle(
          fontSize: 45, fontWeight: material.FontWeight.w600, color: textColor,
        ),
        headlineLarge: material.TextStyle(
          fontSize: 32, fontWeight: material.FontWeight.w700, color: textColor,
        ),
        headlineMedium: material.TextStyle(
          fontSize: 28, fontWeight: material.FontWeight.w600, color: textColor,
        ),
        headlineSmall: material.TextStyle(
          fontSize: 24, fontWeight: material.FontWeight.w600, color: textColor,
        ),
        titleLarge: material.TextStyle(
          fontSize: 22, fontWeight: material.FontWeight.w600, color: textColor,
        ),
        titleMedium: material.TextStyle(
          fontSize: 16, fontWeight: material.FontWeight.w500, color: textColor,
          letterSpacing: 0.15,
        ),
        titleSmall: material.TextStyle(
          fontSize: 14, fontWeight: material.FontWeight.w500, color: textColor,
          letterSpacing: 0.1,
        ),
        bodyLarge: material.TextStyle(fontSize: 16, color: textColor),
        bodyMedium: material.TextStyle(fontSize: 14, color: textColor),
        bodySmall: material.TextStyle(fontSize: 12, color: textColor),
        labelLarge: material.TextStyle(
          fontSize: 14, fontWeight: material.FontWeight.w600, color: textColor,
          letterSpacing: 0.1,
        ),
      );
    // ignore: argument_type_not_assignable
    return GoogleFonts.outfitTextTheme(baseTheme as dynamic) as material.TextTheme;
  }

  // ─── Dark Theme (Primary — outdoor use) ───────────────────────────
  static material.ThemeData get darkTheme {
    final colorScheme = material.ColorScheme.dark(
      primary: _primaryGreen,
      onPrimary: material.Colors.black,
      primaryContainer: _primaryDark,
      secondary: _accentOrange,
      onSecondary: material.Colors.black,
      error: _dangerRed,
      surface: _darkSurface,
      onSurface: const material.Color(0xFFE8EDF2),
      surfaceContainerHighest: _darkCard,
      outline: _darkBorder,
      shadow: material.Colors.black.withAlpha(100),
    );

    return material.ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: _buildTextTheme(const material.Color(0xFFE8EDF2)),
      cardTheme: material.CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: material.RoundedRectangleBorder(
          borderRadius: material.BorderRadius.circular(16),
          side: const material.BorderSide(color: _darkBorder, width: 1),
        ),
      ),
      appBarTheme: material.AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: const material.Color(0xFFE8EDF2),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: material.FontWeight.w600,
          color: const material.Color(0xFFE8EDF2),
        ),
      ),
      bottomNavigationBarTheme: const material.BottomNavigationBarThemeData(
        backgroundColor: _darkCard,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: material.Color(0xFF6B7A99),
        type: material.BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: material.ElevatedButtonThemeData(
        style: material.ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: material.Colors.black,
          elevation: 0,
          padding: const material.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: material.FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: material.InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: material.OutlineInputBorder(
          borderRadius: material.BorderRadius.circular(12),
          borderSide: const material.BorderSide(color: _darkBorder),
        ),
        enabledBorder: material.OutlineInputBorder(
          borderRadius: material.BorderRadius.circular(12),
          borderSide: const material.BorderSide(color: _darkBorder),
        ),
        focusedBorder: material.OutlineInputBorder(
          borderRadius: material.BorderRadius.circular(12),
          borderSide: const material.BorderSide(color: _primaryGreen, width: 2),
        ),
        contentPadding: const material.EdgeInsets.symmetric(
          horizontal: 16, vertical: 14,
        ),
      ),
      dividerColor: _darkBorder,
    );
  }

  // ─── Light Theme (Outdoor daytime) ────────────────────────────────
  static material.ThemeData get lightTheme {
    final colorScheme = material.ColorScheme.light(
      primary: _primaryDark,
      onPrimary: material.Colors.white,
      primaryContainer: _primaryGreen.withAlpha(30),
      secondary: _accentOrange,
      error: _dangerRed,
      surface: _lightSurface,
      onSurface: const material.Color(0xFF1A2332),
      surfaceContainerHighest: _lightCard,
    );

    return material.ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(const material.Color(0xFF1A2332)),
      cardTheme: material.CardThemeData(
        color: _lightCard,
        elevation: 2,
        shadowColor: material.Colors.black.withAlpha(20),
        shape: material.RoundedRectangleBorder(
          borderRadius: material.BorderRadius.circular(16),
        ),
      ),
      appBarTheme: material.AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: const material.Color(0xFF1A2332),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: material.FontWeight.w600,
          color: const material.Color(0xFF1A2332),
        ),
      ),
      elevatedButtonTheme: material.ElevatedButtonThemeData(
        style: material.ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: material.Colors.white,
          elevation: 0,
          padding: const material.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: material.RoundedRectangleBorder(
            borderRadius: material.BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15, fontWeight: material.FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
