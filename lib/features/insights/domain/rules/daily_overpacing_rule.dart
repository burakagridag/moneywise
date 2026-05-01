// DailyOverpacingRule stub — insights feature domain layer.
// Fires when current daily burn rate × remaining days > remaining budget.
// Full implementation: Epic 8b.
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: projected month-end spending exceeds the effective budget.
///
/// First-month fallback: suppresses the insight when
/// [InsightContext.effectiveBudget] is null — no budget configured.
///
/// Stable insight id: `'daily_overpacing'`
// TODO: Epic 8b — implement DailyOverpacingRule logic.
class DailyOverpacingRule implements InsightRule {
  const DailyOverpacingRule();

  static const String id = 'daily_overpacing';

  @override
  Insight? evaluate(InsightContext context) {
    // TODO: Epic 8b — implement rule evaluation.
    return null;
  }
}
