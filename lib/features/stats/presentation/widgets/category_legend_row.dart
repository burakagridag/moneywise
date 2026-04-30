// Category legend row widget for the stats breakdown list — stats feature.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// 56dp row showing a color badge, category icon + name, percentage, and amount.
class CategoryLegendRow extends StatelessWidget {
  const CategoryLegendRow({
    super.key,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.badgeColor,
    this.emoji,
    this.onTap,
  });

  final String categoryName;
  final double amount;
  final double percentage;
  final Color badgeColor;
  final String? emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'de_DE');

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppHeights.listItem,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              // Percentage badge
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTypography.caption1.copyWith(color: badgeColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Category icon circle
              CircleAvatar(
                radius: 18,
                backgroundColor: badgeColor.withValues(alpha: 0.15),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 16))
                    : Icon(Icons.circle, size: 16, color: badgeColor),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name
              Expanded(
                child: Text(
                  categoryName,
                  style: AppTypography.bodyMedium
                      .copyWith(color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Amount
              Text(
                fmt.format(amount),
                style: AppTypography.moneySmall
                    .copyWith(color: context.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
