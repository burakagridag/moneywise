// TransactionsListTab — "Liste" tab of the redesigned 3-tab Transactions screen.
// Shows transactions grouped by day with ADR-015 card decoration — EPIC8D-01.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

/// Liste tab — transaction list grouped by day, with ADR-015 card decoration.
class TransactionsListTab extends ConsumerWidget {
  const TransactionsListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxs = ref.watch(filteredTransactionsProvider);

    return asyncTxs.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (_, __) => Center(
        child: Text(
          AppLocalizations.of(context)!.errorLoadTitle,
          style: AppTypography.subhead.copyWith(color: context.textSecondary),
        ),
      ),
      data: (txs) {
        // Empty state is handled by TransactionsView — see US-EPIC8D-01 AC.
        return _TransactionListGrouped(transactions: txs);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grouped transaction list
// ---------------------------------------------------------------------------

class _TransactionListGrouped extends StatelessWidget {
  const _TransactionListGrouped({required this.transactions});

  final List<TransactionWithDetails> transactions;

  Map<DateTime, List<TransactionWithDetails>> _groupByDay(
    List<TransactionWithDetails> txs,
  ) {
    final map = <DateTime, List<TransactionWithDetails>>{};
    for (final item in txs) {
      final date = item.transaction.date;
      final key = DateTime(date.year, date.month, date.day);
      (map[key] ??= []).add(item);
    }
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
              return _DayCard(day: day, transactions: dayTxs);
            },
            childCount: days.length,
          ),
        ),
        // Bottom padding for FAB.
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day card — ADR-015 decoration
// ---------------------------------------------------------------------------

class _DayCard extends ConsumerWidget {
  const _DayCard({required this.day, required this.transactions});

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
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
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
// Day header row
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

  Color _badgeBgColor(BuildContext context, int weekday) {
    if (weekday == DateTime.saturday) {
      return context.isDark ? const Color(0xFF2A2E3A) : const Color(0xFFEEF0F5);
    } else if (weekday == DateTime.sunday) {
      return context.isDark ? const Color(0xFF2E2A35) : const Color(0xFFF5EEF5);
    }
    return context.bgTertiary;
  }

  @override
  Widget build(BuildContext context) {
    final weekday = day.weekday;
    final dayLabel = DateFormat('EEE').format(day);
    final semanticsLabel = '${DateFormat('d MMMM, EEEE').format(day)}. '
        'Income: ${CurrencyFormatter.format(income)}, '
        'Expense: ${CurrencyFormatter.format(expense)}';

    return Semantics(
      label: semanticsLabel,
      child: Container(
        height: AppHeights.listItem,
        color: _isToday
            ? AppColors.brandPrimary.withValues(alpha: 0.06)
            : context.bgPrimary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Day number
            SizedBox(
              width: 40,
              child: Text(
                '${day.day}',
                style: _isToday
                    ? AppTypography.title2.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      )
                    : AppTypography.title1.copyWith(
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
                  color: context.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            // Amounts
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (expense > 0)
                  Text(
                    '− ${CurrencyFormatter.format(expense)}',
                    style: AppTypography.moneySmall.copyWith(
                      color: context.expenseColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (income > 0)
                  Text(
                    '+ ${CurrencyFormatter.format(income)}',
                    style: AppTypography.moneyTiny.copyWith(
                      color: context.incomeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
