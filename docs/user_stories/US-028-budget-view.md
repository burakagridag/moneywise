# US-028: BudgetView — budget summary card and per-category progress bars

## Persona
A MoneyWise user who has set monthly budgets and wants to see at a glance how much of each
budget has been consumed — and how much is left — so they can course-correct before overspending.

## Story
**As** a MoneyWise user
**I want** the Budget sub-tab in the Stats screen to show a summary card with overall
remaining budget and a list of per-category progress bars
**So that** I can immediately see which categories are on track and which are at risk of
overspending for the current period

## Source
SPEC.md §9.3.5 (Budget Sub-tab, Ekran 15); SPEC.md §16.1 Sprint 5 goal.

## Acceptance Criteria

```gherkin
Scenario: BudgetView shows overall remaining budget when a TOTAL budget is configured
  Given I have a TOTAL monthly budget of 1500.00 EUR for April 2026
  And total expenses in April 2026 are 651.13 EUR
  When I tap the "Budget" sub-tab in the Stats screen
  Then a summary card is visible at the top showing:
    | Label     | "Remaining (Monthly)"      |
    | Amount    | "€ 848,87"                 |
  And a progress bar below shows the consumed percentage (43%)
  And the progress bar has a "Today" indicator at the proportional day position
    (e.g., day 29 of 30 ≈ 96% position)
  And three totals are displayed below the bar:
    | Budget    | "€ 1.500,00" |
    | Spent     | "€ 651,13"   |
    | Remaining | "€ 848,87"   |

Scenario: Summary card when no TOTAL budget is configured
  Given no TOTAL budget exists for April 2026
  When I am on the BudgetView
  Then the summary card shows "€ 0,00" remaining
  And the progress bar shows 0%
  And the "Budget Setting >" link is prominent to guide the user to set a budget

Scenario: Per-category budget list shows progress bars
  Given the following budgets and expenses exist for April 2026:
    | Category   | Budget | Spent  |
    | Restaurant | 200.00 | 198.44 |
    | Groceries  | 150.00 | 163.55 |
    | Transport  | 100.00 | 89.14  |
  When I am on the BudgetView
  Then the category list shows one row per configured budget category
  And each row contains:
    | Left   | emoji + category name |
    | Right  | spent amount          |
    | Below  | progress bar          |
  And the Restaurant bar is filled to approximately 99% in warning color (orange)
  And the Groceries bar is filled to 100% (or beyond) in error color (red/coral)
  And the Transport bar is filled to approximately 89% in normal brand color

Scenario: Category budget exceeded — bar turns red and shows overspend
  Given April 2026 Groceries budget is 150.00
  And April 2026 Groceries spending is 163.55 (overspent by 13.55)
  When I am on the BudgetView
  Then the Groceries progress bar is full-width and shown in error color (#E53935)
  And the amount displayed on the right shows "€ 163,55" in error color
  And there is no negative bar (bar clamps at 100%)

Scenario: Category with no budget configured appears in list without a progress bar
  Given "Transport" category has expenses of 89.14 in April 2026
  And no budget is set for "Transport"
  When I am on the BudgetView
  Then "Transport" appears in the list with its spent amount
  And no progress bar is shown for "Transport" (progress bar area is hidden)

Scenario: Carry-over increases effective budget for the month
  Given March 2026 Food budget was 400.00, actual spending 310.00 (remainder 90.00)
  And April 2026 Food budget is 400.00 with carryOverEnabled = true
  When I am on the BudgetView for April 2026
  Then the Food budget row shows an effective budget of "€ 490,00" (with carry-over)
  And the progress bar is calculated against 490.00

Scenario: "Budget Setting >" link navigates to BudgetSettingScreen
  Given I am on the BudgetView
  When I tap the "Budget Setting >" link in the summary card header
  Then I am navigated to the BudgetSettingScreen (/more/budget-setting)

Scenario: Period toggle changes the view to Weekly or Yearly
  Given I am on the BudgetView with "M" (Monthly) period active
  When I tap the period selector and select "W" (Weekly)
  Then the summary card and category list re-render for the current ISO week
  And the "Today" indicator on the progress bar reflects the current day within the week

Scenario: Empty state — no budget and no expenses
  Given April 2026 has no transactions and no budgets configured
  When I am on the BudgetView
  Then a centred empty-state is shown with the text "No budget set"
  And a prominent "Set Budget" button appears that navigates to BudgetSettingScreen
```

## Edge Cases
- [ ] Budget amount = 0.00 — progress bar shows 0% but does not divide by zero; the bar is hidden or shows "€ 0 / € 0"
- [ ] All categories under budget — all bars are green (normal brand color); no error state triggered
- [ ] More than 15 category budgets — list is scrollable; no layout overflow
- [ ] Very long category name (> 20 chars) — truncated with ellipsis; row height does not expand
- [ ] Carry-over where prior month had no data — treat prior month remainder as 0; no crash
- [ ] Currency mismatch — spending in a sub-currency converted to main currency for progress bar calculation
- [ ] "Today" indicator at day 1 — indicator shows at far left (0%); no overflow
- [ ] "Today" indicator at last day of month — indicator shows at far right (≈ 100%); no overflow
- [ ] Offline — all data is local; BudgetView renders normally
- [ ] Dark / Light theme — progress bar colors remain accessible; error color visible in both themes

## Test Scenarios for QA
1. Happy path iOS: configure budgets, add expenses, open BudgetView — verify summary card values and progress bars
2. Happy path Android: same as above
3. Overspent category: verify bar is full-width in error color and amount is in error color
4. Near-threshold category (80–99%): verify warning color (orange) is applied
5. No TOTAL budget: verify summary card shows 0,00 and "Budget Setting >" is visible
6. Carry-over scenario: verify effective budget is sum of base + carry-over from prior month
7. "Budget Setting >" tap: verify navigation to BudgetSettingScreen
8. Period W toggle: verify weekly aggregation and "Today" indicator position
9. Empty state: no budgets and no expenses — verify empty-state UI is shown
10. 16+ category budgets: verify list scrolls without overflow

## UX Spec
See `docs/specs/SPEC-015-budget-view.md` (to be authored by ux-designer in Sprint 5, due Day 3)

## Estimate
M (3–5 days)

## Dependencies
- US-027 (Budget DB layer — BudgetRepository and CarryOverBudget use case)
- US-026 (StatsScreen scaffold — this view is a sub-tab within StatsScreen)
- US-029 (BudgetSettingScreen — navigation target for "Budget Setting >" link)
- US-010 (Transaction data — spent amounts per category)
