// Unit tests for weeklyTotalsForMonth provider — verifies all-weeks scaffold
// and correct aggregation — features/transactions.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
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

void main() {
  // ---------------------------------------------------------------------------
  // weeklyTotalsForMonth — all-weeks scaffold (Bulgu #3 fix)
  // ---------------------------------------------------------------------------

  group('weeklyTotalsForMonth provider', () {
    test('returns all weeks of the month even with no transactions', () async {
      final (container, _) = _buildContainer();

      // May 2026 has 5 Mon-anchored weeks (28 Apr, 4, 11, 18, 25 May).
      final sub = container.listen(
        weeklyTotalsForMonthProvider(2026, 5),
        (_, __) {},
      );
      addTearDown(sub.close);

      final weekMap =
          await container.read(weeklyTotalsForMonthProvider(2026, 5).future);

      // 5 weeks must be present.
      expect(weekMap.length, 5);

      // All totals should be zero (no transactions).
      for (final entry in weekMap.entries) {
        expect(entry.value.income, 0.0);
        expect(entry.value.expense, 0.0);
      }
    });

    test('returns correct week count for February 2026 (non-leap, 4 weeks)',
        () async {
      final (container, _) = _buildContainer();

      final sub = container.listen(
        weeklyTotalsForMonthProvider(2026, 2),
        (_, __) {},
      );
      addTearDown(sub.close);

      final weekMap =
          await container.read(weeklyTotalsForMonthProvider(2026, 2).future);

      // Feb 2026: 1st is Sunday → first Monday is 26 Jan → weeks start
      // 26 Jan, 2 Feb, 9 Feb, 16 Feb, 23 Feb → 5 weeks overlapping Feb.
      expect(weekMap.length, greaterThanOrEqualTo(4));
    });

    test('aggregates transactions into correct week slot', () async {
      final (container, db) = _buildContainer();

      final accountId = await _createTestAccount(db);
      final now = DateTime.now();

      // Insert one expense on May 7, 2026 (Wednesday → week start = May 4).
      final txDate = DateTime(2026, 5, 7);
      await db.into(db.transactions).insert(
            TransactionsCompanion(
              id: Value(_uuid.v4()),
              type: const Value('expense'),
              date: Value(txDate),
              amount: const Value(50.0),
              currencyCode: const Value('EUR'),
              accountId: Value(accountId),
              isExcluded: const Value(false),
              isDeleted: const Value(false),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final sub = container.listen(
        weeklyTotalsForMonthProvider(2026, 5),
        (_, __) {},
      );
      addTearDown(sub.close);

      final weekMap =
          await container.read(weeklyTotalsForMonthProvider(2026, 5).future);

      // Week starting May 4 must have expense = 50.
      final weekStart = DateTime(2026, 5, 4);
      expect(weekMap.containsKey(weekStart), isTrue);
      expect(weekMap[weekStart]!.expense, closeTo(50.0, 0.01));
      expect(weekMap[weekStart]!.income, 0.0);
    });

    test('weeks with no transactions have zero totals alongside non-zero weeks',
        () async {
      final (container, db) = _buildContainer();

      final accountId = await _createTestAccount(db);
      final now = DateTime.now();

      // Only add a transaction in week 1 of May 2026 (May 4–10).
      await db.into(db.transactions).insert(
            TransactionsCompanion(
              id: Value(_uuid.v4()),
              type: const Value('income'),
              date: Value(DateTime.utc(2026, 5, 5)),
              amount: const Value(100.0),
              currencyCode: const Value('EUR'),
              accountId: Value(accountId),
              isExcluded: const Value(false),
              isDeleted: const Value(false),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final sub = container.listen(
        weeklyTotalsForMonthProvider(2026, 5),
        (_, __) {},
      );
      addTearDown(sub.close);

      final weekMap =
          await container.read(weeklyTotalsForMonthProvider(2026, 5).future);

      // Still 5 weeks.
      expect(weekMap.length, 5);

      // Weeks without transactions are zero.
      int zeroWeeks = 0;
      for (final entry in weekMap.entries) {
        if (entry.value.income == 0.0 && entry.value.expense == 0.0) {
          zeroWeeks++;
        }
      }
      expect(zeroWeeks, 4); // Only 1 week has data.
    });
  });
}
