# Story EPIC8A-04 — UserSettings Table + Migration + Providers

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** none
**Phase:** 1

## Description

Implement the `UserSettings` Drift table as specified in ADR-010. This story delivers the full data layer for the global monthly budget field: the table definition, schema migration (version 6 → 7), DAO, repository, and Riverpod providers. No UI is produced here; the providers are consumed by `BudgetPulseCard` in EPIC8A-07.

The table uses a single-row constraint (`id = 1`, enforced at the DAO layer). The `global_monthly_budget` column is nullable REAL — `null` means "not set, fall back to category budget sum". The `effectiveBudgetProvider` encapsulates the fallback logic so widgets stay dumb.

This story also extends the `UserSettings` table to hold `savings_goal_pct` (nullable REAL, null = not set) as a forward-compatible column, since ADR-011 references it as a future configurable threshold for `SavingsGoalRule`. Adding it now avoids a second migration when Epic 8b ships the rule.

## Inputs (agent must read)

- `docs/decisions/ADR-010-global-budget-field.md` — full spec including table DDL, provider names, fallback behavior, and Flutter Engineer implementation notes
- `docs/decisions/ADR-011-insight-provider-interface.md` — references `savings_goal_pct` as a future configurable threshold
- `lib/data/local/database.dart` — current `schemaVersion` (6) and `onUpgrade` block to extend
- `lib/data/local/tables/` — existing table files for naming conventions
- `lib/data/local/daos/` — existing DAOs for patterns to follow
- `lib/features/budget/presentation/providers/budget_providers.dart` — `totalBudgetProvider` that `effectiveBudgetProvider` delegates to

## Outputs (agent must produce)

- `lib/data/local/tables/user_settings_table.dart` — Drift table definition with `id INTEGER PK CHECK (id=1)`, `global_monthly_budget REAL NULL`, `savings_goal_pct REAL NULL`
- `lib/data/local/daos/user_settings_dao.dart` — `watchSettings()` (Stream) and `upsertGlobalBudget(double? amount)` methods; enforce `id = 1` via `insertOnConflictUpdate`; never expose arbitrary-id insert
- `lib/features/home/data/user_settings_repository.dart` — wraps DAO, exposes typed methods
- `lib/features/home/presentation/providers/user_settings_providers.dart` — three providers:
  - `userSettingsRepositoryProvider` (`Provider<UserSettingsRepository>`)
  - `globalBudgetProvider` (`StreamProvider<double?>`)
  - `effectiveBudgetProvider(DateTime month)` (`FutureProvider<double?>`) with `// V1 ASSUMPTION: single primary currency` comment per ADR-010
- `lib/data/local/database.dart` — `schemaVersion` bumped to 7; migration block added; `onCreate` seeds the singleton row
- `test/features/home/user_settings_dao_test.dart` — unit tests: watch emits null on fresh DB, upsert updates value, upsert with null clears value, second upsert does not create a second row
- `docs/prs/epic8a-04.md` — PR description with migration notes and test results

## Acceptance Criteria

- [ ] `schemaVersion` in `database.dart` is 7
- [ ] Migration branch `if (from < 7)` creates the `user_settings` table and seeds the singleton row (`INSERT OR IGNORE INTO user_settings (id) VALUES (1)`)
- [ ] `onCreate` also seeds the singleton row so fresh installs work
- [ ] `upsertGlobalBudget(150.0)` followed by `watchSettings()` emits `global_monthly_budget = 150.0`
- [ ] `upsertGlobalBudget(null)` followed by `watchSettings()` emits `global_monthly_budget = null`
- [ ] A second call to `upsertGlobalBudget` never creates a second row (confirmed by `SELECT COUNT(*) FROM user_settings` = 1)
- [ ] `effectiveBudgetProvider` returns the global value when non-null
- [ ] `effectiveBudgetProvider` delegates to `totalBudgetProvider(month)` when global value is null
- [ ] `effectiveBudgetProvider` emits null when both global budget and category budgets are absent
- [ ] `effectiveBudgetProvider` code contains `// V1 ASSUMPTION` comment referencing ADR-010
- [ ] All unit tests pass; `flutter analyze` and `dart format` pass
- [ ] Existing app data is unaffected (migration is additive only)

## Out of Scope

- UI for setting the global budget (that is part of Budget tab, deferred)
- `savings_goal_pct` write path / UI (column created now; DAO method for it comes in Epic 8b)
- Any change to `AppPreferencesNotifier` or SharedPreferences

## Quality Bar

The migration must be tested against a fresh install AND a simulated upgrade (existing `NativeDatabase.memory()` test seeded with schema version 6 data). The PR must include both test cases.
