// FifthRulePlaceholder — insights feature domain layer.
// Permanent stub occupying position 5 in the V1 rule registry.
// Full implementation deferred to Sprint 8c (WeekendSpendingRule is leading candidate).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Placeholder for the fifth V1 insight rule.
///
/// Returns null unconditionally — no insight is generated until the trigger
/// condition is agreed with the Product Sponsor in Sprint 8c.
///
/// Registering this stub keeps the rule registry honest: it documents that a
/// fifth rule slot exists without shipping a rule with undefined semantics.
///
/// Stable insight id: `'fifth_rule_placeholder'`
/// Leading candidate for Sprint 8c: `WeekendSpendingRule`.
class FifthRulePlaceholder implements InsightRule {
  const FifthRulePlaceholder();

  /// Stable insight id — preserved for future per-rule dismissal support.
  static const String id = 'fifth_rule_placeholder';

  @override
  // EDGE CASE: stub — always returns null until Sprint 8c implements the rule.
  Insight? evaluate(InsightContext context) => null;
}
