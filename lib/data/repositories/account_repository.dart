// Repository providing account and account-group operations to the domain layer — data/repositories feature.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../local/daos/account_dao.dart';

// database.dart re-exports the generated Account, AccountGroup, AccountsCompanion,
// AccountGroupsCompanion data classes via its .g.dart part file.
import '../local/database.dart';

import '../../domain/entities/account.dart' as domain;
import '../../domain/entities/account_group.dart' as domain;

part 'account_repository.g.dart';

/// Riverpod provider that wires [AccountRepository] to [AppDatabase].
@riverpod
AccountRepository accountRepository(AccountRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepository(db.accountDao);
}

/// Mediates between the data layer (Drift DAOs) and the domain layer.
/// All public methods work exclusively with domain entities.
class AccountRepository {
  AccountRepository(this._dao);

  final AccountDao _dao;

  // ---------------------------------------------------------------------------
  // Account Groups
  // ---------------------------------------------------------------------------

  /// Reactive stream of all non-deleted account groups.
  Stream<List<domain.AccountGroup>> watchGroups() => _dao.watchAllGroups().map(
        (rows) => rows.map(_mapGroup).toList(),
      );

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  /// Reactive stream of all non-deleted accounts.
  Stream<List<domain.Account>> watchAccounts() => _dao.watchAllAccounts().map(
        (rows) => rows.map(_mapAccount).toList(),
      );

  /// Reactive stream of accounts belonging to [groupId].
  Stream<List<domain.Account>> watchAccountsByGroup(String groupId) =>
      _dao.watchAccountsByGroup(groupId).map(
            (rows) => rows.map(_mapAccount).toList(),
          );

  /// Persists a new account derived from the domain entity.
  Future<void> addAccount(domain.Account account) =>
      _dao.insertAccount(_toAccountCompanion(account));

  /// Updates an existing account.
  Future<void> updateAccount(domain.Account account) =>
      _dao.updateAccount(_toAccountCompanion(account));

  /// Soft-deletes an account by [id].
  Future<void> deleteAccount(String id) => _dao.softDeleteAccount(id);

  // ---------------------------------------------------------------------------
  // Mapping — data → domain
  // ---------------------------------------------------------------------------

  domain.AccountGroup _mapGroup(AccountGroup row) => domain.AccountGroup(
        id: row.id,
        name: row.name,
        type: row.type,
        sortOrder: row.sortOrder,
        iconKey: row.iconKey,
        includeInTotals: row.includeInTotals,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isDeleted: row.isDeleted,
      );

  domain.Account _mapAccount(Account row) => domain.Account(
        id: row.id,
        groupId: row.groupId,
        name: row.name,
        description: row.description,
        currencyCode: row.currencyCode,
        initialBalance: row.initialBalance,
        sortOrder: row.sortOrder,
        isHidden: row.isHidden,
        includeInTotals: row.includeInTotals,
        iconKey: row.iconKey,
        colorHex: row.colorHex,
        statementDay: row.statementDay,
        paymentDueDay: row.paymentDueDay,
        creditLimit: row.creditLimit,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isDeleted: row.isDeleted,
      );

  // ---------------------------------------------------------------------------
  // Mapping — domain → data
  // ---------------------------------------------------------------------------

  AccountsCompanion _toAccountCompanion(domain.Account a) => AccountsCompanion(
        id: Value(a.id),
        groupId: Value(a.groupId),
        name: Value(a.name),
        description: Value(a.description),
        currencyCode: Value(a.currencyCode),
        initialBalance: Value(a.initialBalance),
        sortOrder: Value(a.sortOrder),
        isHidden: Value(a.isHidden),
        includeInTotals: Value(a.includeInTotals),
        iconKey: Value(a.iconKey),
        colorHex: Value(a.colorHex),
        statementDay: Value(a.statementDay),
        paymentDueDay: Value(a.paymentDueDay),
        creditLimit: Value(a.creditLimit),
        createdAt: Value(a.createdAt),
        updatedAt: Value(DateTime.now()),
        isDeleted: Value(a.isDeleted),
      );
}
