# US-025: Month/Year navigator — previous/next arrows + month-year picker

## Persona
A MoneyWise user who wants to navigate to a specific past or future month (or year, when on
the Monthly tab) without tapping the arrow button many times when the target period is far away.

## Story
**As** a MoneyWise user
**I want** a navigation bar on the Trans. tab with previous/next arrow buttons and a tappable
month-year title that opens a picker
**So that** I can jump to any month or year quickly and all views update to show data for
the selected period

## Source
SPEC.md §9.1.2 (Ay/Yıl Navigatörü); SPEC.md §16.1 Sprint 4 goal.

## Acceptance Criteria

```gherkin
Scenario: Navigator shows current month and year on Daily, Calendar, and Summary tabs
  Given today is 2026-04-29
  And the user is on the Daily tab
  When the user looks at the navigator bar
  Then the navigator title shows "Apr 2026"
  And a < arrow button is on the left
  And a > arrow button is on the right

Scenario: Navigator shows year only on the Monthly tab
  Given the user is on the Monthly tab
  When the user looks at the navigator bar
  Then the navigator title shows "2026" (year only, no month label)
  And tapping < navigates to 2025
  And tapping > navigates to 2027

Scenario: Tapping < navigates to the previous month
  Given the navigator shows "Apr 2026"
  When the user taps the < arrow
  Then the navigator title changes to "Mar 2026"
  And the active view updates to show March 2026 data

Scenario: Tapping > navigates to the next month
  Given the navigator shows "Apr 2026"
  When the user taps the > arrow
  Then the navigator title changes to "May 2026"
  And the active view updates to show May 2026 data

Scenario: Tapping < from January navigates to December of the previous year
  Given the navigator shows "Jan 2026"
  When the user taps the < arrow
  Then the navigator title changes to "Dec 2025"
  And the active view updates to show December 2025 data

Scenario: Tapping > from December navigates to January of the next year
  Given the navigator shows "Dec 2026"
  When the user taps the > arrow
  Then the navigator title changes to "Jan 2027"
  And the active view updates to show January 2027 data

Scenario: Tapping the month-year title opens the MonthYearPicker
  Given the navigator shows "Apr 2026"
  When the user taps the "Apr 2026" title
  Then a MonthYearPicker modal opens
  And the picker defaults to April 2026 as the selected month and year

Scenario: Selecting a month in the MonthYearPicker updates all views
  Given the MonthYearPicker is open showing April 2026
  When the user selects "August 2025" and confirms
  Then the picker closes
  And the navigator title changes to "Aug 2025"
  And the active view updates to show August 2025 data

Scenario: Cancelling the MonthYearPicker keeps the current selection
  Given the navigator shows "Apr 2026" and the MonthYearPicker is open
  When the user cancels the picker (swipe down or Cancel button)
  Then the picker closes
  And the navigator title remains "Apr 2026"
  And the active view is unchanged

Scenario: Navigator state is shared across all period tabs
  Given the navigator shows "Mar 2026"
  When the user switches from Daily to Calendar
  Then the CalendarView renders March 2026
  And the navigator still shows "Mar 2026"
  When the user switches to Monthly
  Then the MonthlyView renders 2026 (year only)
  And navigating back to Daily still shows "Mar 2026"

Scenario: Switching from Monthly tab to Daily tab restores month context
  Given the user navigated to 2025 on the Monthly tab
  When the user switches to the Daily tab
  Then the navigator shows the month that was last selected on the Daily tab
  (the Monthly tab's year navigation does not override the month tabs' month state)
```

## Edge Cases
- [ ] Minimum navigable date — no hard floor enforced in Sprint 4; the app must not crash if the user navigates to year 1900 via the picker (show empty state in views)
- [ ] Maximum navigable date — no hard ceiling; future months are allowed (no transactions will exist, views show empty states)
- [ ] Rapid successive taps on < or > — state updates must be debounced or queued; the navigator title must not get out of sync with the view
- [ ] MonthlyView year navigation via < and > must increment/decrement the year, not the month
- [ ] The MonthYearPicker must respect the current tab context: when on the Monthly tab, the picker selects year only; on all other tabs, the picker selects month + year
- [ ] Navigator title localisation — month names must use the app's active locale (TR: "Nis 2026", EN: "Apr 2026"); no hardcoded English strings
- [ ] Navigator height is fixed at 48dp per SPEC; long month names in some locales must be truncated or use abbreviated form
- [ ] The navigator is a shared widget placed in `core/widgets/month_navigator.dart`; it must accept a callback or Riverpod provider as its state interface, not hold its own local state

## Test Scenarios for QA
1. Verify navigator shows "Apr 2026" on Daily tab for today (2026-04-29)
2. Verify navigator shows "2026" (year only) on Monthly tab
3. Tap < from January: verify year rolls back to December of previous year
4. Tap > from December: verify year advances to January of next year
5. Tap < and > rapidly 5 times each: verify title stays in sync with view content
6. Tap month-year title: MonthYearPicker opens at correct default selection
7. Select a past month in picker: all views update; navigator title correct
8. Cancel picker: navigator and view unchanged
9. Navigate to a future month (no transactions): view shows empty state, no crash
10. Switch between tabs: verify navigator state is preserved per-tab correctly
11. Turkish locale: verify "Nis 2026" displayed correctly
12. Very long locale month name: verify no overflow in 48dp navigator bar

## UX Spec
See `docs/specs/SPEC-013-month-year-navigator.md` (TBD — due Day 3, 2026-05-01)

## Estimate
S (1–2 days)

## Dependencies
- US-020 (TransactionsScreen scaffold): the navigator is embedded inside the scaffold
- No data-layer dependencies (navigator is a pure UI + state widget)
