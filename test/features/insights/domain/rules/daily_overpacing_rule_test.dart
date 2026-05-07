// Unit tests for DailyOverpacingRule — insights feature domain layer (EPIC8B-03).
// Covers: no-budget suppression, early-month suppression (day < 5),
// zero-spend suppression, last-day suppression, boundary (equal does not fire),
// remainingBudget <= 0 suppression (exhausted / exceeded budget),
// firing when projected spend > remaining, non-firing when <=, and
// fired Insight id/severity.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/rules/daily_overpacing_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal expense [Transaction] for the given [date] and [amount].
Transaction _expense({
  required String id,
  required double amount,
  required DateTime date,
}) {
  return Transaction(
    id: id,
    type: 'expense',
    date: date,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: 'food',
    isExcluded: false,
    isDeleted: false,
    createdAt: date,
    updatedAt: date,
  );
}

/// Builds an [InsightContext] with controllable fields.
///
/// [year] / [month] / [day] set the reference date.
/// [totalSpend] is materialised as a single expense transaction on the
/// reference date so [InsightContext.totalMonthlySpend] equals [totalSpend].
/// [effectiveBudget] is passed directly — pass null to simulate no budget.
InsightContext _ctx({
  int year = 2026,
  int month = 5,
  int day = 15,
  double totalSpend = 0.0,
  double? effectiveBudget,
}) {
  final refDate = DateTime(year, month, day);
  final txns = totalSpend > 0
      ? [_expense(id: 'e1', amount: totalSpend, date: refDate)]
      : <Transaction>[];
  return InsightContext(
    currentMonthTransactions: txns,
    previousMonthTransactions: const [],
    currentMonthBudgets: const [],
    effectiveBudget: effectiveBudget,
    referenceDate: refDate,
    formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const rule = DailyOverpacingRule();

  // -------------------------------------------------------------------------
  // Guard: no budget configured
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — suppressed when no budget is configured', () {
    test('returns null when effectiveBudget is null', () {
      // EDGE CASE: user has no budget — rule cannot project against a target.
      final result = rule.evaluate(_ctx(
        day: 15,
        totalSpend: 500.0,
        effectiveBudget: null,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: too early in the month (day < 5)
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — suppressed when referenceDate.day < 5', () {
    test('returns null on day 1 even if projected spend exceeds budget', () {
      // day=1, spend=100, budget=200 → burn=100/day, remaining=29 days,
      // projected=2900 >> 100 remaining budget. But day < 5 suppresses.
      final result = rule.evaluate(_ctx(
        day: 1,
        totalSpend: 100.0,
        effectiveBudget: 200.0,
      ));
      expect(result, isNull);
    });

    test('returns null on day 4 even if projected spend exceeds budget', () {
      final result = rule.evaluate(_ctx(
        day: 4,
        totalSpend: 400.0,
        effectiveBudget: 500.0,
      ));
      expect(result, isNull);
    });

    test('does NOT suppress on day 5 when condition is met', () {
      // day=5, month=May (31 days), spend=500
      // burn = 500/5 = 100/day, remainingDays = 31-5 = 26
      // projected = 100*26 = 2600 > remaining = 1000-500 = 500 → fires.
      final result = rule.evaluate(_ctx(
        day: 5,
        totalSpend: 500.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: zero spending
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — suppressed when totalMonthlySpend is 0', () {
    test('returns null when there are no expense transactions', () {
      // EDGE CASE: no spending recorded yet — burn rate is zero; no signal.
      final result = rule.evaluate(_ctx(
        day: 15,
        totalSpend: 0.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: remainingBudget <= 0 — budget exhausted or already exceeded
  // -------------------------------------------------------------------------

  group(
      'DailyOverpacingRule — suppressed when remainingBudget <= 0 '
      '(budget exhausted or exceeded)',
      () {
    test('returns null when totalSpend exactly equals effectiveBudget (remaining == 0)',
        () {
      // EDGE CASE: every euro of the budget is spent; remaining == 0.
      // "Pacing" projection is meaningless — nothing left to pace against.
      // A future OverBudgetRule (V1.x) will surface this state.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 15,
        totalSpend: 1000.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test('returns null when totalSpend exceeds effectiveBudget (remaining < 0)',
        () {
      // EDGE CASE: already over budget — "pacing" framing ("you'll exceed by
      // end of month") is wrong when the budget is already exceeded today.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 10,
        totalSpend: 1200.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: last day of month (remainingDays == 0)
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — suppressed on last day of month', () {
    test('returns null on day 31 of a 31-day month (remainingDays = 0)', () {
      // May has 31 days; day 31 → remainingDays = 31-31 = 0.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 31,
        totalSpend: 3000.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test('returns null on day 28 of a 28-day month (February non-leap)', () {
      // 2026 is not a leap year; Feb has 28 days; day 28 → remainingDays = 0.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 2,
        day: 28,
        totalSpend: 2000.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Threshold boundary: projected == remaining must NOT fire
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — boundary: exactly equal does not fire', () {
    test(
        'returns null when projectedAdditionalSpend == remainingBudget (exclusive)',
        () {
      // day=10, month=May(31 days), remainingDays=21
      // We want burn*21 == remaining exactly.
      // Choose totalSpend=210, effectiveBudget=630:
      //   burn = 210/10 = 21, projected = 21*21 = 441
      //   remaining = 630-210 = 420  → 441 > 420 so that would fire.
      // Instead choose totalSpend=100, effectiveBudget=310:
      //   burn = 100/10 = 10, projected = 10*21 = 210
      //   remaining = 310-100 = 210 → equal → must NOT fire.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 10,
        totalSpend: 100.0,
        effectiveBudget: 310.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firing conditions
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — fires when projected spend > remaining budget',
      () {
    test('fires in a typical mid-month overpacing scenario', () {
      // day=15, May(31 days), remainingDays=16
      // totalSpend=900, effectiveBudget=1000
      // burn = 900/15 = 60/day, projected = 60*16 = 960
      // remaining = 1000-900 = 100 → 960 > 100 → fires.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 15,
        totalSpend: 900.0,
        effectiveBudget: 1000.0,
      ));
      expect(result, isNotNull);
    });

    // NOTE: the case where totalSpend > effectiveBudget (remainingBudget < 0)
    // is now handled by the remainingBudget <= 0 guard — see its dedicated
    // group below. The "pacing" framing is semantically wrong once the budget
    // is exhausted; a future OverBudgetRule (V1.x) will surface that state.

    test('does NOT fire when projected additional spend <= remaining budget',
        () {
      // day=10, May(31 days), remainingDays=21
      // totalSpend=100, effectiveBudget=10000
      // burn = 100/10 = 10/day, projected = 10*21 = 210
      // remaining = 10000-100 = 9900 → 210 <= 9900 → does not fire.
      final result = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 10,
        totalSpend: 100.0,
        effectiveBudget: 10000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Fired Insight properties
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — Insight properties when fired', () {
    late Insight fired;

    setUp(() {
      // day=15, May(31 days), spend=900, budget=1000 → fires.
      fired = rule.evaluate(_ctx(
        year: 2026,
        month: 5,
        day: 15,
        totalSpend: 900.0,
        effectiveBudget: 1000.0,
      ))!;
    });

    test("fired Insight has id == 'daily_overpacing'", () {
      expect(fired.id, equals(DailyOverpacingRule.id));
      expect(fired.id, equals('daily_overpacing'));
    });

    test('fired Insight has severity == InsightSeverity.critical', () {
      expect(fired.severity, equals(InsightSeverity.critical));
    });

    test('fired Insight headline is not empty', () {
      expect(fired.headline, isNotEmpty);
    });

    test('fired Insight body is not empty', () {
      expect(fired.body, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Static constants
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule — constants', () {
    test('minimumDayOfMonth is 5', () {
      expect(DailyOverpacingRule.minimumDayOfMonth, equals(5));
    });

    test("id is 'daily_overpacing'", () {
      expect(DailyOverpacingRule.id, equals('daily_overpacing'));
    });
  });
}
