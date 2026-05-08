// BudgetView — redesigned budget widget — EPIC8C-01.
// Slate-blue hero card, metric cards, insight slot, category list,
// donut placeholder, empty state, and category picker modal.
// ignore_for_file: prefer_const_constructors
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
import '../../../home/presentation/widgets/insight_card.dart';
import '../../../insights/domain/insight_classifier.dart';
import '../../../insights/presentation/providers/insights_providers.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../domain/budget_entity.dart';
import '../providers/budget_providers.dart';

// ---------------------------------------------------------------------------
// Hero gradient colors
// ---------------------------------------------------------------------------

const Color _heroGradientStartLight = Color(0xFF3D5A99);
const Color _heroGradientEndLight = Color(0xFF2E4A87);
const Color _heroGradientStartDark = Color(0xFF4F46E5);
const Color _heroGradientEndDark = Color(0xFF3D5A99);

// ---------------------------------------------------------------------------
// BudgetView — top-level entry point
// ---------------------------------------------------------------------------

/// Redesigned budget view (EPIC8C-01).
/// Reads [selectedStatsMonthProvider] for month navigation — shared with
/// the Stats tab so month navigation stays in sync.
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
        if (budgets.isEmpty) {
          return _EmptyState(allCategories: cats);
        }
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
// _BudgetContent — main scrollable layout
// ---------------------------------------------------------------------------

class _BudgetContent extends ConsumerWidget {
  const _BudgetContent({
    required this.budgets,
    required this.categories,
    required this.selectedMonth,
  });

  final List<BudgetWithSpending> budgets;
  final List<Category> categories;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // Aggregate totals
    final totalBudget = budgets.fold<double>(0.0, (s, b) => s + b.effective);
    final totalSpent = budgets.fold<double>(0.0, (s, b) => s + b.spent);
    final totalRemaining = totalBudget - totalSpent;
    final totalRatio = totalBudget > 0 ? totalSpent / totalBudget : 0.0;

    // Days remaining / elapsed in month
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final isCurrentMonth = selectedMonth.year == now.year &&
        selectedMonth.month == now.month;
    final daysLeft = isCurrentMonth
        ? (daysInMonth - now.day + 1).clamp(0, daysInMonth)
        : 0;

    // Actual daily burn rate = total spent ÷ days elapsed this month.
    // For past months, daysElapsed = full month length.
    final daysElapsed = isCurrentMonth ? now.day : daysInMonth;
    final actualDailyBurnRate = totalSpent / daysElapsed;

    // Safe daily pace = remaining budget ÷ days left (what you CAN spend/day).
    final safeDailyPace =
        (daysLeft > 0 && totalRemaining > 0) ? totalRemaining / daysLeft : 0.0;

    // idealDailyPace alias kept for hero card footer label.
    final idealDailyPace = safeDailyPace;

    // Budgeted vs unbudgeted split
    final budgetedCats =
        budgets.where((b) => b.effective > 0).toList()
          ..sort((a, b) => b.spent.compareTo(a.spent));
    final unbudgetedBudgets =
        budgets.where((b) => b.effective == 0).toList();

    return RefreshIndicator(
      color: AppColors.brandPrimary,
      onRefresh: () async {
        ref.invalidate(budgetsForMonthProvider(selectedMonth));
        ref.invalidate(insightsForSurfaceProvider(InsightSurface.budget));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero card
            _BudgetHeroCard(
              remaining: totalRemaining,
              spent: totalSpent,
              totalBudget: totalBudget,
              ratio: totalRatio.clamp(0.0, 1.5),
              daysLeft: daysLeft,
              idealDailyPace: idealDailyPace,
              selectedMonth: selectedMonth,
            ),

            // 2. Metric cards row
            _MetricCardsRow(
              totalSpent: totalSpent,
              actualDailyBurnRate: actualDailyBurnRate,
              safeDailyPace: safeDailyPace,
              selectedMonth: selectedMonth,
            ),

            // 3. Insight slot (budget surface — concentration rule only)
            _BudgetInsightSlot(),

            // 4. Categories section
            _SectionHeader(
              title: l10n.budgetCategoriesTitle,
              actionLabel: l10n.budgetCategoriesEditLink,
              onAction: () => context.push(Routes.budgetSetting),
            ),
            _CategoryList(
              budgetedBudgets: budgetedCats,
              unbudgetedBudgets: unbudgetedBudgets,
              categories: categories,
            ),

            // 5. Distribution placeholder
            _SectionHeader(title: l10n.budgetDistributionTitle),
            _DonutPlaceholder(
              budgets: budgetedCats,
              categories: categories,
              totalSpent: totalSpent,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BudgetHeroCard — slate-blue gradient, no tap (EPIC8B-07 adds tap)
// ---------------------------------------------------------------------------

class _BudgetHeroCard extends StatelessWidget {
  const _BudgetHeroCard({
    required this.remaining,
    required this.spent,
    required this.totalBudget,
    required this.ratio,
    required this.daysLeft,
    required this.idealDailyPace,
    required this.selectedMonth,
  });

  final double remaining;
  final double spent;
  final double totalBudget;
  final double ratio;
  final int daysLeft;
  final double idealDailyPace;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final gradientStart =
        isDark ? _heroGradientStartDark : _heroGradientStartLight;
    final gradientEnd = isDark ? _heroGradientEndDark : _heroGradientEndLight;
    final isOverBudget = remaining < 0;

    // EPIC8C-01: Hero card is NO-OP (no GestureDetector/InkWell/visual affordance).
    // EPIC8B-07 will add InkWell + onTap → edit modal.
    return Semantics(
      label: '${l10n.budgetHeroLabelRemaining}. '
          '${CurrencyFormatter.format(remaining.abs())} '
          '${isOverBudget ? l10n.budgetHeroSemanticOverBudget : l10n.budgetHeroSemanticRemaining}. '
          '${daysLeft > 0 ? l10n.budgetHeroDaysLeft(daysLeft) : ""}.',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: label + days left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.budgetHeroLabelRemaining,
                    style: AppTypography.caption2.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (daysLeft > 0)
                    Text(
                      l10n.budgetHeroDaysLeft(daysLeft),
                      style: AppTypography.caption1
                          .copyWith(color: Colors.white70),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Large remaining amount
              Text(
                CurrencyFormatter.format(remaining.abs()),
                style: AppTypography.moneyLarge.copyWith(
                  color: isOverBudget
                      ? const Color(0xFFFFCDD2)
                      : Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Progress bar — white/transparent theme
              _HeroPaceBar(ratio: ratio, selectedMonth: selectedMonth),
              const SizedBox(height: AppSpacing.sm),

              // Footer: spent / total + ideal pace
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.budgetHeroSpentOf(
                        CurrencyFormatter.format(spent),
                        CurrencyFormatter.format(totalBudget),
                      ),
                      style: AppTypography.caption1
                          .copyWith(color: Colors.white70),
                    ),
                  ),
                  if (idealDailyPace > 0)
                    Text(
                      l10n.budgetHeroIdealPace(
                        CurrencyFormatter.format(idealDailyPace),
                      ),
                      style: AppTypography.caption1
                          .copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HeroPaceBar — white progress bar with today-marker
// ---------------------------------------------------------------------------

class _HeroPaceBar extends StatelessWidget {
  const _HeroPaceBar({required this.ratio, required this.selectedMonth});

  final double ratio;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final now = DateTime.now();
        final daysInMonth =
            DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        final isCurrentMonth = selectedMonth.year == now.year &&
            selectedMonth.month == now.month;
        final dayFraction =
            isCurrentMonth ? (now.day - 1) / (daysInMonth - 1) : 1.0;
        final markerX = (dayFraction * constraints.maxWidth).clamp(
          0.0,
          constraints.maxWidth,
        );
        final fillWidth =
            (ratio.clamp(0.0, 1.0) * constraints.maxWidth);

        return SizedBox(
          height: 8,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              // Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: fillWidth,
                  decoration: BoxDecoration(
                    color: ratio > 1.0
                        ? const Color(0xFFFFCDD2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              // Today marker
              if (isCurrentMonth)
                Positioned(
                  left: markerX - 1,
                  top: -2,
                  bottom: -2,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _MetricCardsRow — 2-column grid: Daily + Last Month
// ---------------------------------------------------------------------------

class _MetricCardsRow extends ConsumerWidget {
  const _MetricCardsRow({
    required this.totalSpent,
    required this.actualDailyBurnRate,
    required this.safeDailyPace,
    required this.selectedMonth,
  });

  final double totalSpent;

  /// Actual daily burn rate = total spent ÷ days elapsed this month.
  final double actualDailyBurnRate;

  /// Safe daily pace = remaining budget ÷ days left (what you CAN spend/day).
  final double safeDailyPace;

  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prevMonth =
        DateTime(selectedMonth.year, selectedMonth.month - 1);
    final prevTotalAsync = ref.watch(totalBudgetProvider(prevMonth));
    final prevSpent = prevTotalAsync.valueOrNull?.totalSpent ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Daily metric — primary: actual burn rate; subtitle: safe to spend.
          Expanded(
            child: _MetricCard(
              title: l10n.budgetMetricDailyTitle,
              primaryValue: CurrencyFormatter.format(actualDailyBurnRate),
              subtitle: safeDailyPace > 0
                  ? l10n.budgetMetricDailySafe(
                      CurrencyFormatter.format(safeDailyPace),
                    )
                  : l10n.budgetMetricDeltaNoData,
              subtitleColor: safeDailyPace > 0
                  ? AppColors.success
                  : context.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Last month metric
          Expanded(
            child: _LastMonthMetricCard(
              currentSpent: totalSpent,
              lastMonthSpent: prevSpent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.primaryValue,
    required this.subtitle,
    required this.subtitleColor,
  });

  final String title;
  final String primaryValue;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption2.copyWith(
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            primaryValue,
            style: AppTypography.moneySmall
                .copyWith(color: context.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption1.copyWith(color: subtitleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LastMonthMetricCard extends StatelessWidget {
  const _LastMonthMetricCard({
    required this.currentSpent,
    required this.lastMonthSpent,
  });

  final double currentSpent;
  final double lastMonthSpent;

  /// Computes delta string and color per spec (5 cases).
  ({String label, Color color}) _delta(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = context.textSecondary;
    final success =
        context.isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    const warning = AppColors.warning;

    // Case 1 & 2: no last month data
    if (lastMonthSpent == 0) {
      return (label: l10n.budgetMetricDeltaNoData, color: secondary);
    }

    final delta =
        ((currentSpent - lastMonthSpent) / lastMonthSpent * 100).round();

    if (delta < 0) {
      // Case 3: decrease (good) — green
      return (
        label: l10n.budgetMetricDeltaDecrease(delta.abs()),
        color: success,
      );
    } else if (delta > 0) {
      // Case 4: increase — orange
      return (
        label: l10n.budgetMetricDeltaIncrease(delta),
        color: warning,
      );
    } else {
      // Case 5: same — secondary
      return (label: l10n.budgetMetricDeltaSame, color: secondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = _delta(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetMetricLastMonthTitle,
            style: AppTypography.caption2.copyWith(
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(lastMonthSpent),
            style: AppTypography.moneySmall
                .copyWith(color: context.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            d.label,
            style: AppTypography.caption1.copyWith(color: d.color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BudgetInsightSlot — concentration insight only, max 1
// ---------------------------------------------------------------------------

class _BudgetInsightSlot extends ConsumerWidget {
  const _BudgetInsightSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsights =
        ref.watch(insightsForSurfaceProvider(InsightSurface.budget));

    return asyncInsights.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final insight = insights.first.copyWithDark(isDark);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: InsightCard(
            icon: insight.icon,
            iconColor: insight.iconColor,
            iconBackgroundColor: insight.iconBackgroundColor,
            title: insight.headline,
            subtitle: insight.body,
            // No actionRoute for budget insight slot in V1
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sectionHeaderTop,
        bottom: AppSpacing.sectionHeaderBottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.caption2.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Semantics(
                label: '$actionLabel, link',
                child: Text(
                  actionLabel!,
                  style: AppTypography.caption1
                      .copyWith(color: AppColors.brandPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryList — budgeted + collapse row for unbudgeted
// ---------------------------------------------------------------------------

class _CategoryList extends StatefulWidget {
  const _CategoryList({
    required this.budgetedBudgets,
    required this.unbudgetedBudgets,
    required this.categories,
  });

  final List<BudgetWithSpending> budgetedBudgets;
  final List<BudgetWithSpending> unbudgetedBudgets;
  final List<Category> categories;

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList> {
  bool _unbudgetedExpanded = false;

  Category? _categoryFor(String categoryId) {
    try {
      return widget.categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRows = [
      ...widget.budgetedBudgets,
      if (_unbudgetedExpanded) ...widget.unbudgetedBudgets,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: context.bgSecondary,
          child: Column(
            children: [
              for (var i = 0; i < allRows.length; i++) ...[
                _CategoryBudgetRow(
                  budgetWithSpending: allRows[i],
                  category: _categoryFor(allRows[i].budget.categoryId),
                ),
                if (i < allRows.length - 1 ||
                    (!_unbudgetedExpanded &&
                        widget.unbudgetedBudgets.isNotEmpty))
                  Divider(
                    height: 1,
                    color: context.dividerColor,
                    indent: 56,
                  ),
              ],
              // Collapse row for unbudgeted categories
              if (widget.unbudgetedBudgets.isNotEmpty && !_unbudgetedExpanded)
                _CollapseRow(
                  count: widget.unbudgetedBudgets.length,
                  onTap: () => setState(() => _unbudgetedExpanded = true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    return Semantics(
      label: '${category?.name ?? ''} ${l10n.budgetCategorySemanticCategory}. '
          '${CurrencyFormatter.format(bws.spent)} ${l10n.budgetCategorySemanticSpent}'
          '${hasBudget ? " / ${CurrencyFormatter.format(bws.effective)} ${l10n.budgetCategorySemanticBudget}" : ""}. '
          '${isOverBudget ? l10n.budgetCategorySemanticOverBudget : ""}',
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
                // Name + progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category?.name ?? bws.budget.categoryId,
                        style: AppTypography.bodyMedium
                            .copyWith(
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (hasBudget) ...[
                        BudgetProgressBar(
                          ratio: bws.progressRatio,
                          height: 4,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyFormatter.format(bws.spent)} / '
                          '${CurrencyFormatter.format(bws.effective)}',
                          style: AppTypography.caption1
                              .copyWith(color: context.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else
                        Text(
                          l10n.budgetViewNoBudgetSet,
                          style: AppTypography.caption1
                              .copyWith(color: context.textSecondary),
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
                    color: BudgetProgressBar.colorForRatio(bws.progressRatio),
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

class _CollapseRow extends StatelessWidget {
  const _CollapseRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const SizedBox(width: 40 + AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetCategoriesCollapsedCount(count),
                  style: AppTypography.caption1
                      .copyWith(color: AppColors.brandPrimary),
                ),
                Text(
                  l10n.budgetCategoriesCollapsedSubtitle,
                  style: AppTypography.caption1
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.brandPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DonutPlaceholder — 2-segment SVG placeholder (EPIC8B-06 will replace)
// ---------------------------------------------------------------------------

class _DonutPlaceholder extends StatelessWidget {
  const _DonutPlaceholder({
    required this.budgets,
    required this.categories,
    required this.totalSpent,
  });

  final List<BudgetWithSpending> budgets;
  final List<Category> categories;
  final double totalSpent;

  Category? _catFor(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Top 2 categories for legend
    final top2 = budgets.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // SVG-style donut placeholder
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      budgets: budgets,
                      totalSpent: totalSpent,
                      isDark: context.isDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, bws) in top2.indexed)
                        _LegendItem(
                          label: _catFor(bws.budget.categoryId)?.name ??
                              bws.budget.categoryId,
                          pct: totalSpent > 0
                              ? (bws.spent / totalSpent * 100).round()
                              : 0,
                          color: _donutColor(i),
                        ),
                      if (budgets.length > 2)
                        _LegendItem(
                          label: '...',
                          pct: totalSpent > 0
                              ? (budgets
                                          .skip(2)
                                          .fold<double>(
                                            0,
                                            (s, b) => s + b.spent,
                                          ) /
                                      totalSpent *
                                      100)
                                  .round()
                              : 0,
                          color: context.isDark
                              ? AppColors.bgTertiary
                              : AppColors.bgTertiaryLight,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.budgetDistributionFooter(
                CurrencyFormatter.format(totalSpent),
              ),
              style: AppTypography.caption1
                  .copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static const _palette = [
    AppColors.brandPrimary,              // 0xFF3D5A99
    Color(0xFF2E86AB),                   // TODO(EPIC8B-06): add to AppColors as chartBlue
    AppColors.success,                   // 0xFF4CAF50
    AppColors.warning,                   // 0xFFFFA726
    AppColors.error,                     // 0xFFE53935
  ];

  static Color _donutColor(int index) =>
      _palette[index % _palette.length];
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.pct,
    required this.color,
  });

  final String label;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$label $pct%',
              style: AppTypography.caption1
                  .copyWith(color: context.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.budgets,
    required this.totalSpent,
    required this.isDark,
  });

  final List<BudgetWithSpending> budgets;
  final double totalSpent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (totalSpent <= 0) {
      // Empty ring
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = isDark ? AppColors.bgTertiary : AppColors.bgTertiaryLight;
      canvas.drawArc(
        Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
        -1.5708,
        6.2832,
        false,
        paint,
      );
      return;
    }

    const palette = _DonutPlaceholder._palette;
    const strokeWidth = 14.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    double startAngle = -1.5708; // -π/2 → 12 o'clock
    for (var i = 0; i < budgets.length && i < palette.length; i++) {
      final sweep = totalSpent > 0
          ? budgets[i].spent / totalSpent * 6.2832
          : 0.0;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = palette[i % palette.length];
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.totalSpent != totalSpent ||
      oldDelegate.isDark != isDark ||
      oldDelegate.budgets != budgets;
}

// ---------------------------------------------------------------------------
// _EmptyState — no budgets set
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.allCategories});

  final List<Category> allCategories;

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
              l10n.budgetEmptyTitle,
              style: AppTypography.title3
                  .copyWith(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.budgetEmptySubtitle,
              style: AppTypography.subhead
                  .copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => _openCategoryPicker(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              child: Text(l10n.budgetEmptyCTA),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {},
              child: Text(
                l10n.budgetEmptySkip,
                style: AppTypography.subhead
                    .copyWith(color: context.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategoryPicker(BuildContext context) {
    // Pattern: return selected IDs from sheet via pop(); navigate in .then()
    // so that navigation uses the outer context AFTER the modal is fully dismissed.
    // This avoids Navigator/GoRouter conflicts from calling push() inside pop().
    showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _CategoryPickerModal(allCategories: allCategories),
    ).then((selectedIds) {
      if (selectedIds != null &&
          selectedIds.isNotEmpty &&
          context.mounted) {
        context.push(Routes.budgetSetting);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// _CategoryPickerModal — bottom sheet for category selection
// ---------------------------------------------------------------------------

class _CategoryPickerModal extends StatefulWidget {
  const _CategoryPickerModal({required this.allCategories});

  final List<Category> allCategories;

  @override
  State<_CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends State<_CategoryPickerModal> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expenseCategories =
        widget.allCategories.where((c) => c.type == 'expense').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: context.bgPrimary,
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.budgetCategoryPickerTitle,
                  style: AppTypography.title3
                      .copyWith(color: context.textPrimary),
                ),
              ),
              // Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: expenseCategories.length,
                  itemBuilder: (context, i) {
                    final cat = expenseCategories[i];
                    final isSelected = _selected.contains(cat.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selected.remove(cat.id);
                        } else {
                          _selected.add(cat.id);
                        }
                      }),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPrimary.withValues(
                                      alpha: 0.15,
                                    )
                                  : context.bgSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.brandPrimary
                                    : context.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat.iconEmoji ?? '💰',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            cat.name,
                            style: AppTypography.caption1
                                .copyWith(color: context.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // CTA
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg +
                      MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            // Return selected IDs to _openCategoryPicker().then()
                            // so that GoRouter navigation happens AFTER the modal
                            // is fully dismissed — avoids Navigator/GoRouter conflicts.
                            Navigator.of(context).pop<Set<String>>(_selected);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                    ),
                    child: Text(
                      l10n.budgetCategoryPickerCTA(_selected.length),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _LoadingState
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.brandPrimary),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorState
// ---------------------------------------------------------------------------

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
          const Icon(
            Icons.warning_outlined,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.budgetViewCouldNotLoad,
            style: AppTypography.title3.copyWith(color: context.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
