// SummaryView — period financial snapshot with stat, accounts, budget, and
// category breakdown cards — features/transactions US-024 / SPEC-012.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/transactions_provider.dart';

/// Scrollable column of summary cards for the selected period.
class SummaryView extends ConsumerWidget {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTotals = ref.watch(monthlyTotalsProvider);

    return asyncTotals.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (_, __) => Center(
        child: Text(
          'Could not load data',
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
      ),
      data: (totals) => _SummaryContent(totals: totals),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          _StatSummaryCard(totals: totals),
          const SizedBox(height: AppSpacing.md),
          _AccountsCard(totalExpense: totals.expense),
          const SizedBox(height: AppSpacing.md),
          const _BudgetCard(),
          const SizedBox(height: AppSpacing.md),
          const _CategoryBreakdownCard(),
          const SizedBox(height: AppSpacing.md),
          const _ExportCard(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// StatSummaryCard
// ---------------------------------------------------------------------------

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({required this.totals});

  final MonthTotals totals;

  String get _savingsRate {
    if (totals.income == 0) return '—';
    final rate = (totals.income - totals.expense) / totals.income * 100;
    return '${rate.toStringAsFixed(1)}%';
  }

  Color get _savingsColor {
    if (totals.income == 0) return AppColors.textSecondary;
    final rate = totals.income - totals.expense;
    return rate >= 0 ? AppColors.income : AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Summary. '
          'Income: ${CurrencyFormatter.format(totals.income)}, '
          'Expense: ${CurrencyFormatter.format(totals.expense)}, '
          'Savings rate: $_savingsRate.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            // Left column: income + expense mini cards
            Expanded(
              child: Column(
                children: [
                  _MiniStatCard(
                    label: 'Income',
                    value: CurrencyFormatter.format(totals.income),
                    valueColor: AppColors.income,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MiniStatCard(
                    label: 'Expense',
                    value: CurrencyFormatter.format(totals.expense),
                    valueColor: AppColors.expense,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Right column: savings rate
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.savingsRateLabel,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _savingsRate,
                      style: AppTypography.title2.copyWith(
                        color: _savingsColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.moneyMedium.copyWith(color: valueColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AccountsCard
// ---------------------------------------------------------------------------

class _AccountsCard extends StatelessWidget {
  const _AccountsCard({required this.totalExpense});

  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Accounts card. '
          'Total expense: ${CurrencyFormatter.format(totalExpense)}. '
          'Tap to go to accounts.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            // Card header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context)!.accountsCardTitle,
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalExpense == 0
                          ? AppLocalizations.of(context)!.noExpensesThisMonth
                          : AppLocalizations.of(context)!.expenseLabel,
                      style: AppTypography.subhead.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (totalExpense > 0)
                      Text(
                        CurrencyFormatter.format(totalExpense),
                        style: AppTypography.moneyMedium.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BudgetCard
// ---------------------------------------------------------------------------

class _BudgetCard extends StatelessWidget {
  const _BudgetCard();

  @override
  Widget build(BuildContext context) {
    // Budget feature is Sprint 5. Render zero/stub state.
    const budget = 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final todayRatio = now.day / daysInMonth;

    return Semantics(
      container: true,
      label: 'Budget card. Budget not configured. Tap to set budget.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.bar_chart,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.budgetCardTitle,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.today,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Budget not configured message
            Text(
              AppLocalizations.of(context)!.budgetNotConfigured,
              style: AppTypography.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Progress bar with Today indicator
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    // Today marker positioned relative to available width
                    Positioned(
                      left: todayRatio.clamp(0.0, 1.0) * constraints.maxWidth,
                      top: -2,
                      child: Container(
                        width: 2,
                        height: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.budgetCardTitle,
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(budget),
                  style: AppTypography.moneySmall.copyWith(
                    color: AppColors.textSecondary,
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
// CategoryBreakdownCard
// ---------------------------------------------------------------------------

class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sprint 4: no category aggregation yet — show empty state.
    // Full implementation in Sprint 5 (stats provider).
    // Top-5 category colors per SPEC-012 are:
    // brandPrimary, income, warning, success, categoryPurple.
    return Semantics(
      container: true,
      label: 'Spending breakdown. No expense data yet.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.pie_chart_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.categoryBreakdownTitle,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                AppLocalizations.of(context)!.noExpensesThisMonth,
                style: AppTypography.subhead.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ExportCard
// ---------------------------------------------------------------------------

class _ExportCard extends StatelessWidget {
  const _ExportCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Export to Excel.',
      button: true,
      child: InkWell(
        onTap: () => _showComingSoonSnackbar(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.file_present_outlined,
                color: AppColors.brandPrimary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.exportToExcelTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.exportComingSoon,
          style: AppTypography.subhead.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.bgTertiary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
