// Riverpod providers exposing account and account-group streams to the UI — accounts feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/account_repository.dart';
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
