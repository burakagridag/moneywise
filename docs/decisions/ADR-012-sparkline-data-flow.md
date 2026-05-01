# ADR-012: Stream-Based Data Flow for Sparkline (Last 30 Days)

## Status
Accepted — 2026-05-01

## Context
Epic 8 adds a sparkline chart to the Home Tab showing the user's daily net
balance (income − expense) over the last 30 days. The chart is decorative but
reactive: it must update when a transaction is added or edited.

The Product Sponsor confirmed: **no snapshot table**. The data is computed
on-the-fly from the `transactions` table via a DAO stream method.

### Design questions that must be resolved

1. **What value to plot per day** — absolute daily net (income − expense for
   that day) vs. cumulative running balance. The sparkline communicates trend,
   not absolute wealth; a per-day net figure is simpler to compute and avoids
   the complexity of tracking opening balance across account types.

2. **Which accounts to include** — all accounts where `include_in_totals = true`
   (the existing `Accounts.includeInTotals` column). Loan accounts are typically
   excluded by the user via this flag; the DAO query follows the same rule as the
   rest of the app rather than introducing a parallel exclusion list.

3. **Gap filling** — days with no transactions must appear as `0.0` (zero net),
   not as a missing point. The sparkline widget (`fl_chart`) requires a
   contiguous list of 30 data points.

4. **DAO placement** — the query touches only the `transactions` table and uses
   no joins that don't already exist in `TransactionDao`. Adding it to the
   existing `TransactionDao` keeps all transaction-related queries in one class
   and avoids creating a `BalanceDao` with a single method.

5. **Performance** — 30 days × typical 10–50 transactions/day = 300–1 500 rows
   scanned per emission. The existing composite index on `(is_deleted, date)` is
   sufficient; no additional index is required.

### Query shape options

**Option A — SQL GROUP BY date (aggregated in SQLite)**
```sql
SELECT
  DATE(date / 1000000, 'unixepoch') AS day,
  SUM(CASE WHEN type = 'income'  AND is_excluded = 0 THEN amount ELSE 0 END) AS income,
  SUM(CASE WHEN type = 'expense' AND is_excluded = 0 THEN amount ELSE 0 END) AS expense
FROM transactions
WHERE is_deleted = 0
  AND date >= :from
  AND date <  :to
GROUP BY day
ORDER BY day ASC
```
The Dart layer fills gaps and subtracts expense from income per day.

Pros: Minimal data transferred from SQLite to Dart; aggregation scales to any
number of transactions without holding all rows in memory.
Cons: `customSelect` bypasses Drift's code-gen; the query must be kept in sync
with the `Transactions` table schema manually.

**Option B — Dart-side aggregation over the existing stream**
Reuse `watchTransactionsByDateRange(from, to)` (already in `TransactionDao`),
then `map()` the emitted `List<Transaction>` in Dart to produce per-day buckets.
This is identical to the pattern used in `watchDailyTotals` (Sprint 4).

Pros: No raw SQL; fully type-safe; gap-filling logic is pure Dart and trivially
unit-testable; consistent with `watchDailyTotals` which already does per-day
bucketing.
Cons: All 30 days' transactions are materialised in memory on every emission.
At the expected usage volume this is imperceptible; if a user has >5 000
transactions in 30 days the scan takes ~5 ms on a mid-range device (acceptable).

## Decision
Use **Option B — Dart-side aggregation** via a new `watchDailyNetAmounts`
method in the existing `TransactionDao`.

The method reuses `watchTransactionsByDateRange` internally (or its underlying
query directly) and maps the stream to a `List<DailyNet>` with exactly 30
entries — one per calendar day from `today - 29` through `today`, with zero-fill
for days that have no transactions.

Only transactions from accounts where `includeInTotals = true` are counted.
Because the `Transactions` table does not store `includeInTotals` directly, the
filtering is applied at the Dart layer using account data already available via
the account stream, or — for simplicity in V1 — the method accepts an
`excludedAccountIds` set that the caller populates from `AccountRepository`.

### Value definition per day
```
dailyNet(day) = SUM(income.amount * exchangeRate) - SUM(expense.amount * exchangeRate)
```
Transfers are excluded (they do not affect net worth). `isExcluded` transactions
are excluded (consistent with all other aggregation methods). `exchangeRate`
normalises multi-currency amounts to the base currency.

### Data model
```dart
// lib/data/local/daos/transaction_dao.dart  (added alongside DayTotals)
class DailyNet {
  const DailyNet({required this.date, required this.netAmount});

  /// Calendar date with time zeroed (UTC midnight).
  final DateTime date;

  /// income - expense for this day, in base currency. May be negative.
  final double netAmount;
}
```

### New DAO method signature
```dart
/// Emits a fixed-length list of [DailyNet] for the last [days] calendar days
/// (default 30), ending on [referenceDate] (default today).
///
/// Always emits exactly [days] entries; days with no qualifying transactions
/// have [DailyNet.netAmount] == 0.0.
///
/// Transactions from [excludedAccountIds] are omitted so that accounts
/// with [includeInTotals] == false are not counted.
Stream<List<DailyNet>> watchDailyNetAmounts({
  DateTime? referenceDate,
  int days = 30,
  Set<String> excludedAccountIds = const {},
})
```

### Riverpod provider
```dart
// lib/features/home/presentation/providers/sparkline_provider.dart

@riverpod
Stream<List<DailyNet>> sparklineData(SparklineDataRef ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
  final excluded = accounts
      .where((a) => !a.includeInTotals)
      .map((a) => a.id)
      .toSet();

  return ref
      .watch(appDatabaseProvider)
      .transactionDao
      .watchDailyNetAmounts(excludedAccountIds: excluded);
}
```

The Home Tab `SparklineCard` widget watches `sparklineDataProvider` via a
`StreamProvider` and passes the 30 `DailyNet.netAmount` values to `fl_chart`'s
`LineChartData`.

### Gap-filling algorithm
```dart
// Inside watchDailyNetAmounts — Dart map() on the stream
final today = referenceDate ?? DateTime.now();
final window = List.generate(days, (i) {
  final d = today.subtract(Duration(days: days - 1 - i));
  return DateTime(d.year, d.month, d.day);
});

// Build a map from date key → cents
final Map<String, int> centsByDay = {};
for (final tx in txList) {
  if (tx.isDeleted || tx.isExcluded) continue;
  if (tx.type == 'transfer') continue;
  if (excludedAccountIds.contains(tx.accountId)) continue;
  final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
  final delta = tx.type == 'income'
      ? (tx.amount * tx.exchangeRate * 100).round()
      : -(tx.amount * tx.exchangeRate * 100).round();
  centsByDay[key] = (centsByDay[key] ?? 0) + delta;
}

return window.map((d) {
  final key = '${d.year}-${d.month}-${d.day}';
  return DailyNet(date: d, netAmount: (centsByDay[key] ?? 0) / 100.0);
}).toList();
```

Integer cent accumulation is used to avoid IEEE 754 drift, consistent with
`watchMonthlyTotals` and `watchDailyTotals` (BUG-010 fix pattern).

### Indexes
The existing indexes created in schema v3 are sufficient:
- `idx_tx_date ON transactions (date)` — bounds the 30-day date range.
- `idx_tx_deleted ON transactions (is_deleted)` — filters soft-deleted rows.

No new index is required for V1 volumes.

## Consequences

### Positive
- No schema change; no migration bump.
- Consistent with `watchDailyTotals` — same bucketing pattern, easy to review.
- Pure Dart gap-filling logic is unit-testable with a fixed set of mock
  transactions and a fixed `referenceDate`.
- `DailyNet` is added to the existing `transaction_dao.dart` file; no new file.
- The `sparklineDataProvider` is a `StreamProvider` — the Home Tab reacts
  immediately when the user adds or edits a transaction.

### Negative
- All qualifying transactions in the 30-day window are materialised in Dart on
  every DB emission. At typical usage (≤1 500 rows) this is negligible; at
  extreme usage (>5 000 rows/month) a ~5 ms map pass may be observable. The
  SQL-aggregation approach (Option A) can replace this in a future sprint without
  changing the Riverpod layer or the UI.
- Multi-currency normalisation uses `exchangeRate` stored on each transaction.
  If exchange rates are not kept up to date, historical sparkline values may
  drift. This is a known limitation shared with all other balance calculations.

### Flutter Engineer implementation notes
- Add `DailyNet` class immediately after `DayTotals` in `transaction_dao.dart`.
  Keep both data classes in the same file; do not create a new file for a single
  data class.
- The `watchDailyNetAmounts` method must be placed in `TransactionDao` (not a
  new `BalanceDao`). The `BalanceDao` option is explicitly rejected to avoid
  fragmenting transaction query logic.
- `referenceDate` parameter defaults to `DateTime.now()` when null but must be
  injectable for tests. Always pass an explicit `referenceDate` in tests; never
  rely on wall-clock time in unit tests.
- The `SparklineCard` widget must handle the `AsyncValue.loading` state with a
  shimmer placeholder — never show an empty chart frame during the initial load.
- When `sparklineDataProvider` emits an error, `SparklineCard` shows a
  non-blocking error indicator (not a full-screen error page).
- `fl_chart` `LineChartData` requires `x` values as `double`; use the list index
  (0.0 – 29.0) as the x-axis. Do not use epoch millis as x — the chart clips
  values outside the `minX`/`maxX` range.
- Keep `excludedAccountIds` derivation inside the provider, not inside the DAO.
  The DAO method accepts a `Set<String>` parameter so it remains testable without
  account repository involvement.

## Alternatives Rejected
- **Snapshot table**: adds write complexity (a snapshot must be written on every
  transaction mutation), creates a data synchronisation risk, and requires a
  schema migration. Rejected by Product Sponsor.
- **SQL GROUP BY (Option A)**: raw `customSelect` bypasses type safety; deferred
  as a performance optimisation if Dart-side bucketing proves too slow at scale.
- **New BalanceDao**: splitting a single closely related query into a separate DAO
  class adds file overhead with no architectural benefit at this scale. All
  transaction queries stay in `TransactionDao`.
- **StreamProvider with asyncExpand over account stream**: overly complex for V1;
  instead, `sparklineDataProvider` reads accounts once via `ref.watch` and passes
  the exclusion set to the DAO.

## References
- ADR-002: Drift database, existing indexes (schemaVersion 3 migration)
- ADR-008: Client-side aggregation pattern (precedent for Dart-side `map`)
- Existing per-day aggregation: `TransactionDao.watchDailyTotals`
  (`lib/data/local/daos/transaction_dao.dart`)
- fl_chart: https://pub.dev/packages/fl_chart
- Accounts table `includeInTotals` column:
  `lib/data/local/tables/accounts_table.dart`
