// Transactions tab screen — daily grouped list with month navigation — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/month_navigator.dart';
import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/entities/transaction.dart';
import '../providers/transactions_provider.dart';
import '../widgets/day_group_header.dart';
import '../widgets/summary_bar.dart';
import '../widgets/transaction_list_item.dart';

/// The main Transactions tab.
/// Shows a month navigator, income/expense summary bar, and a daily-grouped list.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final txnsAsync = ref.watch(transactionsByMonthProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            MonthNavigator(
              selectedMonth: selectedMonth,
              onPrevious: () =>
                  ref.read(selectedMonthProvider.notifier).previous(),
              onNext: () => ref.read(selectedMonthProvider.notifier).next(),
            ),
            txnsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (txns) {
                final income = txns
                    .where((t) => t.type == 'income')
                    .fold(0.0, (s, t) => s + t.amount);
                final expense = txns
                    .where((t) => t.type == 'expense')
                    .fold(0.0, (s, t) => s + t.amount);
                return SummaryBar(
                  income: income,
                  expense: expense,
                  currencySymbol: '€',
                );
              },
            ),
            Expanded(
              child: txnsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.brandPrimary),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Failed to load transactions.',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                data: (txns) => _TransactionList(transactions: txns),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add transaction — coming soon')),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

/// Groups transactions by day and renders headers + rows.
class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No transactions this month',
              style:
                  AppTypography.title3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first transaction.',
              style: AppTypography.subhead
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Group by date (year-month-day key).
    final grouped = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final key = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Build a flat list of header + item entries.
    final items = <_ListItem>[];
    for (final day in sortedDays) {
      final dayTxns = grouped[day]!;
      final dailyTotal = dayTxns.fold(0.0, (s, t) {
        if (t.type == 'income') return s + t.amount;
        if (t.type == 'expense') return s - t.amount;
        return s;
      });
      items.add(_HeaderItem(date: day, dailyTotal: dailyTotal));
      for (final t in dayTxns) {
        items.add(_TxItem(transaction: t));
      }
    }

    return StreamBuilder(
      stream: ref.read(accountRepositoryProvider).watchAccounts(),
      builder: (context, accountSnap) {
        final accounts = accountSnap.data ?? [];
        return StreamBuilder(
          stream: ref.read(categoryRepositoryProvider).watchAll(),
          builder: (context, catSnap) {
            final cats = catSnap.data ?? [];

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is _HeaderItem) {
                  return DayGroupHeader(
                    date: item.date,
                    dailyTotal: item.dailyTotal.abs(),
                    currencySymbol: '€',
                  );
                }
                final tx = (item as _TxItem).transaction;
                final account =
                    accounts.where((a) => a.id == tx.accountId).firstOrNull;
                final category =
                    cats.where((c) => c.id == tx.categoryId).firstOrNull;

                return Column(
                  children: [
                    TransactionListItem(
                      transaction: tx,
                      categoryEmoji: category?.iconEmoji,
                      categoryName: category?.name ?? 'Uncategorized',
                      categoryColor: category?.colorHex != null
                          ? _parseColor(category!.colorHex!)
                          : null,
                      accountName: account?.name ?? '',
                      onTap: () {},
                      onDelete: () {
                        ref
                            .read(
                              transactionWriteNotifierProvider.notifier,
                            )
                            .deleteTransaction(tx.id);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Sealed list item union types
// ---------------------------------------------------------------------------

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  _HeaderItem({required this.date, required this.dailyTotal});

  final DateTime date;
  final double dailyTotal;
}

class _TxItem extends _ListItem {
  _TxItem({required this.transaction});

  final Transaction transaction;
}
