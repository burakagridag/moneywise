// Data access object for budget records — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/budgets_table.dart';
import '../tables/transactions_table.dart';

part 'budget_dao.g.dart';

/// Provides CRUD and reactive query methods for Budgets.
@DriftAccessor(tables: [Budgets, Transactions])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reactive stream of all budgets active during [month].
  ///
  /// A budget is active if:
  ///   effectiveFrom <= monthStart  AND  (effectiveTo IS NULL OR effectiveTo >= monthStart)
  Stream<List<Budget>> watchBudgetsForMonth(DateTime month) {
    final monthStart = _monthKey(month);
    return (select(budgets)
          ..where(
            (b) =>
                b.effectiveFrom.isSmallerOrEqualValue(monthStart) &
                (b.effectiveTo.isNull() |
                    b.effectiveTo.isBiggerOrEqualValue(monthStart)),
          ))
        .watch();
  }

  /// One-shot fetch of the budget for [categoryId] active during [month].
  Future<Budget?> getBudgetForCategory(
    String categoryId,
    DateTime month,
  ) {
    final monthStart = _monthKey(month);
    return (select(budgets)
          ..where(
            (b) =>
                b.categoryId.equals(categoryId) &
                b.effectiveFrom.isSmallerOrEqualValue(monthStart) &
                (b.effectiveTo.isNull() |
                    b.effectiveTo.isBiggerOrEqualValue(monthStart)),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Inserts a new budget row or, if a row with the same [id] already exists,
  /// updates all mutable fields while preserving the original createdAt value.
  ///
  /// Returns the rowid of the inserted or updated row.
  Future<int> upsertBudget(BudgetsCompanion entry) {
    return into(budgets).insert(
      entry,
      onConflict: DoUpdate(
        (old) => BudgetsCompanion.custom(
          categoryId: Variable(entry.categoryId.value),
          amount: Variable(entry.amount.value),
          effectiveFrom: Variable(entry.effectiveFrom.value),
          effectiveTo: Variable(entry.effectiveTo.value),
          updatedAt: Variable(entry.updatedAt.value),
          // Preserve the original createdAt so it is never overwritten.
          createdAt: old.createdAt,
        ),
        target: [budgets.id],
      ),
    );
  }

  /// Hard-deletes a budget by [id].
  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Aggregation — spending per category for a given month
  // ---------------------------------------------------------------------------

  /// Returns the total expense amount for [categoryId] in [month].
  /// Transfer and excluded transactions are excluded from the sum.
  Future<double> getSpentAmount(String categoryId, DateTime month) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);

    final result = await customSelect(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total
      FROM transactions
      WHERE category_id = :categoryId
        AND type = 'expense'
        AND is_excluded = 0
        AND is_deleted = 0
        AND date >= :from
        AND date < :to
      ''',
      variables: [
        Variable.withString(categoryId),
        Variable.withDateTime(from),
        Variable.withDateTime(to),
      ],
      readsFrom: {transactions},
    ).getSingle();

    return result.read<double>('total');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] to the ISO8601 YYYY-MM-DD month-start string used as
  /// the boundary key for effectiveFrom / effectiveTo comparisons.
  String _monthKey(DateTime month) {
    final y = month.year.toString().padLeft(4, '0');
    final m = month.month.toString().padLeft(2, '0');
    return '$y-$m-01';
  }
}
