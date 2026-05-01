# ADR-010: Global Monthly Budget Field

## Status
Accepted — 2026-05-01 (Sponsor approved with multi-currency addendum)

## Context
Epic 8 introduces a Home Tab with a `BudgetPulseCard` widget that shows the user's
overall monthly spending health at a glance. The card needs a single "total budget"
figure to compare against the current month's total spending.

Two distinct figures can serve as this total budget:

1. **Category budget sum** — the sum of all active `BudgetEntity.amount` values for
   the current month, already available via `totalBudgetProvider` in
   `lib/features/budget/presentation/providers/budget_providers.dart`.
2. **Global monthly budget** — a single number the user sets independently of any
   category breakdown (e.g., "I want to spend at most €3 000 this month, regardless
   of how I categorise it").

The Product Sponsor confirmed that a global budget field is required (Approach B):
the user can define a global monthly ceiling independently of category budgets.
`BudgetPulseCard` uses the global value when set and falls back to the category
budget sum otherwise.

### Storage option analysis

**Option A — SharedPreferences key**
Add `pref_global_monthly_budget` (double encoded as String) to the existing
`AppPreferencesNotifier` in
`lib/features/more/presentation/providers/app_preferences_provider.dart`.

Pros: Zero schema migration; reads before the database opens; consistent with
how `themeMode`, `currencyCode`, and `languageCode` are stored (ADR-007).

Cons: The value is a financial figure, not a UI preference. Mixing financial
data with UI preferences violates single-responsibility and makes it harder to
migrate or export later. Also excluded from the encrypted SQLite database.

**Option B — `app_preferences` Drift table (key/value rows)**
Create a new `AppPreferences` Drift table with `key TEXT PK` + `value TEXT`.
Store `global_monthly_budget` as a row.

Pros: Encrypted at rest (SQLCipher, ADR-006); survives future Backup/Restore
(Epic 9, Sprint 7) automatically because it lives in the same DB.

Cons: Requires schema migration (schemaVersion 6 → 7); higher ceremony for a
single scalar value; the existing `AppPreferencesNotifier` becomes a hybrid
(SharedPreferences + Drift) or must be replaced entirely.

**Option C — New `global_monthly_budget` column on existing SharedPreferences
notifier (extend `AppPreferences` value class)**
Same as Option A but acknowledged explicitly as the minimal-change path.
Violates the same SRP concern.

**Option D — Separate `UserSettings` Drift table with typed columns**
A purpose-built table (`user_settings`) with a single row and strongly typed
columns for all user-configurable financial parameters (global budget, savings
goal %, default account, etc.). Future financial settings land here without
schema-per-setting migrations.

Pros: Financial data stays in the encrypted DB; single row design is simple;
scales to future settings without a new migration per field (use nullable columns
with defaults).

Cons: Requires migration 6 → 7; needs a new DAO + repository (~4 files). But
this cost is paid once and all future financial settings benefit.

## Decision
Use **Option D — a new `UserSettings` Drift table** with a single mandatory row
(`id = 1`).

The table starts with one nullable column:
```
user_settings (
  id             INTEGER PK DEFAULT 1 CHECK (id = 1),
  global_monthly_budget  REAL NULL   -- null = not set; uses category-sum fallback
)
```

A `UserSettingsDao` provides `watchSettings()` (stream) and
`upsertGlobalBudget(double? amount)`. A `UserSettingsRepository` wraps the DAO.
A new `globalBudgetProvider` (`StreamProvider<double?>`) emits the raw nullable
value; a derived `effectiveBudgetProvider(DateTime month)` emits the resolved
figure: global value if non-null, else `totalBudgetProvider(month).value`.

The `AppPreferencesNotifier` (SharedPreferences) is **not modified**; it remains
the owner of UI preferences only (theme, currency, language).

Schema version bumps: **6 → 7**.

### Priority rule
Global budget takes precedence over category budget sum when both are defined.
The UI may display a note such as "Based on your global budget" vs
"Based on your category budgets" to clarify the source.

### Fallback behaviour
When `global_monthly_budget IS NULL`:
- `effectiveBudgetProvider` delegates to `totalBudgetProvider(month)`.
- If no category budgets exist either, `effectiveBudgetProvider` emits `null`,
  and `BudgetPulseCard` renders a "Set a budget" call-to-action.

### Riverpod provider structure
```
userSettingsRepositoryProvider   Provider<UserSettingsRepository>
globalBudgetProvider             StreamProvider<double?>
effectiveBudgetProvider(month)   FutureProvider<double?>   (derived)
```

## Consequences

### Positive
- Financial data is encrypted at rest alongside transactions and budgets.
- Single-row `UserSettings` table is a forward-compatible home for future
  financial settings (savings goal rate, default account, etc.).
- `AppPreferencesNotifier` stays pure UI — no SRP violation.
- `effectiveBudgetProvider` encapsulates the fallback logic; `BudgetPulseCard`
  stays dumb.
- Covered by existing `NativeDatabase.memory()` test harness.

### Negative
- Schema migration required (6 → 7); all devices must run the migration.
- Four new files: `user_settings_table.dart`, `user_settings_dao.dart`,
  `user_settings_repository.dart`, `user_settings_providers.dart`.
- The single-row constraint (`CHECK (id = 1)`) must be enforced at the
  application layer in addition to SQL (Drift does not natively enforce CHECK).

### Flutter Engineer implementation notes
- Enforce `id = 1` in the DAO: always use `insertOnConflictUpdate` with `id = 1`;
  never expose an `insert` method that accepts arbitrary ids.
- Add the migration step inside the `onUpgrade` block in `database.dart`:
  `if (from < 7) { await m.createTable(userSettings); }`.
- Seed the row (`INSERT OR IGNORE INTO user_settings (id) VALUES (1)`) inside
  `onCreate` and in the `from < 7` migration branch so existing and new installs
  both have the singleton row.
- `effectiveBudgetProvider` must call `ref.watch` on both
  `globalBudgetProvider` and `totalBudgetProvider(month)` so it rebuilds when
  either changes.
- The `BudgetPulseCard` widget must handle `AsyncValue` loading/error states
  from `effectiveBudgetProvider` before rendering numbers.
- Do NOT store the global budget value in SharedPreferences — keep financial
  data in the encrypted Drift database.

## Multi-Currency Behaviour (V1 Assumption)

**Sponsor decision (2026-05-01):** V1 assumes a single primary currency for all budget
and balance calculations. The primary currency is the user's configured default currency
from Settings (`currencyCode` in `AppPreferencesNotifier`).

- `global_monthly_budget` is stored in the user's primary currency.
- Transactions in other currencies contribute their `exchangeRate`-normalised amount
  to totals (consistent with ADR-012 sparkline behaviour).
- If the user has accounts in a different currency and no exchange rate is set,
  those amounts are treated as 0 in budget calculations.
- Multi-currency aggregation (true net worth across currencies) is **deferred to V2**.
  A dedicated epic will address currency conversion rates and aggregate display.
- The `BudgetPulseCard` must display the primary currency symbol next to all amounts;
  it must NOT show a mixed-currency warning in V1.

Flutter Engineer must add a code comment in `effectiveBudgetProvider` referencing
this assumption so it is visible during the V2 migration.

## Alternatives Rejected
- **Option A / C (SharedPreferences)**: financial data must not live outside
  the encrypted database; mixing concerns into `AppPreferencesNotifier` violates
  SRP and breaks the Backup/Restore boundary (Sprint 7).
- **Option B (key/value Drift table)**: flexible but untyped; strongly-typed
  columns are preferable for a financial field where accidental type coercion
  (string → double) could corrupt values.

## References
- ADR-007: Theme persistence via SharedPreferences (UI preferences boundary)
- ADR-009: Separate Drift table pattern (Bookmarks)
- ADR-002: Drift database schema versioning
- Existing budget providers: `lib/features/budget/presentation/providers/budget_providers.dart`
- Schema: `lib/data/local/database.dart` (schemaVersion 6)
