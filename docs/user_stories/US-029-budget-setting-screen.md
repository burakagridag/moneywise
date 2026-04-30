# US-029: BudgetSettingScreen — create and edit category budgets

## Persona
A MoneyWise user who wants to set or adjust monthly spending limits for each expense
category so that the app can track progress and warn when limits are approached.

## Story
**As** a MoneyWise user
**I want** a Budget Setting screen reachable from the More tab and from BudgetView
**So that** I can configure a budget amount for each expense category — and choose whether
that budget applies only to the current month or to all future months

## Source
SPEC.md §9.11 (BudgetSettingScreen, Ekran 4); SPEC.md §16.1 Sprint 5 goal.

## Acceptance Criteria

```gherkin
Scenario: BudgetSettingScreen is reachable from More tab
  Given I am on the More (Settings) tab
  When I tap "Budget Setting" in the Category/Accounts section
  Then BudgetSettingScreen opens with route /more/budget-setting
  And the AppBar shows title "Budget Setting" and a back arrow to Settings
  And the period selector shows "M ▼" (monthly, default)
  And the Month/Year navigator shows the current month (e.g., "Apr 2026")
  And the Income / Exp. toggle defaults to "Exp."

Scenario: Category list shows all expense categories with their current budget amounts
  Given expense categories: Food (budget 400.00), Transport (budget 100.00), Groceries (no budget)
  When the BudgetSettingScreen is open for April 2026 in Exp. mode
  Then the list shows:
    | Row 1 | TOTAL (overall) | € 0,00 >  |
    | Row 2 | 🍜 Food         | € 400,00 >|
    | Row 3 | 🚕 Transport    | € 100,00 >|
    | Row 4 | 🛒 Groceries    | € 0,00 >  |
  And each row has a ">" chevron indicating it is tappable

Scenario: Tapping a category row opens the BudgetEditModal
  Given the BudgetSettingScreen is open
  When I tap the "🍜 Food" row
  Then a BudgetEditModal (bottom sheet) appears with:
    | Title         | "🍜 Food"               |
    | Amount field  | pre-filled with "400,00"|
    | Checkbox      | "Only this month" (unchecked by default) |
    | Save button   |                         |
    | Cancel button |                         |

Scenario: Save budget applies to all future months by default
  Given the BudgetEditModal is open for "Food" with amount 400.00
  And the "Only this month" checkbox is unchecked
  When I change the amount to 350.00 and tap Save
  Then the Food budget row shows "€ 350,00"
  And BudgetRepository creates a new effective-from-today row for Food
  And the old row receives effectiveTo = yesterday

Scenario: Save budget for only this month creates a time-bounded override
  Given the BudgetEditModal is open for "Food" with amount 400.00
  And the "Only this month" checkbox is checked
  When I change the amount to 250.00 and tap Save
  Then the Food budget for April 2026 is 250.00
  And the budget for May 2026 reverts to the previous default (400.00)

Scenario: Setting TOTAL budget (first row) configures the overall monthly limit
  Given the TOTAL row shows "€ 0,00 >"
  When I tap TOTAL and enter 1500.00 in the BudgetEditModal and tap Save
  Then the TOTAL row shows "€ 1.500,00"
  And BudgetRepository stores a row with categoryId = null

Scenario: Setting a budget of 0.00 clears the budget for that category
  Given Food budget is 400.00
  When I tap Food, enter 0.00 in the modal, and tap Save
  Then the Food row shows "€ 0,00"
  And BudgetView no longer shows a progress bar for Food

Scenario: Period selector switches to Weekly — list shows weekly budgets
  Given the BudgetSettingScreen is open in Monthly mode
  When I tap "M ▼" and select "W"
  Then the AppBar period selector shows "W ▼"
  And the Month/Year navigator is replaced by a Week navigator
  And the category list shows weekly budget amounts (or 0,00 if none set)

Scenario: Income mode shows income categories instead
  Given the Income / Exp. toggle defaults to "Exp."
  When I tap "Income"
  Then the category list shows income categories (Salary, Bonus, Allowance, etc.)
  And any budgets previously set for income categories are shown

Scenario: Tapping Cancel in the BudgetEditModal discards changes
  Given the BudgetEditModal is open with Food budget pre-filled as 400.00
  When I change the amount to 999.00 and tap Cancel
  Then the modal closes
  And the Food row still shows "€ 400,00"
  And no database write has occurred

Scenario: Validation prevents saving a negative budget amount
  Given the BudgetEditModal is open
  When I enter "-50" as the amount
  Then the Save button is disabled
  And an inline error "Amount must be 0 or greater" is shown
```

## Edge Cases
- [ ] Amount field is empty — Save is disabled; hint text shows the placeholder "0,00"
- [ ] Amount field has more than 2 decimal places — input rounds to 2 decimal places on blur
- [ ] Non-numeric input — number keyboard is used; non-numeric characters are filtered
- [ ] Very large amount (e.g., 9,999,999.99) — accepted; no overflow in the display row
- [ ] Category name longer than 20 characters — truncated with ellipsis in modal title
- [ ] BudgetSettingScreen opened while BudgetEditModal is also transitioning — state is isolated; no double-open
- [ ] "Only this month" checked but the current budget already has effectiveTo set to this month — no duplicate rows created; upsert is idempotent
- [ ] No expense categories exist — list shows only the TOTAL row with an empty-state prompt to add categories first
- [ ] Navigating back mid-edit — unsaved changes discarded without confirmation (no destructive action; budget was not yet changed)
- [ ] Offline — all writes go to local Drift DB; no network required

## Test Scenarios for QA
1. Happy path iOS: open from More tab, tap Food, set 400.00, save all-months — verify row updated
2. Happy path Android: same as above
3. "Only this month" checked: verify April budget changes but May reverts to prior value
4. TOTAL budget: set 1500.00 for TOTAL, verify BudgetView summary card reflects new value
5. Set budget to 0.00: verify BudgetView progress bar disappears for that category
6. Cancel in modal: verify no DB write, row value unchanged
7. Negative amount: verify Save is disabled and error message shown
8. Period W: verify weekly mode renders correctly
9. Income mode: verify income categories appear in list
10. Back navigation: verify BudgetView and MoreScreen are in the correct state after returning

## UX Spec
See `docs/specs/SPEC-016-budget-setting-screen.md` (to be authored by ux-designer in Sprint 5, due Day 3)

## Estimate
M (3–5 days)

## Dependencies
- US-027 (Budget DB layer — BudgetRepository.upsert, BudgetDAO)
- US-028 (BudgetView — navigation source via "Budget Setting >" link)
- US-003 (Category management — category list source)
- More tab route already configured in go_router (Sprint 1)
