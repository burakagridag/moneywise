// ConcentrationRule — insights feature domain layer.
// Fires when a single expense category exceeds 70% of total monthly spending.
// Implements EPIC8B-01 (ADR-013 V1 Rule Registry, row 1).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_localization_data.dart';
import '../insight_rule.dart';

/// Rule: top spending category > 70% of total monthly expense.
///
/// Total monthly spend = SUM of expense transactions only (income and transfers
/// excluded). Uses [InsightContext.totalMonthlySpend] and
/// [InsightContext.spendByCategory].
///
/// Returns null (no insight) when:
/// - [InsightContext.totalMonthlySpend] is effectively zero (< 0.001)
/// - [InsightContext.spendByCategory] is empty (no categorised expenses)
/// - Top category ratio is at or below [threshold] (rule is exclusive: > 70%)
///
/// Stable insight id: `'concentration'`
class ConcentrationRule implements InsightRule {
  const ConcentrationRule();

  /// Threshold: top category must EXCEED this fraction of total spend to fire.
  /// Exactly 70% does NOT fire — the condition is strictly greater than.
  static const double threshold = 0.70;

  /// Stable insight id used for keyed UI animations and deduplication.
  static const String id = 'concentration';

  @override
  Insight? evaluate(InsightContext context) {
    // EDGE CASE: no expense spending this month — avoid division by zero.
    if (context.totalMonthlySpend < 0.001) return null;

    // EDGE CASE: no categorised expenses — nothing to evaluate.
    if (context.spendByCategory.isEmpty) return null;

    // Find the category with the highest spend.
    final topEntry = context.spendByCategory.entries
        .reduce((a, b) => a.value >= b.value ? a : b);

    final ratio = topEntry.value / context.totalMonthlySpend;

    // EDGE CASE: ratio is at or below the threshold — condition not met.
    if (ratio <= threshold) return null;

    final pct = (ratio * 100).round();

    return Insight(
      id: id,
      severity: InsightSeverity.warning,
      headline: 'Spending concentrated',
      body: '$pct% of spending in one category.',
      bodyParams: {'pct': pct},
      localizationData: ConcentrationLocalizationData(pct: pct),
    );
  }
}
