// SummaryView — period financial snapshot with stat, accounts, budget, and
// category breakdown cards — features/transactions US-024 / SPEC-012.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/transactions_provider.dart';

/// Horizontally swipeable summary cards for the selected period (BUG-009).
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
          AppLocalizations.of(context)!.errorLoadTitle,
          style: AppTypography.headline.copyWith(color: context.textPrimary),
        ),
      ),
      data: (totals) => _SummaryContent(totals: totals),
    );
  }
}

class _SummaryContent extends StatefulWidget {
  const _SummaryContent({required this.totals});

  final MonthTotals totals;

  @override
  State<_SummaryContent> createState() => _SummaryContentState();
}

class _SummaryContentState extends State<_SummaryContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatSummaryCard(totals: widget.totals),
      _AccountsCard(totalExpense: widget.totals.expense),
      const _BudgetCard(),
      const _ExportCard(),
    ];

    return Column(
      children: [
        // Horizontal PageView of cards (BUG-009).
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: cards[index],
              ),
            ),
          ),
        ),
        // Page indicator dots.
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brandPrimary
                      : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              );
            }),
          ),
        ),
      ],
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

  Color _savingsColor(BuildContext context) {
    if (totals.income == 0) return context.textSecondary;
    final rate = totals.income - totals.expense;
    return rate >= 0 ? AppColors.income : context.expenseColor;
  }

  /// Net amount color: green for positive, coral for negative.
  Color _netColor(BuildContext context) =>
      totals.net >= 0 ? AppColors.income : context.expenseColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: 'Summary. '
          'Income: ${CurrencyFormatter.format(totals.income)}, '
          'Expense: ${CurrencyFormatter.format(totals.expense)}, '
          'Total: ${CurrencyFormatter.formatSigned(totals.net)}.',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Three-column row: Income | Expense | Total (BUG-008)
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: l10n.income,
                    value: CurrencyFormatter.format(totals.income),
                    valueColor: AppColors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MiniStatCard(
                    label: l10n.expenseLabel,
                    value: CurrencyFormatter.format(totals.expense),
                    valueColor: context.expenseColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MiniStatCard(
                    label: l10n.totalLabel,
                    value: CurrencyFormatter.formatSigned(totals.net),
                    valueColor: _netColor(context),
                  ),
                ),
              ],
            ),
            // Savings rate row — only shown when income > 0.
            if (totals.income > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.bgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.savingsRateLabel,
                      style: AppTypography.caption1.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    Text(
                      _savingsRate,
                      style: AppTypography.moneySmall.copyWith(
                        color: _savingsColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        color: context.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: context.textSecondary,
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
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            // Card header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: context.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context)!.accountsCardTitle,
                    style: AppTypography.headline.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: context.textTertiary,
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
                  color: context.bgTertiary,
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
                        color: context.textSecondary,
                      ),
                    ),
                    if (totalExpense > 0)
                      Text(
                        CurrencyFormatter.format(totalExpense),
                        style: AppTypography.moneyMedium.copyWith(
                          color: context.expenseColor,
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
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: context.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.budgetCardTitle,
                  style: AppTypography.headline.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  height: 24,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.bgTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.today,
                      style: AppTypography.caption1.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right,
                  color: context.textTertiary,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Budget not configured message
            Text(
              AppLocalizations.of(context)!.budgetNotConfigured,
              style: AppTypography.subhead.copyWith(
                color: context.textSecondary,
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
                        color: context.bgTertiary,
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
                        color: context.textTertiary,
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
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(budget),
                  style: AppTypography.moneySmall.copyWith(
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
            color: context.bgSecondary,
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
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: context.textTertiary,
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
          style: AppTypography.subhead.copyWith(color: context.textPrimary),
        ),
        backgroundColor: context.bgTertiary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
