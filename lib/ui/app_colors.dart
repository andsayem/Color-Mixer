import 'package:flutter/material.dart';

/// Centralized color definitions for the Color Mixer app.
/// Uses harmonious HSL colors to achieve a premium dark theme with vibrant accents.
class AppColors {
  // Background
  static const Color bg = Color(0xFF111111);

  // Surface and cards
  static const Color surface = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF262626);

  // Accent colors (primary palette)
  static const Color accent1 = Color(0xFFEF4444); // Red accent
  static const Color accent2 = Color(0xFF3B82F6); // Blue accent
  static const Color accent3 = Color(0xFFF59E0B); // Yellow accent

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFBBBBBB);

  // Borders / outlines
  static const Color border = Color(0xFF444444);

  // Gradients used throughout the UI
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent1, accent2, accent3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
