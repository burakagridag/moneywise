// TransactionsSummaryTab — "Özet" tab of the redesigned Transactions screen.
// Hero net card, top categories section, and week trend section — EPIC8D-01.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../providers/transactions_provider.dart';

// Brand gradient (matches BudgetHeroCard / ADR-015)
const Color _heroGradientStartLight = Color(0xFF3D5A99);
const Color _heroGradientEndLight = Color(0xFF2E4A87);
const Color _heroGradientStartDark = Color(0xFF4F46E5);
const Color _heroGradientEndDark = Color(0xFF3D5A99);

/// Özet tab — net hero card, top spending categories, week trend bar chart.
class TransactionsSummaryTab extends ConsumerWidget {
  const TransactionsSummaryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodNotifierProvider);
    final totalsAsync = ref.watch(monthlyTotalsProvider);
    final catsAsync = ref.watch(statsCategoryListProvider);

    return totalsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (_, __) => Center(
        child: Text(
          AppLocalizations.of(context)!.errorLoadTitle,
          style: AppTypography.subhead.copyWith(color: context.textSecondary),
        ),
      ),
      data: (totals) {
        final cats = catsAsync.asData?.value ?? [];
        return _SummaryContent(
          totals: totals,
          categories: cats,
          period: period,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SummaryContent
// ---------------------------------------------------------------------------

class _SummaryContent extends ConsumerWidget {
  const _SummaryContent({
    required this.totals,
    required this.categories,
    required this.period,
  });

  final MonthTotals totals;
  final List<dynamic> categories;
  final SelectedPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero net card
          _HeroNetCard(totals: totals, period: period),

          // 2. Top categories
          _TopCategoriesSection(
            totals: totals,
            categories: categories,
            period: period,
          ),

          // 3. Week trend
          _WeekTrendSection(period: period),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HeroNetCard — brand gradient hero (same pattern as BudgetHeroCard)
// ---------------------------------------------------------------------------

class _HeroNetCard extends StatelessWidget {
  const _HeroNetCard({required this.totals, required this.period});

  final MonthTotals totals;
  final SelectedPeriod period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final gradientStart =
        isDark ? _heroGradientStartDark : _heroGradientStartLight;
    final gradientEnd = isDark ? _heroGradientEndDark : _heroGradientEndLight;

    final net = totals.income - totals.expense;
    final isNegative = net < 0;

    final now = DateTime.now();
    final isCurrentMonth = period.year == now.year && period.month == now.month;
    final daysInMonth = DateTime(period.year, period.month + 1, 0).day;
    final daysLeft =
        isCurrentMonth ? (daysInMonth - now.day + 1).clamp(0, daysInMonth) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Semantics(
        label: '${l10n.transactionsSummaryHeroLabel}. '
            '${CurrencyFormatter.format(net.abs())}. '
            '${daysLeft > 0 ? l10n.transactionsSummaryHeroDaysLeft(daysLeft) : ""}.',
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
                    l10n.transactionsSummaryHeroLabel,
                    style: AppTypography.caption2.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (daysLeft > 0)
                    Text(
                      l10n.transactionsSummaryHeroDaysLeft(daysLeft),
                      style: AppTypography.caption1.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Large net amount
              Text(
                CurrencyFormatter.format(net.abs()),
                style: AppTypography.moneyLarge.copyWith(
                  color: isNegative ? const Color(0xFFFFCDD2) : Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Footer: income + expense labels
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactionsSummaryHeroIncomeFooter(
                        CurrencyFormatter.format(totals.income),
                      ),
                      style: AppTypography.caption1.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Text(
                    l10n.transactionsSummaryHeroExpenseFooter(
                      CurrencyFormatter.format(totals.expense),
                    ),
                    style: AppTypography.caption1.copyWith(
                      color: Colors.white70,
                    ),
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
// _TopCategoriesSection
// ---------------------------------------------------------------------------

class _TopCategoriesSection extends ConsumerWidget {
  const _TopCategoriesSection({
    required this.totals,
    required this.categories,
    required this.period,
  });

  final MonthTotals totals;
  final List<dynamic> categories;
  final SelectedPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;

    // Compute per-category expense totals from monthly transactions stream.
    final txsAsync = ref.watch(monthlyTransactionsProvider);

    return txsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (txs) {
        // Accumulate expense by category id (cents to avoid float drift).
        final Map<String, int> catCents = {};
        for (final tx in txs) {
          if (tx.transactionType != TransactionType.expense || tx.isExcluded) {
            continue;
          }
          final key = tx.categoryId ?? 'uncategorized';
          catCents[key] = (catCents[key] ?? 0) + (tx.amount * 100).round();
        }

        if (catCents.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by spend desc, take top 5.
        final sorted = catCents.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section header
            _SectionHeader(title: l10n.transactionsSummaryTopCategoriesTitle),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.bgSecondary
                      : AppColors.bgElevatedLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark ? AppColors.border : AppColors.borderLight,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Column(
                    children: [
                      for (var i = 0; i < top5.length; i++) ...[
                        _CategoryRow(
                          categoryId: top5[i].key,
                          amountCents: top5[i].value,
                          totalExpenseCents:
                              catCents.values.fold<int>(0, (s, v) => s + v),
                          categories: categories,
                          isDark: isDark,
                        ),
                        if (i < top5.length - 1)
                          Divider(
                            height: 1,
                            color: context.dividerColor,
                            indent: AppSpacing.lg,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (catCents.length == 1)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  l10n.transactionsSummarySingleCategoryHint(1),
                  style: AppTypography.caption1.copyWith(
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.amountCents,
    required this.totalExpenseCents,
    required this.categories,
    required this.isDark,
  });

  final String categoryId;
  final int amountCents;
  final int totalExpenseCents;
  final List<dynamic> categories;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final amount = amountCents / 100.0;
    final pct = totalExpenseCents > 0
        ? (amountCents / totalExpenseCents * 100).round()
        : 0;

    // Resolve category name and emoji from list.
    String? name;
    String? emoji;
    for (final cat in categories) {
      if (cat.id == categoryId) {
        name = cat.name as String?;
        emoji = cat.iconEmoji as String?;
        break;
      }
    }

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.bgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  emoji ?? '💰',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Name + bar
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? categoryId,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.bgTertiary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (pct / 100.0).clamp(0.0, 1.0),
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: context.expenseColor,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Amount + pct
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(amount),
                  style: AppTypography.moneySmall.copyWith(
                    color: context.expenseColor,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$pct%',
                  style: AppTypography.caption1.copyWith(
                    color: context.textSecondary,
                  ),
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
// _WeekTrendSection
// ---------------------------------------------------------------------------

class _WeekTrendSection extends ConsumerWidget {
  const _WeekTrendSection({required this.period});

  final SelectedPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final weeklyAsync = ref.watch(
      weeklyTotalsForMonthProvider(period.year, period.month),
    );

    return weeklyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (weekMap) {
        if (weekMap.isEmpty) return const SizedBox.shrink();

        // Sort weeks chronologically.
        final sortedWeeks = weekMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        // Find busiest week (max net magnitude: |income - expense|).
        final busiestEntry = sortedWeeks.reduce((best, e) {
          final eNet = (e.value.income - e.value.expense).abs();
          final bestNet = (best.value.income - best.value.expense).abs();
          return eNet > bestNet ? e : best;
        });
        // Compute max net magnitude across all weeks for bar scaling.
        final maxNet = sortedWeeks.fold(0.0, (max, e) {
          final net = (e.value.income - e.value.expense).abs();
          return net > max ? net : max;
        });

        // Format busiest week range.
        final weekStart = busiestEntry.key;
        final weekEnd = weekStart.add(const Duration(days: 6));
        final rangeFmt = DateFormat('MMM d');
        final range =
            '${rangeFmt.format(weekStart)} – ${rangeFmt.format(weekEnd)}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: l10n.transactionsSummaryWeekTrendTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.bgSecondary
                      : AppColors.bgElevatedLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark ? AppColors.border : AppColors.borderLight,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bar chart
                    SizedBox(
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: sortedWeeks.map((e) {
                          final isBusiest = e.key == busiestEntry.key;
                          final weekNet =
                              (e.value.income - e.value.expense).abs();
                          final ratio = maxNet > 0 ? weekNet / maxNet : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: (ratio.clamp(0.0, 1.0) * 60) + 4,
                                    decoration: BoxDecoration(
                                      color: isBusiest
                                          ? AppColors.brandPrimary
                                          : AppColors.brandPrimary
                                              .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Labels: W1, W2 ...
                    Row(
                      children: List.generate(sortedWeeks.length, (i) {
                        return Expanded(
                          child: Text(
                            'W${i + 1}',
                            style: AppTypography.caption2.copyWith(
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Footer: busiest week label
                    Text(
                      l10n.transactionsSummaryWeekTrendBusiest(range),
                      style: AppTypography.caption1.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    // Net for busiest week (income - expense).
                    Builder(
                      builder: (context) {
                        final weekNet = busiestEntry.value.income -
                            busiestEntry.value.expense;
                        return Text(
                          l10n.transactionsSummaryWeekTrendNet(
                            CurrencyFormatter.format(weekNet.abs()),
                          ),
                          style: AppTypography.caption1.copyWith(
                            color: weekNet >= 0
                                ? context.incomeColor
                                : context.expenseColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

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
      child: Text(
        title,
        style: AppTypography.caption2.copyWith(
          color:
              isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
