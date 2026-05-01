// Riverpod providers for total balance and previous-month balance — home feature (EPIC8A-06).
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/account_repository.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

part 'net_worth_provider.g.dart';

/// Emits the sum of [Account.balance] for all accounts where
/// [Account.includeInTotals] == true.
///
/// The balance is kept reactive: it re-emits whenever any account stream
/// emits. Per-account balance computation relies on [watchAccountBalance] in
/// [TransactionDao]; here we aggregate the current stored balances from
/// [allAccountsProvider] combined with [AccountBalanceProvider] per account.
///
/// For simplicity in V1 we sum [Account.initialBalance] plus the delta
/// computed via [accountBalanceProvider] for each included account. This avoids
/// coupling the provider to a raw SQL aggregation and stays consistent with the
/// existing per-account balance calculation.
@riverpod
Stream<double> accountsTotal(AccountsTotalRef ref) async* {
  final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
  final included = accounts.where((a) => a.includeInTotals).toList();

  if (included.isEmpty) {
    yield 0.0;
    return;
  }

  // Watch each included account's reactive balance, sum them.
  // Re-evaluates whenever any account changes.
  double total = 0.0;
  for (final account in included) {
    final balance =
        ref.watch(accountBalanceProvider(account.id)).valueOrNull ?? 0.0;
    total += balance;
  }
  yield total;
}

/// One-shot Future returning the total balance one calendar month ago.
///
/// Computes the previous month's balance by reading all transactions up to the
/// first day of the current month and summing them (income − expense ± transfers)
/// added to the sum of initial balances. This is an approximation; a full
/// point-in-time balance requires a snapshot. For V1 the app uses
/// [TransactionDao.getTransactionsByDateRange] on the previous month and sums
/// with initial balances.
@riverpod
Future<double?> previousMonthTotal(PreviousMonthTotalRef ref) async {
  final now = DateTime.now();
  final startOfCurrentMonth = DateTime(now.year, now.month);
  final startOfPreviousMonth = DateTime(now.year, now.month - 1);

  final db = ref.watch(appDatabaseProvider);
  final accountRepo = ref.watch(accountRepositoryProvider);

  final accounts = await accountRepo.watchAccounts().first;
  final included = accounts.where((a) => a.includeInTotals).toList();

  if (included.isEmpty) return null;

  final includedIds = included.map((a) => a.id).toSet();
  final excludedIds =
      accounts.where((a) => !a.includeInTotals).map((a) => a.id).toSet();

  // Transactions up to (exclusive) the start of the current month.
  final txList = await db.transactionDao.getTransactionsByDateRange(
    startOfPreviousMonth,
    startOfCurrentMonth,
  );

  // Sum initial balances for included accounts.
  double prevTotal = included.fold(0.0, (sum, a) => sum + a.initialBalance);

  // Add transaction deltas up to end of previous month.
  for (final tx in txList) {
    if (tx.isExcluded || tx.isDeleted) continue;
    if (excludedIds.contains(tx.accountId)) continue;

    if (tx.type == 'income' && includedIds.contains(tx.accountId)) {
      prevTotal += tx.amount * tx.exchangeRate;
    } else if (tx.type == 'expense' && includedIds.contains(tx.accountId)) {
      prevTotal -= tx.amount * tx.exchangeRate;
    } else if (tx.type == 'transfer') {
      if (includedIds.contains(tx.accountId)) {
        prevTotal -= tx.amount * tx.exchangeRate;
      }
      if (tx.toAccountId != null && includedIds.contains(tx.toAccountId)) {
        prevTotal += tx.amount * tx.exchangeRate;
      }
    }
  }

  return prevTotal;
}
