# ADR-008: Client-Side Filtering for Transaction Search

## Status
Accepted — 2026-04-30

## Context
Sprint 6 adds transaction search and filter. Two implementation strategies:

### Option A — SQLite FTS5 (Full-Text Search)
Create a virtual FTS5 table that mirrors the `transactions` table's `description`
column. Queries use `MATCH` operator via a raw Drift `customSelect`. Requires a new
schema migration, a trigger to keep the FTS index in sync, and additional DAO methods.

### Option B — Client-Side Filtering on Reactive Stream
`TransactionRepository` already emits a `Stream<List<TransactionWithDetails>>` for
the selected month. A new `searchQueryProvider` (`StateProvider<String>`) and a
`transactionFilterProvider` (`StateNotifier<TransactionFilter>`) feed into a derived
`filteredTransactionsProvider` that applies `where` + `contains` predicates over the
already-loaded list.

## Decision
Use **Option B — client-side filtering**.

Rationale:
1. Transaction lists per month are bounded. At typical usage (≤500 txns/month) a
   `List.where` over an already-loaded list is imperceptible (<1 ms).
2. No schema migration needed; no FTS sync trigger to maintain.
3. The reactive Drift stream means search results update instantly when the DB changes.
4. FTS5 is justified only when searching across all months simultaneously (tens of
   thousands of rows). The search scope in Sprint 6 is the currently visible period.

Implementation:
```
searchQueryProvider           StateProvider<String>        (text input debounced 300 ms)
transactionFilterProvider     StateNotifier<TxFilter>       (type, category, date range)
filteredTransactionsProvider  StreamProvider (derived)      combines both providers
```

The existing `monthlyTransactionsWithDetailsProvider` is NOT modified.

## Consequences

### Positive
- Zero schema changes; no migration bump.
- No new native dependency.
- Existing Daily/Calendar/Monthly views are unaffected.
- Filter state is easy to unit test (pure Dart list predicates).

### Negative
- If a user has >2 000 transactions in a single month the linear scan could be
  noticeable. Documented as a known limitation.
- Cross-month / all-time search is not possible without FTS5 — deferred to a future sprint.

## References
- Drift FTS5: https://drift.simonbinder.eu/docs/advanced-features/fts5/
- Existing provider: `lib/features/transactions/presentation/providers/transactions_provider.dart`
