// Unit tests for effectiveSpentProvider — verifies month isolation fix — home feature.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/home/presentation/providers/user_settings_providers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Helpers — in-memory Drift database
// ---------------------------------------------------------------------------

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

(ProviderContainer, AppDatabase) _buildContainer() {
  final db = _openTestDb();
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
  );
  return (container, db);
}

/// Inserts a minimal account row and returns its id.
Future<String> _seedAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final groupId = groups.first.id;
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: const Value('Test Account'),
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
  return id;
}

/// Inserts a transaction with the given [type] and [amount] on [date].
Future<void> _seedTransaction(
  AppDatabase db, {
  required String accountId,
  required String type,
  required double amount,
  required DateTime date,
  bool isExcluded = false,
  bool isDeleted = false,
}) async {
  final now = DateTime.now();
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: Value(type),
      date: Value(date),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
      exchangeRate: const Value(1.0),
      accountId: Value(accountId),
      isExcluded: Value(isExcluded),
      isDeleted: Value(isDeleted),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('effectiveSpentProvider', () {
    // Test 1 — Global budget mode: uses explicit month parameter, not
    // selectedMonthProvider. Verifies the month isolation fix (HOTFIX-04).
    test('should_return_all_expenses_when_global_budget_is_set', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // Set a global budget ceiling so the provider enters global-budget mode.
      await db.userSettingsDao.upsertGlobalBudget(500.0);

      final accountId = await _seedAccount(db);
      final month = DateTime(2026, 5);

      // Seed two expenses and one income for May 2026.
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 50.0,
        date: DateTime(2026, 5, 10),
      );
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 30.0,
        date: DateTime(2026, 5, 20),
      );
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'income',
        amount: 100.0,
        date: DateTime(2026, 5, 15),
      );

      // Seed an expense in a DIFFERENT month to confirm month isolation.
      // This transaction must NOT be included in the result for May 2026.
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 999.0,
        date: DateTime(2026, 11, 1), // November — wrong month
      );

      final result = await container.read(effectiveSpentProvider(month).future);

      // Only May expenses count: 50 + 30 = 80.
      // Income is excluded. November expense is excluded (wrong month).
      expect(result, closeTo(80.0, 0.001));
    });

    // Test 2 — Fallback (category-budget) mode: delegates to totalBudgetProvider.
    test('should_return_only_budgeted_category_spend_when_no_global_budget',
        () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // No global budget — provider must use totalBudgetProvider fallback.
      final global = await container.read(globalBudgetProvider.future);
      expect(global, isNull,
          reason: 'Precondition: global budget must be null');

      final accountId = await _seedAccount(db);
      final month = DateTime(2026, 5);

      // Seed the expense category and a budget row for it.
      final categories = await db.categoryDao.getByType('expense');
      final categoryId = categories.first.id;

      await db.budgetDao.upsertBudget(
        BudgetsCompanion.insert(
          categoryId: categoryId,
          amount: 11.50,
          effectiveFrom: '2026-05-01',
          createdAt: '2026-05-01',
          updatedAt: '2026-05-01',
        ),
      );

      // Seed one expense under the budgeted category (spent = 11.0).
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(2026, 5, 5)),
          amount: const Value(11.0),
          currencyCode: const Value('EUR'),
          exchangeRate: const Value(1.0),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          isExcluded: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final result = await container.read(effectiveSpentProvider(month).future);

      // totalBudgetProvider → totalSpent = 11.0 (matches budget repository
      // getSpentAmount for this category).
      expect(result, closeTo(11.0, 0.001));
    });
  });
}
