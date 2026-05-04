// Unit tests for ConcentrationRule — insights feature domain layer (EPIC8B-01).
// Covers: null guards, threshold boundary, firing at 71% and 100%, id/severity
// assertions, and body percentage accuracy.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/rules/concentration_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal expense [Transaction] for a given category and amount.
Transaction _expense({
  required String id,
  required double amount,
  String? categoryId,
}) {
  final now = DateTime(2026, 5, 15);
  return Transaction(
    id: id,
    type: 'expense',
    date: now,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: categoryId,
    isExcluded: false,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

/// Creates a minimal income [Transaction].
Transaction _income({required String id, required double amount}) {
  final now = DateTime(2026, 5, 15);
  return Transaction(
    id: id,
    type: 'income',
    date: now,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: null,
    isExcluded: false,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

/// Builds an [InsightContext] from a list of transactions.
InsightContext _ctx(List<Transaction> txns) => InsightContext(
      currentMonthTransactions: txns,
      previousMonthTransactions: const [],
      currentMonthBudgets: const [],
      effectiveBudget: null,
      referenceDate: DateTime(2026, 5, 15),
      formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const rule = ConcentrationRule();

  // -------------------------------------------------------------------------
  // Null-guard: totalMonthlySpend == 0
  // -------------------------------------------------------------------------

  group('ConcentrationRule — null guards', () {
    test('returns null when totalMonthlySpend is 0 (no expense transactions)',
        () {
      // EDGE CASE: no expenses at all — must not divide by zero.
      final result = rule.evaluate(_ctx(const []));
      expect(result, isNull);
    });

    test('returns null when only income transactions exist', () {
      // Income does not count towards totalMonthlySpend.
      final result = rule.evaluate(_ctx([
        _income(id: 'i1', amount: 3000.0),
      ]));
      expect(result, isNull);
    });

    test('returns null when spendByCategory is empty', () {
      // Even if totalMonthlySpend > 0, an empty spendByCategory map has no
      // top entry to evaluate. This guards against future changes where
      // totalMonthlySpend could be non-zero but spendByCategory is empty.
      // In the current implementation both guards are equivalent for this
      // scenario, but we test the documented precondition explicitly.
      final result = rule.evaluate(_ctx(const []));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Threshold boundary: exactly 70% must NOT fire
  // -------------------------------------------------------------------------

  group('ConcentrationRule — threshold boundary', () {
    test('returns null when top category is exactly 70% of total spend', () {
      // Condition is strictly > 70%; 70% must NOT trigger the rule.
      // food = 70, other = 30 → ratio = 0.70 exactly.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 70.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 30.0, categoryId: 'other'),
      ]));
      expect(result, isNull);
    });

    test('returns null when top category is below 70% of total spend', () {
      // food = 60, other = 40 → ratio = 0.60.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 60.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 40.0, categoryId: 'other'),
      ]));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firing conditions
  // -------------------------------------------------------------------------

  group('ConcentrationRule — fires when condition is met', () {
    test('fires when top category is 71% of total spend', () {
      // food = 71, other = 29 → ratio ≈ 0.71 > 0.70.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 71.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 29.0, categoryId: 'other'),
      ]));
      expect(result, isNotNull);
    });

    test('fires when top category is 100% of total spend (single category)',
        () {
      // Only one category; ratio = 1.0.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 500.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 200.0, categoryId: 'food'),
      ]));
      expect(result, isNotNull);
    });

    test('selects the highest-spend category as the top entry', () {
      // travel = 800, food = 200, total = 1000, ratio_travel = 0.80 > 0.70.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 200.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 800.0, categoryId: 'travel'),
      ]));
      expect(result, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Fired Insight properties
  // -------------------------------------------------------------------------

  group('ConcentrationRule — Insight properties', () {
    late Insight fired;

    setUp(() {
      // food = 71, other = 29 → 71% → pct = 71.
      fired = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 71.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 29.0, categoryId: 'other'),
      ]))!;
    });

    test('fired Insight has id == \'concentration\'', () {
      expect(fired.id, equals(ConcentrationRule.id));
      expect(fired.id, equals('concentration'));
    });

    test('fired Insight has severity == InsightSeverity.warning', () {
      expect(fired.severity, equals(InsightSeverity.warning));
    });

    test('fired Insight body contains the correct integer percentage', () {
      // 71 / 100 = 0.71 → round(71.0) = 71.
      expect(fired.body, contains('71%'));
    });

    test('fired Insight body rounds percentage correctly for 100% case', () {
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 1000.0, categoryId: 'food'),
      ]))!;
      expect(result.body, contains('100%'));
    });

    test('fired Insight body rounds percentage correctly for fractional ratio',
        () {
      // food = 750, other = 250 → ratio = 0.75 → pct = 75.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 750.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 250.0, categoryId: 'other'),
      ]))!;
      expect(result.body, contains('75%'));
    });
  });

  // -------------------------------------------------------------------------
  // Income and transfers are excluded from totalMonthlySpend
  // -------------------------------------------------------------------------

  group('ConcentrationRule — income and transfers excluded', () {
    test('income transactions do not affect the concentration ratio', () {
      // Expense: food = 80, other = 20 → ratio = 0.80 (fires).
      // Adding income must not dilute the expense ratio.
      final result = rule.evaluate(_ctx([
        _expense(id: 'e1', amount: 80.0, categoryId: 'food'),
        _expense(id: 'e2', amount: 20.0, categoryId: 'other'),
        _income(id: 'i1', amount: 5000.0),
      ]));
      expect(result, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // Static constants
  // -------------------------------------------------------------------------

  group('ConcentrationRule — constants', () {
    test('threshold is 0.70', () {
      expect(ConcentrationRule.threshold, equals(0.70));
    });

    test('id is \'concentration\'', () {
      expect(ConcentrationRule.id, equals('concentration'));
    });
  });
}
