// Unit tests for TransactionDao CRUD and balance stream — data/local feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Creates a test account and returns its id.
/// Uses getGroups() to ensure DB is initialised and seeded before inserting.
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
      initialBalance: const Value(100.0),
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

TransactionsCompanion _makeExpense({
  required String accountId,
  String? categoryId,
  double amount = 50.0,
  DateTime? date,
}) {
  return TransactionsCompanion(
    id: Value(_uuid.v4()),
    type: const Value('expense'),
    date: Value(date ?? DateTime.now()),
    amount: Value(amount),
    currencyCode: const Value('TRY'),
    accountId: Value(accountId),
    categoryId: Value(categoryId),
  );
}

TransactionsCompanion _makeIncome({
  required String accountId,
  double amount = 100.0,
  DateTime? date,
}) {
  return TransactionsCompanion(
    id: Value(_uuid.v4()),
    type: const Value('income'),
    date: Value(date ?? DateTime.now()),
    amount: Value(amount),
    currencyCode: const Value('TRY'),
    accountId: Value(accountId),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _openTestDb();
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // watchTransactionsByMonth
  // ---------------------------------------------------------------------------

  group('TransactionDao.watchTransactionsByMonth', () {
    test('returns empty list for month with no transactions', () async {
      final txns =
          await db.transactionDao.watchTransactionsByMonth(2026, 4).first;
      expect(txns, isEmpty);
    });

    test('returns transactions in the correct month only', () async {
      final accountId = await _createTestAccount(db);
      final aprilDate = DateTime(2026, 4, 15);
      final marchDate = DateTime(2026, 3, 15);

      await db.transactionDao.insertTransaction(
        _makeExpense(accountId: accountId, amount: 30.0, date: aprilDate),
      );
      await db.transactionDao.insertTransaction(
        _makeExpense(accountId: accountId, amount: 20.0, date: marchDate),
      );

      final aprilTxns =
          await db.transactionDao.watchTransactionsByMonth(2026, 4).first;
      expect(aprilTxns.length, 1);
      expect(aprilTxns.first.amount, 30.0);
    });

    test('excludes soft-deleted transactions', () async {
      final accountId = await _createTestAccount(db);
      final id = _uuid.v4();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(id),
          type: const Value('expense'),
          date: Value(DateTime(2026, 4, 10)),
          amount: const Value(99.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );
      await db.transactionDao.softDeleteTransaction(id);

      final txns =
          await db.transactionDao.watchTransactionsByMonth(2026, 4).first;
      expect(txns, isEmpty);
    });

    test('orders transactions newest-first', () async {
      final accountId = await _createTestAccount(db);
      await db.transactionDao.insertTransaction(
        _makeExpense(
          accountId: accountId,
          amount: 10.0,
          date: DateTime(2026, 4, 1),
        ),
      );
      await db.transactionDao.insertTransaction(
        _makeExpense(
          accountId: accountId,
          amount: 20.0,
          date: DateTime(2026, 4, 20),
        ),
      );

      final txns =
          await db.transactionDao.watchTransactionsByMonth(2026, 4).first;
      expect(txns.first.amount, 20.0);
      expect(txns.last.amount, 10.0);
    });
  });

  // ---------------------------------------------------------------------------
  // insertTransaction / updateTransaction / softDeleteTransaction
  // ---------------------------------------------------------------------------

  group('TransactionDao write paths', () {
    test('insertTransaction persists a new row', () async {
      final accountId = await _createTestAccount(db);
      await db.transactionDao.insertTransaction(
        _makeExpense(accountId: accountId, amount: 42.0),
      );
      final all = await db.transactionDao.watchAllTransactions().first;
      expect(all.length, 1);
      expect(all.first.amount, 42.0);
    });

    test('updateTransaction mutates the existing row', () async {
      final accountId = await _createTestAccount(db);
      final id = _uuid.v4();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(id),
          type: const Value('expense'),
          date: Value(DateTime.now()),
          amount: const Value(10.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );

      await db.transactionDao.updateTransaction(
        TransactionsCompanion(
          id: Value(id),
          amount: const Value(99.0),
        ),
      );

      final updated = await db.transactionDao.watchAllTransactions().first;
      expect(updated.first.amount, 99.0);
    });

    test('softDeleteTransaction sets isDeleted=true', () async {
      final accountId = await _createTestAccount(db);
      final id = _uuid.v4();
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(id),
          type: const Value('expense'),
          date: Value(DateTime.now()),
          amount: const Value(5.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
        ),
      );

      await db.transactionDao.softDeleteTransaction(id);

      // watchAllTransactions excludes soft-deleted rows
      final visible = await db.transactionDao.watchAllTransactions().first;
      expect(visible, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getTransactionsByMonth
  // ---------------------------------------------------------------------------

  group('TransactionDao.getTransactionsByMonth', () {
    test('one-shot fetch returns correct rows', () async {
      final accountId = await _createTestAccount(db);
      await db.transactionDao.insertTransaction(
        _makeExpense(
          accountId: accountId,
          amount: 77.0,
          date: DateTime(2026, 5, 1),
        ),
      );
      final rows = await db.transactionDao.getTransactionsByMonth(2026, 5);
      expect(rows.length, 1);
      expect(rows.first.amount, 77.0);
    });
  });

  // ---------------------------------------------------------------------------
  // watchAccountBalance
  // ---------------------------------------------------------------------------

  group('TransactionDao.watchAccountBalance', () {
    test('balance equals initialBalance when no transactions', () async {
      final accountId = await _createTestAccount(db);
      final balance =
          await db.transactionDao.watchAccountBalance(accountId).first;
      // initialBalance is 100.0 set in _createTestAccount
      expect(balance, 100.0);
    });

    test('income increases balance', () async {
      final accountId = await _createTestAccount(db);
      final initialBal =
          await db.transactionDao.watchAccountBalance(accountId).first;

      await db.transactionDao.insertTransaction(
        _makeIncome(accountId: accountId, amount: 200.0),
      );

      final newBal =
          await db.transactionDao.watchAccountBalance(accountId).first;
      expect(newBal, initialBal + 200.0);
    });

    test('expense decreases balance', () async {
      final accountId = await _createTestAccount(db);
      final initialBal =
          await db.transactionDao.watchAccountBalance(accountId).first;

      await db.transactionDao.insertTransaction(
        _makeExpense(accountId: accountId, amount: 50.0),
      );

      final newBal =
          await db.transactionDao.watchAccountBalance(accountId).first;
      expect(newBal, initialBal - 50.0);
    });

    test('excluded transactions do not affect balance', () async {
      final accountId = await _createTestAccount(db);
      final initialBal =
          await db.transactionDao.watchAccountBalance(accountId).first;

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime.now()),
          amount: const Value(999.0),
          currencyCode: const Value('TRY'),
          accountId: Value(accountId),
          isExcluded: const Value(true),
        ),
      );

      final newBal =
          await db.transactionDao.watchAccountBalance(accountId).first;
      expect(newBal, initialBal);
    });
  });
}
