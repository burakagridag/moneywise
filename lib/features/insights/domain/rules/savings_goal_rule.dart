// SavingsGoalRule — insights feature domain layer.
// Fires when net savings rate (income − expense) / income falls below 10%.
// Implemented in Epic 8b (EPIC8B-02).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: net savings rate < 10% of income.
///
/// V1: fixed 10% threshold; user-configurable savings goal is V1.x scope.
/// Insight message: "Saving less than 10% this month"
///
/// Suppression conditions (returns null without firing):
/// - [InsightContext.totalMonthlyIncome] == 0 — no income data this month;
///   dividing by zero is meaningless and would produce false positives for
///   users who log expenses before logging salary.
/// - [InsightContext.referenceDate].day < 5 — too early in the month for a
///   meaningful savings signal; avoids alarming the user on day 1–4.
/// - [InsightContext.savingsRate] >= threshold — condition not met.
///
/// Stable insight id: `'savings_goal'`
class SavingsGoalRule implements InsightRule {
  const SavingsGoalRule();

  /// Threshold: savings rate must fall strictly below this fraction of income
  /// for the rule to fire (exclusive — exactly 10% does NOT fire).
  static const double threshold = 0.10;

  /// Earliest day of the month (inclusive) on which the rule is allowed to fire.
  /// Days 1–4 are suppressed to avoid alarming users before meaningful data.
  static const int minimumDayOfMonth = 5;

  /// Stable insight id used for keyed UI animations and deduplication.
  static const String id = 'savings_goal';

  @override
  Insight? evaluate(InsightContext context) {
    // EDGE CASE: no income this month — suppress, not an error.
    // Dividing by zero is guarded inside savingsRate, but a zero income makes
    // the rate meaningless (user may not have logged salary yet this month).
    if (context.totalMonthlyIncome == 0) return null;

    // EDGE CASE: too early in the month (days 1–4) — suppress to avoid
    // alarming users before meaningful spending data has accumulated.
    if (context.referenceDate.day < minimumDayOfMonth) return null;

    // Condition not met — savings rate is at or above the threshold.
    if (context.savingsRate >= threshold) return null;

    return const Insight(
      id: id,
      severity: InsightSeverity.warning,
      headline: 'Low savings rate',
      body: 'Saving less than 10% this month.',
    );
  }
}
