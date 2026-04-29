// Single transaction list row used in DailyView and DayDetailPanel.
// features/transactions — SPEC-009 TransactionRow.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/transaction.dart';

/// Renders one transaction as a 56dp list tile.
///
/// Shows:
/// * Left: category emoji in coloured circle (or transfer arrows).
/// * Middle: category name (top), account name (bottom).
/// * Right: formatted amount in type-appropriate colour.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.transaction,
    this.categoryName,
    this.categoryEmoji,
    this.categoryColor,
    this.accountName,
    this.toAccountName,
    this.currencySymbol = '€',
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final Transaction transaction;
  final String? categoryName;
  final String? categoryEmoji;

  /// Hex color string for the category icon background, e.g. "#FF6B5C".
  final String? categoryColor;
  final String? accountName;
  final String? toAccountName;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  Color get _amountColor {
    if (transaction.isExcluded) return AppColors.textTertiary;
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
        return AppColors.textPrimary;
    }
  }

  Color get _iconBgColor {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.income.withAlpha(38);
      case TransactionType.expense:
        return AppColors.expense.withAlpha(38);
      case TransactionType.transfer:
        return AppColors.bgTertiary;
    }
  }

  String get _subtitle {
    if (transaction.type == TransactionType.transfer) {
      final from = accountName ?? '';
      final to = toAccountName ?? '';
      return '$from → $to';
    }
    return accountName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final amountText = CurrencyFormatter.format(
      transaction.amount,
      symbol: currencySymbol,
    );
    final semanticsLabel =
        '${categoryName ?? _iconLabel}, ${accountName ?? ''}, $amountText. '
        'Double tap to edit.';

    return Semantics(
      label: semanticsLabel,
      child: Dismissible(
        key: ValueKey('tx_${transaction.id}'),
        direction: DismissDirection.endToStart,
        background: _buildSwipeBackground(),
        confirmDismiss: (_) async {
          if (onDelete == null) return false;
          return await _confirmDelete(context);
        },
        onDismissed: (_) => onDelete?.call(),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: AppHeights.listItem,
            color: AppColors.bgPrimary,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _CategoryIcon(
                  emoji: categoryEmoji,
                  isTransfer: transaction.type == TransactionType.transfer,
                  bgColor: _iconBgColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName ?? _iconLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _subtitle,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  amountText,
                  style: AppTypography.moneySmall.copyWith(
                    color: _amountColor,
                    decoration: transaction.isExcluded
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _iconLabel {
    switch (transaction.type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  Widget _buildSwipeBackground() {
    return Container(
      color: AppColors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Delete Transaction?',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This transaction will be permanently deleted. This action cannot '
          'be undone.',
          style: AppTypography.subhead.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: AppTypography.subhead.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ---------------------------------------------------------------------------
// Category icon circle
// ---------------------------------------------------------------------------

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.emoji,
    required this.isTransfer,
    required this.bgColor,
  });

  final String? emoji;
  final bool isTransfer;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: isTransfer
            ? const Icon(
                Icons.swap_horiz,
                color: AppColors.textPrimary,
                size: 20,
              )
            : Text(
                emoji ?? '💰',
                style: const TextStyle(fontSize: 20),
              ),
      ),
    );
  }
}
