// BuildContext extension providing theme-adaptive color accessors — core/constants.
// Eliminates hardcoded dark-mode AppColors references across all feature screens (US-045).
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extension on [BuildContext] that returns the correct color token for the
/// active theme (light or dark) without requiring explicit Theme.of(context)
/// lookups at every call site.
///
/// Usage:
///   Container(color: context.bgPrimary)
///
/// Rules:
/// - Only background and text surface colors are adaptive.
/// - Brand colors, semantic colors (income/expense/error), and chart palette
///   are theme-invariant and must NOT be accessed through this extension.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // Background surfaces
  // ---------------------------------------------------------------------------

  Color get bgPrimary =>
      isDark ? AppColors.bgPrimary : AppColors.bgPrimaryLight;

  Color get bgSecondary =>
      isDark ? AppColors.bgSecondary : AppColors.bgSecondaryLight;

  Color get bgTertiary =>
      isDark ? AppColors.bgTertiary : AppColors.bgTertiaryLight;

  Color get bgElevated =>
      isDark ? AppColors.bgElevated : AppColors.bgElevatedLight;

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  Color get textPrimary =>
      isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

  Color get textSecondary =>
      isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

  Color get textTertiary =>
      isDark ? AppColors.textTertiary : AppColors.textTertiaryLight;

  // ---------------------------------------------------------------------------
  // Derived / composite
  // ---------------------------------------------------------------------------

  Color get dividerColor => isDark ? AppColors.divider : AppColors.dividerLight;

  Color get cardColor =>
      isDark ? AppColors.bgSecondary : AppColors.bgSecondaryLight;

  Color get expenseColor => isDark ? AppColors.expenseDark : AppColors.expense;

  Color get borderColor => isDark ? AppColors.border : AppColors.borderLight;

  Color get borderFocusColor =>
      isDark ? AppColors.borderFocus : AppColors.borderFocusLight;
}
