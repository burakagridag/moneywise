// DailyView — transaction list grouped by date — features/transactions US-021.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: context.isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
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
        ),
      ),
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

  /// Returns badge bg color based on weekday — tonal, context-aware.
  Color _badgeBgColor(BuildContext context, int weekday) {
    if (weekday == DateTime.saturday) {
      return context.isDark ? const Color(0xFF2A2E3A) : const Color(0xFFEEF0F5);
    } else if (weekday == DateTime.sunday) {
      return context.isDark ? const Color(0xFF2E2A35) : const Color(0xFFF5EEF5);
    }
    return context.bgTertiary;
  }

  Color _badgeTextColor(BuildContext context, int weekday) =>
      context.textSecondary;

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
        color: context.bgPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Day number — today uses brandPrimary bold text; no circle decoration.
            if (_isToday)
              SizedBox(
                width: 40,
                child: Text(
                  '${day.day}',
                  style: AppTypography.title2.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              SizedBox(
                width: 40,
                child: Text(
                  '${day.day}',
                  style: AppTypography.title1.copyWith(
                    color: context.textPrimary,
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
                color: _badgeBgColor(context, weekday),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                dayLabel,
                style: AppTypography.caption1.copyWith(
                  color: _badgeTextColor(context, weekday),
                ),
              ),
            ),
            const Spacer(),
            // Expense amount — shown first (left)
            Opacity(
              opacity: expense > 0 ? 1.0 : 0.5,
              child: Text(
                CurrencyFormatter.format(expense),
                style: AppTypography.moneyTiny.copyWith(
                  color: context.expenseColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Income amount — shown second (right)
            Opacity(
              opacity: income > 0 ? 1.0 : 0.5,
              child: Text(
                CurrencyFormatter.format(income),
                style: AppTypography.moneyTiny.copyWith(
                  color: AppColors.income,
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
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: context.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.dailyEmptyTitle,
              style: AppTypography.title3.copyWith(
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.dailyEmptySubtitle,
              style: AppTypography.subhead.copyWith(
                color: context.textSecondary,
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
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
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
