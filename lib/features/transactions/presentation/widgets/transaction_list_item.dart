// Transaction row widget for the daily list — transactions feature.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/entities/transaction.dart';

/// 56dp row representing one transaction in the daily view.
/// Supports income (blue +), expense (coral -), and transfer (grey) styling.
/// Excluded transactions render in muted grey with strikethrough amount.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.categoryEmoji,
    required this.categoryName,
    required this.categoryColor,
    required this.accountName,
    this.currencySymbol = '€',
    required this.onTap,
    required this.onDelete,
  });

  final Transaction transaction;
  final String? categoryEmoji;
  final String categoryName;
  final Color? categoryColor;
  final String accountName;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isExcluded = transaction.isExcluded;
    final fmt = NumberFormat('#,##0.00', 'de_DE');
    final amt = fmt.format(transaction.amount);

    Color amountColor;
    String amountText;
    TextDecoration amountDecoration;

    if (isExcluded) {
      amountColor = AppColors.textTertiary;
      amountDecoration = TextDecoration.lineThrough;
      amountText = '$currencySymbol $amt';
    } else {
      amountDecoration = TextDecoration.none;
      switch (transaction.type) {
        case 'income':
          amountColor = AppColors.income;
          amountText = '+ $currencySymbol $amt';
        case 'expense':
          amountColor = AppColors.expense;
          amountText = '- $currencySymbol $amt';
        default:
          amountColor = AppColors.textSecondary;
          amountText = '$currencySymbol $amt';
      }
    }

    final circleColor = categoryColor ?? AppColors.bgTertiary;
    final textColor =
        isExcluded ? AppColors.textTertiary : AppColors.textPrimary;
    final subtextColor =
        isExcluded ? AppColors.textTertiary : AppColors.textSecondary;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return _confirmDelete(context);
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppHeights.listItem,
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.lg),
              CircleAvatar(
                radius: 20,
                backgroundColor: circleColor,
                child: categoryEmoji != null
                    ? Text(
                        categoryEmoji!,
                        style: const TextStyle(fontSize: 18),
                      )
                    : const Icon(
                        Icons.swap_horiz,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description?.isNotEmpty == true
                          ? transaction.description!
                          : categoryName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      accountName,
                      style: AppTypography.caption1.copyWith(
                        color: subtextColor,
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
                  color: amountColor,
                  decoration: amountDecoration,
                  decorationColor: amountColor,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    // Guard: widget may have been removed from tree before dialog is shown.
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          'Delete transaction?',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This cannot be undone.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
