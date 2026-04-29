# Sprint 3 User Stories — Transactions, Statistics & SQLCipher Encryption

> **Source:** Product Sponsor vision (Sprint 3 priorities), SPEC.md Sections 1–3 / 6.4 / 7 / 9.1–9.3, ADR-004 (SQLCipher deferral).
> **Sprint:** Sprint 03
> **Date authored:** 2026-04-29

---

## US-010: Add an expense transaction

### Persona
A young professional who wants to record a daily expense (coffee, lunch, transport) within three taps of opening the app.

### Story
**As** a MoneyWise user
**I want** to open the Add Transaction modal and record an expense with amount, category, account, date, and optional note
**So that** the transaction is persisted immediately and the source account balance is updated

### Acceptance Criteria

```gherkin
Scenario: Successfully add an expense
  Given I am on any tab of the app
  And at least one account exists (e.g. "Debit Card" with initial balance 1000.00 EUR)
  And at least one expense category exists (e.g. "Food")
  When I tap the "+" FAB
  And the modal opens with "Expense" type pre-selected
  And I enter Amount: 25.50
  And I select Category: "Food"
  And I leave Account as "Debit Card" (default)
  And I leave Date as today
  And I tap "Save"
  Then the modal closes
  And the transaction is stored with type=expense, amount=25.50, currencyCode=EUR, accountId=<DebitCard>, date=today
  And the Debit Card balance becomes 974.50 EUR
  And the Trans. tab Daily view shows the transaction under today

Scenario: Save is disabled while Amount is missing
  Given I am on the Add Transaction modal with "Expense" selected
  When the Amount field is empty
  Then the "Save" button is disabled (opacity 0.5)
  And the "Continue" button is disabled (opacity 0.5)

Scenario: Save is disabled while Category is missing
  Given I am on the Add Transaction modal with "Expense" selected
  And I have entered Amount: 10.00
  When no Category is selected
  Then the "Save" button is disabled

Scenario: Continue saves and resets form
  Given I am on the Add Transaction modal with "Expense" selected
  And I have entered Amount: 10.00, Category: "Food", Account: "Debit Card"
  When I tap "Continue"
  Then the transaction is saved
  And the Amount field resets to empty
  And the Category field resets to empty
  And the Account and Date fields retain their previous values
  And the modal remains open

Scenario: User changes the date via date picker
  Given I am on the Add Transaction modal
  When I tap the Date field
  Then a Cupertino-style date picker opens
  When I select "2026-04-15" and confirm
  Then the Date field displays "Wed 15.4.2026"
  And the saved transaction carries date=2026-04-15
```

### Edge Cases
- [ ] Amount = 0 — Save disabled; validation message "Amount must be greater than zero"
- [ ] Amount is negative (user types "-") — input should reject or strip negative sign; only positive values accepted
- [ ] Amount with more than 2 decimal places — round to 2 decimal places using decimal-precise math (money2), no float drift
- [ ] Very large amount (e.g. 999 999 999.99) — must save and display without overflow
- [ ] No accounts exist — tapping "+" shows an inline empty state: "Please create an account first" with a shortcut to AccountAddEditScreen; Save is disabled
- [ ] No expense categories exist — category picker shows empty state; Save is disabled
- [ ] Account balance would go negative after expense — no block in Phase 1 (allow negative balance); Phase 2 may add warning
- [ ] Note field exceeds 500 chars — enforce max-length, show character counter
- [ ] Description field exceeds 2000 chars — enforce max-length
- [ ] Offline / local-first — operation must complete with no network; local DB write succeeds
- [ ] Two Add Transaction modals opened concurrently — impossible by navigation guard (modal is full-screen); one can only open at a time
- [ ] User force-kills app during save — Drift atomic write ensures no partial state on restart
- [ ] Date set to far future (e.g. 2099-12-31) — accepted but flagged in UI with "Future date" label
- [ ] Date set to far past (e.g. 2000-01-01) — accepted without restriction

### Test Scenarios for QA
1. Happy path on iOS (expense saved, balance updated, appears in Daily view)
2. Happy path on Android
3. Save disabled with empty Amount on both platforms
4. Save disabled with no Category on both platforms
5. "Continue" flow: two consecutive entries, verify both persisted and balance doubly deducted
6. Date picker: select a past date, verify transaction date in DB
7. Decimal precision: enter 33.333, verify stored and displayed as 33.33
8. Large amount: enter 999999999.99, verify no crash or truncation
9. No accounts edge case: tapping "+" shows correct empty state
10. App restart after save: transaction still present in list and balance correct

### UX Spec
See `docs/specs/SPEC-add-transaction-modal.md` (to be authored by ux-designer for Sprint 3)

### Estimate
M (3–4 days) — form, validation, date picker, repository write, balance recalculation stream

### Dependencies
- US-002 / Sprint 2 — Account data layer (AccountRepository) must be complete
- US-003 / Sprint 2 — Category data layer (CategoryRepository) must be complete
- US-011 (Add income) shares the same modal; implement as one form with type toggle
- US-012 (Transfer) extends the same form with a second account picker
- TransactionRepository (new in Sprint 3) — blocking dependency

---

## US-011: Add an income transaction

### Persona
A salaried user who receives their monthly pay and wants to record it immediately so their account balance reflects reality.

### Story
**As** a MoneyWise user
**I want** to switch to the "Income" type in the Add Transaction modal and record a deposit
**So that** the receiving account balance is increased and income is visible in statistics

### Acceptance Criteria

```gherkin
Scenario: Successfully add an income
  Given I am on the Add Transaction modal
  When I tap the "Income" type button
  Then the modal title changes to "Income"
  And the Category picker filters to income-only categories
  When I enter Amount: 3000.00, Category: "Salary", Account: "Bank Account"
  And I tap "Save"
  Then the transaction is stored with type=income, amount=3000.00
  And "Bank Account" balance increases by 3000.00
  And the Trans. tab shows the entry in blue (income color)

Scenario: Income categories are isolated from expense categories
  Given I am on the Add Transaction modal with "Income" selected
  When I open the Category picker
  Then only income categories are listed (e.g. Salary, Bonus, Allowance)
  And expense categories (e.g. Food, Transport) are not shown

Scenario: Switching type clears category selection
  Given I am on the Add Transaction modal
  And I have selected type "Expense" and Category "Food"
  When I tap the "Income" type button
  Then the Category field resets to empty
  And only income categories appear in the picker
```

### Edge Cases
- [ ] All same edge cases as US-010 (zero amount, no accounts, offline, large amount, decimal precision)
- [ ] User switches type after filling form — category resets; amount, account, date, note are retained
- [ ] Income category list is empty (user deleted all) — same empty-state guard as expense

### Test Scenarios for QA
1. Add income, verify balance increases on iOS and Android
2. Category picker shows income-only categories
3. Switching Income → Expense → Income: category clears each time, amount persists
4. Balance recalculation: add income to account with existing expenses; verify net balance

### UX Spec
Shared with US-010 (same modal, different type toggle state)

### Estimate
S (1 day) — same modal as US-010; only category filter and color change differ

### Dependencies
- US-010 (shared modal implementation)
- Income categories seeded in Sprint 2

---

## US-012: Add a transfer between accounts

### Persona
A user who moves money from their bank account to a savings account and wants both balances to update instantly.

### Story
**As** a MoneyWise user
**I want** to select "Transfer" type in the Add Transaction modal, pick a source and destination account, and enter an amount
**So that** a single transfer transaction is recorded, the source account is debited, and the destination account is credited — with no duplicate entries

### Acceptance Criteria

```gherkin
Scenario: Successfully transfer between two accounts
  Given I have "Bank Account" with balance 2000.00 EUR
  And I have "Savings" with balance 500.00 EUR
  When I open the Add Transaction modal and select "Transfer"
  Then the Category field disappears
  And an additional "To Account" field appears below "Account"
  When I set Account (from): "Bank Account", To Account: "Savings", Amount: 300.00
  And I tap "Save"
  Then ONE transaction record is created with type=transfer, accountId=BankAccount, toAccountId=Savings, amount=300.00
  And "Bank Account" balance becomes 1700.00 EUR
  And "Savings" balance becomes 800.00 EUR
  And the Accounts tab reflects the updated balances immediately

Scenario: Source and destination account cannot be the same
  Given I am on the Add Transaction modal with "Transfer" selected
  And I select "Bank Account" as the source account
  When I open the "To Account" picker
  Then "Bank Account" is disabled (grayed out) in the list

Scenario: Save is disabled when To Account is not selected
  Given I am on the Add Transaction modal with "Transfer" selected
  And I have entered Amount: 100.00 and Account (from): "Bank Account"
  When "To Account" is empty
  Then "Save" is disabled

Scenario: Transfer is recorded as a single row in the transactions table
  Given a transfer has been saved from "Bank Account" to "Savings" for 300.00
  When I query the database
  Then exactly ONE row exists in the transactions table for this operation
  And that row has type='transfer', accountId=<BankAccount>, toAccountId=<Savings>, amount=300.00
```

### Edge Cases
- [ ] Only one account exists — "To Account" picker shows empty state; Save is disabled
- [ ] Transfer amount exceeds source balance — allowed in Phase 1 (negative balance permitted); no block
- [ ] Both accounts have different currencies — in Phase 1, exchange rate = 1.0 is assumed; amount is stored as-is; multi-currency exchange is Phase 2
- [ ] Transfer to/from a liability account (e.g. Credit Card) — allowed; balance formula handles it correctly per SPEC §7.1
- [ ] Large amount edge cases same as US-010
- [ ] Offline — local-first, same as US-010

### Test Scenarios for QA
1. Transfer between two asset accounts: verify both balances update correctly
2. Transfer to a credit card (liability): verify net calculation
3. Self-transfer prevention: source account grayed out in "To Account" picker
4. Only one account: "To Account" shows empty state
5. Database: verify exactly one record inserted per transfer
6. Restart: balances correct after app restart

### UX Spec
Shared with US-010 / US-011 modal (Transfer type state)

### Estimate
S (1–2 days) — modal already built in US-010; adds second account picker and FK logic

### Dependencies
- US-010 (shared modal)
- AccountRepository (Sprint 2)
- TransactionRepository (US-010 sprint 3)

---

## US-013: Edit an existing transaction

### Persona
A user who made a typo in a transaction amount or picked the wrong category and needs to correct it without deleting and re-creating the entry.

### Story
**As** a MoneyWise user
**I want** to tap on a transaction in the Daily view and edit any of its fields
**So that** the record is corrected and all affected account balances are recalculated automatically

### Acceptance Criteria

```gherkin
Scenario: Open edit modal from Daily view
  Given I am on the Trans. tab, Daily view
  And a transaction "Lunch / Food / 25.50 EUR" exists for today
  When I tap on that transaction row
  Then the Add Transaction modal opens pre-filled with all fields: type=Expense, amount=25.50, category=Food, account=Debit Card, date=today

Scenario: Edit the amount and save
  Given the edit modal is open with amount=25.50 and account="Debit Card" (balance 974.50)
  When I change Amount to 30.00
  And I tap "Save"
  Then the transaction record is updated (amount=30.00)
  And "Debit Card" balance becomes 970.00 EUR (recalculated from initialBalance + all transactions)
  And the updated amount is shown in the Daily view

Scenario: Edit is cancelled with no changes
  Given the edit modal is open
  When I tap the back button without changing any field
  Then no database write occurs
  And balances remain unchanged

Scenario: Changing account on an existing expense
  Given a 25.50 EUR expense on "Debit Card"
  And "Cash" account exists with balance 200.00
  When I edit the transaction and change Account to "Cash"
  And I tap "Save"
  Then "Debit Card" balance reverts by +25.50 (as if expense never happened on it)
  And "Cash" balance decreases by 25.50
```

### Edge Cases
- [ ] Changing transaction type (e.g. expense → income) — must recompute both the old and new account balances; category field resets
- [ ] Editing a transfer: changing fromAccount or toAccount must recompute three accounts (old from, old to, new from/to)
- [ ] Editing the date only — no balance change, only re-ordering in the list
- [ ] Concurrent edit: user has the same transaction open on two devices (Phase 1 local only — not applicable; Phase 2 sync conflict)
- [ ] Editing a transaction whose account has been soft-deleted — show warning; allow amount/note/date edits only
- [ ] Editing a recurring-generated transaction — edit applies to THIS INSTANCE only; does not modify the recurring template

### Test Scenarios for QA
1. Edit amount: verify balance delta correct on iOS and Android
2. Edit account: verify old account recovers its balance and new account is debited
3. Edit category: verify statistics screen updates
4. Edit date: verify transaction moves to correct date group in Daily view
5. Edit then cancel: verify no write to DB
6. Edit type expense → income: verify full recalculation

### UX Spec
Same modal as US-010 in edit mode (pre-filled fields, AppBar shows "Edit" or transaction type)

### Estimate
M (2–3 days) — pre-fill logic, update path in repository, balance delta recalculation

### Dependencies
- US-010 (modal and TransactionRepository.add)
- TransactionRepository.update (new method)

---

## US-014: Delete a transaction

### Persona
A user who accidentally added a duplicate transaction and needs to remove it.

### Story
**As** a MoneyWise user
**I want** to delete a transaction from the Daily view or from the edit modal
**So that** the record is removed and the affected account balance is recalculated as if it never existed

### Acceptance Criteria

```gherkin
Scenario: Delete from the edit modal
  Given the edit modal is open for a 25.50 EUR expense on "Debit Card" (balance 974.50)
  When I tap the delete icon (trash)
  Then a confirmation dialog appears: "Delete this transaction? This cannot be undone."
  When I confirm deletion
  Then the transaction is soft-deleted (isDeleted=true)
  And "Debit Card" balance returns to 1000.00 EUR
  And the transaction no longer appears in the Daily view

Scenario: Delete confirmation dialog cancel
  Given the confirmation dialog is showing
  When I tap "Cancel"
  Then the dialog closes
  And no change is made to the database
  And the edit modal remains open

Scenario: Deleted transaction does not appear in any view
  Given a transaction has been soft-deleted
  When I navigate to Trans. tab Daily view
  And when I navigate to Stats screen
  Then the transaction does not appear in any list or chart

Scenario: Delete recalculates balance immediately
  Given "Debit Card" has balance 974.50 (after one 25.50 expense)
  When that expense is deleted
  Then "Debit Card" balance becomes 1000.00 (initial balance)
  And the Accounts tab reflects this within the same session
```

### Edge Cases
- [ ] Deleting a transfer: both the source and destination account balances must be recalculated
- [ ] Deleting the only transaction in a day group — the day header disappears from Daily view (no empty day header)
- [ ] Deleting a transaction linked to a recurring template — soft-delete the instance only; recurring template is unaffected
- [ ] Mass delete (future feature) — not in scope for this story
- [ ] Undo within session — not in Phase 1 scope; noted for backlog

### Test Scenarios for QA
1. Delete expense: verify balance restored on iOS and Android
2. Delete income: verify balance decremented
3. Delete transfer: verify both accounts restored
4. Cancel confirmation: verify no change
5. Daily view: verify day header disappears when last transaction in a day is deleted
6. Stats screen: verify deleted transaction excluded from pie chart

### UX Spec
Trash icon in edit modal AppBar; confirmation dialog (destructive action, red confirm button)

### Estimate
S (1 day) — soft-delete flag, repository method, balance recalculation reactive

### Dependencies
- US-013 (edit modal where delete action lives)
- TransactionRepository.softDelete (new method)

---

## US-015: View transactions in the Trans. tab — Daily view

### Persona
A user who wants to review all spending for the current month, day by day.

### Story
**As** a MoneyWise user
**I want** to see all transactions grouped by day in the Trans. tab Daily view, with a monthly income/expense/total summary bar
**So that** I can quickly understand my spending pattern for any given month

### Acceptance Criteria

```gherkin
Scenario: Daily view shows transactions grouped by day
  Given transactions exist for April 2026
  When I am on the Trans. tab with "Daily" sub-tab selected
  Then transactions are displayed in reverse-chronological order (newest day first)
  And each day group shows a header with: day number, day-of-week label, total income (blue), total expense (coral)
  And each transaction row shows: category emoji + name, account name, amount (blue for income / coral for expense)

Scenario: Income / Exp / Total summary bar is always visible
  Given I am on the Trans. tab Daily view for April 2026
  Then the summary bar shows:
    - "Income" total in blue (sum of all income transactions in the month)
    - "Exp." total in coral (sum of all expense transactions)
    - "Total" = Income - Expense (white, with +/- sign)

Scenario: Navigate to previous month
  Given I am viewing April 2026
  When I tap the "<" month navigator arrow
  Then the view switches to March 2026
  And the summary bar updates to March totals
  And the transaction list shows only March transactions

Scenario: Empty state for month with no transactions
  Given no transactions exist for March 2025
  When I navigate to that month
  Then an empty state message is displayed: "No transactions for this period"
  And the summary bar shows 0.00 / 0.00 / 0.00

Scenario: Sunday header shown with red day label, Saturday with blue
  Given a transaction exists on a Sunday
  When I view the Daily list
  Then the Sunday day-of-week badge is red
  And Saturday badge is blue
```

### Edge Cases
- [ ] Very large number of transactions in one day (100+) — list must remain scrollable and performant (lazy loading / virtualized list)
- [ ] Month with only income (no expenses) — Exp. shows 0.00, Total positive
- [ ] Month with only expenses (no income) — Income shows 0.00, Total negative
- [ ] Transactions in different currencies — display each in its original currency; total bar uses main currency (EUR) with exchange rate 1.0 in Phase 1
- [ ] isExcluded=true transactions — shown in list with a strikethrough or muted style; excluded from summary totals
- [ ] Soft-deleted transactions — never shown

### Test Scenarios for QA
1. List order: newest day first on both platforms
2. Summary bar math: verify Income - Expense = Total (no rounding errors)
3. Month navigation: forward and backward, verify correct data
4. Empty month: empty state displayed correctly
5. Mixed income + expense on same day: day header totals correct
6. isExcluded transaction: excluded from totals but visible in list

### UX Spec
See SPEC.md §9.1.5 (Daily View layout specification)

### Estimate
L (4–5 days) — TransactionRepository stream query, grouped list widget, summary bar, month navigation state, reactive Riverpod providers

### Dependencies
- US-010 / US-011 / US-012 — TransactionRepository must be complete (data must exist to display)
- AccountRepository (Sprint 2)
- Riverpod providers for transaction streams

---

## US-016: Statistics screen — pie chart by category with monthly totals

### Persona
A user who wants to understand where their money is going each month at a glance, without needing a spreadsheet.

### Story
**As** a MoneyWise user
**I want** to see a donut/pie chart breaking down my spending (or income) by category for the selected month, alongside a ranked list
**So that** I can identify my largest expense categories and make informed budget decisions

### Acceptance Criteria

```gherkin
Scenario: Stats screen shows pie chart for current month expenses
  Given I have expense transactions in April 2026 across categories: Food (198.44 EUR), Transport (100.00 EUR), Health (50.00 EUR)
  When I navigate to the Stats tab
  And "Exp." is selected on the Income/Exp toggle
  Then a donut pie chart is rendered with three segments:
    - Food: ~56.7%
    - Transport: ~28.5%
    - Health: ~14.3%
  And each segment has a distinct color from the brand color palette
  And a label with percentage is drawn adjacent to each segment

Scenario: Category list below chart is ranked highest-to-lowest
  Given the same April 2026 data
  Then the list below the chart shows:
    Row 1: [Food color badge] Food ............... € 198,44
    Row 2: [Transport badge] Transport .......... € 100,00
    Row 3: [Health badge] Health ............... € 50,00
  And each row's color badge matches its pie segment color

Scenario: Switching to Income mode updates chart and list
  Given I have income transactions: Salary 3000.00, Bonus 500.00
  When I tap "Income" on the toggle
  Then the pie chart and list update to show income categories only

Scenario: Navigating to previous month updates the chart
  Given I am on the Stats screen for April 2026
  When I tap "<" month navigator
  Then the chart and list update to March 2026 data

Scenario: No transactions for the selected period
  Given no transactions exist for March 2025
  When I navigate to March 2025 on the Stats screen
  Then the pie chart shows an empty/placeholder ring
  And the list shows "No data for this period"
  And Income and Expense totals both show 0.00

Scenario: Tapping a pie slice navigates to category transactions
  Given the pie chart is rendered with a "Food" segment
  When I tap the "Food" slice
  Then the Trans. tab opens filtered to Food category transactions for the same month
```

### Edge Cases
- [ ] Single category with all expenses — pie is a full circle (one color)
- [ ] Very many categories (20+) — pie becomes crowded; group smallest into "Other" if segment < 3% (design decision to be confirmed with UX)
- [ ] Category with zero amount in selected month — excluded from pie and list
- [ ] isExcluded transactions — excluded from pie and list totals
- [ ] Negative net total (income < 0) — should not occur by design (income amounts are always positive); display 0.00
- [ ] Very long category name (>20 chars) — label truncated with ellipsis on pie; full name in list row
- [ ] Month with only one transaction — pie renders a single full-circle segment
- [ ] Amounts in multiple currencies — Phase 1: treat all as main currency (EUR), exchange rate = 1.0

### Test Scenarios for QA
1. Pie chart segment percentages sum to 100% (or within rounding tolerance) on both platforms
2. List ranking: verify highest-amount category is first
3. Income/Expense toggle: verify chart and list swap data correctly
4. Month navigation: March vs April data are distinct
5. Empty month: empty state displayed, no chart error
6. Tap segment: verify navigation to filtered transaction list
7. 1 category: full-circle chart renders without crash
8. 20+ categories: chart renders without overlap or crash (visual regression)

### UX Spec
See SPEC.md §9.3.4 (Stats sub-tab layout specification)

### Estimate
L (4–5 days) — fl_chart integration, Riverpod stats provider, category aggregation query, color palette assignment, segment-tap navigation

### Dependencies
- US-010 / US-011 — transaction data must exist
- CategoryRepository (Sprint 2)
- TransactionRepository (Sprint 3)

---

## US-017: Activate SQLCipher database encryption

### Persona
A privacy-conscious user who stores personal financial data on their phone and expects it to be encrypted at rest.

### Story
**As** a MoneyWise user
**I want** the local database to be encrypted at rest using SQLCipher
**So that** my financial data is not readable if my device is lost or accessed without my permission

### Acceptance Criteria

```gherkin
Scenario: First launch — empty database is created encrypted
  Given the app is installed fresh (no existing database file)
  When the app launches for the first time
  Then the Drift database is opened with a SQLCipher-encrypted executor
  And the encryption key is derived from secure storage (flutter_secure_storage)
  And a random 32-byte key is generated and stored in the secure enclave on first launch
  And all subsequent data writes go to the encrypted database
  And no unencrypted .db file exists on the device

Scenario: Upgrade path — existing unencrypted database is re-keyed
  Given a Sprint 2 build is installed with an existing unencrypted database
  When the user upgrades to the Sprint 3 build and launches the app
  Then the app detects that the database file is unencrypted (PRAGMA key probe)
  And the app uses sqlcipher's re-key mechanism to encrypt the existing data in place
  And the app opens normally after re-keying
  And all previously saved accounts, categories, and transactions are intact

Scenario: App reopens and reads encrypted database successfully
  Given the app has been closed after first launch with encryption active
  When the user reopens the app
  Then the key is retrieved from secure storage
  And the encrypted database is opened successfully
  And all data is readable and correct

Scenario: sqlite3_flutter_libs is removed; sqlcipher_flutter_libs is the only SQLite binary
  Given the pubspec.yaml is updated for Sprint 3
  Then sqlite3_flutter_libs is NOT present as a direct or transitive dependency
  And sqlcipher_flutter_libs is present at the correct version
  And flutter analyze passes with zero warnings
  And all existing unit tests (using in-memory NativeDatabase) continue to pass without modification
```

### Edge Cases
- [ ] Secure storage unavailable (e.g. device has no secure enclave) — fall back to a deterministic key derived from device identifiers; log a warning; do not ship unencrypted
- [ ] Key retrieval fails on app open (e.g. keychain wiped after factory reset on iOS) — show a recovery screen: "Data could not be decrypted. Reset app data?" with explicit user consent
- [ ] Upgrade re-key fails midway (e.g. app is killed during re-key) — detect incomplete re-key on next launch by checking if the DB can be opened unencrypted; retry re-key; if DB is corrupted, present data-loss recovery screen
- [ ] CI environment — tests run against an in-memory NativeDatabase (not cipher); no change to test setup; verified by ADR-004
- [ ] macOS dev build — sqlcipher_flutter_libs must not break macOS sandbox; if it does, macOS target is excluded from native encryption (noted in ADR-004 context)
- [ ] The database key must NOT be stored in SharedPreferences or in the app bundle; only flutter_secure_storage is acceptable
- [ ] Performance — re-key of a large database (10 000+ rows) must complete in under 5 seconds on a mid-range device; show a progress indicator during re-key

### Test Scenarios for QA
1. Fresh install: verify .db file cannot be opened with sqlite3 CLI without the key (binary inspection)
2. Fresh install: all CRUD operations work normally after encryption
3. Upgrade path: install Sprint 2 build, add sample data, upgrade to Sprint 3 build, verify all data intact
4. App restart: data survives close/open cycle
5. Secure storage key: verify key is stored in Keychain (iOS) / Keystore (Android), not in SharedPreferences
6. Performance: re-key of 10 000-row DB completes within acceptable time; progress indicator shown

### UX Spec
N/A — no visible UI change to the user beyond a potential brief "Securing your data..." progress indicator shown during first-launch re-key. Exact copy and animation to be confirmed with ux-designer.

### Estimate
M (2–3 days) — key generation, flutter_secure_storage integration, cipher executor replacement, upgrade detection + re-key migration, CI verification

### Dependencies
- ADR-004 — formal decision to implement in Sprint 3
- Sprint 2 Drift database setup (database.dart with deferred TODO)
- `sqlcipher_flutter_libs` binary already linked in Sprint 2 pubspec.yaml
- `sqlite3_flutter_libs` must be removed from pubspec.yaml (noted in sponsor brief: removed to fix macOS build conflict in Sprint 2; Sprint 3 re-adds sqlcipher_flutter_libs as the sole SQLite provider)
- `flutter_secure_storage` dependency to be added

---

## Dependency Map — Sprint 3

```
US-017 (SQLCipher) ← No story dependency; must ship before or alongside US-010
                       (encrypted DB must be ready before transaction data is written)

US-010 (Add Expense)
  └── US-011 (Add Income)       [shares modal — implement together]
  └── US-012 (Add Transfer)     [extends modal]
  └── US-013 (Edit)             [reuses modal in edit mode]
      └── US-014 (Delete)       [action inside edit modal]

US-015 (Daily View)
  └── Depends on: US-010, US-011, US-012 (data source)

US-016 (Stats Screen)
  └── Depends on: US-010, US-011, US-012 (data source)
  └── Depends on: US-015 (tap-to-filter navigation)
```

**Critical path:** US-017 → US-010/011/012 → US-013/014 → US-015 → US-016
