# US-027: Budget DB layer — Drift table, DAO, repository, and carry-over use case

## Persona
A MoneyWise developer (flutter-engineer) who needs a reliable, well-tested data foundation
for all budget features so that BudgetView and BudgetSettingScreen can be built on top of it.

## Story
**As** the flutter-engineer
**I want** a complete Budget data layer (Drift table, DAO, BudgetRepository, and
CarryOverBudget use case) wired into the existing database and Riverpod provider graph
**So that** BudgetView (US-028), BudgetSettingScreen (US-029), and the SummaryView budget
card (US-024) can query and mutate budget data reactively without direct DB access

## Source
SPEC.md §6.5 (budgets table); SPEC.md §7 (double-entry behaviour); SPEC.md §16.1 Sprint 5;
SPEC.md §9.3.5 (BudgetView carry-over).

## Acceptance Criteria

```gherkin
Scenario: BudgetDAO can insert a new monthly budget for a category
  Given the Drift database is initialised
  And the category "Food" exists with id "cat-food-001"
  When BudgetDAO.upsert is called with:
    | categoryId    | "cat-food-001"  |
    | amount        | 400.00          |
    | currencyCode  | "EUR"           |
    | period        | "monthly"       |
    | effectiveFrom | 2026-04-01      |
    | effectiveTo   | null            |
    | carryOver     | false           |
  Then a row is inserted in the budgets table with isDeleted = false
  And BudgetDAO.watchAll emits the new row within 1 second

Scenario: BudgetDAO supports a TOTAL budget (categoryId = null)
  Given no existing TOTAL budget
  When BudgetDAO.upsert is called with categoryId = null and amount = 1500.00
  Then the row is stored with categoryId null
  And BudgetRepository.watchTotalBudget emits the new row

Scenario: Editing a budget for a specific month creates a time-bounded override
  Given a budget for "Food" with effectiveFrom = 2026-01-01, effectiveTo = null
  When the user edits the budget for April 2026 only (thisMonthOnly = true)
  Then the existing row is updated: effectiveTo = 2026-03-31
  And a new row is inserted: effectiveFrom = 2026-04-01, effectiveTo = 2026-04-30
  And BudgetRepository.watchForMonth(2026, 4) emits only the April-specific row

Scenario: Editing a budget for all future months closes only the active row
  Given a budget for "Food" with effectiveFrom = 2026-01-01, effectiveTo = null
  When the user edits the budget as default for all future months (thisMonthOnly = false)
  Then the old row is updated: effectiveTo = yesterday
  And a new row is inserted: effectiveFrom = today, effectiveTo = null

Scenario: BudgetRepository calculates the spent amount for a category in a given month
  Given April 2026 has expense transactions:
    | Category | Amount |
    | Food     | 120.00 |
    | Food     | 85.50  |
  When BudgetRepository.getSpentAmount(categoryId: "cat-food-001", year: 2026, month: 4)
    is called
  Then the result is 205.50

Scenario: CarryOverBudget use case adds the previous month's unspent remainder
  Given March 2026 budget for "Food" is 400.00
  And March 2026 actual spending for "Food" is 310.00 (remainder = 90.00)
  And the "Food" budget has carryOverEnabled = true
  And April 2026 budget for "Food" is 400.00
  When CarryOverBudget.execute(categoryId: "cat-food-001", year: 2026, month: 4) is called
  Then the effective budget for April 2026 returns 490.00 (400.00 + 90.00 carry-over)

Scenario: CarryOverBudget does not carry over when previous month overspent
  Given March 2026 budget for "Food" is 400.00
  And March 2026 actual spending is 430.00 (overspent by 30.00)
  And carryOverEnabled = true for "Food"
  When CarryOverBudget.execute for April 2026 is called
  Then the carry-over amount is 0.00 (no negative carry-over)
  And the April effective budget remains 400.00

Scenario: Soft delete removes a budget without affecting historical reports
  Given a budget row with id "bgt-001"
  When BudgetDAO.softDelete("bgt-001") is called
  Then the row's isDeleted flag is set to true
  And BudgetDAO.watchAll no longer emits that row
  And historical spending calculations for past months are unaffected

Scenario: watchForMonth returns null when no budget is configured for a category
  Given no budget row exists for "Transport" in April 2026
  When BudgetRepository.watchForMonth(categoryId: "cat-transport", year: 2026, month: 4)
    is observed
  Then the stream emits null (no budget configured)
```

## Edge Cases
- [ ] Budget period = "weekly" — effectiveFrom/effectiveTo align to ISO week boundaries
- [ ] Budget period = "annually" — effectiveFrom is January 1, effectiveTo is December 31
- [ ] Category deleted after budget created — budget row remains; repository must handle orphan gracefully (show "Deleted category" label)
- [ ] Amount = 0.00 — valid (budget explicitly set to zero); must not be excluded from queries
- [ ] Negative amount input — repository rejects with a domain Failure; never stored
- [ ] Concurrent upsert calls for the same category + month — last write wins; no duplicate rows
- [ ] Database migration — budgets table must be added in a new Drift schema version; existing installs migrate without data loss
- [ ] Carry-over chain: March carries into April, April into May — each month calculates independently from its predecessor only (no cascading chain calculation on read)
- [ ] Main currency mismatch — budget stored in EUR, transactions in TRY; repository converts using stored exchange rate before comparison

## Test Scenarios for QA
1. Unit: insert budget row via DAO, verify watchAll stream emits it
2. Unit: upsert (thisMonthOnly=true) correctly sets effectiveTo on old row and inserts new row
3. Unit: upsert (thisMonthOnly=false) replaces active row and keeps history
4. Unit: getSpentAmount aggregates only expense transactions of the correct category and month
5. Unit: CarryOverBudget returns remainder when under budget
6. Unit: CarryOverBudget returns 0.00 when overspent
7. Unit: softDelete hides row from watchAll
8. Unit: watchForMonth returns null when no budget exists
9. Integration: Drift in-memory DB — full CRUD cycle without DB errors
10. Integration: schema migration from Sprint 4 DB snapshot adds budgets table cleanly

## UX Spec
N/A — this is a pure data layer story with no UI.

## Estimate
M (3–5 days)

## Dependencies
- US-003 (Category table and DAO — foreign key target)
- US-010 (Transaction DAO — required for getSpentAmount queries)
- Drift database already initialised with SQLCipher (Sprint 3)
- Riverpod provider graph already established (Sprint 3)
