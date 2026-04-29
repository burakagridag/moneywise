// Unit tests for AccountWriteNotifier and stream providers — accounts feature.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/account_repository.dart';
import 'package:moneywise/domain/entities/account.dart' as domain_account;
import 'package:moneywise/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Builds a [ProviderContainer] backed by an in-memory database.
(ProviderContainer, AppDatabase) _buildContainer() {
  final db = _openTestDb();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((_) => db),
    ],
  );
  return (container, db);
}

domain_account.Account _buildAccount({
  required String id,
  required String groupId,
  String name = 'Test Account',
  String currency = 'EUR',
  double balance = 0.0,
  bool isHidden = false,
}) {
  final now = DateTime.now();
  return domain_account.Account(
    id: id,
    groupId: groupId,
    name: name,
    currencyCode: currency,
    initialBalance: balance,
    sortOrder: 0,
    isHidden: isHidden,
    includeInTotals: true,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // accountGroupsProvider
  // ---------------------------------------------------------------------------

  group('accountGroupsProvider', () {
    test('emits 11 default account groups', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(accountGroupsProvider.future);
      expect(result.length, 11);
    });

    test('all groups are non-deleted', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(sub.close);

      final groups = await container.read(accountGroupsProvider.future);
      for (final g in groups) {
        expect(g.isDeleted, isFalse);
      }
    });

    test('groups are ordered by sortOrder', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(sub.close);

      final groups = await container.read(accountGroupsProvider.future);
      for (var i = 1; i < groups.length; i++) {
        expect(
            groups[i].sortOrder, greaterThanOrEqualTo(groups[i - 1].sortOrder));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // allAccountsProvider — read-only assertions (no mutations)
  // ---------------------------------------------------------------------------

  group('allAccountsProvider', () {
    test('emits empty list when no accounts have been added', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final sub = container.listen(allAccountsProvider, (_, __) {});
      addTearDown(sub.close);

      final result = await container.read(allAccountsProvider.future);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // AccountWriteNotifier.addAccount — verified via repository stream directly
  // ---------------------------------------------------------------------------
  //
  // After a write via the notifier, the Drift-backed AccountRepository stream
  // emits the updated list. We test the notifier delegates to the repository
  // correctly by checking the repository's stream (which bypasses the
  // AutoDispose provider cache-refresh timing issue).

  group('AccountWriteNotifier.addAccount', () {
    test('added account appears in repository watchAccounts stream', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      // Keep group provider alive for ID lookup.
      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final id = _uuid.v4();
      final account =
          _buildAccount(id: id, groupId: groupId, name: 'Added By Notifier');

      await container
          .read(accountWriteNotifierProvider.notifier)
          .addAccount(account);

      // Read directly from the repository's stream for reliable post-write check.
      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      expect(accounts.any((a) => a.id == id && a.name == 'Added By Notifier'),
          isTrue);
    });

    test('multiple accounts can be added sequentially', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final notifier = container.read(accountWriteNotifierProvider.notifier);

      await notifier.addAccount(
          _buildAccount(id: _uuid.v4(), groupId: groupId, name: 'Acc 1'));
      await notifier.addAccount(
          _buildAccount(id: _uuid.v4(), groupId: groupId, name: 'Acc 2'));
      await notifier.addAccount(
          _buildAccount(id: _uuid.v4(), groupId: groupId, name: 'Acc 3'));

      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      expect(accounts.length, 3);
    });

    test('added account fields are persisted correctly', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final id = _uuid.v4();
      final account = _buildAccount(
        id: id,
        groupId: groupId,
        name: 'EUR Wallet',
        currency: 'EUR',
        balance: 250.0,
        isHidden: true,
      );

      await container
          .read(accountWriteNotifierProvider.notifier)
          .addAccount(account);

      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      final saved = accounts.firstWhere((a) => a.id == id);
      expect(saved.name, 'EUR Wallet');
      expect(saved.currencyCode, 'EUR');
      expect(saved.initialBalance, 250.0);
      expect(saved.isHidden, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // AccountWriteNotifier.updateAccount
  // ---------------------------------------------------------------------------

  group('AccountWriteNotifier.updateAccount', () {
    test('updated account name is reflected in repository stream', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final id = _uuid.v4();
      final notifier = container.read(accountWriteNotifierProvider.notifier);
      final account = _buildAccount(id: id, groupId: groupId, name: 'Original');

      await notifier.addAccount(account);
      await notifier.updateAccount(account.copyWith(name: 'Renamed'));

      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      expect(accounts.firstWhere((a) => a.id == id).name, 'Renamed');
    });

    test('updateAccount changes currency code', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final id = _uuid.v4();
      final notifier = container.read(accountWriteNotifierProvider.notifier);
      final account = _buildAccount(id: id, groupId: groupId, currency: 'EUR');

      await notifier.addAccount(account);
      await notifier.updateAccount(account.copyWith(currencyCode: 'USD'));

      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      expect(accounts.firstWhere((a) => a.id == id).currencyCode, 'USD');
    });

    test('updateAccount changes initialBalance', () async {
      final (container, db) = _buildContainer();
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      final groupSub = container.listen(accountGroupsProvider, (_, __) {});
      addTearDown(groupSub.close);

      final groups = await container.read(accountGroupsProvider.future);
      final groupId = groups.first.id;
      final id = _uuid.v4();
      final notifier = container.read(accountWriteNotifierProvider.notifier);
      final account = _buildAccount(id: id, groupId: groupId, balance: 0.0);

      await notifier.addAccount(account);
      await notifier.updateAccount(account.copyWith(initialBalance: 1234.56));

      final repo = container.read(accountRepositoryProvider);
      final accounts = await repo.watchAccounts().first;
      expect(accounts.firstWhere((a) => a.id == id).initialBalance, 1234.56);
    });
  });
}
