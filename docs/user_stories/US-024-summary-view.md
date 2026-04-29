# US-024: SummaryView — period income / expense / balance / savings summary

## Persona
A MoneyWise user who wants a quick high-level snapshot of their finances for the selected
period — including total income, total expenses, net balance, accounts breakdown, and budget
progress — without switching to the Stats tab.

## Story
**As** a MoneyWise user
**I want** the Summary tab to display a horizontally scrollable series of summary cards
covering period totals, account expenses, budget progress, and an export action
**So that** I can get a complete financial overview for the month in a single glance and
take quick actions like exporting data

## Source
SPEC.md §9.1.8 (Summary View, Ekran 17); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Card 1 shows period income, expense, and total
  Given the user has April 2026 transactions (income 500.00, expense 651.13)
  And the Month/Year navigator shows "Apr 2026"
  When the user is on the Summary tab
  Then Card 1 is visible and shows:
    | Income | "€ 500,00"  (blue text)          |
    | Exp.   | "€ 651,13"  (coral text)         |
    | Total  | "€ -151,13" (white text, signed) |

Scenario: Card 2 shows the Accounts expense breakdown
  Given the user has expense transactions from accounts "Cash" and "Debit Card" in April 2026
  When the user is on the Summary tab
  Then Card 2 shows:
    | Header | "Accounts" icon + label                      |
    | Row    | "Exp. (Cash, Debit Card)" label              |
    | Amount | Total expenses across those accounts (coral) |

Scenario: Card 3 shows Budget progress with a Today indicator
  Given the user has a monthly budget set for April 2026
  When the user is on the Summary tab
  Then Card 3 shows:
    | Header          | "Budget" icon + label                  |
    | Today indicator | Vertical marker on the progress bar    |
    | Progress bar    | Spent / Budget percentage filled       |
    | Labels          | Total budget amount and spent amount   |

Scenario: Card 3 shows zero state when no budget is configured
  Given the user has not set any budget for April 2026
  When the user is on the Summary tab
  Then Card 3 shows "€ 0,00" for budget and spent
  And the progress bar shows 0%

Scenario: Card 4 shows "Export data to Excel" action
  Given the user is on the Summary tab
  When the user scrolls to Card 4
  Then Card 4 shows an "Export data to Excel" list row with an icon
  When the user taps the Export row
  Then a snackbar appears saying "Export feature coming soon"
  And no file is created (export is out of scope for Sprint 4)

Scenario: Cards are horizontally scrollable
  Given the user is on the Summary tab
  When the user swipes left
  Then Card 2 scrolls into view
  When the user swipes left again
  Then Card 3 scrolls into view
  When the user swipes left again
  Then Card 4 scrolls into view

Scenario: SummaryView values update reactively when the month changes
  Given the user is viewing April 2026 SummaryView
  When the user navigates to March 2026 via the Month/Year navigator
  Then all card values update to reflect March 2026 data without requiring a manual refresh

Scenario: FAB is present on SummaryView
  Given the user is on the Summary tab
  Then the brand-color + FAB is visible in the bottom-right corner
  And tapping it opens the AddTransactionScreen
```

## Edge Cases
- [ ] No transactions in the selected period — Card 1 shows all zeros; Card 2 shows zero account expense; Card 3 shows zero budget progress; no crash
- [ ] No budget configured — Card 3 renders a zero-state gracefully without crashing; a "Set budget" link is shown (tapping it is a no-op in Sprint 4; budget setup is Sprint 5)
- [ ] Total is positive (income > expense) — Total field shows a positive signed value with blue colour
- [ ] Very large numbers — tabular figures; no text overflow across card boundaries
- [ ] Horizontal scroll must not conflict with any vertical scroll gesture on the same screen; use a dedicated horizontal scroll container within a non-scrolling parent
- [ ] The "Today" indicator on Card 3 must be positioned proportionally to how far into the month today is (e.g., day 15 of 30 = 50% position)
- [ ] Budget that has been exceeded (spent > budget) — progress bar overflows to 100% and turns red; label shows the exceeded amount
- [ ] Transfer transactions must not be counted in Card 1 income or expense totals

## Test Scenarios for QA
1. Happy path (iOS): Card 1 totals match known April 2026 transactions
2. Happy path (Android): same
3. Horizontal swipe through all 4 cards; verify each card is reachable
4. Card 3 Today indicator position correct for current date (e.g., day 15 of 30 = 50%)
5. Card 3 with no budget: zero state renders without crash; "Set budget" link present
6. Card 3 with exceeded budget: progress bar red and shows 100%
7. Card 4 Export tap: snackbar "Export feature coming soon" appears
8. Navigate to a different month: all card values update reactively
9. Empty month (no transactions): all cards show zeros, no crash
10. Transfer transaction: verify not included in Card 1 income/expense totals

## UX Spec
See `docs/specs/SPEC-012-summary-view.md` (TBD — due Day 3, 2026-05-01)

## Estimate
M (2–3 days)

## Dependencies
- US-020 (TransactionsScreen scaffold): provides the hosting tab container and selected month state
- US-025 (Month/Year navigator): controls the active period
- US-010 (Transaction CRUD — Sprint 3): TransactionRepository.watchPeriodSummary() stream
- US-014 (Sprint 2 — AccountRepository): needed for Card 2 account expense breakdown
