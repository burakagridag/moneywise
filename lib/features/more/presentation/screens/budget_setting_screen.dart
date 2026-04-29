// BudgetSettingScreen — per-category budget configuration — more feature (US-029).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/month_navigator.dart';
import '../../../../domain/entities/category.dart';
import '../../../budget/domain/budget_entity.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../widgets/budget_edit_modal.dart';

/// Screen reachable at `/more/budget-setting`. Lists all expense (or income)
/// categories with their configured budgets. Tapping a row opens
/// [BudgetEditModal].
class BudgetSettingScreen extends ConsumerWidget {
  const BudgetSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = ref.watch(selectedStatsMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          l10n.budgetSettingTitle,
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          MonthNavigator(
            selectedMonth: selectedMonth,
            onPrevious: () =>
                ref.read(selectedStatsMonthProvider.notifier).previous(),
            onNext: () => ref.read(selectedStatsMonthProvider.notifier).next(),
          ),
          Expanded(
            child: _BudgetSettingBody(selectedMonth: selectedMonth),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _BudgetSettingBody extends ConsumerWidget {
  const _BudgetSettingBody({required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(statsCategoryListProvider);
    final budgetsAsync = ref.watch(budgetsForMonthProvider(selectedMonth));

    return catsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(statsCategoryListProvider),
      ),
      data: (cats) {
        final expenseCats = cats
            .where((c) => c.type == 'expense' && !c.isDeleted)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return budgetsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary),
          ),
          error: (_, __) => _ErrorState(
            onRetry: () =>
                ref.invalidate(budgetsForMonthProvider(selectedMonth)),
          ),
          data: (budgets) {
            return _BudgetList(
              categories: expenseCats,
              budgets: budgets,
              selectedMonth: selectedMonth,
            );
          },
        );
      },
    );
  }
}

class _BudgetList extends StatelessWidget {
  const _BudgetList({
    required this.categories,
    required this.budgets,
    required this.selectedMonth,
  });

  final List<Category> categories;
  final List<BudgetWithSpending> budgets;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final totalBudget = budgets.fold<double>(0.0, (s, b) => s + b.effective);

    // Find the budget entry for a given categoryId.
    BudgetWithSpending? budgetFor(String catId) {
      try {
        return budgets.firstWhere((b) => b.budget.categoryId == catId);
      } catch (_) {
        return null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      color: AppColors.bgSecondary,
      child: ListView.separated(
        itemCount: categories.length + 1, // +1 for TOTAL row
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            // TOTAL row
            return _TotalRow(
              totalBudget: totalBudget,
              selectedMonth: selectedMonth,
              budgets: budgets,
            );
          }
          final cat = categories[index - 1];
          final bws = budgetFor(cat.id);
          return _CategorySettingRow(
            category: cat,
            budgetWithSpending: bws,
            selectedMonth: selectedMonth,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TotalRow
// ---------------------------------------------------------------------------

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.totalBudget,
    required this.selectedMonth,
    required this.budgets,
  });

  final double totalBudget;
  final DateTime selectedMonth;
  final List<BudgetWithSpending> budgets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // TOTAL is a derived value (sum of per-category budgets) — read-only, not stored in DB.
    return Semantics(
      label: 'Total budget. ${CurrencyFormatter.format(totalBudget)}.',
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetSettingTotal,
                  style: AppTypography.headline
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              Text(
                CurrencyFormatter.format(totalBudget),
                style: AppTypography.moneySmall
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CategorySettingRow
// ---------------------------------------------------------------------------

class _CategorySettingRow extends StatelessWidget {
  const _CategorySettingRow({
    required this.category,
    required this.budgetWithSpending,
    required this.selectedMonth,
  });

  final Category category;
  final BudgetWithSpending? budgetWithSpending;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context) {
    final hasBudget =
        budgetWithSpending != null && budgetWithSpending!.budget.amount > 0;
    final amountText = hasBudget
        ? CurrencyFormatter.format(budgetWithSpending!.budget.amount)
        : CurrencyFormatter.format(0);

    return Semantics(
      label: '${category.iconEmoji ?? ''} ${category.name}. '
          'Budget: ${hasBudget ? amountText : "not set"}. Tap to edit.',
      child: InkWell(
        onTap: () => showBudgetEditModal(
          context: context,
          category: category,
          selectedMonth: selectedMonth,
          existingBudgetId: budgetWithSpending?.budget.id,
          existingAmount: budgetWithSpending?.budget.amount,
        ),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                if (category.iconEmoji != null)
                  Text(
                    category.iconEmoji!,
                    style: const TextStyle(fontSize: 22),
                  )
                else
                  const SizedBox(width: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  amountText,
                  style: AppTypography.moneySmall.copyWith(
                    color: hasBudget
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.errorLoadTitle,
            style:
                AppTypography.headline.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retryButton,
              style:
                  AppTypography.subhead.copyWith(color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
