# US-012: Accounts Drift table and DAO

## Persona
A MoneyWise user who has multiple real-world accounts (a debit card, a savings account, a credit
card) and expects the app to store each one with the correct attributes so balances can be tracked
accurately.

## Story
**As** a MoneyWise user
**I want** the app to persist account records in a structured local database table
**So that** my accounts and their initial balances are reliably stored and queryable

## Source
SPEC.md §6.2 (accounts table definition); SPEC.md §7.1 (balance calculation — currentBalance is
NOT stored, computed dynamically); SPEC.md §7.3 (Asset / Liability distinction).
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Insert a new account record
  Given the accountGroups table contains the "Debit Card" group
  When AccountsDao.insertAccount() is called with:
    | field          | value                              |
    | id             | (new UUID v4)                      |
    | groupId        | (UUID of "Debit Card" group)       |
    | name           | "My Visa Debit"                    |
    | currencyCode   | "EUR"                              |
    | initialBalance | 500.00                             |
    | isHidden       | false                              |
    | includeInTotals| true                               |
  Then the row is persisted in the accounts table
  And createdAt and updatedAt are set to the current timestamp

Scenario: Update an existing account
  Given an account "My Visa Debit" exists with initialBalance 500.00
  When AccountsDao.updateAccount() is called with initialBalance = 750.00 and name = "Visa Debit"
  Then the accounts table reflects name = "Visa Debit" and initialBalance = 750.00
  And updatedAt is refreshed

Scenario: Soft-delete an account
  Given an account "My Visa Debit" exists with isDeleted = false
  When AccountsDao.softDelete(id) is called
  Then isDeleted becomes true
  And AccountsDao.watchAllActive() no longer emits that account

Scenario: watchAllActive() streams only non-deleted accounts ordered by sortOrder
  Given three accounts exist, one with isDeleted = true
  When AccountsDao.watchAllActive() is called
  Then the stream emits exactly two accounts in sortOrder ASC order

Scenario: watchAccountsByGroup(groupId) streams accounts for a given group
  Given accounts belonging to group "Cash" and group "Accounts" exist
  When AccountsDao.watchAccountsByGroup(cashGroupId) is called
  Then only Cash accounts are emitted

Scenario: Card-specific fields are stored and retrieved
  Given a "Card" group account is inserted with:
    | field          | value |
    | statementDay   | 15    |
    | paymentDueDay  | 5     |
    | creditLimit    | 2000  |
  When AccountsDao.findById(id) is called
  Then statementDay = 15, paymentDueDay = 5, creditLimit = 2000.0 are returned

Scenario: Non-card account has nullable card fields
  Given a "Cash" account is inserted without card fields
  When AccountsDao.findById(id) is called
  Then statementDay, paymentDueDay, and creditLimit are all null

Scenario: currencyCode validation
  Given a new account insert is attempted
  When currencyCode is not exactly 3 characters
  Then the DAO throws a DriftDatabaseException (constraint violation)

Scenario: name length boundary
  When name is an empty string
  Then the DAO throws a constraint exception (min 1)
  When name is 50 characters
  Then the insert succeeds
  When name is 51 characters
  Then the DAO throws a constraint exception (max 50)
```

## Edge Cases
- [ ] Duplicate name within the same group — Drift schema does not enforce uniqueness on name; business logic in repository (US-014) must warn the user
- [ ] initialBalance can be negative (e.g. an overdrawn account imported from another source) — no DB constraint prevents negative values; repository must allow it
- [ ] currentBalance is never stored — any attempt to add a currentBalance column is a spec violation; balance is always computed via transaction aggregation (SPEC.md §7.1)
- [ ] groupId FK — inserting an account with a non-existent groupId must fail with FK constraint; Drift FK enforcement must be enabled (PRAGMA foreign_keys = ON)
- [ ] colorHex format — no DB-level format check; repository layer validates #RRGGBB format before insert
- [ ] sortOrder default 0 — multiple accounts may share sortOrder 0; sort-stability is the responsibility of the repository / UI layer
- [ ] isHidden accounts — watchAllActive() must still include hidden accounts (hidden ≠ deleted); UI layer filters display; DAO returns all non-deleted
- [ ] Offline — all operations are local-first; no network dependency in Sprint 2

## Test Scenarios for QA
1. Insert a Cash account: verify all fields persist correctly on both iOS and Android
2. Insert a Card account: verify statementDay, paymentDueDay, creditLimit persist and are nullable for non-card accounts
3. Update account name and initialBalance: confirm DB reflects change and updatedAt updated
4. Soft-delete account: confirm watchAllActive() stream removes it; raw query still finds it (isDeleted = true)
5. FK enforcement: insert account with invalid groupId — confirm app-level error (no crash)
6. Name boundary test: empty name and 51-char name both produce an expected error
7. currencyCode boundary: 2-char and 4-char codes produce constraint errors

## UX Spec
N/A — data layer story only, no UI.

## Estimate
S (1–2 days)

## Dependencies
- US-011 (AccountGroups table must exist — FK target)
- US-004 (Drift DB initialised)
