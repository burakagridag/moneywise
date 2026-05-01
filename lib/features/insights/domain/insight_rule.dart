// Abstract InsightRule interface — insights feature domain layer.
import 'insight.dart';
import 'insight_context.dart';

/// A single evaluatable insight rule.
///
/// Each rule is a standalone class with one responsibility: determine whether
/// a specific financial condition is met and produce an [Insight] if so.
///
/// Rules must be:
/// - Pure — no side effects, no async, no I/O.
/// - Safe — never throw; return null instead of crashing on edge cases.
/// - Documented — each guard clause must have a `// EDGE CASE` comment.
///
/// [RuleBasedInsightProvider] calls [evaluate] on each registered rule and
/// filters out null results.
abstract class InsightRule {
  /// Returns an [Insight] if the rule condition is met, or null if the
  /// condition is not met or the required data is absent/invalid.
  Insight? evaluate(InsightContext context);
}
