// Riverpod providers exposing account and account-group streams to the UI — accounts feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/account_group.dart';

part 'accounts_provider.g.dart';

/// Emits a reactive list of all non-deleted account groups.
@riverpod
Stream<List<AccountGroup>> accountGroups(AccountGroupsRef ref) =>
    ref.watch(accountRepositoryProvider).watchGroups();

/// Emits a reactive list of all non-deleted accounts.
@riverpod
Stream<List<Account>> allAccounts(AllAccountsRef ref) =>
    ref.watch(accountRepositoryProvider).watchAccounts();

/// Reactive stream of the computed balance for a single account.
/// Balance = initialBalance + SUM(income) - SUM(expense) ± SUM(transfers).
@riverpod
Stream<double> accountBalance(AccountBalanceRef ref, String accountId) =>
    ref.watch(transactionRepositoryProvider).watchAccountBalance(accountId);

/// Notifier that exposes write operations for accounts.
/// Screens must use this notifier instead of importing the repository directly.
@riverpod
class AccountWriteNotifier extends _$AccountWriteNotifier {
  @override
  void build() {}

  /// Persists a new [account] via the repository.
  Future<void> addAccount(Account account) =>
      ref.read(accountRepositoryProvider).addAccount(account);

  /// Updates an existing [account] via the repository.
  Future<void> updateAccount(Account account) =>
      ref.read(accountRepositoryProvider).updateAccount(account);
}
