// Data access object for financial transactions and account balance — data/local feature.
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database.dart';
import '../tables/accounts_table.dart';
import '../tables/categories_table.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

/// Aggregated daily income and expense totals.
class DayTotals {
  const DayTotals({
    required this.date,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final double income;
  final double expense;
}

/// Aggregated daily net amount (income − expense) for sparkline rendering.
class DailyNet {
  const DailyNet({required this.date, required this.netAmount});

  /// Calendar date with time zeroed (local midnight).
  final DateTime date;

  /// income - expense for this day, in base currency. May be negative.
  final double netAmount;
}

/// Aggregated monthly income and expense totals.
class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get net => income - expense;
}

/// A transaction row enriched with resolved category and account display names.
class TransactionWithNames {
  const TransactionWithNames({
    required this.transaction,
    this.categoryName,
    this.categoryEmoji,
    this.categoryColorHex,
    this.accountName,
    this.toAccountName,
  });

  final Transaction transaction;
  final String? categoryName;
  final String? categoryEmoji;
  final String? categoryColorHex;
  final String? accountName;
  final String? toAccountName;
}

/// Provides CRUD and reactive query methods for Transactions.
/// Balance is computed on read: initialBalance + SUM(income) - SUM(expense).
@DriftAccessor(tables: [Transactions, Accounts, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ---------------------------------------------------------------------------
  // Queries — Sprint 3 methods
  // ---------------------------------------------------------------------------

  /// Reactive stream of non-deleted transactions for a given [year] and [month],
  /// ordered newest-first.
  Stream<List<Transaction>> watchTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(transactions)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Reactive stream of all non-deleted transactions, ordered newest-first.
  Stream<List<Transaction>> watchAllTransactions() => (select(transactions)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();

  /// One-shot fetch of non-deleted transactions for [year]/[month].
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(transactions)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Queries — Sprint 4 additions
  // ---------------------------------------------------------------------------

  /// One-shot fetch of non-deleted transactions in [from, to) — to is exclusive.
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(transactions)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerThanValue(to),
          )
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Emits all non-deleted transactions in [from]..[to] ordered by date DESC,
  /// then createdAt DESC.
  Stream<List<Transaction>> watchTransactionsByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return (select(transactions)
          ..where(
            (t) => t.isDeleted.equals(false) & t.date.isBetweenValues(from, to),
          )
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// Emits all non-deleted transactions for a given calendar [date].
  Stream<List<Transaction>> watchTransactionsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return watchTransactionsByDateRange(start, end);
  }

  /// Emits aggregated income and expense for [year]/[month].
  /// Transfer transactions are excluded from both income and expense totals.
  /// Uses integer cent accumulation to avoid IEEE 754 float drift (BUG-010).
  Stream<MonthTotals> watchMonthlyTotals(int year, int month) {
    final from = DateTime(year, month);
    final to =
        DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
    return watchTransactionsByDateRange(from, to).map((txList) {
      int incomeCents = 0;
      int expenseCents = 0;
      for (final tx in txList) {
        if (tx.isExcluded) continue;
        if (tx.type == 'income') incomeCents += (tx.amount * 100).round();
        if (tx.type == 'expense') expenseCents += (tx.amount * 100).round();
      }
      return MonthTotals(
        income: incomeCents / 100.0,
        expense: expenseCents / 100.0,
      );
    });
  }

  /// Emits a map from day to [DayTotals] for the given [year]/[month].
  /// Used by CalendarView to show per-day amounts.
  /// Uses integer cent accumulation to avoid IEEE 754 float drift (BUG-010).
  Stream<List<DayTotals>> watchDailyTotals(int year, int month) {
    final from = DateTime(year, month);
    final to =
        DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
    return watchTransactionsByDateRange(from, to).map((txList) {
      final Map<String, ({DateTime date, int incomeCents, int expenseCents})>
          map = {};
      for (final tx in txList) {
        final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
        final iCents = tx.type == 'income' && !tx.isExcluded
            ? (tx.amount * 100).round()
            : 0;
        final eCents = tx.type == 'expense' && !tx.isExcluded
            ? (tx.amount * 100).round()
            : 0;
        final existing = map[key];
        if (existing == null) {
          map[key] = (
            date: DateTime(tx.date.year, tx.date.month, tx.date.day),
            incomeCents: iCents,
            expenseCents: eCents,
          );
        } else {
          map[key] = (
            date: existing.date,
            incomeCents: existing.incomeCents + iCents,
            expenseCents: existing.expenseCents + eCents,
          );
        }
      }
      return map.values
          .map(
            (e) => DayTotals(
              date: e.date,
              income: e.incomeCents / 100.0,
              expense: e.expenseCents / 100.0,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  /// Emits aggregated income and expense totals for every month in [year].
  /// Uses integer cent accumulation to avoid IEEE 754 float drift (BUG-010).
  Stream<Map<int, MonthTotals>> watchYearlyMonthlyTotals(int year) {
    final from = DateTime(year);
    final to = DateTime(year + 1).subtract(const Duration(microseconds: 1));
    return watchTransactionsByDateRange(from, to).map((txList) {
      final Map<int, ({int incomeCents, int expenseCents})> acc = {};
      for (var m = 1; m <= 12; m++) {
        acc[m] = (incomeCents: 0, expenseCents: 0);
      }
      for (final tx in txList) {
        if (tx.isExcluded) continue;
        final m = tx.date.month;
        final cur = acc[m]!;
        if (tx.type == 'income') {
          acc[m] = (
            incomeCents: cur.incomeCents + (tx.amount * 100).round(),
            expenseCents: cur.expenseCents,
          );
        } else if (tx.type == 'expense') {
          acc[m] = (
            incomeCents: cur.incomeCents,
            expenseCents: cur.expenseCents + (tx.amount * 100).round(),
          );
        }
      }
      return acc.map(
        (m, v) => MapEntry(
          m,
          MonthTotals(
            income: v.incomeCents / 100.0,
            expense: v.expenseCents / 100.0,
          ),
        ),
      );
    });
  }

  /// Emits all non-deleted transactions with resolved category and account
  /// names in [from]..[to] via LEFT OUTER JOINs. Used by DailyView to display
  /// human-readable category and account labels (BUG-003).
  Stream<List<TransactionWithNames>> watchTransactionsWithNamesByDateRange(
    DateTime from,
    DateTime to,
  ) {
    // Use aliases so the two Account joins don't conflict.
    final toAcc = alias(accounts, 'to_acc');

    final query = (select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      leftOuterJoin(
        accounts,
        accounts.id.equalsExp(transactions.accountId),
      ),
      leftOuterJoin(
        toAcc,
        toAcc.id.equalsExp(transactions.toAccountId),
      ),
    ]))
      ..where(
        transactions.isDeleted.equals(false) &
            transactions.date.isBetweenValues(from, to),
      )
      ..orderBy([
        OrderingTerm(
          expression: transactions.date,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(
          expression: transactions.createdAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final tx = row.readTable(transactions);
        final cat = row.readTableOrNull(categories);
        final acc = row.readTableOrNull(accounts);
        final toAccRow = row.readTableOrNull(toAcc);
        return TransactionWithNames(
          transaction: tx,
          categoryName: cat?.name,
          categoryEmoji: cat?.iconEmoji,
          categoryColorHex: cat?.colorHex,
          accountName: acc?.name,
          toAccountName: toAccRow?.name,
        );
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Sparkline — Sprint 8 (EPIC8A-06)
  // ---------------------------------------------------------------------------

  /// Emits a fixed-length list of [DailyNet] for the last [days] calendar days
  /// (default 30), ending on [referenceDate] (default today).
  ///
  /// Always emits exactly [days] entries; days with no qualifying transactions
  /// have [DailyNet.netAmount] == 0.0.
  ///
  /// Transfer transactions are excluded. [excludedAccountIds] allows the caller
  /// to omit accounts whose [includeInTotals] flag is false — keeping the DAO
  /// testable without account repository involvement.
  ///
  /// Integer cent accumulation avoids IEEE 754 drift (BUG-010).
  Stream<List<DailyNet>> watchDailyNetAmounts({
    DateTime? referenceDate,
    int days = 30,
    Set<String> excludedAccountIds = const {},
  }) {
    final today = referenceDate ?? DateTime.now();
    final windowStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    final windowEnd =
        DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    // Generate the full 30-day window (oldest first).
    final window = List.generate(days, (i) {
      final d = windowStart.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return watchTransactionsByDateRange(windowStart, windowEnd).map((txList) {
      // Accumulate per-day net in integer cents to avoid float drift.
      final Map<String, int> centsByDay = {};

      for (final tx in txList) {
        if (tx.isExcluded) continue;
        if (tx.type == 'transfer') continue;
        if (excludedAccountIds.contains(tx.accountId)) continue;

        final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
        final delta = tx.type == 'income'
            ? (tx.amount * tx.exchangeRate * 100).round()
            : -(tx.amount * tx.exchangeRate * 100).round();
        centsByDay[key] = (centsByDay[key] ?? 0) + delta;
      }

      return window.map((d) {
        final key = '${d.year}-${d.month}-${d.day}';
        return DailyNet(date: d, netAmount: (centsByDay[key] ?? 0) / 100.0);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Write paths
  // ---------------------------------------------------------------------------

  /// Inserts a new transaction row.
  Future<void> insertTransaction(TransactionsCompanion row) =>
      into(transactions).insert(row);

  /// Replaces mutable fields on an existing transaction.
  Future<void> updateTransaction(TransactionsCompanion row) =>
      (update(transactions)..where((t) => t.id.equals(row.id.value)))
          .write(row);

  /// Marks a transaction as deleted without removing the row.
  Future<void> softDeleteTransaction(String id) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Permanently deletes a transaction by [id]. For test use only.
  @visibleForTesting
  Future<int> deleteTransactionHard(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Balance computation — Sprint 3
  // ---------------------------------------------------------------------------

  /// Reactive stream of current balance for [accountId].
  ///
  /// balance = initialBalance
  ///         + SUM(income where !isExcluded && !isDeleted)
  ///         - SUM(expense where !isExcluded && !isDeleted)
  ///         + SUM(transfer-in where !isExcluded && !isDeleted)
  ///         - SUM(transfer-out where !isExcluded && !isDeleted)
  Stream<double> watchAccountBalance(String accountId) {
    // Account stream for initialBalance
    final accountStream =
        (select(accounts)..where((a) => a.id.equals(accountId))).watchSingle();

    return accountStream.asyncExpand((account) {
      final deltaQuery = customSelect(
        '''
        SELECT
          COALESCE(SUM(
            CASE
              WHEN type = 'income' AND account_id = :id THEN amount
              WHEN type = 'expense' AND account_id = :id THEN -amount
              WHEN type = 'transfer' AND account_id = :id THEN -amount
              WHEN type = 'transfer' AND to_account_id = :id THEN amount
              ELSE 0
            END
          ), 0) AS delta
        FROM transactions
        WHERE (account_id = :id OR to_account_id = :id)
          AND is_excluded = 0
          AND is_deleted = 0
        ''',
        variables: [Variable.withString(accountId)],
        readsFrom: {transactions},
      ).watchSingle();

      return deltaQuery.map(
        (row) => account.initialBalance + row.read<double>('delta'),
      );
    });
  }
}
