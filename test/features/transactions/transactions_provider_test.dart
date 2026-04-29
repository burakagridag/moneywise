// Unit tests for Transactions feature Riverpod providers — features/transactions.
// Covers SelectedMonth (Sprint 3), TransactionWriteNotifier (Sprint 3),
// SelectedPeriod/SelectedPeriodNotifier/SelectedYearNotifier (Sprint 4).
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/data/repositories/transaction_repository.dart';
import 'package:moneywise/features/transactions/presentation/providers/transactions_provider.dart';
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

/// Creates a test account and returns its id.
Future<String> _createTestAccount(AppDatabase db) async {
  // Get a group id from seeded groups.
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

Transaction _makeTransaction(String accountId, {double amount = 25.0}) {
  final now = DateTime.now();
  return Transaction(
    id: _uuid.v4(),
    type: 'expense',
    date: now,
    amount: amount,
    currencyCode: 'TRY',
    accountId: accountId,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // SelectedMonth (Sprint 3)
  // ---------------------------------------------------------------------------

  group('SelectedMonth provider', () {
    test('initialises to current year-month', () {
      final (container, _) = _buildContainer();

      final month = container.read(selectedMonthProvider);
      final now = DateTime.now();
      expect(month.year, now.year);
      expect(month.month, now.month);
    });

    test('previous() decrements month', () {
      final (container, _) = _buildContainer();

      final initial = container.read(selectedMonthProvider);
      container.read(selectedMonthProvider.notifier).previous();
      final prev = container.read(selectedMonthProvider);

      final expectedMonth = initial.month == 1 ? 12 : initial.month - 1;
      final expectedYear = initial.month == 1 ? initial.year - 1 : initial.year;
      expect(prev.month, expectedMonth);
      expect(prev.year, expectedYear);
    });

    test('next() increments month', () {
      final (container, _) = _buildContainer();

      // Go back one month first so next() doesn't overshoot current month guard
      container.read(selectedMonthProvider.notifier).previous();
      final before = container.read(selectedMonthProvider);
      container.read(selectedMonthProvider.notifier).next();
      final after = container.read(selectedMonthProvider);

      final expectedMonth = before.month == 12 ? 1 : before.month + 1;
      expect(after.month, expectedMonth);
    });
  });

  // ---------------------------------------------------------------------------
  // TransactionWriteNotifier (Sprint 3)
  // ---------------------------------------------------------------------------

  group('TransactionWriteNotifier', () {
    test('addTransaction persists to DB', () async {
      final (container, db) = _buildContainer();

      final accountId = await _createTestAccount(db);
      final t = _makeTransaction(accountId);

      await container
          .read(transactionWriteNotifierProvider.notifier)
          .addTransaction(t);

      final repo = container.read(transactionRepositoryProvider);
      final all = await repo.watchAll().first;
      expect(all.any((tx) => tx.id == t.id), isTrue);
    });

    test('updateTransaction mutates the row', () async {
      final (container, db) = _buildContainer();

      final accountId = await _createTestAccount(db);
      final t = _makeTransaction(accountId, amount: 10.0);

      await container
          .read(transactionWriteNotifierProvider.notifier)
          .addTransaction(t);

      final updated = t.copyWith(amount: 99.9);
      await container
          .read(transactionWriteNotifierProvider.notifier)
          .updateTransaction(updated);

      final repo = container.read(transactionRepositoryProvider);
      final all = await repo.watchAll().first;
      expect(all.first.amount, 99.9);
    });

    test('deleteTransaction soft-deletes the row', () async {
      final (container, db) = _buildContainer();

      final accountId = await _createTestAccount(db);
      final t = _makeTransaction(accountId);

      await container
          .read(transactionWriteNotifierProvider.notifier)
          .addTransaction(t);

      await container
          .read(transactionWriteNotifierProvider.notifier)
          .deleteTransaction(t.id);

      final repo = container.read(transactionRepositoryProvider);
      final all = await repo.watchAll().first;
      expect(all, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // transactionsByMonthProvider stream (Sprint 3)
  // ---------------------------------------------------------------------------

  group('transactionsByMonthProvider stream', () {
    test('emits empty list for month with no transactions', () async {
      final (container, _) = _buildContainer();

      // Navigate to a past month with no transactions
      container.read(selectedMonthProvider.notifier).previous();
      container.read(selectedMonthProvider.notifier).previous();
      container.read(selectedMonthProvider.notifier).previous();

      final sub = container.listen(transactionsByMonthProvider, (_, __) {});
      addTearDown(sub.close);
      final txns = await container.read(transactionsByMonthProvider.future);
      expect(txns, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // SelectedPeriod helpers (Sprint 4)
  // ---------------------------------------------------------------------------

  group('SelectedPeriod', () {
    test('equality based on year and month', () {
      const a = SelectedPeriod(year: 2026, month: 4);
      const b = SelectedPeriod(year: 2026, month: 4);
      expect(a, equals(b));
    });

    test('inequality when year differs', () {
      const a = SelectedPeriod(year: 2026, month: 4);
      const b = SelectedPeriod(year: 2025, month: 4);
      expect(a, isNot(equals(b)));
    });

    test('inequality when month differs', () {
      const a = SelectedPeriod(year: 2026, month: 4);
      const b = SelectedPeriod(year: 2026, month: 5);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = SelectedPeriod(year: 2026, month: 4);
      const b = SelectedPeriod(year: 2026, month: 4);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith overrides only specified fields', () {
      const original = SelectedPeriod(year: 2026, month: 4);
      final newMonth = original.copyWith(month: 7);
      expect(newMonth.year, 2026);
      expect(newMonth.month, 7);
    });
  });

  // ---------------------------------------------------------------------------
  // SelectedPeriod.previousMonth (Sprint 4)
  // ---------------------------------------------------------------------------

  group('SelectedPeriod.previousMonth', () {
    test('decrements month by one', () {
      const p = SelectedPeriod(year: 2026, month: 5);
      final prev = p.previousMonth();
      expect(prev.month, 4);
      expect(prev.year, 2026);
    });

    test('wraps January to December of previous year', () {
      const p = SelectedPeriod(year: 2026, month: 1);
      final prev = p.previousMonth();
      expect(prev.month, 12);
      expect(prev.year, 2025);
    });
  });

  // ---------------------------------------------------------------------------
  // SelectedPeriod.nextMonth (Sprint 4)
  // ---------------------------------------------------------------------------

  group('SelectedPeriod.nextMonth', () {
    test('increments month by one', () {
      const p = SelectedPeriod(year: 2026, month: 4);
      final next = p.nextMonth();
      expect(next.month, 5);
      expect(next.year, 2026);
    });

    test('wraps December to January of next year', () {
      const p = SelectedPeriod(year: 2026, month: 12);
      final next = p.nextMonth();
      expect(next.month, 1);
      expect(next.year, 2027);
    });
  });

  // ---------------------------------------------------------------------------
  // SelectedPeriodNotifier (Sprint 4)
  // ---------------------------------------------------------------------------

  group('SelectedPeriodNotifier', () {
    test('initialises with current date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final now = DateTime.now();
      final period = container.read(selectedPeriodNotifierProvider);
      expect(period.year, now.year);
      expect(period.month, now.month);
    });

    test('goToPreviousMonth decrements month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Set to April 2026 first
      container
          .read(selectedPeriodNotifierProvider.notifier)
          .goToMonth(2026, 4);
      container
          .read(selectedPeriodNotifierProvider.notifier)
          .goToPreviousMonth();
      final period = container.read(selectedPeriodNotifierProvider);
      expect(period.month, 3);
      expect(period.year, 2026);
    });

    test('goToNextMonth increments month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(selectedPeriodNotifierProvider.notifier)
          .goToMonth(2026, 4);
      container.read(selectedPeriodNotifierProvider.notifier).goToNextMonth();
      final period = container.read(selectedPeriodNotifierProvider);
      expect(period.month, 5);
      expect(period.year, 2026);
    });

    test('goToMonth sets explicit year and month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(selectedPeriodNotifierProvider.notifier)
          .goToMonth(2024, 11);
      final period = container.read(selectedPeriodNotifierProvider);
      expect(period.year, 2024);
      expect(period.month, 11);
    });

    test('multiple previous navigations cross year boundary', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(selectedPeriodNotifierProvider.notifier)
          .goToMonth(2026, 2);
      final notifier = container.read(selectedPeriodNotifierProvider.notifier);
      notifier.goToPreviousMonth(); // Jan 2026
      notifier.goToPreviousMonth(); // Dec 2025
      final period = container.read(selectedPeriodNotifierProvider);
      expect(period.month, 12);
      expect(period.year, 2025);
    });
  });

  // ---------------------------------------------------------------------------
  // SelectedYearNotifier (Sprint 4)
  // ---------------------------------------------------------------------------

  group('SelectedYearNotifier', () {
    test('initialises with current year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(selectedYearNotifierProvider),
        DateTime.now().year,
      );
    });

    test('goToPreviousYear decrements year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedYearNotifierProvider.notifier).goToYear(2026);
      container.read(selectedYearNotifierProvider.notifier).goToPreviousYear();
      expect(container.read(selectedYearNotifierProvider), 2025);
    });

    test('goToNextYear increments year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedYearNotifierProvider.notifier).goToYear(2026);
      container.read(selectedYearNotifierProvider.notifier).goToNextYear();
      expect(container.read(selectedYearNotifierProvider), 2027);
    });

    test('goToYear sets explicit year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedYearNotifierProvider.notifier).goToYear(2020);
      expect(container.read(selectedYearNotifierProvider), 2020);
    });

    test('chained next/previous returns to original year', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedYearNotifierProvider.notifier).goToYear(2026);
      final notifier = container.read(selectedYearNotifierProvider.notifier);
      notifier.goToNextYear();
      notifier.goToPreviousYear();
      expect(container.read(selectedYearNotifierProvider), 2026);
    });
  });
}
