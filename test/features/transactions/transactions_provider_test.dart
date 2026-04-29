// Unit tests for SelectedMonth provider and TransactionWriteNotifier — transactions feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/data/repositories/transaction_repository.dart';
import 'package:moneywise/domain/entities/transaction.dart';
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
  // SelectedMonth
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
  // TransactionWriteNotifier
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
  // transactionsByMonthProvider stream
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
}
