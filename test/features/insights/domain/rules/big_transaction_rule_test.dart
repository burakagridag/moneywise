// Unit tests for BigTransactionRule — insights feature domain layer (EPIC8B-04).
// Covers: null/zero budget guards, no-expense guard, unbudgeted-category guard
// (Sponsor constraint), threshold boundary (exclusive), firing at 31% and 50%,
// Insight id/severity, body percentage accuracy, and excluded/deleted filtering.
// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:moneywise/features/budget/domain/budget_entity.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/rules/big_transaction_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal expense [Transaction] for a given category and amount.
Transaction _expense({
  required String id,
  required double amount,
  String? categoryId,
  bool isExcluded = false,
  bool isDeleted = false,
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
    isExcluded: isExcluded,
    isDeleted: isDeleted,
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

/// Creates a [BudgetWithSpending] for a given category id with no carry-over.
BudgetWithSpending _budget(String categoryId) {
  final now = DateTime(2026, 5, 1);
  return BudgetWithSpending(
    budget: BudgetEntity(
      id: 1,
      categoryId: categoryId,
      amount: 500.0,
      effectiveFrom: now,
      createdAt: now,
      updatedAt: now,
    ),
    spent: 0.0,
    carryOver: 0.0,
  );
}

/// Builds an [InsightContext] with controllable transactions, budgets and
/// effective budget ceiling.
///
/// [formatAmount] defaults to a simple euro lambda so tests exercise the
/// approved body wording without requiring a real [CurrencyFormatter].
InsightContext _ctx(
  List<Transaction> txns, {
  List<BudgetWithSpending> budgets = const [],
  double? effectiveBudget,
}) =>
    InsightContext(
      currentMonthTransactions: txns,
      previousMonthTransactions: const [],
      currentMonthBudgets: budgets,
      effectiveBudget: effectiveBudget,
      referenceDate: DateTime(2026, 5, 15),
      formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const rule = BigTransactionRule();

  // -------------------------------------------------------------------------
  // Guard: effectiveBudget is null
  // -------------------------------------------------------------------------

  group('BigTransactionRule — returns null when effectiveBudget is null', () {
    test('returns null when effectiveBudget is null (no budget configured)',
        () {
      // EDGE CASE: no budget set — rule has no ceiling to compare against.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: null,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: effectiveBudget is zero or negative
  // -------------------------------------------------------------------------

  group('BigTransactionRule — returns null when effectiveBudget <= 0', () {
    test('returns null when effectiveBudget is exactly 0', () {
      // EDGE CASE: zero budget ceiling — any amount would exceed it trivially;
      // suppress to avoid noisy false-positive.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 1.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 0.0,
      ));
      expect(result, isNull);
    });

    test('returns null when effectiveBudget is negative', () {
      // EDGE CASE: negative budget (e.g. full carry-over) — suppress.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 1.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: -100.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: no expense transactions
  // -------------------------------------------------------------------------

  group('BigTransactionRule — returns null when no expense transactions exist',
      () {
    test('returns null when currentMonthTransactions is empty', () {
      // EDGE CASE: no transactions at all — nothing to evaluate.
      final result = rule.evaluate(_ctx(
        const [],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test('returns null when only income transactions exist', () {
      // Income does not count as an expense — no biggest expense to evaluate.
      final result = rule.evaluate(_ctx(
        [_income(id: 'i1', amount: 5000.0)],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Guard: largest expense is in an unbudgeted category (Sponsor constraint)
  // -------------------------------------------------------------------------

  group(
      'BigTransactionRule — returns null when largest expense is in unbudgeted '
      'category', () {
    test('returns null when the biggest transaction has no matching budget',
        () {
      // Sponsor decision: rule only fires for budgeted categories.
      // 'food' is the biggest expense but there is no budget for 'food'.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: 'food')],
        budgets: [_budget('travel')], // 'food' is NOT in budgets
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test('returns null when budgets list is empty (all categories unbudgeted)',
        () {
      // No budgets at all — every category is unbudgeted.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: 'food')],
        budgets: const [],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test(
        'returns null when biggest expense has null categoryId and null is not '
        'in budgets', () {
      // A transaction with null category cannot match any budget's categoryId.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: null)],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Threshold boundary: exactly 30% must NOT fire (strictly greater than)
  // -------------------------------------------------------------------------

  group('BigTransactionRule — threshold boundary', () {
    test(
        'returns null when largest expense is exactly 30% of effectiveBudget '
        '(boundary is exclusive)', () {
      // effectiveBudget = 1000, expense = 300 → ratio = 0.30 exactly.
      // Condition is strictly > 30%; exactly 30% must NOT fire.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 300.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });

    test('returns null when largest expense is below 30%', () {
      // effectiveBudget = 1000, expense = 200 → ratio = 0.20 < 0.30.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 200.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Firing conditions
  // -------------------------------------------------------------------------

  group('BigTransactionRule — fires when condition is met', () {
    test(
        'fires when largest expense is 31% of effectiveBudget and category is '
        'budgeted', () {
      // effectiveBudget = 1000, expense = 310 → ratio = 0.31 > 0.30.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 310.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNotNull);
    });

    test(
        'fires when largest expense is 50% of effectiveBudget and category is '
        'budgeted', () {
      // effectiveBudget = 1000, expense = 500 → ratio = 0.50 > 0.30.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNotNull);
    });

    test(
        'selects the largest expense when multiple expenses exist and only the '
        'largest exceeds threshold', () {
      // effectiveBudget = 1000, biggest = 400 (food, 40%), smaller = 100 (travel).
      // food has a budget → should fire based on the 400 expense.
      final result = rule.evaluate(_ctx(
        [
          _expense(id: 'e1', amount: 100.0, categoryId: 'travel'),
          _expense(id: 'e2', amount: 400.0, categoryId: 'food'),
        ],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNotNull);
    });

    test(
        'returns null when largest expense belongs to an unbudgeted category '
        'even if a smaller budgeted expense exceeds threshold', () {
      // effectiveBudget = 1000.
      // Biggest: 'travel' = 500 (50%) — but travel is unbudgeted.
      // Second: 'food' = 400 (40%) — food IS budgeted.
      // Rule evaluates ONLY the biggest transaction; food is not evaluated.
      final result = rule.evaluate(_ctx(
        [
          _expense(id: 'e1', amount: 400.0, categoryId: 'food'),
          _expense(id: 'e2', amount: 500.0, categoryId: 'travel'),
        ],
        budgets: [_budget('food')], // 'travel' is NOT budgeted
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Fired Insight properties
  // -------------------------------------------------------------------------

  group('BigTransactionRule — Insight properties when fired', () {
    late Insight fired;

    setUp(() {
      // effectiveBudget = 1000, expense = 500 → ratio = 0.50 → pct = 50.
      fired = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 500.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ))!;
    });

    test("fired Insight has id == 'big_transaction'", () {
      expect(fired.id, equals(BigTransactionRule.id));
      expect(fired.id, equals('big_transaction'));
    });

    test('fired Insight has severity == InsightSeverity.warning', () {
      expect(fired.severity, equals(InsightSeverity.warning));
    });

    test('fired Insight body contains the correct integer percentage (50%)',
        () {
      // 500 / 1000 = 0.50 → round(50.0) = 50.
      expect(fired.body, contains('50%'));
    });

    test(
        'fired Insight body contains the formatted amount with currency symbol',
        () {
      // Sponsor-approved wording (2026-05-06): headline says "Large transaction",
      // so body starts directly with the formatted amount.
      // formatAmount lambda produces '€500.00' for amount 500.0.
      expect(fired.body, contains('€500.00'));
    });

    test('fired Insight body matches Sponsor-approved wording template', () {
      // Full body for amount=500, budget=1000, pct=50:
      // '€500.00 (50% of budget)'
      expect(
        fired.body,
        equals('€500.00 (50% of budget)'),
      );
    });

    test('fired Insight body contains correct percentage for 31% case', () {
      // effectiveBudget = 1000, expense = 310 → ratio = 0.31 → pct = 31.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 310.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ))!;
      expect(result.body, contains('31%'));
    });

    test('fired Insight body rounds fractional percentage correctly', () {
      // effectiveBudget = 1000, expense = 333 → ratio = 0.333 → pct = 33.
      final result = rule.evaluate(_ctx(
        [_expense(id: 'e1', amount: 333.0, categoryId: 'food')],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ))!;
      expect(result.body, contains('33%'));
    });

    test('fired Insight headline is not empty', () {
      expect(fired.headline, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Excluded and deleted transactions are ignored
  // -------------------------------------------------------------------------

  group(
      'BigTransactionRule — excluded and deleted transactions are not '
      'considered when finding the largest expense', () {
    test('excluded transaction is not counted as the largest expense', () {
      // The excluded 900 expense would have triggered the rule, but it must be
      // ignored. The only eligible expense is 200, which is 20% — below threshold.
      final result = rule.evaluate(_ctx(
        [
          _expense(
            id: 'e1',
            amount: 900.0,
            categoryId: 'food',
            isExcluded: true, // must be ignored
          ),
          _expense(id: 'e2', amount: 200.0, categoryId: 'food'),
        ],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      // 200 / 1000 = 0.20 ≤ 0.30 → null.
      expect(result, isNull);
    });

    test('deleted transaction is not counted as the largest expense', () {
      // The deleted 900 expense must be ignored.
      // Only eligible expense is 200 (20% of 1000) — below threshold.
      final result = rule.evaluate(_ctx(
        [
          _expense(
            id: 'e1',
            amount: 900.0,
            categoryId: 'food',
            isDeleted: true, // must be ignored
          ),
          _expense(id: 'e2', amount: 200.0, categoryId: 'food'),
        ],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      // 200 / 1000 = 0.20 ≤ 0.30 → null.
      expect(result, isNull);
    });

    test(
        'returns null when all expense transactions are excluded/deleted and '
        'no eligible expenses remain', () {
      // Both expenses are excluded/deleted → no eligible expenses → null.
      final result = rule.evaluate(_ctx(
        [
          _expense(
              id: 'e1', amount: 900.0, categoryId: 'food', isExcluded: true),
          _expense(
              id: 'e2', amount: 800.0, categoryId: 'food', isDeleted: true),
        ],
        budgets: [_budget('food')],
        effectiveBudget: 1000.0,
      ));
      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Static constants
  // -------------------------------------------------------------------------

  group('BigTransactionRule — constants', () {
    test('threshold is 0.30 (30%) per ADR-013', () {
      expect(BigTransactionRule.threshold, equals(0.30));
    });

    test("id is 'big_transaction'", () {
      expect(BigTransactionRule.id, equals('big_transaction'));
    });
  });
}
