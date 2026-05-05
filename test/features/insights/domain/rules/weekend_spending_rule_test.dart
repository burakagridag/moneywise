// Unit tests for WeekendSpendingRule — insights feature domain layer (EPIC8B-09).
// Covers: null guards, threshold boundary (exactly 2.0 does NOT fire), firing
// condition, pct computation, localizationData type and value, and id/severity.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_localization_data.dart';
import 'package:moneywise/features/insights/domain/rules/weekend_spending_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Reference month: May 2026.
/// May 2, 9 are Saturdays; May 3, 10 are Sundays; Mon–Fri: 4,5,6,7,8,11,...
const _year = 2026;
const _month = 5;

/// Creates an expense [Transaction] on the given day of May 2026.
Transaction _expense({
  required String id,
  required int day,
  required double amount,
}) {
  final date = DateTime(_year, _month, day);
  return Transaction(
    id: id,
    type: 'expense',
    date: date,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    isExcluded: false,
    isDeleted: false,
    createdAt: date,
    updatedAt: date,
  );
}

/// Creates an income [Transaction] on the given day.
Transaction _income(
    {required String id, required int day, required double amount}) {
  final date = DateTime(_year, _month, day);
  return Transaction(
    id: id,
    type: 'income',
    date: date,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: null,
    isExcluded: false,
    isDeleted: false,
    createdAt: date,
    updatedAt: date,
  );
}

/// Creates an excluded expense [Transaction] on the given day.
Transaction _excludedExpense(
    {required String id, required int day, required double amount}) {
  final date = DateTime(_year, _month, day);
  return Transaction(
    id: id,
    type: 'expense',
    date: date,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: 'cat-1',
    isExcluded: true,
    isDeleted: false,
    createdAt: date,
    updatedAt: date,
  );
}

/// Builds an [InsightContext] with the given transactions and a fixed income.
/// [totalIncome] defaults to 3000.0 so income guard passes by default.
InsightContext _ctx(
  List<Transaction> txns, {
  double totalIncome = 3000.0,
}) {
  // Prepend an income transaction so totalMonthlyIncome > 0 (unless explicitly 0).
  final all = [
    if (totalIncome > 0) _income(id: 'inc-base', day: 1, amount: totalIncome),
    ...txns,
  ];
  return InsightContext(
    currentMonthTransactions: all,
    previousMonthTransactions: const [],
    currentMonthBudgets: const [],
    effectiveBudget: null,
    referenceDate: DateTime(_year, _month, 15),
    formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
  );
}

/// Builds a context that fires the rule with a configurable ratio.
///
/// Weekday days: Mon 4, Tue 5, Wed 6 (3 days) — each [weekdayAmount].
/// Weekend days: Sat 2, Sun 3 (2 days) — each [weekendAmount].
///
/// weekdayDailyAvg = weekdayAmount (1 txn per day)
/// weekendDailyAvg = weekendAmount (1 txn per day)
/// ratio = weekendAmount / weekdayAmount
InsightContext _ctxWithRatio({
  required double weekdayAmount,
  required double weekendAmount,
  double totalIncome = 3000.0,
}) {
  return _ctx(
    [
      // 3 weekdays
      _expense(id: 'wd1', day: 4, amount: weekdayAmount), // Monday
      _expense(id: 'wd2', day: 5, amount: weekdayAmount), // Tuesday
      _expense(id: 'wd3', day: 6, amount: weekdayAmount), // Wednesday
      // 2 weekend days
      _expense(id: 'we1', day: 2, amount: weekendAmount), // Saturday
      _expense(id: 'we2', day: 3, amount: weekendAmount), // Sunday
    ],
    totalIncome: totalIncome,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const rule = WeekendSpendingRule();

  // -------------------------------------------------------------------------
  // Null guards
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — null guards', () {
    test('returns null when totalMonthlyIncome == 0', () {
      // EDGE CASE: user logs no income — suppress to avoid noisy output.
      final ctx = _ctx(
        [
          _expense(id: 'wd1', day: 4, amount: 10.0),
          _expense(id: 'wd2', day: 5, amount: 10.0),
          _expense(id: 'wd3', day: 6, amount: 10.0),
          _expense(id: 'we1', day: 2, amount: 100.0),
          _expense(id: 'we2', day: 3, amount: 100.0),
        ],
        totalIncome: 0,
      );
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when weekendDayCount < 2 (only 1 weekend day)', () {
      // Only Saturday has an expense — Sunday is empty.
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0),
        _expense(id: 'wd2', day: 5, amount: 10.0),
        _expense(id: 'wd3', day: 6, amount: 10.0),
        _expense(id: 'we1', day: 2, amount: 100.0), // Saturday only
      ]);
      // weekendDayCount == 1 → suppress.
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when weekendDayCount == 0', () {
      // No weekend expenses at all.
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0),
        _expense(id: 'wd2', day: 5, amount: 10.0),
        _expense(id: 'wd3', day: 6, amount: 10.0),
      ]);
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when weekdayDayCount < 3 (only 2 weekday days)', () {
      // Only Mon + Tue have expenses — Wednesday is empty.
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0), // Monday
        _expense(id: 'wd2', day: 5, amount: 10.0), // Tuesday
        _expense(id: 'we1', day: 2, amount: 100.0), // Saturday
        _expense(id: 'we2', day: 3, amount: 100.0), // Sunday
      ]);
      // weekdayDayCount == 2 → suppress.
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when weekdayDailyAvg == 0 (all weekday txns excluded)',
        () {
      // Weekday expenses exist but are excluded — weekdayTotalSpend == 0.
      final ctx = InsightContext(
        currentMonthTransactions: [
          _income(id: 'inc', day: 1, amount: 3000.0),
          _excludedExpense(id: 'wd1', day: 4, amount: 50.0),
          _excludedExpense(id: 'wd2', day: 5, amount: 50.0),
          _excludedExpense(id: 'wd3', day: 6, amount: 50.0),
          _expense(id: 'we1', day: 2, amount: 100.0),
          _expense(id: 'we2', day: 3, amount: 100.0),
        ],
        previousMonthTransactions: const [],
        currentMonthBudgets: const [],
        effectiveBudget: null,
        referenceDate: DateTime(_year, _month, 15),
        formatAmount: (a) => '€${a.toStringAsFixed(2)}',
      );
      // weekdayDayCount == 0 because excluded txns are filtered, so guard fires.
      expect(rule.evaluate(ctx), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Threshold boundary: exactly 2.0 must NOT fire
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — threshold boundary', () {
    test('returns null when ratio == exactly 2.0', () {
      // weekendDailyAvg = 20, weekdayDailyAvg = 10 → ratio = 2.0 exactly.
      // Condition is strictly > 2.0; exactly 2.0 must NOT fire.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 20.0);
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when ratio < 2.0', () {
      // weekendDailyAvg = 15, weekdayDailyAvg = 10 → ratio = 1.5 < 2.0.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 15.0);
      expect(rule.evaluate(ctx), isNull);
    });

    test('returns null when ratio == 1.0 (equal spend)', () {
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 10.0);
      expect(rule.evaluate(ctx), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firing condition: ratio > 2.0
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — fires when condition is met', () {
    test('fires when ratio is slightly above 2.0', () {
      // weekendDailyAvg = 20.01, weekdayDailyAvg = 10 → ratio ≈ 2.001 > 2.0.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 20.01);
      expect(rule.evaluate(ctx), isNotNull);
    });

    test('fires when ratio == 3.0', () {
      // weekendDailyAvg = 30, weekdayDailyAvg = 10 → ratio = 3.0.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 30.0);
      expect(rule.evaluate(ctx), isNotNull);
    });

    test('fires when ratio == 2.5', () {
      // weekendDailyAvg = 25, weekdayDailyAvg = 10 → ratio = 2.5.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 25.0);
      expect(rule.evaluate(ctx), isNotNull);
    });

    test('fires correctly when multiple txns exist on same weekend day', () {
      // Sat (day 2) has two expenses: 80 + 70 = 150. Sun (day 3) = 150.
      // weekendTotalSpend = 300, weekendDayCount = 2 (distinct days), avg = 150.
      // weekdayDailyAvg = 10. ratio = 15.0 > 2.0.
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0),
        _expense(id: 'wd2', day: 5, amount: 10.0),
        _expense(id: 'wd3', day: 6, amount: 10.0),
        _expense(id: 'we1a', day: 2, amount: 80.0),
        _expense(id: 'we1b', day: 2, amount: 70.0),
        _expense(id: 'we2', day: 3, amount: 150.0),
      ]);
      expect(rule.evaluate(ctx), isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Percentage computation
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — pct computation', () {
    test('pct == 200 when ratio == 3.0', () {
      // ratio = 3.0 → (3.0 - 1.0) * 100 = 200.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 30.0);
      final result = rule.evaluate(ctx)!;
      final data = result.localizationData as WeekendSpendingLocalizationData;
      expect(data.pct, equals(200));
    });

    test('pct == 150 when ratio == 2.5', () {
      // ratio = 2.5 → (2.5 - 1.0) * 100 = 150.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 25.0);
      final result = rule.evaluate(ctx)!;
      final data = result.localizationData as WeekendSpendingLocalizationData;
      expect(data.pct, equals(150));
    });

    test('pct rounds correctly for non-integer ratio', () {
      // weekendAvg = 22.5, weekdayAvg = 10 → ratio = 2.25
      // pct = (2.25 - 1.0) * 100 = 125.
      final ctx = _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 22.5);
      final result = rule.evaluate(ctx)!;
      final data = result.localizationData as WeekendSpendingLocalizationData;
      expect(data.pct, equals(125));
    });
  });

  // -------------------------------------------------------------------------
  // Fired Insight properties
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — Insight properties', () {
    late Insight fired;

    setUp(() {
      // ratio = 3.0, weekdayAmount=10, weekendAmount=30.
      fired = rule.evaluate(
        _ctxWithRatio(weekdayAmount: 10.0, weekendAmount: 30.0),
      )!;
    });

    test('fired Insight has id == \'weekend_spending\'', () {
      expect(fired.id, equals(WeekendSpendingRule.id));
      expect(fired.id, equals('weekend_spending'));
    });

    test('fired Insight has severity == InsightSeverity.warning', () {
      expect(fired.severity, equals(InsightSeverity.warning));
    });

    test('fired Insight body contains the pct value', () {
      // pct = 200 for ratio 3.0.
      expect(fired.body, contains('200'));
    });

    test('fired Insight localizationData is WeekendSpendingLocalizationData',
        () {
      expect(fired.localizationData, isA<WeekendSpendingLocalizationData>());
    });

    test('localizationData.pct matches the computed pct', () {
      final data = fired.localizationData as WeekendSpendingLocalizationData;
      expect(data.pct, equals(200));
    });
  });

  // -------------------------------------------------------------------------
  // Static constants
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — constants', () {
    test('threshold is 2.0', () {
      expect(WeekendSpendingRule.threshold, equals(2.0));
    });

    test('id is \'weekend_spending\'', () {
      expect(WeekendSpendingRule.id, equals('weekend_spending'));
    });
  });

  // -------------------------------------------------------------------------
  // Edge: income and excluded transactions are not counted
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule — filtering', () {
    test('income transactions are not counted in weekend spend', () {
      // Weekend income should NOT inflate weekendTotalSpend.
      // weekendExpense = 30/day, weekdayExpense = 10/day → ratio = 3.0 (fires).
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0),
        _expense(id: 'wd2', day: 5, amount: 10.0),
        _expense(id: 'wd3', day: 6, amount: 10.0),
        _expense(id: 'we1', day: 2, amount: 30.0),
        _expense(id: 'we2', day: 3, amount: 30.0),
        _income(id: 'inc-we', day: 2, amount: 9999.0), // must be ignored
      ]);
      final result = rule.evaluate(ctx)!;
      final data = result.localizationData as WeekendSpendingLocalizationData;
      // ratio should still be 3.0 → pct = 200 (income not counted).
      expect(data.pct, equals(200));
    });

    test('excluded expense transactions are not counted', () {
      // Excluded weekend expenses should NOT count toward weekendTotalSpend.
      // Only the non-excluded txns fire.
      final ctx = _ctx([
        _expense(id: 'wd1', day: 4, amount: 10.0),
        _expense(id: 'wd2', day: 5, amount: 10.0),
        _expense(id: 'wd3', day: 6, amount: 10.0),
        _expense(id: 'we1', day: 2, amount: 30.0),
        _expense(id: 'we2', day: 3, amount: 30.0),
        _excludedExpense(
            id: 'we3-excl', day: 9, amount: 9999.0), // Saturday, excluded
      ]);
      final result = rule.evaluate(ctx)!;
      // weekendDayCount should be 2 (days 2 and 3 only — day 9 is excluded).
      // weekendDailyAvg = 30, weekdayDailyAvg = 10 → ratio = 3.0 → pct = 200.
      final data = result.localizationData as WeekendSpendingLocalizationData;
      expect(data.pct, equals(200));
    });
  });
}
