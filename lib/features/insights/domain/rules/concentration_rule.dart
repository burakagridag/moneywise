// ConcentrationRule stub — insights feature domain layer.
// Fires when a single category exceeds 50% of total monthly spending.
// Full implementation: Epic 8b.
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: top spending category > 50% of total monthly expense.
///
/// Stable insight id: `'concentration'`
// TODO: Epic 8b — implement ConcentrationRule logic.
class ConcentrationRule implements InsightRule {
  const ConcentrationRule();

  static const String id = 'concentration';

  @override
  Insight? evaluate(InsightContext context) {
    // TODO: Epic 8b — implement rule evaluation.
    return null;
  }
}
