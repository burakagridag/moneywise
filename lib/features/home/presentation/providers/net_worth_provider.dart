// Riverpod providers for total balance and previous-month balance — home feature (EPIC8A-06).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/account.dart' as domain;

part 'net_worth_provider.g.dart';

/// Emits the sum of the computed balance for all accounts where
/// [domain.Account.includeInTotals] == true.
///
/// Uses pure stream composition (no rxdart) to avoid the `async*` + `ref.watch`
/// anti-pattern that caused perpetual `AsyncLoading`:
///
/// - The accounts stream drives the outer `asyncExpand`, which re-subscribes
///   the inner combined-balance stream whenever the account list changes.
/// - The inner stream opens one `watchAccountBalance` stream per included
///   account and emits their running sum via a [StreamController] that closes
///   when superseded.
///
/// This guarantees that [accountsTotalProvider] transitions to `AsyncData`
/// exactly once per emission of any upstream stream, with no intermediate
/// `AsyncLoading` flicker.
@riverpod
Stream<double> accountsTotal(AccountsTotalRef ref) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  return accountRepo.watchAccounts().asyncExpand(
        (accounts) => _combineBalances(accounts, txRepo),
      );
}

/// Combines per-account balance streams for [accounts] that have
/// [domain.Account.includeInTotals] == true into a single `Stream<double>`.
///
/// Emits 0.0 immediately when there are no included accounts.
/// Otherwise opens one reactive balance stream per account and emits
/// the running sum every time any individual balance changes.
Stream<double> _combineBalances(
  List<domain.Account> accounts,
  TransactionRepository txRepo,
) {
  final included = accounts.where((a) => a.includeInTotals).toList();

  if (included.isEmpty) {
    return Stream.value(0.0);
  }

  // One stream per account — each emits the computed balance reactively.
  final streams = included
      .map((a) => txRepo.watchAccountBalance(a.id))
      .toList(growable: false);

  // Maintain a list of the most-recent value from each stream.
  // Initialised to null; we only emit a sum once every stream has a value.
  final latestValues = List<double?>.filled(streams.length, null);

  final controller = StreamController<double>();

  final subscriptions = <StreamSubscription<double>>[];
  for (var i = 0; i < streams.length; i++) {
    final index = i;
    final sub = streams[index].listen(
      (balance) {
        latestValues[index] = balance;
        if (latestValues.every((v) => v != null)) {
          // All streams have at least one value — safe to sum.
          final total = latestValues.fold<double>(0.0, (sum, v) => sum + v!);
          if (!controller.isClosed) controller.add(total);
        }
      },
      onError: controller.addError,
    );
    subscriptions.add(sub);
  }

  // Cancel all subscriptions AND close the controller to release resources.
  controller.onCancel = () async {
    await Future.wait(subscriptions.map((s) => s.cancel()));
    await controller.close();
  };

  return controller.stream;
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

  // Sum initial balances for included accounts using integer cent accumulation
  // to avoid IEEE 754 float drift (BUG-010). Consistent with watchDailyNetAmounts
  // and watchMonthlyTotals in TransactionDao.
  int prevCents =
      included.fold(0, (sum, a) => sum + (a.initialBalance * 100).round());

  // Add transaction deltas up to end of previous month.
  for (final tx in txList) {
    if (tx.isExcluded || tx.isDeleted) continue;
    if (excludedIds.contains(tx.accountId)) continue;

    final deltaCents = (tx.amount * tx.exchangeRate * 100).round();

    if (tx.type == 'income' && includedIds.contains(tx.accountId)) {
      prevCents += deltaCents;
    } else if (tx.type == 'expense' && includedIds.contains(tx.accountId)) {
      prevCents -= deltaCents;
    } else if (tx.type == 'transfer') {
      if (includedIds.contains(tx.accountId)) prevCents -= deltaCents;
      if (tx.toAccountId != null && includedIds.contains(tx.toAccountId)) {
        prevCents += deltaCents;
      }
    }
  }

  return prevCents / 100.0;
}

// ---------------------------------------------------------------------------
// Testing shim — makes _combineBalances accessible for unit tests without
// exposing it as part of the public API.
// ---------------------------------------------------------------------------

/// Thin wrapper around [_combineBalances] that makes it accessible from tests.
///
/// Only intended for use in `net_worth_provider_test.dart`.
@visibleForTesting
Stream<double> combineBalancesForTesting(
  List<domain.Account> accounts,
  TransactionRepository txRepo,
) =>
    _combineBalances(accounts, txRepo);
