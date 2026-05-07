// WeekendSpendingRule — insights feature domain layer.
// Fires when the weekend daily average spend exceeds 2x the weekday daily average.
// Implements EPIC8B-09 (ADR-013 V1 Rule Registry, row 5 — Sprint 8c).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_localization_data.dart';
import '../insight_rule.dart';

/// Rule: weekend daily average spending > 2× weekday daily average.
///
/// weekendDailyAvg = weekendTotalSpend / weekendDayCount
/// weekdayDailyAvg = weekdayTotalSpend / weekdayDayCount
///
/// Weekend = Saturday (DateTime.weekday==6) and Sunday (DateTime.weekday==7).
/// Weekday = Monday–Friday (DateTime.weekday 1–5).
///
/// Only expense transactions that are not excluded and not deleted are counted.
///
/// Returns null (no insight) when:
/// - [InsightContext.totalMonthlyIncome] is 0 (guard against income-free months)
/// - [InsightContext.weekendDayCount] < 2 (insufficient weekend data)
/// - [InsightContext.weekdayDayCount] < 3 (insufficient weekday data)
/// - weekdayDailyAvg <= 0 (avoid division by zero / degenerate case)
/// - ratio <= [threshold] (strictly greater than — exactly 2.0 does NOT fire)
///
/// Stable insight id: `'weekend_spending'`
class WeekendSpendingRule implements InsightRule {
  const WeekendSpendingRule();

  /// Threshold: weekend daily average must EXCEED this multiple of weekday daily
  /// average to fire. Exactly 2.0 does NOT fire — the condition is strictly
  /// greater than.
  static const double threshold = 2.0;

  /// Stable insight id used for keyed UI animations and deduplication.
  static const String id = 'weekend_spending';

  @override
  Insight? evaluate(InsightContext context) {
    // GUARD: no income recorded — suppress to avoid noisy insights for users
    // who only log expenses without income entries.
    if (context.totalMonthlyIncome == 0) return null;

    // GUARD: fewer than 2 distinct weekend days with expenses — not enough data.
    if (context.weekendDayCount < 2) return null;

    // GUARD: fewer than 3 distinct weekday days with expenses — not enough data.
    if (context.weekdayDayCount < 3) return null;

    final weekdayDailyAvg = context.weekdayTotalSpend / context.weekdayDayCount;

    // GUARD: weekday average is zero or negative — avoid division by zero and
    // degenerate ratios when all weekday expenses are excluded.
    if (weekdayDailyAvg <= 0) return null;

    final weekendDailyAvg = context.weekendTotalSpend / context.weekendDayCount;

    final ratio = weekendDailyAvg / weekdayDailyAvg;

    // EDGE CASE: ratio is at or below the threshold — condition not met.
    // Exactly 2.0 does NOT fire per the spec (strictly greater than).
    if (ratio <= threshold) return null;

    // pct = (ratio - 1.0) * 100, rounded.
    // e.g. ratio=3.0 → pct=200, ratio=2.5 → pct=150.
    final pct = ((ratio - 1.0) * 100).round();

    return Insight(
      id: id,
      severity: InsightSeverity.warning,
      headline: 'Weekend spending high',
      body: 'Weekend $pct% above weekday.',
      bodyParams: {'pct': pct},
      localizationData: WeekendSpendingLocalizationData(pct: pct),
    );
  }
}
