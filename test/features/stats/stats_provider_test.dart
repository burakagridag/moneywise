// Unit tests for stats providers — SelectedStatsMonth, StatsType, categoryBreakdown — stats feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/stats/presentation/providers/stats_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

(ProviderContainer, AppDatabase) _buildContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
    ],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);
  return (container, db);
}

Future<String> _createTestAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final groupId = groups.first.id;
  final accountId = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(accountId),
      groupId: Value(groupId),
      name: const Value('Test Account'),
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

Future<String> _firstCategoryId(AppDatabase db, String type) async {
  final categories = await db.categoryDao.getByType(type);
  return categories.first.id;
}

void main() {
  // ---------------------------------------------------------------------------
  // SelectedStatsMonth
  // ---------------------------------------------------------------------------

  group('SelectedStatsMonth provider', () {
    test('initialises to current year-month', () {
      final (container, _) = _buildContainer();
      final month = container.read(selectedStatsMonthProvider);
      final now = DateTime.now();
      expect(month.year, now.year);
      expect(month.month, now.month);
    });

    test('previous() decrements month', () {
      final (container, _) = _buildContainer();
      final initial = container.read(selectedStatsMonthProvider);
      container.read(selectedStatsMonthProvider.notifier).previous();
      final prev = container.read(selectedStatsMonthProvider);

      final expectedMonth = initial.month == 1 ? 12 : initial.month - 1;
      expect(prev.month, expectedMonth);
    });

    test('next() does not exceed current month', () {
      final (container, _) = _buildContainer();
      final initial = container.read(selectedStatsMonthProvider);
      container.read(selectedStatsMonthProvider.notifier).next();
      // should stay at current month
      expect(container.read(selectedStatsMonthProvider), initial);
    });

    test('next() increments after going back', () {
      final (container, _) = _buildContainer();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final before = container.read(selectedStatsMonthProvider);
      container.read(selectedStatsMonthProvider.notifier).next();
      final after = container.read(selectedStatsMonthProvider);

      final expected = before.month == 12 ? 1 : before.month + 1;
      expect(after.month, expected);
    });
  });

  // ---------------------------------------------------------------------------
  // StatsType toggle
  // ---------------------------------------------------------------------------

  group('StatsType provider', () {
    test('defaults to expense', () {
      final (container, _) = _buildContainer();
      expect(container.read(statsTypeProvider), 'expense');
    });

    test('setIncome switches to income', () {
      final (container, _) = _buildContainer();
      container.read(statsTypeProvider.notifier).setIncome();
      expect(container.read(statsTypeProvider), 'income');
    });

    test('setExpense switches back to expense', () {
      final (container, _) = _buildContainer();
      container.read(statsTypeProvider.notifier).setIncome();
      container.read(statsTypeProvider.notifier).setExpense();
      expect(container.read(statsTypeProvider), 'expense');
    });
  });

  // ---------------------------------------------------------------------------
  // categoryBreakdownProvider
  // ---------------------------------------------------------------------------

  group('categoryBreakdownProvider', () {
    test('emits empty map when no transactions', () async {
      final (container, _) = _buildContainer();
      // Navigate to a past month
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();

      final breakdown = await container.read(categoryBreakdownProvider.future);
      expect(breakdown, isEmpty);
    });

    test('aggregates expense amounts by category', () async {
      final (container, db) = _buildContainer();
      final accountId = await _createTestAccount(db);
      final categoryId = await _firstCategoryId(db, 'expense');

      // Navigate to a specific past month to control test isolation
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final month = container.read(selectedStatsMonthProvider);

      final now = DateTime(month.year, month.month, 15);
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(now),
          amount: const Value(50.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(now),
          amount: const Value(30.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
          categoryId: Value(categoryId),
        ),
      );

      container.invalidate(categoryBreakdownProvider);
      final breakdown = await container.read(categoryBreakdownProvider.future);
      expect(breakdown[categoryId], 80.0);
    });

    test('income transactions not included in expense breakdown', () async {
      final (container, db) = _buildContainer();
      final accountId = await _createTestAccount(db);

      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final month = container.read(selectedStatsMonthProvider);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('income'),
          date: Value(DateTime(month.year, month.month, 1)),
          amount: const Value(1000.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );

      container.invalidate(categoryBreakdownProvider);
      final breakdown = await container.read(categoryBreakdownProvider.future);
      expect(breakdown, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // statsIncomeTotal and statsExpenseTotal
  // ---------------------------------------------------------------------------

  group('statsIncomeTotal and statsExpenseTotal', () {
    test('totals are zero when no transactions', () async {
      final (container, _) = _buildContainer();
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();

      final income = await container.read(statsIncomeTotalProvider.future);
      final expense = await container.read(statsExpenseTotalProvider.future);
      expect(income, 0.0);
      expect(expense, 0.0);
    });

    test('income total sums income transactions', () async {
      final (container, db) = _buildContainer();
      final accountId = await _createTestAccount(db);

      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final month = container.read(selectedStatsMonthProvider);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('income'),
          date: Value(DateTime(month.year, month.month, 1)),
          amount: const Value(300.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );

      container.invalidate(statsIncomeTotalProvider);
      final income = await container.read(statsIncomeTotalProvider.future);
      expect(income, 300.0);
    });

    test('expense total sums expense transactions', () async {
      final (container, db) = _buildContainer();
      final accountId = await _createTestAccount(db);

      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final month = container.read(selectedStatsMonthProvider);

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(month.year, month.month, 1)),
          amount: const Value(150.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );

      container.invalidate(statsExpenseTotalProvider);
      final expense = await container.read(statsExpenseTotalProvider.future);
      expect(expense, 150.0);
    });
  });
}
