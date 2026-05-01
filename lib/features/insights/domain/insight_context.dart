// InsightContext value class — insights feature domain layer.
// Aggregates all data required by InsightRule implementations.
// Imports only domain entity types — zero data-layer imports.
import '../../../domain/entities/transaction.dart';
import '../../../features/budget/domain/budget_entity.dart';

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
}
