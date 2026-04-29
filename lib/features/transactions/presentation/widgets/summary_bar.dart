// Summary bar showing monthly income, expense, and total — transactions feature.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// 60dp bar displaying income / expense / total for the selected month.
class SummaryBar extends StatelessWidget {
  const SummaryBar({
    super.key,
    required this.income,
    required this.expense,
    required this.currencySymbol,
  });

  final double income;
  final double expense;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'de_DE');
    final total = income - expense;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _SummaryCell(
            label: 'Income',
            value: '$currencySymbol ${fmt.format(income)}',
            valueColor: AppColors.income,
          ),
          const _Divider(),
          _SummaryCell(
            label: 'Expense',
            value: '$currencySymbol ${fmt.format(expense)}',
            valueColor: AppColors.expense,
          ),
          const _Divider(),
          _SummaryCell(
            label: 'Total',
            value: '$currencySymbol ${fmt.format(total)}',
            valueColor: total >= 0 ? AppColors.income : AppColors.expense,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style:
                AppTypography.caption1.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.moneySmall.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.divider,
    );
  }
}
