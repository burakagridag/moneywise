# US-022: CalendarView — calendar grid with daily spend indicators

## Persona
A MoneyWise user who thinks about their finances in a monthly calendar mental model and
wants to see at a glance which days had spending or income, then drill into any specific day.

## Story
**As** a MoneyWise user
**I want** to see a monthly calendar grid where each day cell shows my income and expense
totals for that day, and tap a cell to see the full list of transactions for that day
**So that** I can visually identify heavy-spending days and review them without scrolling
through a long list

## Source
SPEC.md §9.1.6 (Calendar View, Ekran 19); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Calendar grid renders correctly for the selected month
  Given the Month/Year navigator shows "Apr 2026"
  When the user is on the Calendar tab
  Then the grid shows 7 columns: Mon, Tue, Wed, Thu, Fri, Sat, Sun
  And "Sat" column header is blue, "Sun" column header is red
  And every day of April 2026 (1–30) is displayed in its correct weekday column
  And days from the previous month (March) that fill the first row are shown in textTertiary
  And days from the next month (May) that fill the last row are shown in textTertiary

Scenario: Day cell with transactions shows income and expense rows
  Given the user has transactions on 2026-04-27:
    | type    | amount |
    | income  | 200.00 |
    | expense | 53.95  |
  When the user views the CalendarView for April 2026
  Then the cell for day 27 shows:
    | Day number | "27"                     |
    | Top row    | "€ 200,00" (blue text)   |
    | Bottom row | "€ 53,95"  (coral text)  |

Scenario: Day cell with only expense shows one row
  Given the user has only expense transactions on 2026-04-25 (total € 12,00)
  When the user views the CalendarView for April 2026
  Then the cell for day 25 shows only the coral expense row "€ 12,00"
  And no blue income row is shown

Scenario: Day cell with no transactions shows only the day number
  Given the user has no transactions on 2026-04-10
  When the user views the CalendarView for April 2026
  Then the cell for day 10 shows only the day number "10" with no amount rows

Scenario: Today's date cell has a highlighted background
  Given today is 2026-04-29
  When the user views the CalendarView for April 2026
  Then the cell for day 29 has a highlighted (light white/brand tint) background
  And day numbers for future dates (30) are shown in textTertiary colour

Scenario: Tapping a day cell opens a bottom sheet with that day's transactions
  Given the user has two transactions on 2026-04-27
  When the user taps the cell for day 27
  Then a bottom sheet slides up
  And the bottom sheet shows both transactions with category, account name, and amount
  And the bottom sheet shows the date "Mon, 27 April 2026" as its title

Scenario: Tapping an empty day cell opens a bottom sheet with empty state
  Given the user has no transactions on 2026-04-10
  When the user taps the cell for day 10
  Then a bottom sheet slides up
  And the bottom sheet shows a "No transactions" message for that day

Scenario: Tapping the + FAB from CalendarView opens AddTransactionScreen
  Given the user is on the Calendar tab
  When the user taps the brand-color + FAB
  Then the AddTransactionScreen opens
  And the date field in the form defaults to today's date (not the last tapped calendar cell)

Scenario: Navigating to a different month updates the calendar grid
  Given the user is viewing April 2026 in CalendarView
  When the user taps the < arrow to go to March 2026
  Then the grid re-renders for March 2026 with correct day-of-week positioning
  And transaction amount indicators update to show March data
```

## Edge Cases
- [ ] Month starting on Sunday — the first row of the grid may have 6 empty leading cells; layout must not break
- [ ] February in a leap year (28 vs 29 days) — grid renders the correct number of cells
- [ ] A day cell that has many transactions — only the aggregate income total and aggregate expense total are shown in the cell, not individual transaction amounts
- [ ] Very large daily total (e.g., € 10,000.00) — amount text must truncate or use abbreviated notation (€ 10K) if it overflows the cell width; cell height remains fixed
- [ ] Previous/next month day cells (textTertiary) — tapping them should navigate to that month and open the day's bottom sheet, not show an empty bottom sheet for the wrong month
- [ ] Income and expense both zero for a day — no amount rows rendered; cell shows day number only
- [ ] Transfer transactions — included in the day cell display but as a neutral entry (not added to income or expense totals in the cell)
- [ ] Offline — all data rendered from local Drift DB; no loading spinner required
- [ ] Landscape orientation — grid must remain usable; consider fixed row heights or scroll behaviour

## Test Scenarios for QA
1. Happy path (iOS): verify grid layout for April 2026, correct weekday columns, Sat/Sun header colours
2. Happy path (Android): same verification
3. Income-only day: verify only blue row shown
4. Expense-only day: verify only coral row shown
5. Both income and expense: verify two rows shown
6. Empty day: verify no amount rows, only day number
7. Today cell: verify highlighted background
8. Future days: verify textTertiary colour
9. Tap occupied day cell: bottom sheet shows correct transactions
10. Tap empty day cell: bottom sheet shows empty state
11. Navigate previous month (< arrow): grid updates to correct month
12. Previous/next month overflow cells shown in textTertiary and tapping them navigates to that month
13. February 2028 (leap year, 29 days): grid renders correctly
14. A month starting on Sunday: first row padding renders without layout errors

## UX Spec
See `docs/specs/SPEC-010-calendar-view.md` (TBD — due Day 3, 2026-05-01)

## Estimate
M (2–3 days)

## Dependencies
- US-020 (TransactionsScreen scaffold): provides the hosting tab container
- US-025 (Month/Year navigator): controls which month the grid renders
- US-010 (Transaction CRUD — Sprint 3): TransactionRepository.watchDailyTotalsForMonth() stream
