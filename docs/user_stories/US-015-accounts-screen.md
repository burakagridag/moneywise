# US-015: AccountsScreen — account groups list with live balances

## Persona
A MoneyWise user who wants to see all their accounts organised by group (Cash, Card, Savings,
etc.) with current balances at a glance, so they understand their net worth without opening
each account individually.

## Story
**As** a MoneyWise user
**I want** the Accounts tab to show all my account groups and accounts with live balances
and an Assets / Liabilities / Total summary bar at the top
**So that** I can see my overall financial position in one screen

## Source
SPEC.md §9.4 (AccountsScreen, Ekran 13); SPEC.md §7.3 (Asset/Liability split);
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Accounts tab shows summary bar with Assets, Liabilities, Total
  Given the user has:
    | account         | group type  | computed balance |
    | Wallet          | cash        | 200.00 EUR       |
    | Bank            | accounts    | 1000.00 EUR      |
    | Visa Card       | card        | -350.00 EUR      |
  When the user navigates to the Accounts tab
  Then the summary bar shows:
    | Assets      | 1200.00 EUR  (blue text)   |
    | Liabilities | 350.00 EUR   (red text)    |
    | Total       | 850.00 EUR   (white text)  |

Scenario: Empty state — no accounts added yet
  Given the user has no accounts
  When the Accounts tab is displayed
  Then the summary bar shows 0.00 for Assets, Liabilities, and Total
  And the list area shows an empty-state message (e.g. "No accounts yet")
  And the + button in the AppBar is visible

Scenario: Account groups with accounts are displayed collapsible
  Given the user has two accounts in group "Cash" and one in group "Savings"
  When the Accounts tab is displayed
  Then the "Cash" group header row is visible with the sum of its accounts' balances
  And the "Cash" group is expanded by default showing its two accounts
  And the "Savings" group is visible with its account balance

Scenario: Tap account group header to collapse and expand
  Given the "Cash" group is expanded showing 2 accounts
  When the user taps the "Cash" group header
  Then the group collapses and the 2 account rows are hidden
  When the user taps the "Cash" group header again
  Then the group expands and the 2 account rows are visible again

Scenario: Account group with no accounts is hidden
  Given the "Investments" group has no accounts
  When the Accounts tab is displayed
  Then the "Investments" group header is not shown in the list

Scenario: Account balance is colour-coded
  Given an account has a positive balance
  Then the balance is displayed in white text
  Given an account has a negative balance
  Then the balance is displayed in red (expense colour)

Scenario: Tap account row navigates to AccountAddEditScreen in edit mode
  Given the user is on the Accounts tab
  When the user taps on the "Bank" account row
  Then the app navigates to /accounts/edit/:id for that account

Scenario: Tap + button navigates to AccountAddEditScreen in add mode
  Given the user is on the Accounts tab
  When the user taps the + button in the AppBar
  Then the app navigates to /accounts/add

Scenario: Balances update reactively when a transaction is added (Sprint 3 readiness)
  Given the "Bank" account shows balance 1000.00
  When a new expense of 50.00 is added to "Bank" (simulated via direct DAO insert in test)
  Then the Accounts tab updates the "Bank" balance to 950.00 without requiring a screen reload

Scenario: Banner ad shown for free-tier users
  Given the user is on the free tier
  When the Accounts tab is displayed
  Then a 50dp banner ad placeholder is visible above the tab bar

Scenario: isHidden accounts do not appear in the main list
  Given account "Secret Savings" has isHidden = true
  When the Accounts tab is displayed
  Then "Secret Savings" is not shown in the list
  And the summary bar still includes its balance in the total
    (includeInTotals = true governs the summary; isHidden governs display only)
```

## Edge Cases
- [ ] Empty state for the entire screen (no accounts at all) — must show a helpful call-to-action, not a blank screen
- [ ] All account groups empty (no accounts in any group) — same empty state
- [ ] Account group with all accounts hidden (isHidden = true) — group header is also hidden
- [ ] Very long account name (50 chars) — must truncate with ellipsis, not overflow
- [ ] Very large balance (e.g. 999,999,999.99) — tabular figures, no layout overflow
- [ ] Negative net worth (more liabilities than assets) — Total shown in red with minus sign
- [ ] Offline — screen loads from local DB; no spinner or error for offline state
- [ ] Dark mode and Light mode — both must render correctly (verified per SPEC.md §2.1)

## Test Scenarios for QA
1. Fresh install (no accounts): empty-state message and + button visible on both iOS and Android
2. Add 3 accounts (cash + bank + credit card via DAO): verify summary bar values and group display
3. Collapse and expand group header: confirm accounts show/hide correctly
4. Positive and negative balance colour coding: visual inspection on both platforms
5. isHidden account: confirm absent from list, balance still in summary total
6. Long account name (50 chars): confirm ellipsis in list row, no overflow
7. Very large balance: confirm tabular display does not break layout
8. Navigate to add screen via + button: verify route /accounts/add opens
9. Navigate to edit screen by tapping account row: verify route /accounts/edit/:id opens with correct data

## UX Spec
TBD — ux-designer to deliver `docs/specs/SPEC-004-accounts-screen.md` during Sprint 2.
Reference: SPEC.md §9.4 (Ekran 13).

## Estimate
M (3–4 days)

## Dependencies
- US-014 (AccountRepository — provides watchAllAccountGroups, watchNetWorth)
- US-012 (Accounts table and DAO)
- US-011 (AccountGroups table and DAO)
- US-016 (AccountAddEditScreen — navigation target)
