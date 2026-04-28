# US-011: AccountGroups Drift table, DAO, and default seed data

## Persona
A MoneyWise user who expects predefined account group types to be present on first launch
(Cash, Accounts, Card, Debit Card, Savings, Top-Up/Prepaid, Investments, Overdrafts, Loan,
Insurance, Others) so that they can immediately add accounts without manual setup.

## Story
**As** a MoneyWise user
**I want** the app to ship with all standard account groups pre-populated in the database
**So that** I can add accounts immediately after install without configuring groups from scratch

## Source
SPEC.md §6.1 (accountGroups table definition); SPEC.md §7.3 (Asset / Liability classification);
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Default account groups are seeded on first launch
  Given the app is installed fresh on a device
  When the Drift database initialises for the first time
  Then the accountGroups table contains exactly 11 rows with the following names (in sort order):
    | sortOrder | name            | type           | includeInTotals |
    | 0         | Cash            | cash           | true            |
    | 1         | Accounts        | accounts       | true            |
    | 2         | Card            | card           | true            |
    | 3         | Debit Card      | debitCard      | true            |
    | 4         | Savings         | savings        | true            |
    | 5         | Top-Up/Prepaid  | topUpPrepaid   | true            |
    | 6         | Investments     | investments    | true            |
    | 7         | Overdrafts      | overdrafts     | true            |
    | 8         | Loan            | loan           | true            |
    | 9         | Insurance       | insurance      | true            |
    | 10        | Others          | others         | true            |
  And each row has a non-null UUID id
  And isDeleted is false for all rows

Scenario: Seed is idempotent — runs only once
  Given the database already contains the 11 default groups
  When the app is restarted (database re-opens)
  Then the accountGroups table still contains exactly 11 rows
  And no duplicate rows are created

Scenario: AccountGroupsDao.watchAll() streams all non-deleted groups
  Given the database is seeded with default groups
  When AccountGroupsDao.watchAll() is called
  Then the stream emits a list of 11 AccountGroup objects in sortOrder ascending order
  And none of the emitted items have isDeleted = true

Scenario: AccountGroupsDao.findById() returns the correct group
  Given the database is seeded
  When AccountGroupsDao.findById(id) is called with a valid UUID
  Then the matching AccountGroup is returned
  When called with an unknown UUID
  Then null is returned

Scenario: Soft-delete a default account group
  Given the accountGroups table contains the "Cash" group
  When AccountGroupsDao.softDelete(id) is called for "Cash"
  Then the row's isDeleted becomes true
  And updatedAt is refreshed to the current timestamp
  And AccountGroupsDao.watchAll() no longer emits "Cash"

Scenario: AccountGroups table schema matches SPEC.md §6.1
  Given the database is open
  Then the accountGroups table has columns:
    id (TEXT, PK), name (TEXT), type (TEXT), sortOrder (INTEGER),
    iconKey (TEXT nullable), includeInTotals (INTEGER/BOOL),
    createdAt (INTEGER/DATETIME), updatedAt (INTEGER/DATETIME),
    isDeleted (INTEGER/BOOL)
```

## Edge Cases
- [ ] App upgraded from Sprint 1 (no accountGroups table) — migration must CREATE TABLE and INSERT seeds without data loss on existing (empty) tables
- [ ] Two simultaneous app launches on the same device (edge case on Android multi-window) — seed transaction must be atomic; no duplicate inserts
- [ ] sortOrder collision — seed data must use unique sortOrder values; UI lists by sortOrder ASC
- [ ] iconKey is nullable — DAO must handle null gracefully; no crash on null iconKey
- [ ] Name max length 50 chars — seed data names are all within limit; DAO enforces constraint
- [ ] isDeleted soft-delete — hard delete is never performed on default groups; restore via isDeleted = false must be possible

## Test Scenarios for QA
1. Fresh install on iOS Simulator: verify 11 rows present in accountGroups table via debug DB inspector
2. Fresh install on Android Emulator: same check
3. Cold restart after first launch: row count remains 11 (no duplication)
4. Confirm all 11 types map correctly to their AccountGroupType enum values
5. Soft-delete a group via DAO: confirm it disappears from watchAll() stream but is recoverable by querying with isDeleted = true
6. Confirm schema migration from Sprint 1 DB (no tables) succeeds on both platforms without crash

## UX Spec
N/A — data layer story only, no UI.

## Estimate
S (1–2 days)

## Dependencies
- US-004 (Drift DB initialised) — table is added in the first real schema migration on top of the Sprint 1 DB stub
