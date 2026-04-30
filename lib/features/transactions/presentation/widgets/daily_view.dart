// DailyView — transaction list grouped by date — features/transactions US-021.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/search_filter_provider.dart';
import '../providers/transactions_provider.dart';
import 'transaction_row.dart';

/// Groups transactions by date (DESC) and renders date-header rows above
/// each day's transactions. Uses the enriched provider that resolves category
/// and account names via a LEFT JOIN (BUG-003).
class DailyView extends ConsumerWidget {
  const DailyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxs = ref.watch(filteredTransactionsProvider);

    return asyncTxs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (e, __) => _ErrorState(
          onRetry: () => ref.invalidate(filteredTransactionsProvider)),
      data: (txs) {
        if (txs.isEmpty) return const _EmptyState();
        return _TransactionList(transactions: txs);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction list
// ---------------------------------------------------------------------------

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<TransactionWithDetails> transactions;

  /// Groups transactions by calendar day (date only, no time).
  Map<DateTime, List<TransactionWithDetails>> _groupByDay(
    List<TransactionWithDetails> txs,
  ) {
    final map = <DateTime, List<TransactionWithDetails>>{};
    for (final item in txs) {
      final date = item.transaction.date;
      final key = DateTime(date.year, date.month, date.day);
      (map[key] ??= []).add(item);
    }
    // Sort days descending
    final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(transactions);
    final days = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final day = days[index];
              final dayTxs = grouped[day]!;
              return _DayGroup(day: day, transactions: dayTxs);
            },
            childCount: days.length,
          ),
        ),
        // Bottom padding for FAB + banner ad.
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}

class _DayGroup extends ConsumerWidget {
  const _DayGroup({required this.day, required this.transactions});

  final DateTime day;
  final List<TransactionWithDetails> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use integer cent accumulation to avoid float drift.
    int incomeCents = 0;
    int expenseCents = 0;
    for (final item in transactions) {
      final tx = item.transaction;
      if (tx.isExcluded) continue;
      if (tx.transactionType == TransactionType.income) {
        incomeCents += (tx.amount * 100).round();
      }
      if (tx.transactionType == TransactionType.expense) {
        expenseCents += (tx.amount * 100).round();
      }
    }
    final income = incomeCents / 100.0;
    final expense = expenseCents / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DayHeaderRow(day: day, income: income, expense: expense),
        ...transactions.map(
          (item) => TransactionRow(
            transaction: item.transaction,
            categoryName: item.categoryName,
            categoryEmoji: item.categoryEmoji,
            categoryColor: item.categoryColorHex,
            accountName: item.accountName,
            toAccountName: item.toAccountName,
            currencySymbol: AppConstants.defaultCurrencySymbol,
            onTap: () => context.push(
              Routes.transactionAddEdit,
              extra: item.transaction,
            ),
            onDelete: () => ref
                .read(transactionWriteNotifierProvider.notifier)
                .deleteTransaction(item.transaction.id),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DayHeaderRow
// ---------------------------------------------------------------------------

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({
    required this.day,
    required this.income,
    required this.expense,
  });

  final DateTime day;
  final double income;
  final double expense;

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  /// Returns badge bg color based on weekday (Mon=1, Sun=7 in ISO).
  Color _badgeBgColor(int weekday) {
    if (weekday == DateTime.saturday) {
      return AppColors.income.withAlpha(38);
    } else if (weekday == DateTime.sunday) {
      return AppColors.expense.withAlpha(38);
    }
    return AppColors.bgTertiary;
  }

  Color _badgeTextColor(int weekday) {
    if (weekday == DateTime.saturday) return AppColors.income;
    if (weekday == DateTime.sunday) return AppColors.expense;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final weekday = day.weekday;
    final dayLabel = DateFormat('EEE').format(day); // "Mon", "Sat"
    final semanticsLabel = '${DateFormat('d MMMM, EEEE').format(day)}. '
        'Income: ${CurrencyFormatter.format(income)}, '
        'Expense: ${CurrencyFormatter.format(expense)}';

    return Semantics(
      label: semanticsLabel,
      child: Container(
        height: AppHeights.listItem,
        color: AppColors.bgPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Day number (with today highlight) — 40px wide to fit two-digit dates.
            if (_isToday)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.bgTertiary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: AppTypography.title2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 40,
                child: Text(
                  '${day.day}',
                  style: AppTypography.title1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            // Day-of-week badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _badgeBgColor(weekday),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                dayLabel,
                style: AppTypography.caption1.copyWith(
                  color: _badgeTextColor(weekday),
                ),
              ),
            ),
            const Spacer(),
            // Income amount
            Text(
              CurrencyFormatter.format(income),
              style: AppTypography.moneySmall.copyWith(
                color: income > 0 ? AppColors.income : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Expense amount
            Text(
              CurrencyFormatter.format(expense),
              style: AppTypography.moneySmall.copyWith(
                color: expense > 0 ? AppColors.expense : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / Error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.dailyEmptyTitle,
              style: AppTypography.title3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.dailyEmptySubtitle,
              style: AppTypography.subhead.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.errorLoadTitle,
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retryButton,
              style: AppTypography.subhead.copyWith(
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
