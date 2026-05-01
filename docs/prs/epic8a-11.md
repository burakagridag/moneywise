# PR: EPIC8A-11 — Pull-to-Refresh + Tab Focus Invalidation

## Summary

Replaces the TODO stubs in `HomeScreen.onRefresh` with real provider invalidation
calls and wires the tab-focus invalidation mechanism so the Home tab reflects
transaction mutations made on other tabs without requiring a manual pull-to-refresh.

## Pull-to-Refresh

`RefreshIndicator.onRefresh` now:

1. Captures a fresh `DateTime.now()` inside the callback (avoids stale build-time
   reference).
2. Calls `ref.invalidate(insightsProvider)`, `ref.invalidate(previousMonthTotalProvider)`,
   and `ref.invalidate(effectiveBudgetProvider(month))` to force re-fetch of all
   non-streaming home providers.
3. Awaits `ref.read(insightsProvider.future)` so the spinner does not dismiss until
   the slowest non-streaming provider has resolved.
4. Does NOT invalidate `sparklineDataProvider` or `recentTransactionsProvider` —
   both are `StreamProvider`s backed by Drift reactive queries and update
   automatically (ADR-011).

## Tab Focus Invalidation — Chosen Approach

**Mutation signal (`TransactionMutationSignal`)** — ADR-011 §Reactive Behaviour,
Option B.

A new `@riverpod class TransactionMutationSignal extends _$TransactionMutationSignal`
provider (a simple `AutoDisposeNotifier<int>`) is incremented after every successful
`addTransaction`, `updateTransaction`, and `deleteTransaction` call inside
`TransactionWriteNotifier`.

`HomeScreen.build` registers a `ref.listen(transactionMutationSignalProvider, ...)` that
invalidates `insightsProvider` and `previousMonthTotalProvider` whenever the counter
increments.

### Why mutation signal over go_router route listening

- No dependency on the routing layer — the signal works even if navigation
  implementation changes (e.g., replacing go_router).
- Trivially testable: assert the counter increments in a `ProviderContainer` unit test.
- Simpler: no `RouteInformationProvider` subscription, no `WidgetsBindingObserver`.
- Consistent with existing Riverpod-first patterns in this codebase.

### ADR-011 reference

ADR-011 §Reactive Behaviour — V1 Compensating Mechanisms explicitly lists this as
an accepted implementation option.

## Files Changed

| File | Change |
|---|---|
| `lib/features/home/presentation/screens/home_screen.dart` | Pull-to-refresh body; `ref.listen` for mutation signal |
| `lib/features/transactions/presentation/providers/transaction_mutation_signal_provider.dart` | New — `TransactionMutationSignal` notifier |
| `lib/features/transactions/presentation/providers/transaction_mutation_signal_provider.g.dart` | Generated |
| `lib/features/transactions/presentation/providers/transactions_provider.dart` | Increment signal in all three write methods |

## Manual Test Steps

1. Launch the app and navigate to the Transactions tab.
2. Add a new expense transaction (any amount, category, account).
3. Tap Save — the form dismisses.
4. Navigate to the Home tab **without** pulling to refresh.
5. Confirm the insights section (ThisWeekSection) and balance card reflect the
   newly added transaction's data.
6. Return to the Transactions tab, open the transaction, change the amount, save.
7. Navigate to the Home tab — confirm the data has updated.
8. Delete the transaction, return to Home tab — confirm the data has updated.

> Expected: the Home tab reflects mutations made in the Transactions tab without
> requiring a manual pull-to-refresh gesture, satisfying EPIC8A-11 AC #2–#4.

## StreamProvider Confirmation (AC #5)

`sparklineDataProvider` and `recentTransactionsProvider` are generated with the
`@riverpod` annotation returning `Stream<...>` — they are backed by Drift's
`watchTransactionsForMonth` / `watchRecentTransactions` reactive queries.
These streams are never cancelled between tab switches (Riverpod keeps them alive
as long as there is a listener). No explicit invalidation is needed or performed.

## No Double-Refresh Race (AC #6)

`ref.listen` invalidation and `RefreshIndicator.onRefresh` invalidation both call
`ref.invalidate(insightsProvider)`. Riverpod de-duplicates rapid consecutive
invalidations — if the provider is already loading, a second invalidation simply
re-queues a rebuild after the in-flight future resolves. No duplicate DB calls or
crashes result.
