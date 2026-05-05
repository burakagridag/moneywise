// InsightContext value class — insights feature domain layer.
// Aggregates all data required by InsightRule implementations.
// Imports only domain entity types — zero data-layer imports.
import '../../../domain/entities/transaction.dart';
import '../../budget/domain/budget_entity.dart';

/// Immutable snapshot of the financial data needed to evaluate all V1 insight
/// rules without the rule engine touching the database directly.
///
/// All fields contain domain entities only — no Drift table types.
/// Data is assembled by [insightsProvider] in the presentation layer and
/// injected via [InsightProvider.generate].
class InsightContext {
  const InsightContext({
    required this.currentMonthTransactions,
    required this.previousMonthTransactions,
    required this.currentMonthBudgets,
    required this.effectiveBudget,
    required this.referenceDate,
    required this.formatAmount,
  });

  /// Non-deleted transactions for the current calendar month.
  final List<Transaction> currentMonthTransactions;

  /// Non-deleted transactions for the previous calendar month.
  ///
  /// May be empty for new users (first-month fallback — see ADR-011).
  /// Each rule must handle the empty case by returning null, not crashing.
  final List<Transaction> previousMonthTransactions;

  /// Active budgets enriched with carry-over spending for the current month.
  final List<BudgetWithSpending> currentMonthBudgets;

  /// Resolved budget ceiling for the current month (global budget or sum of
  /// category budgets). Null when neither is configured.
  ///
  /// Rules that depend on this field must guard against null and return null
  /// (no insight) when it is absent.
  final double? effectiveBudget;

  /// The date used as "now" — injected by the caller so rules are testable
  /// with a fixed reference date.
  final DateTime referenceDate;

  /// Locale-aware currency formatter provided by the presentation layer.
  /// Pure Dart function type — keeps the domain Flutter-free.
  final String Function(double) formatAmount;

  // ---------------------------------------------------------------------------
  // Derived computed properties — used by rule implementations
  // ---------------------------------------------------------------------------

  /// Sum of all non-excluded, non-deleted expense transaction amounts
  /// in [currentMonthTransactions]. Income and transfers are excluded.
  double get totalMonthlySpend => currentMonthTransactions
      .where((t) => t.type == 'expense' && !t.isExcluded && !t.isDeleted)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Total income amount from [currentMonthTransactions].
  double get totalMonthlyIncome => currentMonthTransactions
      .where((t) => t.type == 'income' && !t.isExcluded && !t.isDeleted)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Net savings rate: (income − expense) / income.
  ///
  /// Returns 0.0 when [totalMonthlyIncome] is zero to avoid division by zero.
  /// A value below 0.0 indicates spending exceeds income.
  double get savingsRate {
    final income = totalMonthlyIncome;
    // EDGE CASE: no income this month — avoid division by zero, return 0.0.
    if (income == 0.0) return 0.0;
    return (income - totalMonthlySpend) / income;
  }

  /// Remaining budget: effectiveBudget − totalMonthlySpend.
  ///
  /// Returns null when [effectiveBudget] is null (no budget configured).
  /// Callers MUST null-check before using this value — a null result means
  /// "no budget set", which is distinct from "budget fully consumed" (0.0).
  /// Rules that depend on remaining budget must return null (no insight)
  /// when this property is null.
  double? get remainingBudget {
    if (effectiveBudget == null) return null;
    return effectiveBudget! - totalMonthlySpend;
  }

  /// Category-level expense aggregation: categoryId → sum of expense amounts.
  ///
  /// Only expense transactions that are not excluded and not deleted are counted.
  /// Transactions with a null categoryId are grouped under the empty string key.
  Map<String, double> get spendByCategory {
    final result = <String, double>{};
    for (final t in currentMonthTransactions) {
      if (t.type != 'expense' || t.isExcluded || t.isDeleted) continue;
      final key = t.categoryId ?? '';
      result[key] = (result[key] ?? 0.0) + t.amount;
    }
    return result;
  }

  /// Days that have at least one qualifying expense transaction, as day-of-month ints.
  /// Used by WeekendSpendingRule to count distinct weekend/weekday days.
  Set<int> get daysWithExpense => currentMonthTransactions
      .where((t) => t.type == 'expense' && !t.isExcluded && !t.isDeleted)
      .map((t) => t.date.day)
      .toSet();

  /// Total expense amount on weekend days (Saturday=6, Sunday=7) this month.
  double get weekendTotalSpend {
    return currentMonthTransactions
        .where((t) =>
            t.type == 'expense' &&
            !t.isExcluded &&
            !t.isDeleted &&
            (t.date.weekday == DateTime.saturday ||
                t.date.weekday == DateTime.sunday))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Number of distinct weekend days (Sat/Sun) that have at least one expense.
  int get weekendDayCount => currentMonthTransactions
      .where((t) =>
          t.type == 'expense' &&
          !t.isExcluded &&
          !t.isDeleted &&
          (t.date.weekday == DateTime.saturday ||
              t.date.weekday == DateTime.sunday))
      .map((t) => t.date.day)
      .toSet()
      .length;

  /// Total expense amount on weekday days (Mon–Fri) this month.
  double get weekdayTotalSpend {
    return currentMonthTransactions
        .where((t) =>
            t.type == 'expense' &&
            !t.isExcluded &&
            !t.isDeleted &&
            t.date.weekday >= DateTime.monday &&
            t.date.weekday <= DateTime.friday)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Number of distinct weekday days (Mon–Fri) that have at least one expense.
  int get weekdayDayCount => currentMonthTransactions
      .where((t) =>
          t.type == 'expense' &&
          !t.isExcluded &&
          !t.isDeleted &&
          t.date.weekday >= DateTime.monday &&
          t.date.weekday <= DateTime.friday)
      .map((t) => t.date.day)
      .toSet()
      .length;
}
