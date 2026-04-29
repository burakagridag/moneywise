// In-memory DB tests for BudgetDao — budget/data.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
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
      currencyCode: const Value('EUR'),
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

/// Inserts a budget row for [categoryId] active in [month] and returns the row id.
String _monthKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  return '$y-$m-01';
}

Future<int> _insertBudget(
  AppDatabase db, {
  required String categoryId,
  required DateTime month,
  double amount = 500.0,
  DateTime? effectiveTo,
}) async {
  final now = DateTime.now().toIso8601String();
  return db.budgetDao.upsertBudget(
    BudgetsCompanion(
      categoryId: Value(categoryId),
      amount: Value(amount),
      effectiveFrom: Value(_monthKey(month)),
      effectiveTo: effectiveTo != null
          ? Value(_monthKey(effectiveTo))
          : const Value.absent(),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
}

/// Inserts an expense transaction for [categoryId] on [date].
Future<void> _insertExpense(
  AppDatabase db, {
  required String accountId,
  required String categoryId,
  required DateTime date,
  required double amount,
  bool isExcluded = false,
}) async {
  final now = DateTime.now();
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: const Value('expense'),
      date: Value(date),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      isExcluded: Value(isExcluded),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
}

/// Inserts an income transaction for [categoryId] on [date].
Future<void> _insertIncome(
  AppDatabase db, {
  required String accountId,
  required String categoryId,
  required DateTime date,
  required double amount,
}) async {
  final now = DateTime.now();
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: const Value('income'),
      date: Value(date),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
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

  setUp(() {
    db = _openTestDb();
  });

  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // watchBudgetsForMonth / getBudgetForCategory
  // ---------------------------------------------------------------------------

  group('BudgetDao — active budget queries', () {
    test('should_return_active_budget_for_month', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      await _insertBudget(db, categoryId: categoryId, month: month);

      final budget = await db.budgetDao.getBudgetForCategory(categoryId, month);

      expect(budget, isNotNull);
      expect(budget!.categoryId, categoryId);
      expect(budget.amount, 500.0);
    });

    test('should_not_return_expired_budget (effectiveTo in past)', () async {
      final categoryId = await _createCategory(db);
      // Budget only active in January 2026
      await _insertBudget(
        db,
        categoryId: categoryId,
        month: DateTime(2026, 1),
        effectiveTo: DateTime(2026, 1), // expires after January
      );

      // Query April 2026 — budget should not appear
      final budget = await db.budgetDao
          .getBudgetForCategory(categoryId, DateTime(2026, 4));

      expect(budget, isNull);
    });

    test('should_preserve_createdAt_on_upsert_conflict', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);
      const originalNow = '2026-01-15T10:00:00.000';

      // Insert with a fixed createdAt
      final rowId = await db.budgetDao.upsertBudget(
        BudgetsCompanion(
          categoryId: Value(categoryId),
          amount: const Value(300.0),
          effectiveFrom: const Value('2026-04-01'),
          createdAt: const Value(originalNow),
          updatedAt: const Value(originalNow),
        ),
      );

      // Upsert again with updated amount and a new createdAt
      await db.budgetDao.upsertBudget(
        BudgetsCompanion(
          id: Value(rowId),
          categoryId: Value(categoryId),
          amount: const Value(800.0),
          effectiveFrom: const Value('2026-04-01'),
          createdAt:
              const Value('2099-01-01T00:00:00.000'), // should be ignored
          updatedAt: const Value('2026-04-29T12:00:00.000'),
        ),
      );

      final budget = await db.budgetDao.getBudgetForCategory(categoryId, month);

      expect(budget, isNotNull);
      expect(budget!.amount, 800.0);
      // createdAt must not be overwritten by the upsert
      expect(budget.createdAt, originalNow);
    });
  });

  // ---------------------------------------------------------------------------
  // getSpentAmount
  // ---------------------------------------------------------------------------

  group('BudgetDao.getSpentAmount', () {
    test('zero spending returns 0.0', () async {
      final categoryId = await _createCategory(db);
      final month = DateTime(2026, 4);

      final spent = await db.budgetDao.getSpentAmount(categoryId, month);

      expect(spent, 0.0);
    });

    test('sums multiple expense transactions for the category in the month',
        () async {
      final categoryId = await _createCategory(db);
      final accountId = await _createAccount(db);
      final month = DateTime(2026, 4);

      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 4, 5),
        amount: 120.0,
      );
      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 4, 20),
        amount: 80.0,
      );

      final spent = await db.budgetDao.getSpentAmount(categoryId, month);

      expect(spent, closeTo(200.0, 0.001));
    });

    test('expense outside date range is not included', () async {
      final categoryId = await _createCategory(db);
      final accountId = await _createAccount(db);

      // Expense in March — should not count for April
      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 3, 31),
        amount: 999.0,
      );
      // Expense on first day of May — should not count for April
      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 5, 1),
        amount: 999.0,
      );

      final spent =
          await db.budgetDao.getSpentAmount(categoryId, DateTime(2026, 4));

      expect(spent, 0.0);
    });

    test('type=income transactions are not included in spending sum', () async {
      final categoryId = await _createCategory(db);
      final accountId = await _createAccount(db);
      final month = DateTime(2026, 4);

      await _insertIncome(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 4, 10),
        amount: 1000.0,
      );

      final spent = await db.budgetDao.getSpentAmount(categoryId, month);

      expect(spent, 0.0);
    });

    test('December month boundary does not overflow into next year', () async {
      final categoryId = await _createCategory(db);
      final accountId = await _createAccount(db);
      final december = DateTime(2026, 12);

      // Expense inside December
      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2026, 12, 15),
        amount: 50.0,
      );

      // Expense in January of the next year — must NOT be counted
      await _insertExpense(
        db,
        accountId: accountId,
        categoryId: categoryId,
        date: DateTime(2027, 1, 1),
        amount: 999.0,
      );

      final spent = await db.budgetDao.getSpentAmount(categoryId, december);

      expect(spent, closeTo(50.0, 0.001));
    });
  });
}
