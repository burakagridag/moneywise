// BigTransactionRule stub — insights feature domain layer.
// Fires when any single transaction exceeds 30% of the monthly budget.
// Full implementation: Epic 8b.
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: any single transaction amount > 30% of [InsightContext.effectiveBudget].
///
/// First-month fallback: suppresses the insight when
/// [InsightContext.effectiveBudget] is null — no budget configured.
///
/// Stable insight id: `'big_transaction'`
// TODO: Epic 8b — implement BigTransactionRule logic.
class BigTransactionRule implements InsightRule {
  const BigTransactionRule();

  static const String id = 'big_transaction';

  @override
  Insight? evaluate(InsightContext context) {
    // TODO: Epic 8b — implement rule evaluation.
    return null;
  }
}
