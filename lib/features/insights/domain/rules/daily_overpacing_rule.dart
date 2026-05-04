// DailyOverpacingRule — insights feature domain layer.
// Fires when current daily burn rate × remaining days > remaining budget.
// Implements EPIC8B-03 (ADR-013 V1 Rule Registry, row 3).
import '../insight.dart';
import '../insight_context.dart';
import '../insight_rule.dart';

/// Rule: projected month-end spending exceeds the effective budget.
///
/// Fires only when BOTH conditions are true:
///   context.referenceDate.day >= 5   (suppresses false positives on days 1–4)
///   dailyBurnRate * remainingDays > remainingBudget
///
/// Where:
///   dailyBurnRate   = totalMonthlySpend / referenceDate.day
///   remainingDays   = daysInMonth − referenceDate.day
///   daysInMonth     = DateTime(year, month + 1, 0).day
///   remainingBudget = effectiveBudget − totalMonthlySpend
///
/// Suppresses the insight (returns null) when:
/// - [InsightContext.effectiveBudget] is null — no budget configured.
/// - [InsightContext.remainingBudget] is null — belt-and-suspenders guard.
/// - referenceDate.day < 5 — too early in the month to project reliably.
/// - totalMonthlySpend <= 0 — no spending recorded yet.
/// - remainingDays <= 0 — last day of the month; nothing left to project.
///
/// Stable insight id: `'daily_overpacing'`
class DailyOverpacingRule implements InsightRule {
  const DailyOverpacingRule();

  /// Minimum day-of-month before the rule activates (suppresses day 1–4 noise).
  static const int minimumDayOfMonth = 5;

  /// Stable insight id used for keyed UI animations and deduplication.
  static const String id = 'daily_overpacing';

  @override
  Insight? evaluate(InsightContext context) {
    // EDGE CASE: no budget configured — rule cannot produce a meaningful signal.
    if (context.effectiveBudget == null) return null;

    // EDGE CASE: remainingBudget is null — belt-and-suspenders; mirrors the
    // effectiveBudget null guard but is stated explicitly in the spec.
    final remaining = context.remainingBudget;
    if (remaining == null) return null;

    // EDGE CASE: budget already exhausted or exceeded — "pacing" projection is
    // meaningless when there is nothing left to pace against. A future
    // OverBudgetRule (V1.x) will surface this state with correct messaging.
    // Discovered in Sprint 8b simulator testing (2026-05-06).
    if (remaining <= 0) return null;

    // EDGE CASE: too early in the month — burn rate is unreliable before day 5.
    if (context.referenceDate.day < minimumDayOfMonth) return null;

    // EDGE CASE: no spending yet — daily burn rate would be zero; no signal.
    if (context.totalMonthlySpend <= 0) return null;

    final year = context.referenceDate.year;
    final month = context.referenceDate.month;
    final dayOfMonth = context.referenceDate.day;

    // Total days in the current month using the "day 0 of next month" trick.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final remainingDays = daysInMonth - dayOfMonth;

    // EDGE CASE: last day of month — no days remaining to project over.
    if (remainingDays <= 0) return null;

    final dailyBurnRate = context.totalMonthlySpend / dayOfMonth;
    final projectedAdditionalSpend = dailyBurnRate * remainingDays;

    // EDGE CASE: projected additional spend does not strictly exceed remaining
    // budget — condition must be strictly greater than (not equal).
    if (projectedAdditionalSpend <= remaining) return null;

    return const Insight(
      id: id,
      severity: InsightSeverity.critical,
      headline: 'Overspending pace',
      body: 'On track to exceed budget.',
    );
  }
}
