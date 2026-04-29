# US-023: MonthlyView — monthly transaction list grouped by date with totals

## Persona
A MoneyWise user who wants to see a year-at-a-glance breakdown of their finances, review
which months and weeks were heavier in spending, and understand the Income/Expense/Total
balance for any month without opening each day individually.

## Story
**As** a MoneyWise user
**I want** the Monthly tab to show the selected year broken down by month, with each month
showing its date range, income, expense, and total, and the current week highlighted
**So that** I can compare months and weeks within the year and spot financial patterns

## Source
SPEC.md §9.1.7 (Monthly View, Ekran 18); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Monthly view shows each month of the selected year with totals
  Given the Month/Year navigator shows "2026" (year only, per SPEC §9.1.2)
  And the user has transactions in April 2026 (income 500.00, expense 651.13)
  And the user has no transactions in any other month of 2026
  When the user is on the Monthly tab
  Then the view shows 12 month rows for 2026
  And the April row shows:
    | Label       | "Apr / 1.4. ~ 30.4."                    |
    | Income      | "€ 500,00"  (blue text)                 |
    | Expense     | "€ 651,13"  (coral text)                |
    | Total       | "€ -151,13" (white text, signed)        |
  And months with no transactions show "€ 0,00" for income, expense, and total

Scenario: Monthly view navigator shows year only (not month+year)
  Given the user is on the Monthly tab
  Then the Month/Year navigator title shows only the year (e.g., "2026"), not "Apr 2026"
  And tapping < navigates to 2025
  And tapping > navigates to 2027

Scenario: Current week row has a light-coral background highlight
  Given today is 2026-04-29 (week of 27 Apr – 3 May)
  When the user is on the Monthly tab viewing 2026
  Then the weekly sub-row "27.4. ~ 3.5." has a light-coral background highlight
  And no other weekly row has this highlight

Scenario: Weekly sub-rows show correct income, expense, and total per week
  Given April 2026 has transactions in the week of 27 Apr – 3 May:
    | type    | amount |
    | expense | 53.95  |
  When the user views the MonthlyView for 2026
  Then the April month row is expandable (or shows sub-rows inline)
  And the sub-row "27.4. ~ 3.5." shows:
    | Income  | "€ 0,00"  (blue)   |
    | Expense | "€ 53,95" (coral)  |
    | Total   | "€ -53,95" (white) |

Scenario: Empty year shows all months with zero values
  Given the user navigates to 2024 which has no transactions
  When the user is on the Monthly tab showing 2024
  Then all 12 month rows show "€ 0,00" for income, expense, and total
  And no weekly sub-rows have the current-week highlight

Scenario: Monthly view updates reactively after a new transaction is added
  Given the user is viewing MonthlyView for 2026
  When the user adds a new expense transaction of € 100.00 for April 2026
  Then the April row totals update immediately without requiring a manual refresh
```

## Edge Cases
- [ ] The current month's week range may span two months (e.g., 27 Apr – 3 May); the sub-row must correctly attribute the transaction to its actual transaction date, not clip at month boundaries
- [ ] A year with no transactions at all — 12 rows all showing zero; no crash or empty-state widget (the list itself is the content)
- [ ] Navigating to a year far in the past (e.g., 2020) — all 12 months rendered, all zeros if no data; no performance issue
- [ ] Transactions exactly at midnight (00:00:00) on the first or last day of a month — must be attributed to the correct month
- [ ] Transfer transactions — excluded from income and expense month totals per double-entry rules; shown in weekly sub-rows as a neutral line if sub-row detail is shown
- [ ] Very large annual total (e.g., € 1,000,000.00 expense) — must not overflow the row layout; use tabular figures
- [ ] Decimal precision — monthly totals must use `money2` summation, not raw floating-point addition, to avoid rounding errors across many transactions
- [ ] The current-week highlight must correctly identify the ISO week that contains today, even when the week spans two months

## Test Scenarios for QA
1. Happy path (iOS): verify 12-month list for 2026, April totals match known transaction data
2. Happy path (Android): same
3. Navigator shows year only on Monthly tab; verify < and > navigate by year
4. Current week sub-row highlight visible and correct for today's date
5. Weekly sub-row income/expense/total values correct for a week with known transactions
6. Navigate to a year with no data — all zero rows, no crash
7. Add a transaction for the current year while MonthlyView is open; verify reactive update
8. Transfer transaction: verify it does not inflate income or expense month totals
9. Month boundary week (e.g., 27 Apr – 3 May): verify transactions are attributed to correct month
10. Large total amounts: verify no layout overflow

## UX Spec
See `docs/specs/SPEC-011-monthly-view.md` (TBD — due Day 3, 2026-05-01)

## Estimate
M (2–3 days)

## Dependencies
- US-020 (TransactionsScreen scaffold): provides the hosting tab container
- US-025 (Month/Year navigator): controls the active year; must pass year (not month) to MonthlyView
- US-010 (Transaction CRUD — Sprint 3): TransactionRepository.watchMonthlyTotalsForYear() and watchWeeklyTotalsForMonth() streams
