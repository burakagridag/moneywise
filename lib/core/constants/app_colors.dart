// Core color tokens for MoneyWise design system.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFFFF6B5C);
  static const Color brandPrimaryDim = Color(0xFFE85A4D);
  static const Color brandPrimaryGlow = Color(0x33FF6B5C);

  // Dark mode backgrounds
  static const Color bgPrimary = Color(0xFF1A1B1E);
  static const Color bgSecondary = Color(0xFF24252A);
  static const Color bgTertiary = Color(0xFF2E2F35);

  // Dark mode text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3B8);
  static const Color textTertiary = Color(0xFF6B6E76);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // Semantic
  static const Color income = Color(0xFF4A90E2);
  static const Color expense = Color(0xFFFF6B5C);
  static const Color neutral = Color(0xFFFFFFFF);

  // System
  static const Color divider = Color(0xFF2E2F35);
  static const Color border = Color(0xFF3A3B42);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);

  // Light mode backgrounds
  static const Color bgPrimaryLight = Color(0xFFFFFFFF);
  static const Color bgSecondaryLight = Color(0xFFF5F5F7);
  static const Color bgTertiaryLight = Color(0xFFEAEAEC);

  // Light mode text
  static const Color textPrimaryLight = Color(0xFF1A1B1E);
  static const Color textSecondaryLight = Color(0xFF6B6E76);

  // Chart palette — 8 distinct colours per SPEC-010.
  static const List<Color> chartPalette = [
    Color(0xFFFF6B5C), // coral — brand primary
    Color(0xFFFF9F40), // orange
    Color(0xFFFFD166), // yellow
    Color(0xFF06D6A0), // green
    Color(0xFF4A90E2), // blue
    Color(0xFF9B59B6), // purple
    Color(0xFFF78FB3), // pink
    Color(0xFF48CAE4), // teal
  ];
}
