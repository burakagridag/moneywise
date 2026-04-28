# US-014: AccountRepository and CategoryRepository

## Persona
A MoneyWise flutter-engineer building UI features (AccountsScreen, CategoryManagementScreen)
who needs clean, testable domain-layer interfaces to read and mutate accounts and categories
without coupling UI code directly to Drift DAOs.

## Story
**As** the MoneyWise codebase
**I want** AccountRepository and CategoryRepository that wrap the DAOs with business-rule
validation and expose Riverpod-compatible reactive streams
**So that** all feature UI providers interact with a single source of truth and business rules
are enforced in one place rather than scattered across widgets

## Source
SPEC.md §5 (Repository pattern, Clean Architecture); SPEC.md §6.1–6.3 (data model);
SPEC.md §7.3 (asset/liability classification must be applied at repository level).
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
# ─── AccountRepository ────────────────────────────────────────────────────

Scenario: watchAllAccountGroups() returns reactive stream of non-deleted groups
  Given the database is seeded with default account groups
  When AccountRepository.watchAllAccountGroups() is subscribed to
  Then the stream emits all 11 non-deleted groups in sortOrder ASC order

Scenario: watchAccountsByGroup(groupId) returns accounts for that group
  Given two accounts in group "Cash" and one in group "Accounts" exist
  When AccountRepository.watchAccountsByGroup(cashGroupId) is subscribed
  Then only the two Cash accounts are emitted (non-deleted, sortOrder ASC)

Scenario: addAccount() enforces no-duplicate-name-within-group rule
  Given account "Main Wallet" already exists in group "Cash"
  When AccountRepository.addAccount() is called with name = "Main Wallet" in group "Cash"
  Then a DuplicateNameFailure is returned (Result pattern)
  And no new row is inserted in the database

Scenario: addAccount() succeeds for unique name within group
  Given no account named "Savings Pot" exists in group "Savings"
  When AccountRepository.addAccount() is called with name = "Savings Pot", group = "Savings"
  Then the account is inserted
  And a Success result is returned

Scenario: updateAccount() enforces no-duplicate-name rule
  Given accounts "Alpha" and "Beta" both in group "Cash"
  When AccountRepository.updateAccount() renames "Alpha" to "Beta" (same group)
  Then a DuplicateNameFailure is returned
  And the database row for "Alpha" remains unchanged

Scenario: deleteAccount() is rejected when transactions are linked
  Given account "My Bank" has 3 linked transactions
  When AccountRepository.deleteAccount(id) is called
  Then an AccountHasTransactionsFailure is returned
  And isDeleted remains false

Scenario: deleteAccount() soft-deletes account with no transactions
  Given account "Empty Account" has no linked transactions
  When AccountRepository.deleteAccount(id) is called
  Then isDeleted becomes true
  And the account is no longer emitted by watchAllAccountGroups()

Scenario: watchNetWorth() computes Assets - |Liabilities| total
  Given accounts with the following computed balances:
    | name          | group type | computed balance |
    | Wallet        | cash       | 200.00           |
    | Bank          | accounts   | 1000.00          |
    | Visa Card     | card       | -350.00          |
  When AccountRepository.watchNetWorth() is subscribed to
  Then it emits 1200.00 - 350.00 = 850.00 (Assets - Liabilities)

# ─── CategoryRepository ───────────────────────────────────────────────────

Scenario: watchCategories(type) streams active categories of given type
  Given the database is seeded
  When CategoryRepository.watchCategories('expense') is subscribed
  Then 21 expense categories are emitted in sortOrder ASC

Scenario: addCategory() enforces unique name within type
  Given category "Coffee Shops" of type expense already exists
  When CategoryRepository.addCategory() is called with name = "Coffee Shops", type = expense
  Then a DuplicateNameFailure is returned

Scenario: addCategory() succeeds for unique name
  Given no "Side Income" income category exists
  When CategoryRepository.addCategory() is called with name = "Side Income", type = income
  Then the category is inserted and a Success result returned

Scenario: deleteCategory() with linked transactions prompts re-assignment
  Given category "Food" has 5 linked transactions
  When CategoryRepository.deleteCategory(id) is called
  Then a CategoryHasTransactionsFailure is returned
  And the caller must resolve by reassigning transactions to another category
    (this resolution call is: CategoryRepository.reassignAndDelete(fromId, toId))

Scenario: reassignAndDelete() atomically reassigns and soft-deletes
  Given category "Food" has 5 linked transactions
  And category "Other" exists as the target
  When CategoryRepository.reassignAndDelete(foodId, otherId) is called
  Then all 5 transactions now have categoryId = otherId
  And "Food" category has isDeleted = true
  And the operation is atomic (either all succeed or none)

Scenario: deleteCategory() is rejected for isDefault = true categories
  Given category "Other" (isDefault = true) exists
  When CategoryRepository.deleteCategory(id) is called
  Then a CannotDeleteDefaultCategoryFailure is returned
  And isDeleted remains false

Scenario: updateSortOrder() batch-updates sortOrder for drag-to-reorder
  Given expense categories with sortOrders [0, 1, 2, 3]
  When CategoryRepository.updateSortOrder([(id1, 3), (id2, 0), (id3, 1), (id4, 2)]) is called
  Then all four rows are updated atomically
  And the next stream emission reflects the new order
```

## Edge Cases
- [ ] Repository methods return typed failures via Result/Either pattern — no uncaught exceptions propagating to UI
- [ ] All mutating operations are wrapped in Drift transactions — partial success is not possible
- [ ] watchNetWorth() must reactively re-compute whenever any account's transactions change (Sprint 3+ will add transactions; repository must be structured for reactive composition)
- [ ] Currency mismatch in net worth — in Sprint 2 all accounts are assumed to share the main currency; multi-currency aggregation is deferred to Sprint 5 (flag in code with TODO)
- [ ] Riverpod providers exposing repository streams must be defined in the accounts/providers/ and more/providers/ directories per SPEC.md §5 folder structure
- [ ] Offline — all operations are local-first; no network calls in this story

## Test Scenarios for QA
1. Add two accounts with the same name in the same group: second add returns DuplicateNameFailure
2. Add two accounts with the same name in different groups: both succeed
3. Delete an account with linked transactions: AccountHasTransactionsFailure returned, DB unchanged
4. Delete an account with no transactions: isDeleted = true confirmed in DB
5. watchNetWorth() updates when a new account with a non-zero initialBalance is added
6. Delete default "Other" category: CannotDeleteDefaultCategoryFailure returned
7. reassignAndDelete(): verify transaction categoryId updated and source category soft-deleted atomically (test failure mid-transaction — inject error — confirm rollback)
8. updateSortOrder() for all expense categories: verify stream order updates

## UX Spec
N/A — data / domain layer story only, no UI.

## Estimate
M (3–4 days)

## Dependencies
- US-011 (AccountGroups table and DAO)
- US-012 (Accounts table and DAO)
- US-013 (Categories table and DAO)
