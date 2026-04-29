// Unit tests for AccountDao write paths and non-watch methods — data/local feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() {
    db = _openTestDb();
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // getGroups — non-reactive read
  // ---------------------------------------------------------------------------

  group('AccountDao.getGroups', () {
    test('returns 11 default groups after seeding', () async {
      final groups = await db.accountDao.getGroups();
      expect(groups.length, 11);
    });

    test('groups are ordered by sortOrder ascending', () async {
      final groups = await db.accountDao.getGroups();
      for (var i = 1; i < groups.length; i++) {
        expect(
            groups[i].sortOrder, greaterThanOrEqualTo(groups[i - 1].sortOrder));
      }
    });

    test('soft-deleted groups are excluded from getGroups', () async {
      // Insert an additional group then manually soft-delete it via raw update.
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertGroup(
        AccountGroupsCompanion(
          id: Value(id),
          name: const Value('TestGroup'),
          type: const Value('cash'),
          sortOrder: const Value(99),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      // Mark it deleted by inserting with isDeleted=true directly.
      // We use a fresh insert with a different id to test filtering.
      final id2 = _uuid.v4();
      await db.accountDao.insertGroup(
        AccountGroupsCompanion(
          id: Value(id2),
          name: const Value('DeletedGroup'),
          type: const Value('others'),
          sortOrder: const Value(100),
          includeInTotals: const Value(true),
          isDeleted: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final groups = await db.accountDao.getGroups();
      expect(groups.any((g) => g.id == id), isTrue);
      expect(groups.any((g) => g.id == id2), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // insertGroup
  // ---------------------------------------------------------------------------

  group('AccountDao.insertGroup', () {
    test('inserted group appears in watchAllGroups stream', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertGroup(
        AccountGroupsCompanion(
          id: Value(id),
          name: const Value('Crypto'),
          type: const Value('investments'),
          sortOrder: const Value(50),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final groups = await db.accountDao.watchAllGroups().first;
      expect(groups.any((g) => g.id == id && g.name == 'Crypto'), isTrue);
    });

    test('inserted group appears in getGroups', () async {
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertGroup(
        AccountGroupsCompanion(
          id: Value(id),
          name: const Value('Forex'),
          type: const Value('investments'),
          sortOrder: const Value(51),
          includeInTotals: const Value(false),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final groups = await db.accountDao.getGroups();
      final found = groups.firstWhere((g) => g.id == id);
      expect(found.name, 'Forex');
      expect(found.includeInTotals, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // insertAccount + watchAllAccounts + watchAccountsByGroup
  // ---------------------------------------------------------------------------

  group('AccountDao.insertAccount', () {
    Future<String> getFirstGroupId() async {
      final groups = await db.accountDao.getGroups();
      return groups.first.id;
    }

    test('inserted account appears in watchAllAccounts', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupId),
          name: const Value('Savings Jar'),
          currencyCode: const Value('EUR'),
          initialBalance: const Value(500.0),
          sortOrder: const Value(0),
          isHidden: const Value(false),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final list = await db.accountDao.watchAllAccounts().first;
      expect(list.any((a) => a.id == id && a.name == 'Savings Jar'), isTrue);
    });

    test('inserted account appears in watchAccountsByGroup', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupId),
          name: const Value('Piggy Bank'),
          currencyCode: const Value('USD'),
          initialBalance: const Value(0.0),
          sortOrder: const Value(1),
          isHidden: const Value(false),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final list = await db.accountDao.watchAccountsByGroup(groupId).first;
      expect(list.any((a) => a.id == id), isTrue);
    });

    test('account from different group does not appear in watchAccountsByGroup',
        () async {
      final groups = await db.accountDao.getGroups();
      final groupA = groups[0].id;
      final groupB = groups[1].id;
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupA),
          name: const Value('Account A'),
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
      final listB = await db.accountDao.watchAccountsByGroup(groupB).first;
      expect(listB.any((a) => a.id == id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // updateAccount
  // ---------------------------------------------------------------------------

  group('AccountDao.updateAccount', () {
    Future<String> getFirstGroupId() async {
      final groups = await db.accountDao.getGroups();
      return groups.first.id;
    }

    test('updateAccount changes the account name', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupId),
          name: const Value('Before'),
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
      await db.accountDao.updateAccount(
        AccountsCompanion(
          id: Value(id),
          name: const Value('After'),
          groupId: Value(groupId),
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
      final list = await db.accountDao.watchAllAccounts().first;
      expect(list.firstWhere((a) => a.id == id).name, 'After');
    });

    test('updateAccount changes initialBalance', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupId),
          name: const Value('Balance Test'),
          currencyCode: const Value('EUR'),
          initialBalance: const Value(100.0),
          sortOrder: const Value(0),
          isHidden: const Value(false),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.accountDao.updateAccount(
        AccountsCompanion(
          id: Value(id),
          name: const Value('Balance Test'),
          groupId: Value(groupId),
          currencyCode: const Value('EUR'),
          initialBalance: const Value(999.0),
          sortOrder: const Value(0),
          isHidden: const Value(false),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final list = await db.accountDao.watchAllAccounts().first;
      expect(list.firstWhere((a) => a.id == id).initialBalance, 999.0);
    });
  });

  // ---------------------------------------------------------------------------
  // softDeleteAccount
  // ---------------------------------------------------------------------------

  group('AccountDao.softDeleteAccount', () {
    Future<String> getFirstGroupId() async {
      final groups = await db.accountDao.getGroups();
      return groups.first.id;
    }

    test('soft-deleted account is excluded from watchAllAccounts', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(id),
          groupId: Value(groupId),
          name: const Value('Gone'),
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
      await db.accountDao.softDeleteAccount(id);
      final list = await db.accountDao.watchAllAccounts().first;
      expect(list.any((a) => a.id == id), isFalse);
    });

    test('soft-delete of non-existent id does not throw', () async {
      await expectLater(
        db.accountDao.softDeleteAccount(_uuid.v4()),
        completes,
      );
    });
  });
}
