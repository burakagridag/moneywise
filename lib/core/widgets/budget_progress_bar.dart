// Reusable progress bar with threshold colour logic and optional Today indicator — core/widgets.
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../i18n/arb/app_localizations.dart';

/// A horizontal progress bar used in BudgetView and BudgetSettingScreen.
///
/// Colour thresholds:
///   0–69%  → [AppColors.brandPrimary]
///   70–99% → [AppColors.warning]
///   ≥100%  → [AppColors.error]
///
/// When [showTodayIndicator] is true, a vertical line is drawn at the
/// proportion of the current day within the month.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.ratio,
    this.height = 8.0,
    this.showTodayIndicator = false,
    this.selectedMonth,
  });

  /// Spending ratio in [0.0 .. 1.0+]. Values > 1.0 indicate over-budget.
  final double ratio;

  /// Height of the bar in logical pixels.
  final double height;

  /// When true, renders a vertical "Today" line inside the bar.
  final bool showTodayIndicator;

  /// The month for which the Today indicator should be calculated.
  /// Required when [showTodayIndicator] is true.
  final DateTime? selectedMonth;

  /// Returns the fill colour based on [ratio].
  static Color colorForRatio(double ratio) {
    if (ratio >= 1.0) return AppColors.error;
    if (ratio >= 0.7) return AppColors.warning;
    return AppColors.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = colorForRatio(ratio);
    final clampedRatio = ratio.clamp(0.0, 1.0);

    if (!showTodayIndicator) {
      return _BarOnly(
        fillColor: fillColor,
        ratio: clampedRatio,
        height: height,
      );
    }

    // Calculate the today indicator position within the month.
    final now = DateTime.now();
    final month = selectedMonth ?? now;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day.toDouble();
    final todayRatio = (now.year == month.year && now.month == month.month)
        ? (now.day / daysInMonth).clamp(0.0, 1.0)
        : -1.0; // Off-screen if not the current month.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (todayRatio >= 0)
          LayoutBuilder(
            builder: (context, constraints) {
              final leftOffset = constraints.maxWidth * todayRatio;
              final l10n = AppLocalizations.of(context)!;
              return SizedBox(
                height: AppSpacing.md,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: leftOffset - 1,
                      top: 0,
                      child: Column(
                        children: [
                          Text(
                            l10n.today,
                            style: AppTypography.caption2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        _BarWithTodayIndicator(
          fillColor: fillColor,
          ratio: clampedRatio,
          todayRatio: todayRatio,
          height: height,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private implementation widgets
// ---------------------------------------------------------------------------

class _BarOnly extends StatelessWidget {
  const _BarOnly({
    required this.fillColor,
    required this.ratio,
    required this.height,
  });

  final Color fillColor;
  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor: AppColors.bgTertiary,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
          minHeight: height,
        ),
      ),
    );
  }
}

class _BarWithTodayIndicator extends StatelessWidget {
  const _BarWithTodayIndicator({
    required this.fillColor,
    required this.ratio,
    required this.todayRatio,
    required this.height,
  });

  final Color fillColor;
  final double ratio;
  final double todayRatio;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              // Background
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  width: barWidth,
                  height: height,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppColors.bgTertiary,
                    valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                    minHeight: height,
                  ),
                ),
              ),
              // Today indicator line
              if (todayRatio >= 0)
                Positioned(
                  left: (barWidth * todayRatio).clamp(1.0, barWidth - 2),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
