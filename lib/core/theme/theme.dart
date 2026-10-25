import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF000000),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF131B2E),
      onPrimaryContainer: Color(0xFF7C839B),
      secondary: Color(0xFF006C49),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF6CF8BB),
      onSecondaryContainer: Color(0xFF00714D),
      tertiary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFF410004),
      onTertiaryContainer: Color(0xFFEF4444),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F9FF),
      onSurface: Color(0xFF0B1C30),
      onSurfaceVariant: Color(0xFF45464D),
      outline: Color(0xFF76777D),
      outlineVariant: Color(0xFFC6C6CD),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A), // Deep Obsidian Slate
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded-xl
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
        ),
      ),
    );
  }
}
