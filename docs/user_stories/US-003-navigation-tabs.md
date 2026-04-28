# US-003: go_router configured with 4-tab bottom navigation and empty placeholder screens

## Source
SPEC.md §3.1 (Bottom Tab Navigator), §3.2 (Page Stack), §16.1 Sprint 1 checklist — "go_router kurulumu, ana 4 tab navigation" and "Boş ekran scaffold'ları"

## Persona
A flutter engineer and a QA engineer who need a functioning navigation shell so that all future feature screens can be slotted in at the correct routes.

## Story
**As** a MoneyWise developer
**I want** go_router configured with a 4-tab bottom navigation bar and empty placeholder screens at each route
**So that** navigation between tabs works end-to-end and each feature screen has a clearly identified route to build into

## Acceptance Criteria

```gherkin
Scenario: App opens on Transactions tab by default
  Given the app is launched fresh
  When the home screen appears
  Then the bottom navigation bar is visible with 4 tabs
  And the first tab (Transactions) is selected and highlighted in brandPrimary color
  And the tab bar height matches AppHeights.tabBar (49dp)

Scenario: Transactions tab displays correct label and icon
  Given I am on any tab
  When I look at the bottom navigation bar
  Then tab 1 shows today's date in "DD.M." format as its label (e.g., "28.4.")
  And tab 1 shows the notebook/ledger icon
  And the label updates to the correct date each day

Scenario: Stats tab navigation
  Given I am on the Transactions tab
  When I tap the Stats tab (bar chart icon, label "Stats")
  Then the Stats placeholder screen is displayed
  And the current route is "/stats"
  And the Stats tab icon and label become brandPrimary colored

Scenario: Accounts tab navigation
  Given I am on the Transactions tab
  When I tap the Accounts tab (stacked coins icon, label "Accounts")
  Then the Accounts placeholder screen is displayed
  And the current route is "/accounts"

Scenario: More tab navigation
  Given I am on any tab
  When I tap the More tab (3-dot icon, label "More")
  Then the More placeholder screen is displayed
  And the current route is "/more"

Scenario: Each tab maintains its own navigation stack
  Given I have navigated to a sub-screen within the Transactions stack
  When I tap the Stats tab and then tap back to Transactions
  Then the Transactions stack is restored to where I left it
  And the sub-screen is still visible (iOS standard tab behavior)

Scenario: All placeholder screens render without error
  Given the app is running
  When I navigate to each of the four tabs
  Then each tab shows a centered placeholder text identifying the screen name
  And no red error widgets or exceptions are thrown
  And flutter analyze passes on all route and screen files
```

## Edge Cases
- [ ] Tab 1 label ("28.4." style) must use the device locale date — must not hard-code date format
- [ ] Rapid tab switching (tapping multiple tabs within 200ms) must not crash or cause duplicate route pushes
- [ ] Back button on Android when on a root tab must show an exit confirmation (or exit app directly — to be confirmed with Sponsor before Sprint 2)
- [ ] Deep links to "/stats", "/accounts", "/more" must select the correct tab without breaking tab state
- [ ] Modal routes (e.g., AddTransactionModal added in Sprint 3) must cover all 4 tabs — the tab bar must be hidden while modal is open
- [ ] Accessibility: each tab item must have a semanticsLabel for screen readers

## Test Scenarios for QA
1. Launch app — verify Transactions tab is active and its label shows today's date in "DD.M." format
2. Tap each of the 4 tabs in sequence — verify correct route and tab highlight for each
3. Navigate to a hypothetical sub-screen stub inside Transactions tab, switch to Stats tab, switch back — verify Transactions tab sub-screen is preserved
4. Run on both iOS and Android — verify tab bar appearance and behavior matches on both platforms
5. Use TalkBack / VoiceOver — verify each tab has a readable label announced
6. Run `flutter analyze` — zero warnings on router and screen files

## UX Spec
TBD — ux-designer Sprint 1 (bottom tab bar visual specification)

## Estimate
S (1–2 days)

## Dependencies
- US-001 (project skeleton)
- US-002 (theme tokens for tab bar colors)
- US-007 (go_router dependency in pubspec.yaml)
