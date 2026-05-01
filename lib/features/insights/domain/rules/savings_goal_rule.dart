// SavingsGoalRule stub — insights feature domain layer.
// Fires when net savings rate (income - expense) / income falls below 10%.
// Full implementation: Epic 8b.
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: net savings rate < 10% of income.
///
/// First-month fallback: calculated from current-month income only when
/// [InsightContext.previousMonthTransactions] is empty. Returns null when
/// income is zero to avoid division by zero.
///
/// Stable insight id: `'savings_goal'`
// TODO: Epic 8b — implement SavingsGoalRule logic.
class SavingsGoalRule implements InsightRule {
  const SavingsGoalRule();

  static const String id = 'savings_goal';

  @override
  Insight? evaluate(InsightContext context) {
    // TODO: Epic 8b — implement rule evaluation.
    return null;
  }
}
