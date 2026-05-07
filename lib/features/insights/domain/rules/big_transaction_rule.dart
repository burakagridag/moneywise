// BigTransactionRule — insights feature domain layer.
// Fires when any single expense transaction exceeds 30% of the monthly budget,
// but only when that transaction's category has an active budget.
// Implements EPIC8B-04 (ADR-013 V1 Rule Registry, row 4).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_localization_data.dart';
import '../insight_rule.dart';

/// Rule: the single largest expense transaction this month exceeds 30% of
/// [InsightContext.effectiveBudget], AND the transaction's category has an
/// active budget in [InsightContext.currentMonthBudgets].
///
/// Guard clauses — returns null (no insight) when:
/// - [InsightContext.effectiveBudget] is null (no budget configured)
/// - [InsightContext.effectiveBudget] is <= 0
/// - No non-excluded, non-deleted expense transactions exist this month
/// - The largest expense's category is NOT in [InsightContext.currentMonthBudgets]
///   (unbudgeted category — Sponsor constraint from EPIC8B-04 clarification)
/// - The largest expense amount is at or below [threshold] × effectiveBudget
///   (condition is strictly greater than — exactly 30% does NOT fire)
///
/// Stable insight id: `'big_transaction'`
class BigTransactionRule implements InsightRule {
  const BigTransactionRule();

  /// Threshold: a transaction must EXCEED this fraction of effective budget to fire.
  /// Exactly 30% does NOT fire — the condition is strictly greater than.
  static const double threshold = 0.30;

  /// Stable insight id used for keyed UI animations and deduplication.
  static const String id = 'big_transaction';

  @override
  Insight? evaluate(InsightContext context) {
    // EDGE CASE: no budget configured — cannot evaluate ratio against budget.
    if (context.effectiveBudget == null) return null;

    // EDGE CASE: effectiveBudget is zero or negative — division would be
    // meaningless and any amount would trivially exceed 0.
    if (context.effectiveBudget! <= 0) return null;

    // Collect non-excluded, non-deleted expense transactions.
    final expenses = context.currentMonthTransactions
        .where((t) => t.type == 'expense' && !t.isExcluded && !t.isDeleted)
        .toList();

    // EDGE CASE: no expense transactions this month — nothing to evaluate.
    if (expenses.isEmpty) return null;

    // Find the single transaction with the largest amount.
    final biggest = expenses.reduce((a, b) => a.amount >= b.amount ? a : b);

    // EDGE CASE: transaction category is not in the active budget list.
    // Per Sponsor decision: rule only fires for budgeted categories.
    final isBudgeted = context.currentMonthBudgets
        .any((b) => b.budget.categoryId == biggest.categoryId);
    if (!isBudgeted) return null;

    final ratio = biggest.amount / context.effectiveBudget!;

    // EDGE CASE: ratio is at or below the threshold — condition not met.
    // Strictly greater than 30%; exactly 30% does NOT fire.
    if (ratio <= threshold) return null;

    final pct = (ratio * 100).round();

    // Body wording: Option D (Sprint 8b live test decision — 2026-05-06).
    // When transaction ≤ 100% of budget: show formatted amount + percentage.
    // When transaction > 100% of budget: use simplified message to avoid
    // confusing "150% of budget" phrasing.
    // Amount is formatted via context.formatAmount (locale-aware, e.g. "300,00 €").
    final formattedAmount = context.formatAmount(biggest.amount);
    final body = pct <= 100
        ? '$formattedAmount ($pct% of budget)'
        : 'Exceeds your monthly budget';

    return Insight(
      id: id,
      severity: InsightSeverity.warning,
      headline: 'Large transaction',
      body: body,
      bodyParams:
          pct <= 100 ? {'amount': formattedAmount, 'pct': pct} : const {},
      localizationData: BigTransactionLocalizationData(
        pct: pct,
        formattedAmount: formattedAmount,
        exceedsBudget: pct > 100,
      ),
    );
  }
}
