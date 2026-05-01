// RuleBasedInsightProvider — insights feature data layer.
// Iterates registered InsightRule instances and returns matching insights.
import '../domain/insight.dart';
import '../domain/insight_context.dart';
import '../domain/insight_provider.dart';
import '../domain/insight_rule.dart';

/// Concrete [InsightProvider] that evaluates a list of [InsightRule]s in order.
///
/// [generate] iterates all registered rules, calls [InsightRule.evaluate], filters
/// null results, then sorts by severity (critical → warning → info) so the most
/// urgent observation is shown first.
///
/// V1: constructed with an empty [rules] list — returns an empty list until Epic
/// 8b registers the four concrete rule classes. Adding a new rule in Epic 8b
/// requires only a registration line in [insightProviderInstanceProvider];
/// no changes to this class, [insightsProvider], or any UI widget are needed.
class RuleBasedInsightProvider implements InsightProvider {
  const RuleBasedInsightProvider({required this.rules});

  /// Ordered list of rules evaluated on every [generate] call.
  final List<InsightRule> rules;

  @override
  List<Insight> generate(InsightContext context) {
    final insights = rules
        .map((rule) => rule.evaluate(context))
        .whereType<Insight>()
        .toList();

    // Sort by severity so critical/warning insights appear before info.
    insights.sort(
      (a, b) => a.severity.sortOrder.compareTo(b.severity.sortOrder),
    );

    return insights;
  }
}
