// TransactionsEmptyState — brand-tinted empty state shown when a month has
// zero transactions — features/transactions EPIC8D-01.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';

/// Full-screen empty state for the Transactions screen.
/// Shown when the selected month has no transactions.
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand-tinted circle with clipboard icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.transactionsEmptyTitle,
              style: AppTypography.title3.copyWith(
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.transactionsEmptySubtitle,
              style: AppTypography.subhead.copyWith(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.push(Routes.transactionAddEdit),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                minimumSize: const Size(double.infinity, AppSpacing.huge),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
              ),
              child: Text(
                l10n.transactionsEmptyCTA,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textOnBrand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
