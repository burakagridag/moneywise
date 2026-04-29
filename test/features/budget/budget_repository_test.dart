// Unit tests for BudgetRepository — budget feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/budget/data/budget_repository.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Inserts a minimal category and returns its id.
Future<String> _createCategory(AppDatabase db) async {
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.categoryDao.insertCategory(
    CategoriesCompanion(
      id: Value(id),
      name: const Value('Food'),
      type: const Value('expense'),
      sortOrder: const Value(0),
      isDefault: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
    ),
  );
  return id;
}

/// Inserts a minimal account and returns its id.
Future<String> _createAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final groupId = groups.first.id;
  final accountId = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(accountId),
      groupId: Value(groupId),
      name: const Value('Wallet'),
      currencyCode: const Value('TRY'),
      initialBalance: const Value(0.0),
      sortOrder: const Value(0),
      isHidden: const Value(false),
      includeInTotals: const Value(true),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return accountId;
}

/// Inserts an expense transaction for [categoryId] during [month] with [amount].
Future<void> _insertExpense(
  AppDatabase db, {
  required String accountId,
  required String categoryId,
  required DateTime month,
  required double amount,
}) async {
  final now = DateTime.now();
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: const Value('expense'),
      date: Value(DateTime(month.year, month.month, 10)),
      amount: Value(amount),
      currencyCode: const Value('TRY'),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      isExcluded: const Value(false),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
}

void main() {
  late AppDatabase db;
  late BudgetRepository repo;

  setUp(() {
    db = _openTestDb();
    repo = BudgetRepository(db.budgetDao);
  });

  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Upsert
  // ---------------------------------------------------------------------------

  group('upsertBudget', () {
    test('inserts a new budget row and returns a valid id', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      final id = await repo.upsertBudget(
        categoryId: categoryId,
        amount: 500.0,
        effectiveFrom: month,
      );

      expect(id, greaterThan(0));
    });

    test('updates an existing budget by id', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      final id = await repo.upsertBudget(
        categoryId: categoryId,
        amount: 500.0,
        effectiveFrom: month,
      );

      await repo.upsertBudget(
        id: id,
        categoryId: categoryId,
        amount: 800.0,
        effectiveFrom: month,
      );

      final budget = await repo.getBudgetForCategory(categoryId, month);
      expect(budget, isNotNull);
      expect(budget!.amount, 800.0);
    });
  });

  // ---------------------------------------------------------------------------
  // watchBudgetsForMonth
  // ---------------------------------------------------------------------------

  group('watchBudgetsForMonth', () {
    test('emits budget active in the queried month', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      await repo.upsertBudget(
        categoryId: categoryId,
        amount: 300.0,
        effectiveFrom: month,
      );

      final budgets = await repo.watchBudgetsForMonth(month).first;
      expect(budgets.length, 1);
      expect(budgets.first.categoryId, categoryId);
      expect(budgets.first.amount, 300.0);
    });

    test('excludes budget whose effectiveTo is before the queried month',
        () async {
      final categoryId = await _createCategory(db);

      // Budget only active in Jan 2026.
      await repo.upsertBudget(
        categoryId: categoryId,
        amount: 200.0,
        effectiveFrom: DateTime(2026, 1),
        effectiveTo: DateTime(2026, 1),
      );

      // Query April 2026 — budget should NOT appear.
      final budgets = await repo.watchBudgetsForMonth(DateTime(2026, 4)).first;
      expect(budgets, isEmpty);
    });

    test('includes open-ended budget for any future month', () async {
      final categoryId = await _createCategory(db);

      await repo.upsertBudget(
        categoryId: categoryId,
        amount: 400.0,
        effectiveFrom: DateTime(2026, 1),
        // effectiveTo is null — open-ended
      );

      final budgets = await repo.watchBudgetsForMonth(DateTime(2026, 12)).first;
      expect(budgets.length, 1);
    });

    test('emits updated list after a second upsert', () async {
      final catId1 = await _createCategory(db);
      final catId2 = await _createCategory(db);
      final month = DateTime(2026, 4);

      await repo.upsertBudget(
        categoryId: catId1,
        amount: 100.0,
        effectiveFrom: month,
      );

      final stream = repo.watchBudgetsForMonth(month);
      final firstEmit = await stream.first;
      expect(firstEmit.length, 1);

      await repo.upsertBudget(
        categoryId: catId2,
        amount: 200.0,
        effectiveFrom: month,
      );

      final secondEmit = await stream.first;
      expect(secondEmit.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteBudget
  // ---------------------------------------------------------------------------

  group('deleteBudget', () {
    test('removes the budget row and returns 1', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      final id = await repo.upsertBudget(
        categoryId: categoryId,
        amount: 500.0,
        effectiveFrom: month,
      );

      final deleted = await repo.deleteBudget(id);
      expect(deleted, 1);

      final budgets = await repo.watchBudgetsForMonth(month).first;
      expect(budgets, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getSpentAmount
  // ---------------------------------------------------------------------------

  group('getSpentAmount', () {
    test('returns 0 when no expenses exist for the category', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      final spent = await repo.getSpentAmount(categoryId, month);
      expect(spent, 0.0);
    });

    test('sums expense amounts for the given category and month', () async {
      final db2 = _openTestDb();
      final repo2 = BudgetRepository(db2.budgetDao);
      final categoryId = await _createCategory(db2);
      final accountId = await _createAccount(db2);
      final month = DateTime(2026, 4);

      await _insertExpense(
        db2,
        accountId: accountId,
        categoryId: categoryId,
        month: month,
        amount: 120.0,
      );
      await _insertExpense(
        db2,
        accountId: accountId,
        categoryId: categoryId,
        month: month,
        amount: 80.0,
      );

      final spent = await repo2.getSpentAmount(categoryId, month);
      expect(spent, 200.0);

      await db2.close();
    });

    test('excludes expenses from other months', () async {
      final db2 = _openTestDb();
      final repo2 = BudgetRepository(db2.budgetDao);
      final categoryId = await _createCategory(db2);
      final accountId = await _createAccount(db2);

      // Expense in March — should not count for April.
      await _insertExpense(
        db2,
        accountId: accountId,
        categoryId: categoryId,
        month: DateTime(2026, 3),
        amount: 500.0,
      );

      final spent = await repo2.getSpentAmount(categoryId, DateTime(2026, 4));
      expect(spent, 0.0);

      await db2.close();
    });

    test('excludes income and transfer transactions', () async {
      final db2 = _openTestDb();
      final repo2 = BudgetRepository(db2.budgetDao);
      final categoryId = await _createCategory(db2);
      final accountId = await _createAccount(db2);
      final month = DateTime(2026, 4);
      final now = DateTime.now();

      // Insert income for the same category — should not count.
      await db2.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('income'),
          date: Value(DateTime(month.year, month.month, 5)),
          amount: const Value(1000.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          isExcluded: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final spent = await repo2.getSpentAmount(categoryId, month);
      expect(spent, 0.0);

      await db2.close();
    });
  });
}
