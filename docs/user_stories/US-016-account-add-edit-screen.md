# US-016: AccountAddEditScreen — add and edit an account

## Persona
A MoneyWise user who wants to add a new bank account or credit card with the correct group,
currency, initial balance, icon, and colour — or edit an existing account — in a single
straightforward form.

## Story
**As** a MoneyWise user
**I want** a form to add a new account or edit an existing one
**So that** I can manage all my real-world accounts in the app with accurate initial balances
and visual identifiers

## Source
SPEC.md §9.5 (AccountAddEditScreen, Ekran 12); SPEC.md §6.2 (accounts table fields);
SPEC.md §7.3 (Card-specific fields: statementDay, paymentDueDay, creditLimit).
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Add mode — form opens empty and all required fields are visible
  Given the user taps + in the AccountsScreen AppBar
  When /accounts/add is pushed
  Then the screen title shows "Add Account" (or equivalent)
  And Group, Name, and Amount fields are visible and empty
  And the Save/Add button in the AppBar is disabled

Scenario: Group picker shows all 11 default account groups
  Given the user is on the AccountAddEditScreen
  When the user taps the Group field
  Then a bottom-sheet picker opens listing all 11 groups:
    Cash, Accounts, Card, Debit Card, Savings, Top-Up/Prepaid,
    Investments, Overdrafts, Loan, Insurance, Others
  And a Cancel option closes the picker without selection

Scenario: Selecting a non-card group shows no card-specific fields
  Given the user has tapped the Group field
  When the user selects "Cash"
  Then the picker closes and "Cash" is shown in the Group field
  And Statement Day, Payment Due Day, and Credit Limit fields are NOT visible

Scenario: Selecting Card group reveals card-specific fields
  When the user selects "Card" from the group picker
  Then Statement Day (1–31), Payment Due Day (1–31), and Credit Limit fields appear below Amount

Scenario: Save is enabled only when required fields are filled
  Given Group = "Cash" and Name = "" and Amount = ""
  Then the Save button is disabled
  When Name = "My Wallet" and Amount = 0.00 (zero is valid as initial balance)
  Then the Save button is enabled

Scenario: Happy path — add a Cash account
  Given the user fills:
    | Group  | Cash        |
    | Name   | My Wallet   |
    | Amount | 100.00      |
  When the user taps Save
  Then the account is saved in the database
  And the user is navigated back to AccountsScreen
  And "My Wallet" appears in the "Cash" group with balance 100.00

Scenario: Happy path — add a Card account
  Given the user fills:
    | Group          | Card        |
    | Name           | Visa Credit |
    | Amount         | -500.00     |
    | Statement Day  | 15          |
    | Payment Due    | 5           |
    | Credit Limit   | 3000.00     |
  When the user taps Save
  Then the account is saved with all card fields
  And the user is navigated back to AccountsScreen

Scenario: Edit mode — form opens pre-filled with existing values
  Given account "Bank" exists in group "Accounts" with initialBalance 1000.00
  When the user taps "Bank" in AccountsScreen
  And /accounts/edit/:id is pushed
  Then all fields are pre-filled with the stored values
  And the AppBar shows "Edit Account" (or equivalent)

Scenario: Edit mode — save updates the record
  Given edit mode for account "Bank"
  When the user changes Name to "Main Bank" and taps Save
  Then the accounts table row is updated with name = "Main Bank"
  And updatedAt is refreshed
  And the user is navigated back to AccountsScreen showing "Main Bank"

Scenario: Duplicate name within same group is rejected
  Given a "Cash" account "My Wallet" already exists
  When the user tries to add another "Cash" account with name = "My Wallet"
  Then a validation error message is shown: "An account with this name already exists in this group"
  And the record is not saved

Scenario: Name exceeds 50 characters
  When the user enters 51 characters in the Name field
  Then the field caps input at 50 characters (maxLength enforced in text field)

Scenario: Amount field rejects non-numeric input
  When the user attempts to type letters in the Amount field
  Then only numeric characters and one decimal separator are accepted

Scenario: Negative initial balance is allowed
  Given Amount = -200.00
  Then the Save button is enabled
  And the account is saved with initialBalance = -200.00

Scenario: Zero initial balance is allowed
  Given Amount = 0
  Then the Save button is enabled
  And the account is saved with initialBalance = 0.00

Scenario: Back navigation discards unsaved changes
  Given the user has entered data in the form
  When the user taps the back button without saving
  Then a confirmation dialog asks "Discard changes?"
  And tapping "Discard" navigates back without saving
  And tapping "Cancel" returns to the form with data intact
```

## Edge Cases
- [ ] Empty Name field — Save must remain disabled; no silent empty-string save
- [ ] Amount field: decimal precision — app uses money2 for storage; the field must not allow more than 2 decimal places for standard currencies (e.g. EUR); validation in repository
- [ ] Currency field: defaults to main currency from settings (Settings.mainCurrency); user can override via currency picker (deferred to US-018 for full currency screen, but picker must be hookable)
- [ ] Card statement day / payment due day boundaries: 1–31; days >28 may not exist in all months — repository stores the integer as-is; no month-specific validation in V1
- [ ] Credit limit: must be >= 0 if provided; negative credit limit is a validation error
- [ ] Screen rotation (Android): form state must survive orientation change (Riverpod StateNotifier)
- [ ] Back gesture (iOS swipe): same discard-changes confirmation
- [ ] Keyboard obscuring fields: form must scroll so the active field is visible above the keyboard
- [ ] Dark mode and Light mode: form must render correctly in both themes
- [ ] Offline: save always goes to local DB; no network dependency

## Test Scenarios for QA
1. Add Cash account (happy path): verify in AccountsScreen and DB on iOS and Android
2. Add Card account: verify card fields visible and persisted
3. Non-card group selected after Card was selected: verify card fields disappear
4. Edit existing account: verify pre-fill and successful update
5. Duplicate name in same group: verify error message, no DB insert
6. Same name in different group: verify save succeeds
7. Name exactly 50 chars: verify save succeeds; 51 chars: verify input capped at 50
8. Negative initial balance: verify saved correctly
9. Back with unsaved data: verify discard dialog appears
10. Statement Day boundary: 0 → validation error; 31 → save succeeds; 32 → validation error

## UX Spec
TBD — ux-designer to deliver `docs/specs/SPEC-005-account-add-edit-screen.md` during Sprint 2.
Reference: SPEC.md §9.5 (Ekran 12).

## Estimate
M (3–4 days)

## Dependencies
- US-014 (AccountRepository — add/update/delete business rules)
- US-015 (AccountsScreen — origin and return navigation target)
- US-018 (CurrencyScreen — currency picker in account form; can use placeholder in Sprint 2)
