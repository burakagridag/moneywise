// Data access object for financial transactions and account balance — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/accounts_table.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

/// Provides CRUD and reactive query methods for Transactions.
/// Balance is computed on read: initialBalance + SUM(income) - SUM(expense).
@DriftAccessor(tables: [Transactions, Accounts])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ---------------------------------------------------------------------------
  // Queries
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

  // ---------------------------------------------------------------------------
  // Balance computation
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
