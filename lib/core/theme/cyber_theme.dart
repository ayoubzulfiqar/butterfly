import 'package:flutter/material.dart';

/// Cyber-minimal, high-contrast dark theme tokens inspired by Ghostline.
class CyberTheme {
  // Canvas & Backgrounds
  static const Color background = Color(0xFF0B0D13);
  static const Color surface = Color(0xFF141824);
  static const Color surfaceTranslucent = Color(0xB3141824); // ~70% opacity
  static const Color border = Color(0xFF1E2640);
  static const Color borderHighlight = Color(0xFF2A3656);

  // Neon Signal Accents
  static const Color neonEmerald = Color(0xFF00FFA3);
  static const Color cyberCyan = Color(0xFF00D0FF);
  static const Color neonAmber = Color(0xFFFFB703);
  static const Color neonCoral = Color(0xFFFF4D6D);
  static const Color electricViolet = Color(0xFF8B5CF6);

  // Typography
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  /// Generates the dark Cyber ThemeData for the application.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonEmerald,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: neonEmerald,
        secondary: cyberCyan,
        error: neonCoral,
      ),
      fontFamily: 'Inter',
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
