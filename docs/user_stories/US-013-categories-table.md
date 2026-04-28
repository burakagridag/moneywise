# US-013: Categories Drift table, DAO, and default seed data

## Persona
A MoneyWise user who expects to categorise every transaction immediately after install using
familiar built-in categories (Food, Salary, Transport, etc.) without any manual setup.

## Story
**As** a MoneyWise user
**I want** the app to ship with all standard income and expense categories pre-populated
**So that** I can categorise transactions from the first day without creating categories manually

## Source
SPEC.md §6.3 (categories table definition); SPEC.md §9.9 (CategoryManagementScreen, Ekran 6, 7
— seed categories visible in list); Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Default expense categories are seeded on first launch
  Given the app is installed fresh
  When the Drift database initialises
  Then the categories table contains expense categories with the following names and emojis
  (in sortOrder order, isDefault = true):
    | sortOrder | name         | iconEmoji |
    | 0         | Food         | 🍜        |
    | 1         | Social Life  | 👫        |
    | 2         | Pets         | 🐶        |
    | 3         | Transport    | 🚕        |
    | 4         | Culture      | 🖼️        |
    | 5         | Household    | 🪑        |
    | 6         | Apparel      | 🧥        |
    | 7         | Beauty       | 💄        |
    | 8         | Health       | 🧘        |
    | 9         | Education    | 📚        |
    | 10        | Gift         | 🎁        |
    | 11        | Other        | (none)    |
    | 12        | Insurance    | 🤵        |
    | 13        | Rent         | 🏠        |
    | 14        | Cigarette    | 🚬        |
    | 15        | Groceries    | (none)    |
    | 16        | Restaurant   | (none)    |
    | 17        | Parking      | (none)    |
    | 18        | Bills        | (none)    |
    | 19        | Gym          | (none)    |
    | 20        | Medicine     | (none)    |

Scenario: Default income categories are seeded on first launch
  Given the app is installed fresh
  When the Drift database initialises
  Then the categories table contains income categories with the following names and emojis
  (isDefault = true):
    | sortOrder | name        | iconEmoji |
    | 0         | Allowance   | 🤑        |
    | 1         | Salary      | 💰        |
    | 2         | Petty cash  | 💵        |
    | 3         | Bonus       | 🥇        |
    | 4         | Other       | (none)    |
    | 5         | Dividend    | 💸        |
    | 6         | Interest    | 💸        |

Scenario: Seed is idempotent on restart
  Given the database is already seeded
  When the app restarts
  Then no duplicate category rows are created

Scenario: CategoriesDao.watchByType('expense') streams active expense categories
  Given seed data is present
  When CategoriesDao.watchByType('expense') is called
  Then the stream emits all 21 expense categories in sortOrder ASC
  And no income categories are included
  And no soft-deleted categories are included

Scenario: CategoriesDao.watchByType('income') streams active income categories
  Given seed data is present
  When CategoriesDao.watchByType('income') is called
  Then the stream emits all 7 income categories

Scenario: Insert a custom category
  When CategoriesDao.insertCategory() is called with:
    | name       | Coffee Shops |
    | type       | expense      |
    | iconEmoji  | ☕            |
    | colorHex   | #6F4E37      |
    | isDefault  | false        |
    | parentId   | null         |
  Then the row persists with a new UUID
  And watchByType('expense') emits it alongside the defaults

Scenario: Insert a subcategory
  Given "Food" category exists with id = (foodId)
  When CategoriesDao.insertCategory() is called with parentId = foodId
  Then the subcategory row has parentId = foodId
  And CategoriesDao.watchSubcategories(foodId) emits the new subcategory

Scenario: Soft-delete a custom category
  Given a custom "Coffee Shops" category exists
  When CategoriesDao.softDelete(id) is called
  Then isDeleted becomes true
  And the category no longer appears in watchByType streams

Scenario: Attempt to soft-delete a default category
  Given the "Food" category with isDefault = true exists
  When softDelete is called (via DAO directly)
  Then the DAO permits the soft-delete (enforcement of "cannot delete defaults" is business logic
       in the repository — US-014)
```

## Edge Cases
- [ ] "Other" category (income and expense) must always exist — repository layer (US-014) must prevent hard delete; if soft-deleted by mistake, restore is required
- [ ] Self-referential FK (parentId → id) — inserting a subcategory with a non-existent parentId must fail FK constraint; Drift FK enforcement must be enabled
- [ ] Circular parentId (A's parent = B, B's parent = A) — DB does not prevent this; repository layer must validate depth ≤ 1 (no grandchildren per V1 scope)
- [ ] Duplicate category name within same type — no DB uniqueness constraint; repository warns on duplicate names
- [ ] iconEmoji nullable — DAO and UI must handle null emoji without crash; display a placeholder icon
- [ ] colorHex nullable — same handling as iconEmoji
- [ ] sortOrder — drag-to-reorder updates sortOrder for all affected rows atomically; DAO must support batch update
- [ ] Offline — all operations are local-first

## Test Scenarios for QA
1. Fresh install on iOS: verify 21 expense + 7 income default categories present, all with isDefault = true
2. Fresh install on Android: same check
3. Cold restart: no duplication
4. Insert a custom expense category: verify it appears in watchByType('expense') stream
5. Insert a subcategory under "Food": verify parentId FK is set correctly
6. Soft-delete custom category: confirm disappears from stream; raw query confirms isDeleted = true
7. Attempt subcategory insert with invalid parentId: confirm FK error is surfaced (no silent failure)
8. Verify "Other" exists for both income and expense types

## UX Spec
N/A — data layer story only, no UI.

## Estimate
S (1–2 days)

## Dependencies
- US-004 (Drift DB initialised)
- US-011 is not a dependency (categories table is independent of account groups)
