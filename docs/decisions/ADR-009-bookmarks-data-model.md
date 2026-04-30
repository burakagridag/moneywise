# ADR-009: Bookmarks as a Separate Drift Table

## Status
Accepted — 2026-04-30

## Context
Sprint 6 adds "bookmarks" — named transaction templates a user can tap to pre-fill
the Add Transaction form quickly.

Two modelling options:

### Option A — Reuse Transactions table with an `isTemplate` flag
Add a boolean column `isTemplate` to the existing `Transactions` table. Template rows
are excluded from balance calculations via the existing `isExcluded` flag.

Cons:
- All transaction queries must add `WHERE is_template = 0` to avoid polluting live data.
- Semantically wrong: a bookmark is a reusable pattern, not a historical ledger event.
- Soft-delete and sync semantics designed for events do not map cleanly to templates.

### Option B — Separate `Bookmarks` table
A dedicated Drift table with its own DAO, repository, and provider. Columns mirror
the fields a user would pre-fill: name, amount (nullable), type, categoryId,
accountId, toAccountId, note. No `date` column (date is always "now" when instantiated).

## Decision
Use **Option B — separate `Bookmarks` table**.

The separation keeps the transactions ledger clean, requires no changes to existing
DAOs, and allows the bookmark entity to evolve independently (e.g. adding a
`usageCount` column for frequency-based sorting later).

Schema version bumps: 5 → 6 (add Bookmarks table).

## Consequences

### Positive
- Zero impact on existing transaction queries and DAOs.
- Bookmark entity can have bookmark-specific fields without cluttering transactions schema.
- Clear separation of concerns between ledger and templates.

### Negative
- New migration step (schemaVersion 5 → 6).
- Additional DAO + repository + provider files (~6 new files).

## References
- Existing transactions table: `lib/data/local/tables/transactions_table.dart`
- Drift migrations: https://drift.simonbinder.eu/docs/advanced-features/migrations/
