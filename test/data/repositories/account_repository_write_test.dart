// Additional write-path integration tests for AccountRepository — data/repositories feature.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/account_repository.dart';
import 'package:moneywise/domain/entities/account.dart' as domain;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late AccountRepository repository;

  setUp(() {
    db = _openTestDb();
    repository = AccountRepository(db.accountDao);
  });

  tearDown(() async => db.close());

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String> getFirstGroupId() async {
    final groups = await repository.watchGroups().first;
    return groups.first.id;
  }

  domain.Account buildTestAccount({
    required String id,
    required String groupId,
    String name = 'Test Account',
    String currency = 'EUR',
    double balance = 0.0,
  }) {
    final now = DateTime.now();
    return domain.Account(
      id: id,
      groupId: groupId,
      name: name,
      currencyCode: currency,
      initialBalance: balance,
      sortOrder: 0,
      isHidden: false,
      includeInTotals: true,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  // ---------------------------------------------------------------------------
  // watchAccountsByGroup
  // ---------------------------------------------------------------------------

  group('watchAccountsByGroup', () {
    test('returns only accounts belonging to the specified group', () async {
      final groups = await repository.watchGroups().first;
      final groupA = groups[0].id;
      final groupB = groups[1].id;

      await repository.addAccount(
          buildTestAccount(id: _uuid.v4(), groupId: groupA, name: 'AccA'));
      await repository.addAccount(
          buildTestAccount(id: _uuid.v4(), groupId: groupB, name: 'AccB'));

      final listA = await repository.watchAccountsByGroup(groupA).first;
      final listB = await repository.watchAccountsByGroup(groupB).first;

      expect(listA.every((a) => a.groupId == groupA), isTrue);
      expect(listB.every((a) => a.groupId == groupB), isTrue);
      expect(listA.any((a) => a.name == 'AccA'), isTrue);
      expect(listB.any((a) => a.name == 'AccB'), isTrue);
    });

    test('stream is empty when no accounts belong to group', () async {
      final groups = await repository.watchGroups().first;
      final emptyGroup = groups.last.id;
      final list = await repository.watchAccountsByGroup(emptyGroup).first;
      expect(list, isEmpty);
    });

    test('soft-deleted accounts are excluded from watchAccountsByGroup',
        () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account =
          buildTestAccount(id: id, groupId: groupId, name: 'SoftDel');
      await repository.addAccount(account);
      await repository.deleteAccount(id);
      final list = await repository.watchAccountsByGroup(groupId).first;
      expect(list.any((a) => a.id == id), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // updateAccount — domain field propagation
  // ---------------------------------------------------------------------------

  group('updateAccount — field propagation', () {
    test('updates currency code', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account =
          buildTestAccount(id: id, groupId: groupId, currency: 'EUR');
      await repository.addAccount(account);
      await repository.updateAccount(account.copyWith(currencyCode: 'USD'));
      final list = await repository.watchAccounts().first;
      expect(list.firstWhere((a) => a.id == id).currencyCode, 'USD');
    });

    test('updates initialBalance', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account =
          buildTestAccount(id: id, groupId: groupId, balance: 100.0);
      await repository.addAccount(account);
      await repository.updateAccount(account.copyWith(initialBalance: 9999.99));
      final list = await repository.watchAccounts().first;
      expect(list.firstWhere((a) => a.id == id).initialBalance, 9999.99);
    });

    test('updates isHidden flag', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account = buildTestAccount(id: id, groupId: groupId);
      await repository.addAccount(account);
      await repository.updateAccount(account.copyWith(isHidden: true));
      final list = await repository.watchAccounts().first;
      expect(list.firstWhere((a) => a.id == id).isHidden, isTrue);
    });

    test('updates optional creditLimit field', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account = buildTestAccount(id: id, groupId: groupId);
      await repository.addAccount(account);
      await repository.updateAccount(account.copyWith(creditLimit: 5000.0));
      final list = await repository.watchAccounts().first;
      expect(list.firstWhere((a) => a.id == id).creditLimit, 5000.0);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteAccount — idempotent
  // ---------------------------------------------------------------------------

  group('deleteAccount', () {
    test('deleting same id twice does not throw', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      await repository.addAccount(buildTestAccount(id: id, groupId: groupId));
      await repository.deleteAccount(id);
      await expectLater(repository.deleteAccount(id), completes);
    });

    test('other accounts remain after targeted delete', () async {
      final groupId = await getFirstGroupId();
      final idA = _uuid.v4();
      final idB = _uuid.v4();
      await repository.addAccount(
          buildTestAccount(id: idA, groupId: groupId, name: 'KeepMe'));
      await repository.addAccount(
          buildTestAccount(id: idB, groupId: groupId, name: 'DeleteMe'));
      await repository.deleteAccount(idB);
      final list = await repository.watchAccounts().first;
      expect(list.any((a) => a.id == idA), isTrue);
      expect(list.any((a) => a.id == idB), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // addAccount — optional field mapping
  // ---------------------------------------------------------------------------

  group('addAccount — optional field mapping', () {
    test('optional fields are null when not provided', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final account = buildTestAccount(id: id, groupId: groupId);
      await repository.addAccount(account);
      final list = await repository.watchAccounts().first;
      final saved = list.firstWhere((a) => a.id == id);
      expect(saved.description, isNull);
      expect(saved.iconKey, isNull);
      expect(saved.colorHex, isNull);
      expect(saved.statementDay, isNull);
      expect(saved.paymentDueDay, isNull);
      expect(saved.creditLimit, isNull);
    });

    test('optional fields are persisted when provided', () async {
      final groupId = await getFirstGroupId();
      final id = _uuid.v4();
      final now = DateTime.now();
      final account = domain.Account(
        id: id,
        groupId: groupId,
        name: 'Full Account',
        description: 'My main account',
        currencyCode: 'EUR',
        initialBalance: 200.0,
        sortOrder: 5,
        isHidden: false,
        includeInTotals: true,
        iconKey: 'wallet',
        colorHex: '#FF0000',
        statementDay: 1,
        paymentDueDay: 15,
        creditLimit: 2000.0,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );
      await repository.addAccount(account);
      final list = await repository.watchAccounts().first;
      final saved = list.firstWhere((a) => a.id == id);
      expect(saved.description, 'My main account');
      expect(saved.iconKey, 'wallet');
      expect(saved.colorHex, '#FF0000');
      expect(saved.statementDay, 1);
      expect(saved.paymentDueDay, 15);
      expect(saved.creditLimit, 2000.0);
    });
  });
}
