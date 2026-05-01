// EmptyStateCards — home feature (EPIC8A-10).
// Shows onboarding action cards independently per completion state.
// Each card auto-dismisses when the user completes its respective action.
// All cards hidden → entire widget collapses to SizedBox.shrink().
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../providers/empty_state_provider.dart';

/// Side length of the icon well container inside each onboarding card.
const double _kIconWellSize = 48.0;

/// Size of the icon glyph rendered inside the icon well.
const double _kIconGlyphSize = 24.0;

/// Chevron icon size for onboarding card trailing indicator.
const double _kChevronIconSize = 16.0;

/// Renders onboarding action cards for actions the user has not yet completed.
///
/// Each of the three cards has an independent completion condition:
///   - "Add your first transaction" — hidden once [totalTransactionCountProvider] > 0
///   - "Manage your accounts"       — hidden once [userAccountCountProvider] > 0
///   - "Set a monthly budget"       — hidden once [hasBudgetConfiguredProvider] emits true
///     (true when a global budget OR any category budget with amount > 0 exists)
///
/// If all three conditions are met the entire widget (including the section header)
/// collapses to [SizedBox.shrink]. While any provider is still loading the widget
/// stays hidden to avoid incorrect flashing.
class EmptyStateCards extends ConsumerWidget {
  const EmptyStateCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txCountAsync = ref.watch(totalTransactionCountProvider);
    final acctCountAsync = ref.watch(userAccountCountProvider);
    final hasBudgetAsync = ref.watch(hasBudgetConfiguredProvider);

    // While any provider is still loading, stay hidden — no flash on startup.
    if (txCountAsync.isLoading ||
        acctCountAsync.isLoading ||
        hasBudgetAsync.isLoading) {
      return const SizedBox.shrink();
    }

    // On error, stay hidden — don't surface provider errors in onboarding UI.
    if (txCountAsync.hasError ||
        acctCountAsync.hasError ||
        hasBudgetAsync.hasError) {
      return const SizedBox.shrink();
    }

    final showAddTransaction = (txCountAsync.valueOrNull ?? 0) == 0;
    final showManageAccounts = (acctCountAsync.valueOrNull ?? 0) == 0;
    // Card is hidden when any budget (global or category) is configured.
    final showSetBudget = !(hasBudgetAsync.valueOrNull ?? false);

    final anyVisible =
        showAddTransaction || showManageAccounts || showSetBudget;
    if (!anyVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    final cards = <Widget>[];

    if (showAddTransaction) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: AppSpacing.sm));
      cards.add(_OnboardingCard(
        icon: Icons.add_circle_outline,
        title: l10n.homeEmptyStateAddTransactionTitle,
        subtitle: l10n.homeEmptyStateAddTransactionSubtitle,
        onTap: () => context.go(Routes.transactions),
      ));
    }

    if (showManageAccounts) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: AppSpacing.sm));
      cards.add(_OnboardingCard(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.homeEmptyStateManageAccountsTitle,
        subtitle: l10n.homeEmptyStateManageAccountsSubtitle,
        onTap: () => context.go(Routes.accounts),
      ));
    }

    if (showSetBudget) {
      if (cards.isNotEmpty) cards.add(const SizedBox(height: AppSpacing.sm));
      cards.add(_OnboardingCard(
        icon: Icons.savings_outlined,
        title: l10n.homeEmptyStateSetBudgetTitle,
        subtitle: l10n.homeEmptyStateSetBudgetSubtitle,
        onTap: () => context.go(Routes.budget),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
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
                // Icon container — _kIconWellSize × _kIconWellSize dp
                Container(
                  width: _kIconWellSize,
                  height: _kIconWellSize,
                  decoration: BoxDecoration(
                    color: context.brandSurfaceAdaptive,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    icon,
                    size: _kIconGlyphSize,
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
                  size: _kChevronIconSize,
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
