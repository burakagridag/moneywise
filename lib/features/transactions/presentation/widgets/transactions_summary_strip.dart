// TransactionsSummaryStrip — shared Income / Expense / Net strip used on all
// 3 tabs of the redesigned Transactions screen — features/transactions EPIC8D-01.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Three-column Income / Expense / Net summary strip.
/// Appears at the top of all 3 tabs (List, Calendar, Summary).
class TransactionsSummaryStrip extends StatelessWidget {
  const TransactionsSummaryStrip({
    super.key,
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final net = income - expense;
    final isDark = context.isDark;

    // SPEC-021 §4: net positive is text-primary (neutral black), not income green.
    final netColor = net < 0 ? context.expenseColor : context.textPrimary;

    return Container(
      color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StripColumn(
              label: l10n.transactionsStripIncome,
              value: CurrencyFormatter.format(income),
              valueColor: context.incomeColor,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StripColumn(
              label: l10n.transactionsStripExpense,
              value: CurrencyFormatter.format(expense),
              valueColor: context.expenseColor,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StripColumn(
              label: l10n.transactionsStripNet,
              value: CurrencyFormatter.format(net.abs()),
              valueColor: netColor,
              prefix: net < 0 ? '−' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripColumn extends StatelessWidget {
  const _StripColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    this.prefix,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.caption2.copyWith(
            color: context.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          prefix != null ? '$prefix $value' : value,
          style: AppTypography.moneySmall.copyWith(
            color: valueColor,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: context.dividerColor,
    );
  }
}
