// Repository providing transaction operations to the domain layer — data/repositories feature.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../local/daos/transaction_dao.dart';
import '../local/database.dart';

// Import domain entity with alias to avoid name collision with Drift-generated Transaction class.
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/transaction_with_details.dart';

export '../local/daos/transaction_dao.dart'
    show DayTotals, MonthTotals, TransactionWithNames;

part 'transaction_repository.g.dart';

/// Riverpod provider that wires [TransactionRepository] to [AppDatabase].
@riverpod
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionRepository(db.transactionDao);
}

/// Mediates between the data layer (Drift DAOs) and the domain layer.
/// All public methods work exclusively with domain entities.
class TransactionRepository {
  TransactionRepository(this._dao);

  final TransactionDao _dao;

  // ---------------------------------------------------------------------------
  // Queries — Sprint 3
  // ---------------------------------------------------------------------------

  /// Reactive stream of non-deleted transactions for [year]/[month].
  Stream<List<domain.Transaction>> watchByMonth(int year, int month) =>
      _dao.watchTransactionsByMonth(year, month).map(
            (rows) => rows.map(_mapToDomain).toList(),
          );

  /// Reactive stream of all non-deleted transactions.
  Stream<List<domain.Transaction>> watchAll() =>
      _dao.watchAllTransactions().map(
            (rows) => rows.map(_mapToDomain).toList(),
          );

  /// Reactive stream of all non-deleted transactions enriched with category and
  /// account names — used by the home tab's recent-transactions list so that the
  /// 3-step display-name fallback (description → category name → type string)
  /// has access to the resolved category name without a second round-trip.
  Stream<List<TransactionWithDetails>> watchAllWithDetails() =>
      _dao.watchAllTransactionsWithDetails().map(
            (rows) => rows.map(_mapToDetailEntity).toList(),
          );

  /// One-shot fetch of transactions for [year]/[month].
  Future<List<domain.Transaction>> getByMonth(int year, int month) async {
    final rows = await _dao.getTransactionsByMonth(year, month);
    return rows.map(_mapToDomain).toList();
  }

  /// One-shot fetch of non-deleted transactions within [from]..[to] (inclusive).
  Future<List<domain.Transaction>> getByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _dao.getTransactionsByDateRange(from, to);
    return rows.map(_mapToDomain).toList();
  }

  /// Reactive stream of current account balance.
  Stream<double> watchAccountBalance(String accountId) =>
      _dao.watchAccountBalance(accountId);

  // ---------------------------------------------------------------------------
  // Queries — Sprint 4 additions
  // ---------------------------------------------------------------------------

  /// Reactive stream of non-deleted transactions for [year]/[month] using
  /// date-range queries. Alias for Sprint 4 providers.
  Stream<List<domain.Transaction>> watchTransactionsForMonth(
    int year,
    int month,
  ) {
    final from = DateTime(year, month);
    final to =
        DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
    return _dao
        .watchTransactionsByDateRange(from, to)
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  /// Reactive stream of non-deleted transactions for a specific [date].
  Stream<List<domain.Transaction>> watchTransactionsForDay(DateTime date) {
    return _dao
        .watchTransactionsByDate(date)
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  /// Emits transactions enriched with resolved category and account names for
  /// the given month. Used by DailyView (BUG-003).
  Stream<List<TransactionWithDetails>> watchTransactionsWithDetailsForMonth(
    int year,
    int month,
  ) {
    final from = DateTime(year, month);
    final to =
        DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
    return _dao
        .watchTransactionsWithNamesByDateRange(from, to)
        .map((rows) => rows.map(_mapToDetailEntity).toList());
  }

  Stream<MonthTotals> watchMonthlyTotals(int year, int month) =>
      _dao.watchMonthlyTotals(year, month);

  Stream<List<DayTotals>> watchDailyTotals(int year, int month) =>
      _dao.watchDailyTotals(year, month);

  Stream<Map<int, MonthTotals>> watchYearlyMonthlyTotals(int year) =>
      _dao.watchYearlyMonthlyTotals(year);

  // ---------------------------------------------------------------------------
  // Write paths
  // ---------------------------------------------------------------------------

  /// Persists a new transaction derived from the domain entity.
  Future<void> addTransaction(domain.Transaction t) =>
      _dao.insertTransaction(_toCompanion(t));

  /// Updates an existing transaction.
  Future<void> updateTransaction(domain.Transaction t) =>
      _dao.updateTransaction(_toCompanion(t));

  /// Soft-deletes a transaction by [id].
  Future<void> deleteTransaction(String id) => _dao.softDeleteTransaction(id);

  // ---------------------------------------------------------------------------
  // Mapping — data → domain
  // ---------------------------------------------------------------------------

  // Drift generates a class also named `Transaction` from the Transactions table.
  // The parameter type here uses the Drift-generated class (no alias needed in
  // the data layer). The return type uses domain.Transaction via the alias.
  domain.Transaction _mapToDomain(Transaction row) => domain.Transaction(
        id: row.id,
        type: row.type,
        date: row.date,
        amount: row.amount,
        currencyCode: row.currencyCode,
        exchangeRate: row.exchangeRate,
        accountId: row.accountId,
        toAccountId: row.toAccountId,
        categoryId: row.categoryId,
        subcategoryId: row.subcategoryId,
        description: row.description,
        isExcluded: row.isExcluded,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isDeleted: row.isDeleted,
      );

  TransactionWithDetails _mapToDetailEntity(TransactionWithNames row) =>
      TransactionWithDetails(
        transaction: _mapToDomain(row.transaction),
        categoryName: row.categoryName,
        categoryEmoji: row.categoryEmoji,
        categoryColorHex: row.categoryColorHex,
        accountName: row.accountName,
        toAccountName: row.toAccountName,
      );

  // ---------------------------------------------------------------------------
  // Mapping — domain → data
  // ---------------------------------------------------------------------------

  TransactionsCompanion _toCompanion(domain.Transaction t) =>
      TransactionsCompanion(
        id: Value(t.id),
        type: Value(t.type),
        date: Value(t.date),
        amount: Value(t.amount),
        currencyCode: Value(t.currencyCode),
        exchangeRate: Value(t.exchangeRate),
        accountId: Value(t.accountId),
        toAccountId: Value(t.toAccountId),
        categoryId: Value(t.categoryId),
        subcategoryId: Value(t.subcategoryId),
        description: Value(t.description),
        isExcluded: Value(t.isExcluded),
        createdAt: Value(t.createdAt),
        updatedAt: Value(DateTime.now()),
        isDeleted: Value(t.isDeleted),
      );
}
