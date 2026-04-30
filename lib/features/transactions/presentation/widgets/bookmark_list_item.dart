// Bookmark list item widget displaying name, type chip, and optional amount — transactions feature.
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/bookmark.dart';

/// A single row in the bookmarks list.
/// Shows the bookmark name, a colored type chip, and optionally the amount.
class BookmarkListItem extends StatelessWidget {
  const BookmarkListItem({
    super.key,
    required this.bookmark,
    this.onTap,
  });

  final Bookmark bookmark;
  final VoidCallback? onTap;

  Color get _typeColor {
    switch (bookmark.type) {
      case 'income':
        return AppColors.income;
      case 'expense':
        return AppColors.expense;
      case 'transfer':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(bookmark.name, style: AppTypography.body),
      subtitle: Row(
        children: [
          _TypeChip(label: bookmark.type, color: _typeColor),
          if (bookmark.amount != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              CurrencyFormatter.format(bookmark.amount!),
              style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(color: color),
      ),
    );
  }
}
