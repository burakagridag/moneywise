// Unit tests for SavingsGoalRule — insights feature domain layer (EPIC8B-02).
// Covers: income=0 suppression, early-month suppression (day < 5),
// threshold boundary (exclusive), above-threshold suppression,
// firing at 9% and negative rate, and fired Insight id/severity.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/rules/savings_goal_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal income [Transaction] with the given [amount].
Transaction _income({required String id, required double amount}) {
  final date = DateTime(2026, 5, 15);
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

/// Creates a minimal expense [Transaction] with the given [amount].
Transaction _expense({required String id, required double amount}) {
  final date = DateTime(2026, 5, 15);
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

/// Builds an [InsightContext] with the given transactions and reference date.
///
/// [day] defaults to 15 (mid-month) so the day < 5 guard does not interfere
/// unless explicitly tested.
InsightContext _ctx(
  List<Transaction> txns, {
  int day = 15,
}) =>
    InsightContext(
      currentMonthTransactions: txns,
      previousMonthTransactions: const [],
      currentMonthBudgets: const [],
      effectiveBudget: null,
      referenceDate: DateTime(2026, 5, day),
      formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const rule = SavingsGoalRule();

  // -------------------------------------------------------------------------
  // Suppression: income == 0
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — suppressed when income is 0', () {
    test('returns null when there are no transactions (income = 0)', () {
      // EDGE CASE: no income data at all — division by zero is meaningless.
      final result = rule.evaluate(_ctx(const []));
      expect(result, isNull);
    });

    test('returns null when only expense transactions exist (income = 0)', () {
      // EDGE CASE: user logged expenses but no income yet — suppress insight.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 500.0),
      ]));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Suppression: too early in the month (day < 5)
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — suppressed when referenceDate.day < 5', () {
    test('returns null on day 1 even if savings rate is below threshold', () {
      // 91% spend of 1000 income → savings rate ≈ 0.09 < 0.10, but day = 1.
      final result = rule.evaluate(_ctx(
        [
          _income(id: 'i1', amount: 1000.0),
          _expense(id: 'e1', amount: 910.0),
        ],
        day: 1,
      ));
      expect(result, isNull);
    });

    test('returns null on day 4 even if savings rate is below threshold', () {
      // 91% spend → savings rate ≈ 0.09 < 0.10, but day < minimumDayOfMonth.
      final result = rule.evaluate(_ctx(
        [
          _income(id: 'i1', amount: 1000.0),
          _expense(id: 'e1', amount: 910.0),
        ],
        day: SavingsGoalRule.minimumDayOfMonth - 1,
      ));
      expect(result, isNull);
    });

    test('does NOT suppress on day 5 (first eligible day)', () {
      // 91% spend → savings rate ≈ 0.09 < 0.10, day = minimumDayOfMonth → should fire.
      final result = rule.evaluate(_ctx(
        [
          _income(id: 'i1', amount: 1000.0),
          _expense(id: 'e1', amount: 910.0),
        ],
        day: SavingsGoalRule.minimumDayOfMonth,
      ));
      expect(result, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Threshold boundary: exactly 10% must NOT fire (exclusive < threshold)
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — threshold boundary', () {
    test('returns null when savings rate is exactly 10% (threshold exclusive)',
        () {
      // income = 1000, expense = 900 → savings = 100 → rate = 0.10 exactly.
      // Condition is strictly < 0.10; 10% must NOT trigger the rule.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
        _expense(id: 'e1', amount: 900.0),
      ]));
      expect(result, isNull);
    });

    test('returns null when savings rate is 15% (above threshold)', () {
      // income = 1000, expense = 850 → savings = 150 → rate = 0.15 > 0.10.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
        _expense(id: 'e1', amount: 850.0),
      ]));
      expect(result, isNull);
    });

    test('returns null when savings rate is 100% (no expenses)', () {
      // income = 1000, no expenses → rate = 1.0.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
      ]));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firing conditions
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — fires when condition is met', () {
    test('fires when savings rate is 9% (just below 10% threshold)', () {
      // income = 1000, expense = 910 → savings = 90 → rate = 0.09 < 0.10.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
        _expense(id: 'e1', amount: 910.0),
      ]));
      expect(result, isNotNull);
    });

    test('fires when savings rate is 0% (spending equals income)', () {
      // income = 1000, expense = 1000 → rate = 0.0 < 0.10.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
        _expense(id: 'e1', amount: 1000.0),
      ]));
      expect(result, isNotNull);
    });

    test('fires when savings rate is negative (spending exceeds income)', () {
      // income = 500, expense = 800 → savings = -300 → rate = -0.60 < 0.10.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 500.0),
        _expense(id: 'e1', amount: 800.0),
      ]));
      expect(result, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Fired Insight properties
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — Insight properties when fired', () {
    late Insight fired;

    setUp(() {
      // 9% savings rate — guaranteed to fire.
      fired = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 1000.0),
        _expense(id: 'e1', amount: 910.0),
      ]))!;
    });

    test('fired Insight has id == \'savings_goal\'', () {
      expect(fired.id, equals(SavingsGoalRule.id));
      expect(fired.id, equals('savings_goal'));
    });

    test('fired Insight has severity == InsightSeverity.warning', () {
      expect(fired.severity, equals(InsightSeverity.warning));
    });

    test('fired Insight headline is not empty', () {
      expect(fired.headline, isNotEmpty);
    });

    test('fired Insight body mentions 10%', () {
      // The body must reference "10%" to match the sponsor-approved copy.
      expect(fired.body, contains('10%'));
    });
  });

  // -------------------------------------------------------------------------
  // Static constants
  // -------------------------------------------------------------------------

  group('SavingsGoalRule — constants', () {
    test('threshold is 0.10 (10%) per ADR-013', () {
      expect(SavingsGoalRule.threshold, equals(0.10));
    });

    test('minimumDayOfMonth is 5 per ADR-013', () {
      expect(SavingsGoalRule.minimumDayOfMonth, equals(5));
    });

    test('id is \'savings_goal\'', () {
      expect(SavingsGoalRule.id, equals('savings_goal'));
    });
  });
}
