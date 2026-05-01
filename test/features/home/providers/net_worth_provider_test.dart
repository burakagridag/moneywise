// Unit tests for combineBalancesForTesting and previousMonthTotal — home feature (EPIC8A-06).
import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/transaction_repository.dart';
import 'package:moneywise/domain/entities/account.dart' as domain;
import 'package:moneywise/features/home/presentation/providers/net_worth_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Fake TransactionRepository — overrides watchAccountBalance only.
// ---------------------------------------------------------------------------

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  /// Per-account StreamControllers — the test drives balance updates via these.
  final Map<String, StreamController<double>> _controllers = {};

  /// Registers a [StreamController] for [accountId] before it is subscribed.
  void seedController(String accountId, StreamController<double> controller) {
    _controllers[accountId] = controller;
  }

  @override
  Stream<double> watchAccountBalance(String accountId) {
    final ctrl = _controllers[accountId];
    if (ctrl == null) {
      throw StateError(
        '_FakeTransactionRepository: no controller seeded for $accountId',
      );
    }
    return ctrl.stream;
  }
}

// ---------------------------------------------------------------------------
// Helpers — in-memory Drift database.
// ---------------------------------------------------------------------------

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Inserts a minimal account row.  [initialBalance] defaults to 0.0.
/// Returns the inserted account id.
Future<String> _seedAccount(
  AppDatabase db, {
  double initialBalance = 0.0,
  bool includeInTotals = true,
}) async {
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
      initialBalance: Value(initialBalance),
      sortOrder: const Value(0),
      isHidden: const Value(false),
      includeInTotals: Value(includeInTotals),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return id;
}

/// Inserts a transaction row. [exchangeRate] defaults to 1.0.
Future<void> _seedTransaction(
  AppDatabase db, {
  required String accountId,
  required String type,
  required double amount,
  required DateTime date,
  String? toAccountId,
  double exchangeRate = 1.0,
  bool isExcluded = false,
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
      isDeleted: const Value(false),
    ),
  );
}

/// Builds a minimal [domain.Account] suitable for use with [combineBalancesForTesting].
domain.Account _makeDomainAccount({
  required String id,
  bool includeInTotals = true,
  double initialBalance = 0.0,
}) {
  final now = DateTime.now();
  return domain.Account(
    id: id,
    groupId: 'group-1',
    name: 'Account $id',
    currencyCode: 'EUR',
    initialBalance: initialBalance,
    sortOrder: 0,
    isHidden: false,
    includeInTotals: includeInTotals,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

// ---------------------------------------------------------------------------
// Tests — _combineBalances (via combineBalancesForTesting shim)
// ---------------------------------------------------------------------------

void main() {
  group('combineBalancesForTesting — empty account list', () {
    test('emits 0.0 and completes immediately', () async {
      final fake = _FakeTransactionRepository();
      final stream = combineBalancesForTesting([], fake);

      // Stream.value emits once and closes.
      final values = await stream.toList();
      expect(values, [0.0]);
    });
  });

  group('combineBalancesForTesting — two accounts', () {
    test('does NOT emit until BOTH account streams have emitted', () async {
      const idA = 'acc-a';
      const idB = 'acc-b';
      final ctrlA = StreamController<double>();
      final ctrlB = StreamController<double>();

      final fake = _FakeTransactionRepository()
        ..seedController(idA, ctrlA)
        ..seedController(idB, ctrlB);

      final accounts = [
        _makeDomainAccount(id: idA),
        _makeDomainAccount(id: idB),
      ];

      final stream = combineBalancesForTesting(accounts, fake);
      final emitted = <double>[];
      final sub = stream.listen(emitted.add);

      // Only account A has emitted — no sum should be available yet.
      ctrlA.add(10.0);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, isEmpty,
          reason: 'must not emit before both streams fire');

      // Now account B emits — sum should be available.
      ctrlB.add(20.0);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [30.0]);

      await sub.cancel();
      await ctrlA.close();
      await ctrlB.close();
    });

    test('emits updated sum when one account balance changes', () async {
      const idA = 'acc-a';
      const idB = 'acc-b';
      final ctrlA = StreamController<double>();
      final ctrlB = StreamController<double>();

      final fake = _FakeTransactionRepository()
        ..seedController(idA, ctrlA)
        ..seedController(idB, ctrlB);

      final accounts = [
        _makeDomainAccount(id: idA),
        _makeDomainAccount(id: idB),
      ];

      final stream = combineBalancesForTesting(accounts, fake);
      final emitted = <double>[];
      final sub = stream.listen(emitted.add);

      // Provide initial values for both.
      ctrlA.add(100.0);
      ctrlB.add(200.0);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [300.0]);

      // Account A balance changes.
      ctrlA.add(150.0);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [300.0, 350.0]);

      await sub.cancel();
      await ctrlA.close();
      await ctrlB.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Tests — previousMonthTotal (via Riverpod ProviderContainer + in-memory DB)
  // ---------------------------------------------------------------------------

  group('previousMonthTotal — income and expense adjust previous balance', () {
    test('correctly computes balance from income and expense in previous month',
        () async {
      final db = _openTestDb();
      addTearDown(db.close);

      // Seed one account with initialBalance = 100.00.
      final accountId = await _seedAccount(db, initialBalance: 100.0);

      // Previous month relative to now.
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 15);

      // +50 income, -30 expense → net delta = +20. Expected = 100 + 20 = 120.
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'income',
        amount: 50.0,
        date: prevMonth,
      );
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'expense',
        amount: 30.0,
        date: prevMonth,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final result = await container.read(previousMonthTotalProvider.future);
      expect(result, closeTo(120.0, 0.001));
    });

    test('excludes transactions with isExcluded = true', () async {
      final db = _openTestDb();
      addTearDown(db.close);

      final accountId = await _seedAccount(db, initialBalance: 100.0);

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 10);

      // Excluded income — should have no effect.
      await _seedTransaction(
        db,
        accountId: accountId,
        type: 'income',
        amount: 999.0,
        date: prevMonth,
        isExcluded: true,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final result = await container.read(previousMonthTotalProvider.future);
      // Only initialBalance contributes.
      expect(result, closeTo(100.0, 0.001));
    });
  });

  group('previousMonthTotal — transfer double-entry', () {
    test('transfer between two included accounts has zero net effect',
        () async {
      final db = _openTestDb();
      addTearDown(db.close);

      // Two accounts, each with initialBalance = 500.
      final accountA = await _seedAccount(db, initialBalance: 500.0);
      final accountB = await _seedAccount(db, initialBalance: 500.0);

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 20);

      // Transfer 200 from A to B.
      // - A: debit 200 (prevCents -= 200_00)
      // - B: credit 200 (prevCents += 200_00)
      // Net change on total = 0.
      await _seedTransaction(
        db,
        accountId: accountA,
        type: 'transfer',
        amount: 200.0,
        date: prevMonth,
        toAccountId: accountB,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final result = await container.read(previousMonthTotalProvider.future);
      // A: 500 - 200 = 300; B: 500 + 200 = 700. Total = 1000.
      expect(result, closeTo(1000.0, 0.001));
    });
  });
}
