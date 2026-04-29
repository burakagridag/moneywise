// Transactions tab screen — daily grouped list with month navigation — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/month_navigator.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
                // TODO(sprint-4): use user base currency setting
                final currencySymbol =
                    txns.isNotEmpty ? txns.first.currencyCode : 'EUR';
                final income = txns
                    .where((t) => t.type == 'income' && !t.isExcluded)
                    .fold(0.0, (s, t) => s + t.amount);
                final expense = txns
                    .where((t) => t.type == 'expense' && !t.isExcluded)
                    .fold(0.0, (s, t) => s + t.amount);
                return SummaryBar(
                  income: income,
                  expense: expense,
                  currencySymbol: currencySymbol,
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
                    l10n.failedToLoadTransactions,
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
        onPressed: () => context.push(Routes.transactionAddEdit),
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
    final l10n = AppLocalizations.of(context)!;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.noTransactionsThisMonth,
              style:
                  AppTypography.title3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.tapPlusToAddFirst,
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

    // TODO(sprint-4): use user base currency setting
    final currencySymbol =
        transactions.isNotEmpty ? transactions.first.currencyCode : 'EUR';

    final accountsAsync = ref.watch(transactionAccountListProvider);
    final catsAsync = ref.watch(transactionCategoryListProvider);

    final accounts = accountsAsync.asData?.value ?? [];
    final cats = catsAsync.asData?.value ?? [];

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _HeaderItem) {
          return DayGroupHeader(
            date: item.date,
            dailyTotal: item.dailyTotal.abs(),
            currencySymbol: currencySymbol,
          );
        }
        final tx = (item as _TxItem).transaction;
        final account = accounts.where((a) => a.id == tx.accountId).firstOrNull;
        final category = cats.where((c) => c.id == tx.categoryId).firstOrNull;

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
              // Use account currency; fall back to transaction currency code.
              currencySymbol: account?.currencyCode ?? tx.currencyCode,
              onTap: () => context.push(Routes.transactionAddEdit, extra: tx),
              onDelete: () async {
                try {
                  await ref
                      .read(transactionWriteNotifierProvider.notifier)
                      .deleteTransaction(tx.id);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.errorDeletingTransaction),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 1, color: AppColors.divider),
          ],
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
