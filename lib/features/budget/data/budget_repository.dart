// Repository providing budget operations to the domain layer — budget feature.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/daos/budget_dao.dart';
import '../../../data/local/database.dart';
import '../domain/budget_entity.dart';

part 'budget_repository.g.dart';

/// Riverpod provider that wires [BudgetRepository] to [AppDatabase].
@riverpod
BudgetRepository budgetRepository(BudgetRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetRepository(db.budgetDao);
}

/// Mediates between the data layer (BudgetDao) and the domain layer.
/// All public methods work exclusively with domain entities.
class BudgetRepository {
  BudgetRepository(this._dao);

  final BudgetDao _dao;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reactive stream of all budgets active during [month].
  Stream<List<BudgetEntity>> watchBudgetsForMonth(DateTime month) =>
      _dao.watchBudgetsForMonth(month).map(
            (rows) => rows.map(_mapToDomain).toList(),
          );

  /// One-shot fetch of the budget for [categoryId] active during [month].
  Future<BudgetEntity?> getBudgetForCategory(
    String categoryId,
    DateTime month,
  ) async {
    final row = await _dao.getBudgetForCategory(categoryId, month);
    return row == null ? null : _mapToDomain(row);
  }

  /// Returns total expense spending for [categoryId] during [month].
  Future<double> getSpentAmount(String categoryId, DateTime month) =>
      _dao.getSpentAmount(categoryId, month);

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Inserts or updates a budget.
  /// When [id] is omitted the record is treated as a new insert.
  Future<int> upsertBudget({
    int? id,
    required String categoryId,
    required double amount,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
  }) {
    final now = DateTime.now();
    final from = _dateKey(effectiveFrom);
    final to = effectiveTo == null ? null : _dateKey(effectiveTo);
    return _dao.upsertBudget(
      BudgetsCompanion(
        id: id != null ? Value(id) : const Value.absent(),
        categoryId: Value(categoryId),
        amount: Value(amount),
        effectiveFrom: Value(from),
        effectiveTo: Value(to),
        // Always provide createdAt so the insert path satisfies Drift's
        // required-field validation. The DAO's DoUpdate clause preserves
        // the original value on conflict.
        createdAt: Value(now.toIso8601String()),
        updatedAt: Value(now.toIso8601String()),
      ),
    );
  }

  /// Hard-deletes a budget row by [id].
  Future<int> deleteBudget(int id) => _dao.deleteBudget(id);

  // ---------------------------------------------------------------------------
  // Mapping — data → domain
  // ---------------------------------------------------------------------------

  BudgetEntity _mapToDomain(Budget row) => BudgetEntity(
        id: row.id,
        categoryId: row.categoryId,
        amount: row.amount,
        effectiveFrom: _parseDate(row.effectiveFrom),
        effectiveTo:
            row.effectiveTo == null ? null : _parseDate(row.effectiveTo!),
        createdAt: DateTime.parse(row.createdAt),
        updatedAt: DateTime.parse(row.updatedAt),
      );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Serialises a [DateTime] to ISO8601 YYYY-MM-DD (first day of month).
  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m-01';
  }

  /// Parses a YYYY-MM-DD string back to [DateTime].
  DateTime _parseDate(String key) => DateTime.parse(key);
}
