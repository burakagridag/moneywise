// Unit tests for AccountRepository mapping logic — data/repositories feature.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // watchGroups — seeding
  // ---------------------------------------------------------------------------

  group('watchGroups', () {
    test('emits 11 default groups after DB creation', () async {
      // Seed runs in onCreate inside AppDatabase.forTesting only when a
      // migration is triggered; for in-memory DBs we call _seedDefaultData
      // manually by re-running onCreate.
      // Since forTesting uses the same MigrationStrategy, we just wait for
      // the first emission.
      final groups = await repository.watchGroups().first;
      expect(groups.length, 11);
    });

    test('groups are ordered by sortOrder', () async {
      final groups = await repository.watchGroups().first;
      for (var i = 1; i < groups.length; i++) {
        expect(
            groups[i].sortOrder, greaterThanOrEqualTo(groups[i - 1].sortOrder));
      }
    });

    test('first group maps correctly', () async {
      final groups = await repository.watchGroups().first;
      final first = groups.first;
      expect(first.name, 'Cash');
      expect(first.type, 'cash');
      expect(first.includeInTotals, isTrue);
      expect(first.isDeleted, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // addAccount / watchAccounts — round-trip mapping
  // ---------------------------------------------------------------------------

  group('addAccount + watchAccounts', () {
    Future<String> getFirstGroupId() async {
      final groups = await repository.watchGroups().first;
      return groups.first.id;
    }

    test('adding an account makes it appear in watchAccounts', () async {
      final groupId = await getFirstGroupId();
      final now = DateTime.now();
      final account = domain.Account(
        id: _uuid.v4(),
        groupId: groupId,
        name: 'My Wallet',
        currencyCode: 'EUR',
        initialBalance: 100.0,
        sortOrder: 0,
        isHidden: false,
        includeInTotals: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.addAccount(account);
      final accounts = await repository.watchAccounts().first;

      expect(accounts.length, 1);
      expect(accounts.first.name, 'My Wallet');
      expect(accounts.first.currencyCode, 'EUR');
      expect(accounts.first.initialBalance, 100.0);
      expect(accounts.first.includeInTotals, isTrue);
    });

    test('soft-deleted account is excluded from watchAccounts', () async {
      final groupId = await getFirstGroupId();
      final now = DateTime.now();
      final id = _uuid.v4();
      final account = domain.Account(
        id: id,
        groupId: groupId,
        name: 'Temp Account',
        currencyCode: 'USD',
        initialBalance: 0.0,
        sortOrder: 0,
        isHidden: false,
        includeInTotals: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.addAccount(account);
      await repository.deleteAccount(id);

      final accounts = await repository.watchAccounts().first;
      expect(accounts.where((a) => a.id == id), isEmpty);
    });

    test('updateAccount changes the name', () async {
      final groupId = await getFirstGroupId();
      final now = DateTime.now();
      final id = _uuid.v4();
      final account = domain.Account(
        id: id,
        groupId: groupId,
        name: 'Old Name',
        currencyCode: 'EUR',
        initialBalance: 0.0,
        sortOrder: 0,
        isHidden: false,
        includeInTotals: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      await repository.addAccount(account);
      final updated = account.copyWith(name: 'New Name');
      await repository.updateAccount(updated);

      final accounts = await repository.watchAccounts().first;
      expect(accounts.first.name, 'New Name');
    });
  });

  // ---------------------------------------------------------------------------
  // Riverpod provider wiring
  // ---------------------------------------------------------------------------

  group('accountRepositoryProvider', () {
    test('provider creates AccountRepository', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => _openTestDb()),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(accountRepositoryProvider);
      expect(repo, isA<AccountRepository>());
    });
  });
}
