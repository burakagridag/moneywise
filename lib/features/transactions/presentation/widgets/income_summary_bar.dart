// Income / Expense / Total summary bar displayed below the period tab bar.
// features/transactions — SPEC-008 IncomeSummaryBar.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/i18n/arb/app_localizations.dart';

/// Displays three evenly-distributed columns: Income, Exp., Total.
/// Values update reactively via props — the widget itself is stateless.
class IncomeSummaryBar extends StatelessWidget {
  const IncomeSummaryBar({
    super.key,
    required this.income,
    required this.expense,
    this.currencySymbol = '€',
    this.onIncomeTap,
    this.onExpenseTap,
    this.onTotalTap,
  });

  final double income;
  final double expense;
  final String currencySymbol;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onTotalTap;

  double get _total => income - expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _SummaryColumn(
            label: l10n.income,
            value: CurrencyFormatter.format(income, symbol: currencySymbol),
            valueColor: AppColors.income,
            semanticsLabel: 'Total income: '
                '${CurrencyFormatter.format(income, symbol: currencySymbol)}',
            onTap: onIncomeTap,
          ),
          const _VerticalDivider(),
          _SummaryColumn(
            label: l10n.expenseLabel,
            value: CurrencyFormatter.format(expense, symbol: currencySymbol),
            valueColor: AppColors.expense,
            semanticsLabel: 'Total expense: '
                '${CurrencyFormatter.format(expense, symbol: currencySymbol)}',
            onTap: onExpenseTap,
          ),
          const _VerticalDivider(),
          _SummaryColumn(
            label: l10n.totalLabel,
            value:
                CurrencyFormatter.formatSigned(_total, symbol: currencySymbol),
            valueColor: _total >= 0 ? AppColors.income : AppColors.expense,
            semanticsLabel: 'Net balance: '
                '${CurrencyFormatter.formatSigned(_total, symbol: currencySymbol)}',
            onTap: onTotalTap,
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.semanticsLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: semanticsLabel,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.caption1.copyWith(
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.moneySmall.copyWith(color: valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: context.dividerColor,
    );
  }
}
