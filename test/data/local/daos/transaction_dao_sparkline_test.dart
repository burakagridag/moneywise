// Unit tests for TransactionDao.watchDailyNetAmounts — data/local feature (EPIC8A-06).
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/daos/transaction_dao.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Creates a test account and returns its id.
/// Sets [includeInTotals] to [true] by default.
Future<String> _createAccount(
  AppDatabase db, {
  bool includeInTotals = true,
}) async {
  final groups = await db.accountDao.getGroups();
  final groupId = groups.first.id;
  final accountId = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(accountId),
      groupId: Value(groupId),
      name: const Value('Test Account'),
      currencyCode: const Value('EUR'),
      initialBalance: const Value(0.0),
      sortOrder: const Value(0),
      isHidden: const Value(false),
      includeInTotals: Value(includeInTotals),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return accountId;
}

/// Inserts a transaction for [accountId] on [date].
Future<void> _insertTx(
  AppDatabase db, {
  required String accountId,
  String type = 'expense',
  double amount = 10.0,
  required DateTime date,
  bool isExcluded = false,
  String? toAccountId,
  double exchangeRate = 1.0,
}) async {
  await db.transactionDao.insertTransaction(
    TransactionsCompanion(
      id: Value(_uuid.v4()),
      type: Value(type),
      date: Value(date),
      amount: Value(amount),
      currencyCode: const Value('EUR'),
      exchangeRate: Value(exchangeRate),
      accountId: Value(accountId),
      toAccountId: Value(toAccountId),
      isExcluded: Value(isExcluded),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _openTestDb();
  });

  tearDown(() async => db.close());

  group('TransactionDao.watchDailyNetAmounts', () {
    // -------------------------------------------------------------------------
    // Empty DB
    // -------------------------------------------------------------------------

    test('returns exactly 30 DailyNet entries for empty DB', () async {
      final accountId = await _createAccount(db);
      // accountId used only to confirm DB is seeded; no transactions inserted.
      expect(accountId, isNotEmpty);

      final referenceDate = DateTime(2024, 3, 31);
      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      expect(result, hasLength(30));
    });

    test('all entries have netAmount == 0.0 for empty DB', () async {
      final referenceDate = DateTime(2024, 3, 31);
      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      expect(result.every((d) => d.netAmount == 0.0), isTrue);
    });

    test('first entry is referenceDate - 29 days, last is referenceDate',
        () async {
      final referenceDate = DateTime(2024, 3, 31);
      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      final expectedFirst = DateTime(2024, 3, 2);
      final expectedLast = DateTime(2024, 3, 31);

      expect(result.first.date, equals(expectedFirst));
      expect(result.last.date, equals(expectedLast));
    });

    // -------------------------------------------------------------------------
    // Gap-filling
    // -------------------------------------------------------------------------

    test('days with no transactions have netAmount == 0.0 (gap-fill)',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      // Insert one transaction on day 29-of-window only.
      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 100.0,
        date: DateTime(2024, 3, 30),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      expect(result, hasLength(30));

      // All days except March 30 should be 0.
      for (final d in result) {
        if (d.date == DateTime(2024, 3, 30)) {
          expect(d.netAmount, equals(100.0),
              reason: 'March 30 should have income netAmount = 100.0');
        } else {
          expect(d.netAmount, equals(0.0),
              reason: '${d.date} should be 0.0 (gap-fill)');
        }
      }
    });

    // -------------------------------------------------------------------------
    // Single income transaction
    // -------------------------------------------------------------------------

    test('single income transaction in window produces positive netAmount',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 250.0,
        date: DateTime(2024, 3, 15),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      final march15 = result.firstWhere(
        (d) => d.date == DateTime(2024, 3, 15),
      );
      expect(march15.netAmount, equals(250.0));
    });

    // -------------------------------------------------------------------------
    // Single expense transaction
    // -------------------------------------------------------------------------

    test('single expense transaction in window produces negative netAmount',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      await _insertTx(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 75.0,
        date: DateTime(2024, 3, 20),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      final march20 = result.firstWhere(
        (d) => d.date == DateTime(2024, 3, 20),
      );
      expect(march20.netAmount, equals(-75.0));
    });

    // -------------------------------------------------------------------------
    // Transfer excluded
    // -------------------------------------------------------------------------

    test('transfer transactions are excluded from netAmount', () async {
      final accountId = await _createAccount(db);
      final toAccountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      await _insertTx(
        db,
        accountId: accountId,
        type: 'transfer',
        amount: 500.0,
        date: DateTime(2024, 3, 15),
        toAccountId: toAccountId,
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      // Transfer must not affect any day's netAmount.
      expect(result.every((d) => d.netAmount == 0.0), isTrue,
          reason: 'Transfers must be excluded from net calculation');
    });

    // -------------------------------------------------------------------------
    // Excluded account IDs
    // -------------------------------------------------------------------------

    test('transactions from excludedAccountIds are omitted', () async {
      final includedAccount = await _createAccount(db);
      final excludedAccount = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      // Income on included account.
      await _insertTx(
        db,
        accountId: includedAccount,
        type: 'income',
        amount: 200.0,
        date: DateTime(2024, 3, 15),
      );

      // Income on excluded account — must not appear.
      await _insertTx(
        db,
        accountId: excludedAccount,
        type: 'income',
        amount: 999.0,
        date: DateTime(2024, 3, 15),
      );

      final result = await db.transactionDao.watchDailyNetAmounts(
        referenceDate: referenceDate,
        excludedAccountIds: {excludedAccount},
      ).first;

      final march15 = result.firstWhere(
        (d) => d.date == DateTime(2024, 3, 15),
      );
      expect(march15.netAmount, equals(200.0),
          reason: 'Only includedAccount income (200.0) should appear');
    });

    // -------------------------------------------------------------------------
    // isExcluded flag
    // -------------------------------------------------------------------------

    test('transactions with isExcluded=true are omitted', () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 300.0,
        date: DateTime(2024, 3, 10),
        isExcluded: true,
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      expect(result.every((d) => d.netAmount == 0.0), isTrue,
          reason: 'isExcluded transactions must not be counted');
    });

    // -------------------------------------------------------------------------
    // Integer cent accumulation — no float drift for same-day transactions
    // -------------------------------------------------------------------------

    test(
        'two transactions on the same day accumulate correctly without float drift',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      // Two income entries: 0.1 + 0.2 = 0.3 (exact in cent-based arithmetic).
      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 0.1,
        date: DateTime(2024, 3, 15),
      );
      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 0.2,
        date: DateTime(2024, 3, 15),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      final march15 = result.firstWhere(
        (d) => d.date == DateTime(2024, 3, 15),
      );
      // Expect 0.30 — not 0.30000000000000004.
      expect(march15.netAmount, closeTo(0.30, 0.001));
    });

    // -------------------------------------------------------------------------
    // Mixed window with income and expense on different days
    // -------------------------------------------------------------------------

    test('mixed income and expense across multiple days are bucketed correctly',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 1000.0,
        date: DateTime(2024, 3, 10),
      );
      await _insertTx(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 400.0,
        date: DateTime(2024, 3, 10),
      );
      await _insertTx(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 50.0,
        date: DateTime(2024, 3, 20),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      final march10 = result.firstWhere((d) => d.date == DateTime(2024, 3, 10));
      final march20 = result.firstWhere((d) => d.date == DateTime(2024, 3, 20));

      expect(march10.netAmount, equals(600.0),
          reason: '1000 income - 400 expense = 600');
      expect(march20.netAmount, equals(-50.0), reason: 'expense only = -50');
    });

    // -------------------------------------------------------------------------
    // Transactions outside the 30-day window are ignored
    // -------------------------------------------------------------------------

    test('transaction before the 30-day window does not appear in result',
        () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      // 31 days before referenceDate — outside the window.
      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 500.0,
        date: DateTime(2024, 2, 29),
      );

      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .first;

      expect(result.every((d) => d.netAmount == 0.0), isTrue,
          reason: 'Transactions before window must be ignored');
    });

    // -------------------------------------------------------------------------
    // Custom [days] parameter
    // -------------------------------------------------------------------------

    test('custom days parameter returns the correct number of entries',
        () async {
      final referenceDate = DateTime(2024, 3, 31);
      final result = await db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate, days: 7)
          .first;

      expect(result, hasLength(7));
    });

    // -------------------------------------------------------------------------
    // Reactive update — emits again after new transaction
    // -------------------------------------------------------------------------

    test('stream emits updated data after a transaction is inserted', () async {
      final accountId = await _createAccount(db);
      final referenceDate = DateTime(2024, 3, 31);

      // Collect two emissions via a broadcast stream: initial + post-insert.
      final stream = db.transactionDao
          .watchDailyNetAmounts(referenceDate: referenceDate)
          .asBroadcastStream();

      // Start listening before inserting.
      final secondFuture = stream.skip(1).first;

      // Ensure the stream is subscribed (first emission consumed).
      await stream.first;

      // Insert a transaction — triggers a second emission.
      await _insertTx(
        db,
        accountId: accountId,
        type: 'income',
        amount: 100.0,
        date: DateTime(2024, 3, 15),
      );

      final second = await secondFuture;
      final march15 = second.firstWhere((d) => d.date == DateTime(2024, 3, 15));
      expect(march15.netAmount, equals(100.0));
    });
  });
}
