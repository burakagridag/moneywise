// Core color tokens for MoneyWise design system.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFF3D5A99);
  static const Color brandPrimaryDim = Color(0xFF2E4A87);
  static const Color brandPrimaryGlow = Color(0x303D5A99);

  // Dark mode backgrounds
  static const Color bgPrimary = Color(0xFF0F1117);
  static const Color bgSecondary = Color(0xFF181C27);
  static const Color bgTertiary = Color(0xFF222637);

  // Dark mode text
  static const Color textPrimary = Color(0xFFF0F2F8);
  static const Color textSecondary = Color(0xFF8A90A8);
  static const Color textTertiary = Color(0xFF4E5470);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // Semantic
  static const Color income = Color(0xFF2E86AB);
  static const Color expense = Color(0xFFC0392B);
  static const Color neutral = Color(0xFFFFFFFF);

  // System
  static const Color divider = Color(0xFF1E2235);
  static const Color border = Color(0xFF2E3453);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);

  // Light mode backgrounds
  static const Color bgPrimaryLight = Color(0xFFF7F6F3);
  static const Color bgSecondaryLight = Color(0xFFEEECEA);
  static const Color bgTertiaryLight = Color(0xFFE3E1DD);

  // Light mode text
  static const Color textPrimaryLight = Color(0xFF1A1C24);
  static const Color textSecondaryLight = Color(0xFF5C5E6B);
  static const Color textTertiaryLight = Color(0xFF9395A3);

  // Chart palette — 6 colours per Sprint 7 design refresh.
  static const List<Color> chartPalette = [
    Color(0xFF3D5A99), // slate blue — brand
    Color(0xFF5B8DD4), // light blue
    Color(0xFF2E86AB), // teal blue — income
    Color(0xFF7B8DB0), // muted slate
    Color(0xFF4CAF82), // muted teal-green
    Color(0xFFD4A843), // muted amber-gold
  ];

  // Category chart colours (used in SummaryView CategoryBreakdownCard)
  static const Color categoryPurple = Color(0xFFAB47BC);

  // Extended surface tokens
  static const Color bgElevated = Color(0xFF1E2333);
  static const Color bgElevatedLight = Color(0xFFFFFFFF);
  static const Color brandSurface = Color(0xFF1E2E52);
  static const Color expenseDark = Color(0xFFE55A4E);
  static const Color transfer = Color(0xFF7B8DB0);
  static const Color dividerLight = Color(0xFFD8D5CF);
  static const Color borderLight = Color(0xFFC8C4BC);
  static const Color borderFocus = Color(0xFF4A5580);
  static const Color borderFocusLight = Color(0xFF3D5A99);
}
