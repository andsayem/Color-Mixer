import 'package:flutter/material.dart';

/// Centralized color definitions for the Color Mixer app: a deep indigo
/// dark theme with violet / cyan / pink accents, shared by every screen.
class AppColors {
  // Background
  static const Color bg = Color(0xFF0A0A1A);

  // Surface and cards
  static const Color surface = Color(0xFF12122A);
  static const Color card = Color(0xFF1A1A38);
  static const Color cardBright = Color(0xFF222248);

  // Accent colors
  static const Color accent1 = Color(0xFF8B5CF6); // Violet
  static const Color accent2 = Color(0xFF06B6D4); // Cyan
  static const Color accent3 = Color(0xFFEC4899); // Pink

  /// Premium / "Pro" highlights.
  static const Color gold = Color(0xFFFBBF24);

  // Paint primaries
  static const Color red = Color(0xFFEF4444);
  static const Color blue = Color(0xFF3B82F6);
  static const Color yellow = Color(0xFFF59E0B);

  // Text colors
  static const Color textPrimary = Color(0xFFF1F0FF);
  static const Color textSecondary = Color(0xFF9898CC);

  // Borders / outlines
  static const Color border = Color(0xFF2C2C5E);
  static const Color divider = Color(0xFF1E1E40);

  // Gradients used throughout the UI
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E45), Color(0xFF16163A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
