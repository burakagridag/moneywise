// EmptyStateCards — home feature (EPIC8A-10).
// Shows 3 onboarding action cards when the user has zero transactions.
// Auto-dismisses when recentTransactionsProvider emits at least 1 transaction.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../providers/recent_transactions_provider.dart';

/// Renders 3 onboarding action cards when the user has no transactions.
///
/// Watches [recentTransactionsProvider]. Returns [SizedBox.shrink] as soon as
/// the provider emits a non-empty list (auto-dismiss behaviour, no animation
/// required for V1 per Sponsor decision).
class EmptyStateCards extends ConsumerWidget {
  const EmptyStateCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxns = ref.watch(recentTransactionsProvider);

    // While loading or on error, stay hidden so we don't flash incorrectly.
    final isEmpty = asyncTxns.when(
      data: (txns) => txns.isEmpty,
      loading: () => false,
      error: (_, __) => false,
    );

    if (!isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OnboardingCard(
          icon: Icons.add_circle_outline,
          title: l10n.homeEmptyStateAddTransactionTitle,
          subtitle: l10n.homeEmptyStateAddTransactionSubtitle,
          onTap: () => context.go(Routes.transactions),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OnboardingCard(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.homeEmptyStateManageAccountsTitle,
          subtitle: l10n.homeEmptyStateManageAccountsSubtitle,
          onTap: () => context.go(Routes.more),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OnboardingCard(
          icon: Icons.savings_outlined,
          title: l10n.homeEmptyStateSetBudgetTitle,
          subtitle: l10n.homeEmptyStateSetBudgetSubtitle,
          onTap: () => context.go(Routes.budget),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private card widget
// ---------------------------------------------------------------------------

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor =
        context.isDark ? AppColors.bgElevated : AppColors.bgElevatedLight;
    final borderColor =
        context.isDark ? AppColors.border : AppColors.borderLight;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Icon container — 48×48dp
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTypography.caption1.copyWith(
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: context.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
