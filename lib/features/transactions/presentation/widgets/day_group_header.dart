// Day group header widget for the transaction daily list — transactions feature.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// 48dp section header showing the day, weekday, and daily total.
/// Saturdays get a blue badge, Sundays get a coral badge.
class DayGroupHeader extends StatelessWidget {
  const DayGroupHeader({
    super.key,
    required this.date,
    required this.dailyTotal,
    required this.currencySymbol,
  });

  final DateTime date;
  final double dailyTotal;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat('d');
    final weekdayFmt = DateFormat('EEE');
    final isSaturday = date.weekday == DateTime.saturday;
    final isSunday = date.weekday == DateTime.sunday;
    final amtFmt = NumberFormat('#,##0.00', 'de_DE');

    Color badgeColor;
    if (isSunday) {
      badgeColor = AppColors.expense;
    } else if (isSaturday) {
      badgeColor = AppColors.income;
    } else {
      badgeColor = AppColors.bgTertiary;
    }

    return Container(
      height: 48,
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayFmt.format(date),
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    weekdayFmt.format(date),
                    style: AppTypography.caption2
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            '$currencySymbol ${amtFmt.format(dailyTotal)}',
            style: AppTypography.moneySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
