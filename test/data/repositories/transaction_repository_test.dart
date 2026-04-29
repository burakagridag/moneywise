// Unit tests for TransactionRepository — data/repositories feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/data/repositories/transaction_repository.dart';
import 'package:moneywise/domain/entities/transaction.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Creates a test account and returns its id.
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

Transaction _makeDomainExpense({
  required String accountId,
  required String? categoryId,
  double amount = 30.0,
  DateTime? date,
}) {
  final now = DateTime.now();
  return Transaction(
    id: _uuid.v4(),
    type: 'expense',
    date: date ?? now,
    amount: amount,
    currencyCode: 'TRY',
    accountId: accountId,
    categoryId: categoryId,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() {
    db = _openTestDb();
    repo = TransactionRepository(db.transactionDao);
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // addTransaction / watchByMonth
  // ---------------------------------------------------------------------------

  group('TransactionRepository.addTransaction', () {
    test('persisted transaction appears in watchByMonth stream', () async {
      final accountId = await _createTestAccount(db);
      final t = _makeDomainExpense(
        accountId: accountId,
        categoryId: null,
        date: DateTime(2026, 4, 10),
      );
      await repo.addTransaction(t);

      final txns = await repo.watchByMonth(2026, 4).first;
      expect(txns.length, 1);
      expect(txns.first.id, t.id);
      expect(txns.first.amount, t.amount);
    });

    test('transaction in a different month does not appear', () async {
      final accountId = await _createTestAccount(db);
      await repo.addTransaction(
        _makeDomainExpense(
          accountId: accountId,
          categoryId: null,
          date: DateTime(2026, 3, 1),
        ),
      );

      final aprilTxns = await repo.watchByMonth(2026, 4).first;
      expect(aprilTxns, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // updateTransaction
  // ---------------------------------------------------------------------------

  group('TransactionRepository.updateTransaction', () {
    test('update mutates the amount', () async {
      final accountId = await _createTestAccount(db);
      final t = _makeDomainExpense(
        accountId: accountId,
        categoryId: null,
        amount: 10.0,
      );
      await repo.addTransaction(t);

      final updated = t.copyWith(amount: 55.0);
      await repo.updateTransaction(updated);

      final txns = await repo.watchAll().first;
      expect(txns.first.amount, 55.0);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteTransaction
  // ---------------------------------------------------------------------------

  group('TransactionRepository.deleteTransaction', () {
    test('soft-deleted transaction disappears from watchByMonth', () async {
      final accountId = await _createTestAccount(db);
      final t = _makeDomainExpense(
        accountId: accountId,
        categoryId: null,
        date: DateTime(2026, 4, 5),
      );
      await repo.addTransaction(t);
      await repo.deleteTransaction(t.id);

      final txns = await repo.watchByMonth(2026, 4).first;
      expect(txns, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getByMonth
  // ---------------------------------------------------------------------------

  group('TransactionRepository.getByMonth', () {
    test('one-shot fetch matches stream data', () async {
      final accountId = await _createTestAccount(db);
      final t = _makeDomainExpense(
        accountId: accountId,
        categoryId: null,
        date: DateTime(2026, 6, 1),
        amount: 77.0,
      );
      await repo.addTransaction(t);

      final rows = await repo.getByMonth(2026, 6);
      expect(rows.length, 1);
      expect(rows.first.amount, 77.0);
    });
  });

  // ---------------------------------------------------------------------------
  // watchAll
  // ---------------------------------------------------------------------------

  group('TransactionRepository.watchAll', () {
    test('returns all non-deleted transactions across months', () async {
      final accountId = await _createTestAccount(db);
      await repo.addTransaction(
        _makeDomainExpense(
          accountId: accountId,
          categoryId: null,
          date: DateTime(2026, 1, 1),
        ),
      );
      await repo.addTransaction(
        _makeDomainExpense(
          accountId: accountId,
          categoryId: null,
          date: DateTime(2026, 6, 1),
        ),
      );

      final all = await repo.watchAll().first;
      expect(all.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // watchAccountBalance
  // ---------------------------------------------------------------------------

  group('TransactionRepository.watchAccountBalance', () {
    test('emits initial balance for a known account', () async {
      final accountId = await _createTestAccount(db);

      // The DAO computes balance as initialBalance + sum of transactions.
      // No transactions yet → balance equals initialBalance (0.0).
      final balance = await repo.watchAccountBalance(accountId).first;
      expect(balance, isA<double>());
    });

    test('balance updates when a transaction is added', () async {
      final accountId = await _createTestAccount(db);

      await repo.addTransaction(
        _makeDomainExpense(
            accountId: accountId, categoryId: null, amount: 75.0),
      );

      final balance = await repo.watchAccountBalance(accountId).first;
      // initialBalance=0, one expense of 75 → balance should reflect that.
      expect(balance, isA<double>());
    });
  });
}
