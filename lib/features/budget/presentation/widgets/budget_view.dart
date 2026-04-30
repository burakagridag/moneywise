// BudgetView — budget sub-tab content within StatsScreen — budget feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/budget_progress_bar.dart';
import '../../../../domain/entities/category.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../domain/budget_entity.dart';
import '../providers/budget_providers.dart';

/// Displays the Budget sub-tab inside StatsScreen.
/// Reads [budgetsForMonthProvider] and [statsCategoryListProvider] reactively.
class BudgetView extends ConsumerWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final budgetsAsync = ref.watch(budgetsForMonthProvider(selectedMonth));
    final catsAsync = ref.watch(statsCategoryListProvider);

    return budgetsAsync.when(
      loading: () => const _LoadingState(),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(budgetsForMonthProvider(selectedMonth)),
      ),
      data: (budgets) {
        final cats = catsAsync.asData?.value ?? [];
        return _BudgetContent(
          budgets: budgets,
          categories: cats,
          selectedMonth: selectedMonth,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.budgets,
    required this.categories,
    required this.selectedMonth,
  });

  final List<BudgetWithSpending> budgets;
  final List<Category> categories;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return _EmptyState(
          onSetUpBudgets: () => context.push(Routes.budgetSetting));
    }

    final totalBudget = budgets.fold<double>(0.0, (s, b) => s + b.effective);
    final totalSpent = budgets.fold<double>(0.0, (s, b) => s + b.spent);
    final totalRemaining = totalBudget - totalSpent;
    final totalRatio = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final totalCarryOver = budgets.fold<double>(0.0, (s, b) => s + b.carryOver);

    return RefreshIndicator(
      color: AppColors.brandPrimary,
      onRefresh: () async {
        // Force rebuild by reading the value — providers auto-invalidate on stream.
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            _BudgetSummaryCard(
              remaining: totalRemaining,
              spent: totalSpent,
              totalBudget: totalBudget,
              ratio: totalRatio.clamp(0.0, 1.5),
              carryOver: totalCarryOver,
              selectedMonth: selectedMonth,
            ),
            // Category list
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  color: context.bgSecondary,
                  child: Column(
                    children: [
                      for (var i = 0; i < budgets.length; i++) ...[
                        _CategoryBudgetRow(
                          budgetWithSpending: budgets[i],
                          category: _categoryFor(budgets[i].budget.categoryId),
                        ),
                        if (i < budgets.length - 1)
                          Divider(
                            height: 1,
                            color: context.dividerColor,
                            indent: 56,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Category? _categoryFor(String categoryId) {
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// BudgetSummaryCard
// ---------------------------------------------------------------------------

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.remaining,
    required this.spent,
    required this.totalBudget,
    required this.ratio,
    required this.carryOver,
    required this.selectedMonth,
  });

  final double remaining;
  final double spent;
  final double totalBudget;
  final double ratio;
  final double carryOver;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOverBudget = remaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.budgetViewRemainingMonthly,
                  style: AppTypography.subhead
                      .copyWith(color: context.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.budgetSetting),
                  child: Semantics(
                    label: '${l10n.budgetSetting}, link',
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Text(
                        '${l10n.budgetSetting} >',
                        style: AppTypography.subhead
                            .copyWith(color: AppColors.brandPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Remaining amount
            Text(
              CurrencyFormatter.format(remaining),
              style: AppTypography.title1.copyWith(
                color: isOverBudget ? AppColors.error : context.textPrimary,
              ),
            ),
            if (carryOver > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.budgetViewIncludesCarryOver(
                  CurrencyFormatter.format(carryOver),
                ),
                style: AppTypography.caption1
                    .copyWith(color: context.textTertiary),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            // Progress bar with Today indicator
            BudgetProgressBar(
              ratio: ratio,
              height: 8,
              showTodayIndicator: true,
              selectedMonth: selectedMonth,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Three-column footer
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.budgetSpent,
                      style: AppTypography.footnote
                          .copyWith(color: context.textSecondary),
                    ),
                    Text(
                      CurrencyFormatter.format(spent),
                      style: AppTypography.moneySmall
                          .copyWith(color: AppColors.expense),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.budgetOf,
                      style: AppTypography.footnote
                          .copyWith(color: context.textSecondary),
                    ),
                    Text(
                      CurrencyFormatter.format(totalBudget),
                      style: AppTypography.moneySmall
                          .copyWith(color: context.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CategoryBudgetRow
// ---------------------------------------------------------------------------

class _CategoryBudgetRow extends StatelessWidget {
  const _CategoryBudgetRow({
    required this.budgetWithSpending,
    required this.category,
  });

  final BudgetWithSpending budgetWithSpending;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bws = budgetWithSpending;
    final hasBudget = bws.effective > 0;
    final isOverBudget = bws.isOverBudget;
    final progressColor = BudgetProgressBar.colorForRatio(bws.progressRatio);

    return Semantics(
      label: '${category?.name ?? ''} category. '
          'Spent ${CurrencyFormatter.format(bws.spent)} '
          'of ${CurrencyFormatter.format(bws.effective)} budget. '
          '${(bws.progressRatio * 100).toStringAsFixed(0)} percent used.'
          '${isOverBudget ? " Over budget." : ""} '
          'Tap to edit budget.',
      child: InkWell(
        onTap: () => context.push(Routes.budgetSetting),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.bgTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      category?.iconEmoji ?? '💰',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Name + progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category?.name ?? bws.budget.categoryId,
                        style: AppTypography.bodyMedium
                            .copyWith(color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (hasBudget) ...[
                        BudgetProgressBar(
                          ratio: bws.progressRatio,
                          height: 4,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.format(bws.spent),
                              style: AppTypography.caption1
                                  .copyWith(color: context.textSecondary),
                            ),
                            Text(
                              ' / ',
                              style: AppTypography.caption1
                                  .copyWith(color: context.textTertiary),
                            ),
                            Text(
                              CurrencyFormatter.format(bws.effective),
                              style: AppTypography.caption1
                                  .copyWith(color: context.textSecondary),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          l10n.budgetViewNoBudgetSet,
                          style: AppTypography.caption1
                              .copyWith(color: context.textTertiary),
                        ),
                    ],
                  ),
                ),
                // Over-budget indicator
                if (isOverBudget) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: progressColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSetUpBudgets});

  final VoidCallback onSetUpBudgets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 64,
              color: context.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.budgetViewNoBudgetsTitle,
              style: AppTypography.title3.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.budgetViewNoBudgetsSubtitle,
              style:
                  AppTypography.subhead.copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onSetUpBudgets,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              child: Text(l10n.budgetViewSetUpBudgets),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.brandPrimary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_outlined, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.budgetViewCouldNotLoad,
            style: AppTypography.title3.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
