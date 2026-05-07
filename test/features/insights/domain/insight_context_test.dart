// Unit tests for InsightContext computed properties — insights feature (EPIC8B-05).
// Verifies derived values: totalMonthlySpend, savingsRate, remainingBudget,
// spendByCategory. Covers the income=0 edge case for savingsRate.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal [Transaction] for testing.
Transaction _makeTx({
  required String id,
  required String type,
  required double amount,
  String? categoryId,
  bool isExcluded = false,
  bool isDeleted = false,
}) {
  final now = DateTime(2026, 5, 15);
  return Transaction(
    id: id,
    type: type,
    date: now,
    amount: amount,
    currencyCode: 'EUR',
    accountId: 'acc-1',
    categoryId: categoryId,
    isExcluded: isExcluded,
    isDeleted: isDeleted,
    createdAt: now,
    updatedAt: now,
  );
}

/// Returns an empty [InsightContext] with the given transactions.
InsightContext _ctx({
  List<Transaction> txns = const [],
  double? effectiveBudget,
}) {
  return InsightContext(
    currentMonthTransactions: txns,
    previousMonthTransactions: const [],
    currentMonthBudgets: const [],
    effectiveBudget: effectiveBudget,
    referenceDate: DateTime(2026, 5, 15),
    formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // totalMonthlySpend
  // -------------------------------------------------------------------------

  group('InsightContext.totalMonthlySpend', () {
    test('returns 0.0 when there are no transactions', () {
      expect(_ctx().totalMonthlySpend, equals(0.0));
    });

    test('sums only expense transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0),
          _makeTx(id: 'i1', type: 'income', amount: 500.0),
          _makeTx(id: 't1', type: 'transfer', amount: 200.0),
        ],
      );
      expect(ctx.totalMonthlySpend, equals(100.0));
    });

    test('excludes isExcluded transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0),
          _makeTx(id: 'e2', type: 'expense', amount: 50.0, isExcluded: true),
        ],
      );
      expect(ctx.totalMonthlySpend, equals(100.0));
    });

    test('excludes isDeleted transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0),
          _makeTx(id: 'e2', type: 'expense', amount: 50.0, isDeleted: true),
        ],
      );
      expect(ctx.totalMonthlySpend, equals(100.0));
    });

    test('sums multiple valid expense transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0),
          _makeTx(id: 'e2', type: 'expense', amount: 250.0),
          _makeTx(id: 'e3', type: 'expense', amount: 50.0),
        ],
      );
      expect(ctx.totalMonthlySpend, equals(400.0));
    });
  });

  // -------------------------------------------------------------------------
  // totalMonthlyIncome
  // -------------------------------------------------------------------------

  group('InsightContext.totalMonthlyIncome', () {
    test('returns 0.0 when no income transactions exist', () {
      expect(_ctx().totalMonthlyIncome, equals(0.0));
    });

    test('sums only income transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'i1', type: 'income', amount: 1000.0),
          _makeTx(id: 'i2', type: 'income', amount: 500.0),
          _makeTx(id: 'e1', type: 'expense', amount: 200.0),
        ],
      );
      expect(ctx.totalMonthlyIncome, equals(1500.0));
    });

    test('excludes isExcluded income transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'i1', type: 'income', amount: 1000.0),
          _makeTx(id: 'i2', type: 'income', amount: 500.0, isExcluded: true),
        ],
      );
      expect(ctx.totalMonthlyIncome, equals(1000.0));
    });
  });

  // -------------------------------------------------------------------------
  // savingsRate — EDGE CASE: income = 0
  // -------------------------------------------------------------------------

  group('InsightContext.savingsRate', () {
    test('returns 0.0 when income is zero (edge case: no income this month)',
        () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 200.0),
        ],
      );
      // EDGE CASE: income = 0 → savingsRate must be 0.0, not NaN or infinity.
      expect(ctx.savingsRate, equals(0.0));
    });

    test('returns 0.0 when income and expenses are both zero', () {
      expect(_ctx().savingsRate, equals(0.0));
    });

    test('computes correct savings rate when income > expenses', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'i1', type: 'income', amount: 1000.0),
          _makeTx(id: 'e1', type: 'expense', amount: 700.0),
        ],
      );
      // (1000 - 700) / 1000 = 0.30
      expect(ctx.savingsRate, closeTo(0.30, 0.0001));
    });

    test('computes savings rate of 1.0 when there are no expenses', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'i1', type: 'income', amount: 1000.0),
        ],
      );
      // (1000 - 0) / 1000 = 1.0
      expect(ctx.savingsRate, closeTo(1.0, 0.0001));
    });

    test('returns negative value when expenses exceed income', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'i1', type: 'income', amount: 500.0),
          _makeTx(id: 'e1', type: 'expense', amount: 800.0),
        ],
      );
      // (500 - 800) / 500 = -0.60
      expect(ctx.savingsRate, closeTo(-0.60, 0.0001));
    });
  });

  // -------------------------------------------------------------------------
  // remainingBudget
  // -------------------------------------------------------------------------

  group('InsightContext.remainingBudget', () {
    test('returns null when effectiveBudget is null', () {
      final ctx = _ctx(
        txns: [_makeTx(id: 'e1', type: 'expense', amount: 200.0)],
        effectiveBudget: null,
      );
      expect(ctx.remainingBudget, isNull);
    });

    test('returns effectiveBudget when no expenses', () {
      final ctx = _ctx(effectiveBudget: 1000.0);
      expect(ctx.remainingBudget, equals(1000.0));
    });

    test('deducts totalMonthlySpend from effectiveBudget', () {
      final ctx = _ctx(
        txns: [_makeTx(id: 'e1', type: 'expense', amount: 300.0)],
        effectiveBudget: 1000.0,
      );
      expect(ctx.remainingBudget, closeTo(700.0, 0.0001));
    });

    test('goes negative when spending exceeds budget', () {
      final ctx = _ctx(
        txns: [_makeTx(id: 'e1', type: 'expense', amount: 1200.0)],
        effectiveBudget: 1000.0,
      );
      expect(ctx.remainingBudget, closeTo(-200.0, 0.0001));
    });
  });

  // -------------------------------------------------------------------------
  // spendByCategory
  // -------------------------------------------------------------------------

  group('InsightContext.spendByCategory', () {
    test('returns empty map when no transactions', () {
      expect(_ctx().spendByCategory, isEmpty);
    });

    test('groups expenses by categoryId', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0, categoryId: 'food'),
          _makeTx(id: 'e2', type: 'expense', amount: 50.0, categoryId: 'food'),
          _makeTx(
              id: 'e3', type: 'expense', amount: 200.0, categoryId: 'travel'),
        ],
      );
      final map = ctx.spendByCategory;
      expect(map['food'], closeTo(150.0, 0.0001));
      expect(map['travel'], closeTo(200.0, 0.0001));
    });

    test('uses empty string key for null categoryId', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 75.0, categoryId: null),
        ],
      );
      expect(ctx.spendByCategory[''], closeTo(75.0, 0.0001));
    });

    test('excludes income and transfer transactions', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0, categoryId: 'food'),
          _makeTx(id: 'i1', type: 'income', amount: 500.0, categoryId: 'food'),
          _makeTx(
              id: 't1', type: 'transfer', amount: 200.0, categoryId: 'food'),
        ],
      );
      final map = ctx.spendByCategory;
      expect(map.length, equals(1));
      expect(map['food'], closeTo(100.0, 0.0001));
    });

    test('excludes isExcluded and isDeleted expenses', () {
      final ctx = _ctx(
        txns: [
          _makeTx(id: 'e1', type: 'expense', amount: 100.0, categoryId: 'food'),
          _makeTx(
              id: 'e2',
              type: 'expense',
              amount: 50.0,
              categoryId: 'food',
              isExcluded: true),
          _makeTx(
              id: 'e3',
              type: 'expense',
              amount: 30.0,
              categoryId: 'food',
              isDeleted: true),
        ],
      );
      expect(ctx.spendByCategory['food'], closeTo(100.0, 0.0001));
    });
  });
}
