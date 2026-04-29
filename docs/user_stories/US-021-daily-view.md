# US-021: DailyView — grouped daily transaction list

## Persona
A MoneyWise user who wants to review what they spent today (or on any past day) and
understand the income and expense breakdown at a glance without leaving the Trans. tab.

## Story
**As** a MoneyWise user
**I want** the Daily tab to show transactions grouped by date, with a date header displaying
the day number, day-of-week badge, and that day's income/expense totals
**So that** I can quickly scan my spending day by day and identify where my money went

## Source
SPEC.md §9.1.5 (Daily View, Ekran 20); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Transactions are grouped under date headers in descending date order
  Given the user has transactions in April 2026:
    | date       | type    | amount | category | account     |
    | 2026-04-27 | expense | 53.95  | Food     | Debit Card  |
    | 2026-04-27 | income  | 200.00 | Salary   | Bank        |
    | 2026-04-25 | expense | 12.00  | Transport| Cash        |
  And the Month/Year navigator shows "Apr 2026"
  When the user is on the Daily tab
  Then the list shows two date sections in descending order: 27 April, then 25 April
  And the "27" section header shows:
    | Day number    | "27"                          |
    | Day badge     | "Mon" (grey background)       |
    | Daily income  | "€ 200,00" (blue text)        |
    | Daily expense | "€ 53,95"  (coral text)       |
  And the "25" section header shows:
    | Day number    | "25"                          |
    | Day badge     | "Sat" (blue background)       |
    | Daily income  | "€ 0,00"   (blue text)        |
    | Daily expense | "€ 12,00"  (coral text)       |

Scenario: Sunday date header badge is red
  Given there is at least one transaction on a Sunday in the selected month
  When the user views the DailyView
  Then the day-of-week badge for Sunday shows a red background

Scenario: Saturday date header badge is blue
  Given there is at least one transaction on a Saturday in the selected month
  When the user views the DailyView
  Then the day-of-week badge for Saturday shows a blue background

Scenario: Weekday date header badge is grey
  Given there is at least one transaction on a weekday (Mon–Fri) in the selected month
  When the user views the DailyView
  Then the day-of-week badge for that weekday shows a grey background

Scenario: Each transaction row shows category, account, and amount
  Given a transaction: expense 53.95 EUR, category "Food", account "Debit Card"
  When the user sees the transaction row under its date section
  Then the row shows:
    | Left   | "Food" (category name, textSecondary) |
    | Middle | "Debit Card" (account name, grey)     |
    | Right  | "€ 53,95" (coral, expense colour)     |
  And income transactions show their amount in blue

Scenario: Recurring transaction shows recurrence label in the middle column
  Given a transaction linked to a recurring rule "Every Month"
  When the user views that transaction row in DailyView
  Then the middle column shows "Bank Accounts (Every Month)" in grey text

Scenario: Empty state when no transactions exist for the selected month
  Given the user has no transactions in March 2026
  And the Month/Year navigator shows "Mar 2026"
  When the user is on the Daily tab
  Then the list shows no date sections
  And a centred empty-state illustration and "No transactions yet" label are shown

Scenario: DailyView updates after a new transaction is added
  Given the user is viewing April 2026 DailyView with one existing transaction
  When the user taps the + FAB, adds a new expense for today, and saves it
  Then the new transaction appears immediately under today's date header
  And today's daily expense total in the date header updates to reflect the new amount
```

## Edge Cases
- [ ] A day with only income transactions — daily expense shows "€ 0,00"; only income amount is non-zero
- [ ] A day with only expense transactions — daily income shows "€ 0,00"
- [ ] Multiple transactions on the same day — all listed under a single date header, newest first (by createdAt)
- [ ] Transfer transactions — displayed in the list but excluded from the daily income/expense totals per double-entry rules; row shows both from-account and to-account
- [ ] Transaction with `isExcluded = true` — must be visually marked (e.g., strikethrough amount) and excluded from the date header totals and summary bar totals
- [ ] Transactions in a non-main currency — displayed with the transaction's original currency code and the converted main-currency equivalent
- [ ] Very long category name or account name — must truncate with ellipsis; row height must remain 56dp
- [ ] Very large amount (e.g., € 1,000,000.00) — must not overflow the row; use tabular figures
- [ ] User scrolls to bottom of a long list — no pagination jitter; Drift reactive stream must not reload the full list on each new transaction
- [ ] Month with 31 days and transactions on every day — list renders without performance issues (< 300ms render time on mid-range device)
- [ ] Offline — list renders from local Drift DB; no network dependency

## Test Scenarios for QA
1. Happy path (iOS): add income and expense on two different days, verify grouping, badges, and totals
2. Happy path (Android): same as above
3. Sunday and Saturday badge colours verified
4. Recurring transaction recurrence label displayed in middle column
5. Transfer transaction visible in list but income/expense totals unaffected
6. Excluded transaction (`isExcluded = true`) renders with strikethrough and excluded from totals
7. Empty state: navigate to a month with no transactions and confirm the empty-state widget shows
8. Add a new transaction while DailyView is open; confirm reactive update without full screen refresh
9. Long category/account names: confirm text truncation, row height unchanged
10. Large dataset: populate 200 transactions in one month; measure scroll frame rate

## UX Spec
See `docs/specs/SPEC-009-daily-view.md` (TBD — due Day 3, 2026-05-01)

## Estimate
M (2–3 days)

## Dependencies
- US-020 (TransactionsScreen scaffold): provides TabController host and summary bar
- US-025 (Month/Year navigator): controls which month is displayed
- US-010 (Transaction CRUD — Sprint 3): TransactionRepository.watchTransactionsForMonth() stream
