# US-020: TransactionsScreen scaffold + period tab bar

## Persona
A MoneyWise user who opens the app and lands on the Trans. tab to browse their transactions,
expecting to see a coherent screen with clearly labelled period tabs and a summary of their
income and expenses for the selected month.

## Story
**As** a MoneyWise user
**I want** the Trans. tab to display a top app bar, a month/year navigator, a period tab bar
(Daily / Calendar / Monthly / Summary / Description), and an Income/Exp./Total summary strip
**So that** I can quickly orient myself within the transactions screen and choose the view
that best suits the task at hand

## Source
SPEC.md §9.1 (TransactionsScreen, Ekran 17–20); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Trans. tab opens to DailyView by default
  Given the user launches the app for the first time
  When the app has finished loading
  Then the Trans. tab is active in the bottom navigation bar
  And the period tab bar shows "Daily" as the selected tab (brand-color underline)
  And the DailyView content area is visible

Scenario: Period tabs are labelled correctly and switch views
  Given the user is on the Trans. tab
  When the user taps "Calendar"
  Then the "Calendar" tab becomes active (brand-color underline)
  And the CalendarView content area replaces the DailyView
  When the user taps "Monthly"
  Then the "Monthly" tab becomes active
  And the MonthlyView content area is displayed
  When the user taps "Summary"
  Then the "Summary" tab becomes active
  And the SummaryView content area is displayed
  When the user taps "Description"
  Then the "Description" tab becomes active
  And a "Coming soon" placeholder is displayed

Scenario: Income / Exp. / Total summary bar shows correct values
  Given the user has transactions in April 2026:
    | type    | amount  |
    | income  | 500.00  |
    | expense | 320.50  |
  And the Month/Year navigator shows "Apr 2026"
  When the user is on the Daily, Calendar, or Monthly view
  Then the summary bar shows:
    | Income  | € 500,00  (blue text)         |
    | Exp.    | € 320,50  (coral text)        |
    | Total   | € 179,50  (white text, +/-)   |

Scenario: Summary bar values update when the month changes
  Given the summary bar shows April 2026 values
  When the user navigates to March 2026 via the Month/Year navigator
  Then the summary bar values update to reflect March 2026 transactions

Scenario: App bar contains search, bookmark, and filter icons
  Given the user is on the Trans. tab
  Then the app bar shows:
    | Left  | search (magnifying glass) icon  |
    | Title | "Trans."                        |
    | Right | bookmark icon                   |
    | Right | filter icon                     |

Scenario: FABs are always visible above the banner ad area
  Given the user is on any period view
  Then a brand-color circular + FAB is visible in the bottom-right corner
  And a secondary grey circular bookmark FAB is visible above the + FAB
  And both FABs are layered above the banner ad placeholder
```

## Edge Cases
- [ ] No transactions exist at all — summary bar shows € 0,00 for all three values; views show their empty states
- [ ] Switching between tabs must not reset the selected month
- [ ] Very long month name in a locale (e.g., German "September") must not overflow the navigator title area
- [ ] Rapid successive tab taps must not cause duplicate state subscriptions or frame drops
- [ ] Period tab bar must be scrollable or use equal-flex layout if labels overflow the screen width on small devices (e.g., iPhone SE)
- [ ] Summary bar tapping (Income / Exp.) is a no-op in this sprint; button is rendered but no navigation action yet (filter screen is Sprint 6)
- [ ] Tab state must survive foreground/background app lifecycle transitions

## Test Scenarios for QA
1. Fresh install: verify Trans. tab opens to DailyView, summary bar shows zeros, all five tabs are visible
2. Tap each period tab in sequence and confirm the correct view renders for each
3. Add one income and one expense transaction, then verify summary bar totals
4. Navigate to a different month via the navigator and confirm the summary bar updates
5. Rotate device (landscape) and verify tab bar and summary bar do not overflow or clip
6. Force-quit and reopen app; verify the previously selected tab is restored (or defaults to Daily per settings)
7. Verify on iOS (iPhone SE + iPhone 15 Pro) and Android (Pixel 4a + Galaxy S22)

## UX Spec
See `docs/specs/SPEC-008-transactions-screen.md` (TBD — due Day 3, 2026-05-01)

## Estimate
S (1–2 days)

## Dependencies
- US-010 (Transaction CRUD — Sprint 3): TransactionRepository and Drift DAO must be available
- US-025 (Month/Year navigator): navigator widget must be stubbed or delivered in parallel
