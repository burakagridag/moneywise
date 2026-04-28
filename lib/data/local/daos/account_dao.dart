// Data access object for account groups and accounts — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/account_groups_table.dart';
import '../tables/accounts_table.dart';

part 'account_dao.g.dart';

/// Provides CRUD and reactive query methods for AccountGroups and Accounts.
@DriftAccessor(tables: [AccountGroups, Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  // ---------------------------------------------------------------------------
  // Account Groups
  // ---------------------------------------------------------------------------

  /// Emits the full list of non-deleted groups ordered by [sortOrder].
  Stream<List<AccountGroup>> watchAllGroups() => (select(accountGroups)
        ..where((g) => g.isDeleted.equals(false))
        ..orderBy([(g) => OrderingTerm(expression: g.sortOrder)]))
      .watch();

  /// Returns all non-deleted groups once (non-reactive).
  Future<List<AccountGroup>> getGroups() => (select(accountGroups)
        ..where((g) => g.isDeleted.equals(false))
        ..orderBy([(g) => OrderingTerm(expression: g.sortOrder)]))
      .get();

  /// Inserts a new account group.
  Future<void> insertGroup(AccountGroupsCompanion group) =>
      into(accountGroups).insert(group);

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  /// Emits all non-deleted accounts ordered by [sortOrder].
  Stream<List<Account>> watchAllAccounts() => (select(accounts)
        ..where((a) => a.isDeleted.equals(false))
        ..orderBy([(a) => OrderingTerm(expression: a.sortOrder)]))
      .watch();

  /// Emits accounts belonging to [groupId] (non-deleted only).
  Stream<List<Account>> watchAccountsByGroup(String groupId) =>
      (select(accounts)
            ..where(
              (a) => a.isDeleted.equals(false) & a.groupId.equals(groupId),
            ))
          .watch();

  /// Inserts a new account.
  Future<void> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  /// Replaces all mutable fields on an existing account.
  Future<void> updateAccount(AccountsCompanion account) =>
      (update(accounts)..where((a) => a.id.equals(account.id.value)))
          .write(account);

  /// Marks an account as deleted without removing the row (soft delete).
  Future<void> softDeleteAccount(String id) =>
      (update(accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
