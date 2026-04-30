# US-026: StatsScreen — category pie chart and monthly income/expense bar chart

## Persona
A MoneyWise user who wants to understand where their money goes each month through visual
charts so they can make informed spending decisions.

## Story
**As** a MoneyWise user
**I want** the Stats tab to show a donut pie chart of expenses by category and a toggle
to switch between expense and income views for the selected period
**So that** I can instantly see which categories consume the most of my budget and compare
spending patterns over time

## Source
SPEC.md §9.3 (StatsScreen, Ekran 14/15/16); SPEC.md §16.1 Sprint 5 goal.

## Acceptance Criteria

```gherkin
Scenario: Stats tab opens with Exp. active and pie chart rendered
  Given I have transactions in April 2026:
    | Category    | Amount  |
    | Restaurant  | 198.44  |
    | Groceries   | 163.55  |
    | Transport   | 89.14   |
  And I navigate to the Stats tab
  When the Stats sub-tab is selected (default)
  And the "Exp." toggle is active
  Then a donut pie chart is rendered with three segments
  And each segment uses a distinct color from the brand palette
  And the chart is approximately 360dp tall
  And below the chart a legend list shows each category with:
    | percentage badge (colored) | emoji | category name | amount |
  And the percentage badges sum to approximately 100%

Scenario: Toggle to Income view clears the pie chart and shows income categories
  Given I am on the Stats sub-tab with "Exp." active
  When I tap "Income"
  Then the pie chart re-renders with income category segments
  And the category legend list updates to show income categories

Scenario: Tapping a pie segment navigates to filtered transactions
  Given the Stats pie chart is visible with a "Restaurant" segment
  When I tap the "Restaurant" segment
  Then the app navigates to the DailyView filtered to "Restaurant" transactions
    for the selected month

Scenario: Month navigation updates the chart
  Given the Stats tab is showing data for April 2026
  When I tap the "<" arrow in the Month/Year navigator
  Then the navigator shows "Mar 2026"
  And the pie chart and legend list re-render with March data
  And if March has no transactions the chart shows an empty-state illustration
    with text "No data for this period"

Scenario: Empty state — no transactions for selected period
  Given I have no transactions in January 2026
  And the Month/Year navigator shows "Jan 2026"
  When the Stats sub-tab is active
  Then no pie chart is rendered
  And a centred empty-state illustration is shown
  And the text "No data for this period" is displayed

Scenario: Period selector switches between W / M / Y
  Given the Stats sub-tab is active
  When I tap the period selector dropdown showing "M"
  And I select "W" (Weekly)
  Then the Month/Year navigator is replaced by a Week navigator
  And the pie chart shows data aggregated for the current week

Scenario: Stats sub-tab is selected by default when entering the Stats tab
  Given I navigate to the Stats tab from any other tab
  Then the "Stats" sub-tab is active (brand fill)
  And the "Budget" and "Note" sub-tabs are inactive
```

## Edge Cases
- [ ] Single category holds 100% of spending — pie renders as a full circle, legend shows one row
- [ ] More than 10 categories — legend list scrolls; chart shows top 9 + "Other" segment
- [ ] Amounts with non-EUR currency — convert to main currency before aggregation; display in main currency
- [ ] Category with 0.00 amount — excluded from pie chart and legend
- [ ] Float precision — use `money2` Decimal arithmetic; no rounding artifacts in percentage display
- [ ] Very small segment (< 1%) — label may overlap; ensure chart library handles gracefully (no crash)
- [ ] Offline — all data is local; chart renders normally
- [ ] Period "Y" (yearly) selected — navigator shows year only ("2026"); data aggregated for full year
- [ ] Dark and Light theme — chart segment colors remain accessible (WCAG AA contrast against both backgrounds)
- [ ] Landscape orientation — chart must not overflow; scrollable layout

## Test Scenarios for QA
1. Happy path iOS: open Stats tab, verify pie chart renders with correct categories and percentages
2. Happy path Android: same as above
3. Tap Income toggle: verify chart and legend switch to income data
4. Month navigation: tap "<" three times, verify chart updates each time
5. Tap a pie segment: verify navigation to filtered DailyView
6. Empty month: verify empty-state illustration and message appear, no chart crash
7. "Other" aggregation: add 11+ expense categories, verify chart shows "Other" bucket
8. Period W / Y: verify navigator UI and data aggregation change correctly
9. Light theme: verify chart is readable
10. Verify no float rounding artifacts in percentage labels (e.g., no "33.333333%")

## UX Spec
See `docs/specs/SPEC-014-stats-screen.md` (to be authored by ux-designer in Sprint 5, due Day 3)

## Estimate
M (3–5 days)

## Dependencies
- US-010 (Transaction CRUD — data source for aggregation)
- US-003 (Category management — category names and emoji)
- `fl_chart` package already declared in `pubspec.yaml`
- Riverpod `StreamProvider` for reactive aggregation query from Drift
