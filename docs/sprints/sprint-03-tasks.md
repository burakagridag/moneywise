# Sprint 03 — Ordered Implementation Task Breakdown

**Sprint:** 03 — Transaction Management, Statistics & SQLCipher Encryption
**Branch:** `sprint/03-transactions-stats-sqlcipher`
**Engineer start date:** 2026-04-30
**ADRs governing this sprint:** ADR-005 (Transaction Data Model), ADR-006 (SQLCipher Activation)

---

## Conventions

- **Est.** = engineering hours (excludes review and QA time)
- **Deps** = task IDs that must be complete before this task starts
- Files marked `[new]` are created from scratch; `[modify]` are changes to existing files

---

## Phase 0 — SQLCipher (US-017)

Must land before any transaction data is written. All subsequent phases run on the
encrypted database.

---

### T-01: Replace sqlite3_flutter_libs with sqlcipher_flutter_libs

**Est.:** 1 h
**Deps:** none

Files to modify:
- `pubspec.yaml` [modify] — remove `sqlite3_flutter_libs`, add `sqlcipher_flutter_libs: ^0.5.4`, add `flutter_secure_storage: ^9.2.2`

Steps:
1. Remove the `sqlite3_flutter_libs` line.
2. Add `sqlcipher_flutter_libs: ^0.5.4` under `# Local database`.
3. Add `flutter_secure_storage: ^9.2.2` under dependencies.
4. Run `flutter pub get` and verify no duplicate-symbol errors.
5. Run `flutter analyze` — must pass with zero warnings.

Verification: `flutter pub deps | grep sqlite` shows only `sqlcipher_flutter_libs`.

---

### T-02: CipherKeyService — secure key generation and retrieval

**Est.:** 3 h
**Deps:** T-01

Files to create:
- `lib/data/local/cipher_key_service.dart` [new]
- `test/data/local/cipher_key_service_test.dart` [new]

`CipherKeyService` responsibilities:
- `Future<String> getOrCreateHexKey()` — reads from secure storage; generates 32
  random bytes via `Random.secure()` on first call; writes back; returns hex string.
- `FlutterSecureStorage` configured with `AndroidOptions(encryptedSharedPreferences: true)`
  and `IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device)`.
- Fallback if storage throws: derive key via HMAC-SHA256 of `"moneywise" + Platform.operatingSystemVersion`; log warning.

Unit tests (mock `FlutterSecureStorage` via mocktail):
- First call with empty storage generates and stores a key.
- Second call returns the same stored key without regenerating.
- Storage failure triggers fallback and logs a warning.

---

### T-03: CipherMigrationService — detect and re-key existing plaintext DB

**Est.:** 4 h
**Deps:** T-02

Files to create:
- `lib/data/local/cipher_migration_service.dart` [new]
- `test/data/local/cipher_migration_service_test.dart` [new]

`CipherMigrationService` responsibilities:
- `Future<CipherMigrationState> run(File dbFile, String hexKey)` — state machine:
  - `notNeeded`: DB file does not exist (fresh install).
  - `completed`: DB file already encrypted with the stored key (normal subsequent launch).
  - `migrating`: DB is unencrypted; runs `ATTACH` + `sqlcipher_export` + atomic rename; returns `completed`.
  - `failed`: Any error during re-key → returns `failed`; caller shows `DataRecoveryScreen`.
- Detection: open file with raw `sqlite3` (no key), run `SELECT count(*) FROM sqlite_master`.
  Success = plaintext. Failure = already encrypted or corrupted.
- Partial re-key detection: if `moneywise_encrypted.db` exists alongside `moneywise.db`,
  delete the partial file and retry.

Unit tests (real temp files via `NativeDatabase` fixture):
- Fresh file: `notNeeded` returned.
- Plaintext file: migration produces encrypted file readable with the key.
- Pre-existing partial `_encrypted` file: partial file is cleaned up before retry.

---

### T-04: Cipher executor and updated database.dart

**Est.:** 2 h
**Deps:** T-02, T-03

Files to create:
- `lib/data/local/cipher_executor.dart` [new]

Files to modify:
- `lib/data/local/database.dart` [modify]

`cipher_executor.dart`:
- Exports `Future<QueryExecutor> buildCipherExecutor(File dbFile, String hexKey)`.
- Uses `NativeDatabase.createInBackground` with a `setup` callback that runs
  `PRAGMA key = "x'$hexKey'";` before any other statement.
- Key is passed as a hex blob (bypasses PBKDF2; see ADR-006 §3).

`database.dart` changes:
- Remove `// NOTE: SQLCipher encryption is deferred...` comment.
- Replace `_openConnection()` body:
  1. Resolve DB file path (unchanged).
  2. Instantiate `CipherKeyService` and call `getOrCreateHexKey()`.
  3. Instantiate `CipherMigrationService` and call `run(file, hexKey)`.
  4. If result is `failed`, throw `DatabaseEncryptionException` (caller shows recovery screen).
  5. Return `buildCipherExecutor(file, hexKey)`.
- `AppDatabase.forTesting(QueryExecutor e)` constructor remains unchanged.

---

### T-05: DataRecoveryScreen — key loss UX

**Est.:** 2 h
**Deps:** T-04

Files to create:
- `lib/features/onboarding/presentation/screens/data_recovery_screen.dart` [new]
- `lib/l10n/arb/app_en.arb` [modify] — add `dataRecoveryTitle`, `dataRecoveryBody`, `dataRecoveryResetButton`
- `lib/l10n/arb/app_tr.arb` [modify] — Turkish translations

Screen behaviour:
- Displayed when `_openConnection()` throws `DatabaseEncryptionException`.
- Single CTA: "Reset App" (destructive, styled with `AppColors.error`).
- Confirmation dialog before deleting DB file and restarting the app.
- Wired via `go_router` initial route override when the exception is caught at app startup.

---

### Phase 0 build_runner step

After T-04 modifies `database.dart`, run:
```
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

All must pass before Phase 1 begins.

---

## Phase 1 — Transaction Data Layer (US-010, US-011, US-012, US-013, US-014)

---

### T-06: TransactionsTable Drift table definition

**Est.:** 1 h
**Deps:** T-04 (encrypted DB must be in place)

Files to create:
- `lib/data/local/tables/transactions_table.dart` [new]

Implement the `Transactions` class exactly as specified in ADR-005 §1.
All columns, nullable modifiers, and foreign keys match the ADR precisely.

Files to modify:
- `lib/data/local/database.dart` [modify]
  - Add `Transactions` to `@DriftDatabase(tables: [...])`.
  - Increment `schemaVersion` from `2` to `3`.
  - Add `from < 3` block in `onUpgrade`: `m.createTable(transactions)` + four indexes (ADR-005 §1 and §4).

Run code-gen after this task:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### T-07: TransactionDao — CRUD queries

**Est.:** 3 h
**Deps:** T-06

Files to create:
- `lib/data/local/daos/transaction_dao.dart` [new]
- `test/data/local/daos/transaction_dao_test.dart` [new]

`TransactionDao` methods:
- `Stream<List<Transaction>> watchByMonth(int year, int month)` — reactive; filters `is_deleted = 0`, ordered `date DESC`.
- `Stream<List<Transaction>> watchByAccount(String accountId)` — for balance computation stream.
- `Future<Transaction?> getById(String id)`
- `Future<void> insert(TransactionsCompanion t)`
- `Future<void> update(TransactionsCompanion t)` — also updates `updatedAt`.
- `Future<void> softDelete(String id)` — sets `isDeleted = true`, `updatedAt = now()`.
- `Stream<double> watchBalanceForAccount(String accountId)` — executes the double-entry
  SUM query from ADR-005 §3. Joins with `accounts.initial_balance`. Filters
  `is_deleted = 0` and `is_excluded = 0`.
- `Stream<List<CategoryTotal>> watchCategoryTotals(String type, int year, int month)` —
  returns `(categoryId, SUM(amount))` tuples; used by Stats screen.

Unit tests using `NativeDatabase.memory()`:
- Insert income → watchBalanceForAccount emits `initialBalance + amount`.
- Insert expense → emits `initialBalance - amount`.
- Insert transfer → source balance decreases, destination balance increases.
- SoftDelete → transaction excluded from balance stream.
- isExcluded=true → excluded from balance but still visible (list query returns it, balance query excludes it).
- watchByMonth → only returns transactions within the given year/month.

---

### T-08: Transaction domain entity and type enum

**Est.:** 1 h
**Deps:** T-06

Files to create:
- `lib/domain/entities/transaction_entity.dart` [new]
- `lib/domain/enums/transaction_type.dart` [new]

`TransactionType` enum: `income`, `expense`, `transfer`.

`TransactionEntity` is a `freezed` immutable value object mirroring the DB row but
using domain types (e.g. `DateTime`, `double`, `TransactionType`).
This is the type passed between the domain and presentation layers.

Run code-gen after adding freezed annotations:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### T-09: TransactionRepository

**Est.:** 3 h
**Deps:** T-07, T-08

Files to create:
- `lib/data/repositories/transaction_repository.dart` [new]
- `test/data/repositories/transaction_repository_test.dart` [new]

`TransactionRepository` exposes:
- `Stream<List<TransactionEntity>> watchByMonth(int year, int month)`
- `Stream<double> watchAccountBalance(String accountId)`
- `Stream<List<CategoryTotal>> watchCategoryTotals(String type, int year, int month)`
- `Future<void> add(TransactionEntity t)` — validates invariants (amount > 0, toAccountId != accountId for transfer, categoryId present for income/expense).
- `Future<void> update(TransactionEntity t)` — same validation.
- `Future<void> softDelete(String id)`
- `Future<TransactionEntity?> getById(String id)`

Validation errors throw typed exceptions: `InvalidTransactionException(String message)`.

Unit tests using mocktail `MockTransactionDao`:
- `add` with valid expense → dao.insert called once.
- `add` with amount = 0 → throws `InvalidTransactionException`.
- `add` transfer with same accountId and toAccountId → throws.
- `update` → dao.update called with updated fields.
- `softDelete` → dao.softDelete called.

---

### T-10: Add/Edit Transaction use cases

**Est.:** 2 h
**Deps:** T-09

Files to create:
- `lib/domain/usecases/add_transaction_usecase.dart` [new]
- `lib/domain/usecases/update_transaction_usecase.dart` [new]
- `lib/domain/usecases/delete_transaction_usecase.dart` [new]
- `test/domain/usecases/transaction_usecases_test.dart` [new]

Each use case wraps the corresponding `TransactionRepository` method, applies any
additional domain rules not enforced at the repository level, and returns a typed
`Result<void, TransactionError>` (using a simple sealed class — no external result
package needed).

Unit tests (mock repository via mocktail):
- `AddTransactionUseCase` calls `repository.add` on success.
- `AddTransactionUseCase` propagates `InvalidTransactionException` as `TransactionError.invalid`.
- `DeleteTransactionUseCase` calls `repository.softDelete`.

---

## Phase 2 — Add Transaction UI (US-010, US-011, US-012)

---

### T-11: AddTransactionFormState — Riverpod provider

**Est.:** 4 h
**Deps:** T-10

Files to create:
- `lib/features/transactions/presentation/providers/add_transaction_provider.dart` [new]

`AddTransactionFormState` (freezed):
```
transactionType: TransactionType
amount: String  // raw text; parsed on save
selectedCategoryId: String?
selectedAccountId: String?
selectedToAccountId: String?  // transfer only
selectedDate: DateTime
description: String
note: String
isSubmitting: bool
errorMessage: String?
editingId: String?  // non-null when editing
```

Computed getters (in notifier, not widget):
- `bool get canSave` — amount parseable and > 0, categoryId present for income/expense, toAccountId present for transfer, toAccountId != accountId.
- `bool get isEditing` — editingId != null.

Methods on the notifier:
- `void setType(TransactionType)` — clears `selectedCategoryId`.
- `void setAmount(String)`, `void setCategory(String?)`, `void setAccount(String?)`,
  `void setToAccount(String?)`, `void setDate(DateTime)`,
  `void setDescription(String)`, `void setNote(String)`.
- `Future<void> save()` — calls `AddTransactionUseCase` or `UpdateTransactionUseCase`.
- `Future<void> saveAndContinue()` — saves then resets `amount` and `selectedCategoryId`; retains account and date.
- `void loadForEditing(TransactionEntity t)` — pre-fills all fields.

Unit tests using `ProviderContainer` overrides:
- `setType(expense → income)` clears category.
- `canSave` false when amount empty.
- `canSave` false when category missing for expense.
- `save()` succeeds → `isSubmitting` resets to false.
- `saveAndContinue()` resets amount and category, retains account.

---

### T-12: AddTransactionScreen — shell and type toggle

**Est.:** 3 h
**Deps:** T-11

Files to create:
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` [new]

Structure:
- Full-screen modal (presented via `go_router` with `fullscreenDialog: true`).
- AppBar: back/close icon left; "Expense" / "Income" / "Transfer" type toggle centre (3-segment control using `AppColors.bgTertiary` inactive, `AppColors.brandPrimary` active).
- Form body (scrollable): fields wired to `AddTransactionFormNotifier`.
- Footer: "Continue" button (secondary style) left, "Save" button (primary style) right.
  Both disabled when `!canSave`, shown at 50% opacity.
- `mounted` check after every async call.
- No `setState()` — all state via the provider.

Widget tests:
- Save button disabled when amount is empty.
- Switching type from expense to income clears category display.

---

### T-13: AmountInputField widget

**Est.:** 2 h
**Deps:** T-12

Files to create:
- `lib/features/transactions/presentation/widgets/amount_input_field.dart` [new]

Behaviour:
- Numeric keyboard with decimal.
- Strips leading zeros, rejects negative sign.
- Maximum 2 decimal places enforced on input (not only on save).
- Large typography (`AppTypography.moneyLarge`), right-aligned, coral for expense / blue for income / white for transfer.
- Placeholder: "0.00".

Widget tests:
- Entering "33.333" displays "33.33".
- Negative sign stripped.
- "0" alone shows "0.00" on focus loss.

---

### T-14: CategoryPickerModal

**Est.:** 2 h
**Deps:** T-12

Files to create:
- `lib/features/transactions/presentation/widgets/category_picker_modal.dart` [new]

Behaviour:
- Bottom sheet, full height.
- Filtered by current `transactionType` (income vs expense categories).
- Shows parent categories; tapping one that has subcategories expands inline.
- Selecting a (sub)category calls `notifier.setCategory(id)` and closes.
- Empty state if no categories exist for the type: "No categories. Create one in More > Categories."
- Transfer type: category picker is hidden entirely (field row not rendered).

Widget tests:
- Income type: only income categories displayed.
- Expense type: only expense categories displayed.
- Selection calls provider method.

---

### T-15: AccountPickerModal

**Est.:** 2 h
**Deps:** T-12

Files to create:
- `lib/features/transactions/presentation/widgets/account_picker_modal.dart` [new]

Behaviour:
- Bottom sheet; lists all non-deleted accounts with group headers.
- For the "To Account" picker in transfer mode: the currently selected source account
  is disabled (greyed out, not tappable).
- Empty state: "No accounts. Create one in Accounts tab."

---

### T-16: DatePickerField and Cupertino date picker

**Est.:** 1 h
**Deps:** T-12

Files to create:
- `lib/features/transactions/presentation/widgets/date_picker_field.dart` [new]

Behaviour:
- Tapping opens `CupertinoDatePicker` in a bottom sheet modal.
- Displayed value: "Wed 15.4.2026" format.
- Future dates show a "Future date" label in `AppColors.warning`.
- Confirms selection via "Done" button; dismiss without confirming does not change state.

---

### T-17: Wire Add Transaction modal to go_router

**Est.:** 1 h
**Deps:** T-12

Files to modify:
- `lib/core/router/app_router.dart` [modify] — add `/add-transaction` route as
  `fullscreenDialog`, accepting optional `transactionId` query param (for edit mode).
- FAB in the existing scaffold (or `TransactionsScreen`) is wired to `context.push('/add-transaction')`.

---

### T-18: Edit mode — pre-fill from existing transaction (US-013)

**Est.:** 2 h
**Deps:** T-17

Files to modify:
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` [modify]
  — detect `transactionId` param, call `transactionRepository.getById`, call
  `notifier.loadForEditing(entity)` in `initState` equivalent (using `ref.listen` or
  a `useEffect`-style `ref.read` in `ConsumerStatefulWidget.initState`).
- `lib/features/transactions/presentation/providers/add_transaction_provider.dart` [modify]
  — `loadForEditing` method already defined in T-11.

AppBar title changes to "Edit" when `isEditing == true`.

---

### T-19: Delete transaction action (US-014)

**Est.:** 1 h
**Deps:** T-18

Files to modify:
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` [modify]
  — add trash icon to AppBar (visible only when `isEditing`).
  — show `AlertDialog` on tap; on confirm, call `DeleteTransactionUseCase` and pop modal.

ARB keys: `deleteTransactionConfirmTitle`, `deleteTransactionConfirmBody`,
`deleteTransactionConfirmButton`, `deleteTransactionCancelButton`.

---

### Phase 2 build_runner step

After T-11 (freezed state), run:
```
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

---

## Phase 3 — Trans. Tab Daily View (US-015)

---

### T-20: TransactionsByMonthProvider and daily-grouping logic

**Est.:** 3 h
**Deps:** T-09

Files to create:
- `lib/features/transactions/presentation/providers/transactions_by_month_provider.dart` [new]
- `lib/features/transactions/domain/daily_group.dart` [new]

`TransactionsByMonthProvider`:
- State: `AsyncValue<List<DailyGroup>>`.
- Input: `(int year, int month)` — implemented as a family provider.
- Consumes `TransactionRepository.watchByMonth` stream.
- Maps flat list → `List<DailyGroup>` sorted by day descending.

`DailyGroup`:
- `DateTime date`
- `List<TransactionEntity> transactions`
- `double dayIncomeTotal`
- `double dayExpenseTotal`

Computed `MonthSummary` (separate provider or derived):
- `monthIncomeTotal`, `monthExpenseTotal`, `monthTotal = income - expense`.
- Excludes `isExcluded = true` transactions from totals.
- Includes `isExcluded = true` rows in the list (displayed with muted style).

Unit tests (`ProviderContainer`):
- Empty month → empty list.
- Mixed income + expense → correct daily totals and month totals.
- isExcluded transaction → in list, excluded from totals.

---

### T-21: MonthNavigatorWidget

**Est.:** 1 h
**Deps:** T-20

Files to create:
- `lib/core/widgets/month_navigator.dart` [new]

Reusable widget displaying `< Apr 2026 >` with left/right tap callbacks.
Used in both Trans. tab and Stats screen.

---

### T-22: MonthlySummaryBar widget

**Est.:** 1 h
**Deps:** T-20

Files to create:
- `lib/features/transactions/presentation/widgets/monthly_summary_bar.dart` [new]

Displays `Income` (blue), `Exp.` (coral), `Total` (white ± sign) from `MonthSummary`.
Fixed at top of the `TransactionsScreen` below the month navigator.

---

### T-23: DailyGroupHeader widget

**Est.:** 1 h
**Deps:** T-20

Files to create:
- `lib/features/transactions/presentation/widgets/daily_group_header.dart` [new]

Displays day number, day-of-week label (red for Sunday, blue for Saturday, white otherwise),
day income total (blue), day expense total (coral). Matches SPEC §9.1.5 layout.

---

### T-24: TransactionListTile widget

**Est.:** 2 h
**Deps:** T-23

Files to create:
- `lib/features/transactions/presentation/widgets/transaction_list_tile.dart` [new]

Displays: category emoji + category name | account name | amount (blue income / coral expense / white transfer).
56px height per `AppHeights.listItem`. Tapping navigates to edit modal.
`isExcluded` transactions: muted text colour, strikethrough on amount.

---

### T-25: TransactionsScreen — Daily view wired with real data

**Est.:** 3 h
**Deps:** T-21, T-22, T-23, T-24

Files to modify:
- Existing `lib/features/transactions/presentation/screens/transactions_screen.dart` [modify]
  — replace placeholder body with a `SliverList` of `DailyGroupHeader` + `TransactionListTile` rows.
  — connect `MonthNavigatorWidget` and `MonthlySummaryBar`.
  — empty state: "No transactions for this period" centred in the list area.
  — 5 sub-tabs scaffolded (Daily active; Calendar, Monthly, Summary, Description as `Center(child: Text('Coming soon'))` placeholders).

Performance: use `CustomScrollView` + `SliverList`. Each day group renders its
header as a `SliverPersistentHeader` (sticky) and its rows as sliver items.

---

## Phase 4 — Statistics Screen (US-016)

---

### T-26: CategoryTotalsProvider

**Est.:** 2 h
**Deps:** T-09

Files to create:
- `lib/features/statistics/presentation/providers/category_totals_provider.dart` [new]

Family provider inputs: `(String type, int year, int month)`.
Consumes `TransactionRepository.watchCategoryTotals`.
Maps to `List<CategoryTotalEntity>` sorted by amount descending.
Assigns segment colors cycling through the brand palette (8 distinct colors from `AppColors`).
Categories with < 3% share grouped into an "Other" bucket when there are > 8 categories
(design decision confirmed in ADR-005; threshold value extracted to a constant
`kPieMinSegmentPercent = 0.03` in `lib/core/constants/stats_constants.dart`).

---

### T-27: DonutPieChart widget

**Est.:** 3 h
**Deps:** T-26

Files to create:
- `lib/features/statistics/presentation/widgets/donut_pie_chart.dart` [new]

Wraps `fl_chart PieChart` with:
- Donut style (hole radius 0.5).
- Segment percentage labels drawn outside via `PieTouchData`.
- Tap callback returns `categoryId` to the caller.
- Empty state: grey full-circle placeholder ring when list is empty.
- Long category names (> 20 chars) truncated with ellipsis in the label.

Widget tests:
- Single category → full ring (one section, 100%).
- Tap section → correct categoryId returned via callback.
- Empty list → placeholder ring rendered, no exception.

---

### T-28: CategoryRankedList widget

**Est.:** 1 h
**Deps:** T-26

Files to create:
- `lib/features/statistics/presentation/widgets/category_ranked_list.dart` [new]

Ranked list of `CategoryTotalEntity`, each row: colour badge + name + amount (right-aligned).
Colour badge matches the pie segment colour assigned in `CategoryTotalsProvider`.
Empty state: "No data for this period".

---

### T-29: StatsScreen — wired with real data

**Est.:** 3 h
**Deps:** T-27, T-28, T-21

Files to modify:
- Existing `lib/features/statistics/presentation/screens/stats_screen.dart` [modify]
  — replace placeholder with `DonutPieChart` + `CategoryRankedList`.
  — `MonthNavigatorWidget` (reused from T-21).
  — Income/Expense toggle (2-segment control).
  — Month summary totals (income total / expense total) shown above chart.
  — Tap on pie segment: `context.push('/transactions?filter=category:<id>&month=<year-month>')`.
  — Stats, Budget, Note sub-tabs scaffolded (Stats active; Budget and Note as `Coming soon` placeholders).

---

### T-30: Segment-tap navigation — filtered transaction list

**Est.:** 2 h
**Deps:** T-29, T-25

Files to modify:
- `lib/core/router/app_router.dart` [modify] — add `/transactions` query param handling for `filter=category:<id>` and `month=<YYYY-MM>`.
- `lib/features/transactions/presentation/providers/transactions_by_month_provider.dart` [modify]
  — add optional `categoryId` filter parameter to the family.
- `lib/features/transactions/presentation/screens/transactions_screen.dart` [modify]
  — read optional `categoryId` filter from route params; pass to provider.

---

## Phase 5 — Cross-Cutting: i18n, Tests, Cleanup

---

### T-31: ARB localisation keys for all Sprint 3 strings

**Est.:** 2 h
**Deps:** T-12, T-19, T-25, T-29 (all UI strings must be finalised)

Files to modify:
- `lib/l10n/arb/app_en.arb` [modify]
- `lib/l10n/arb/app_tr.arb` [modify]

Keys to add (English baseline; Turkish translations for all):
```
addTransactionTitle, editTransactionTitle,
incomeLabel, expenseLabel, transferLabel,
amountLabel, categoryLabel, accountLabel,
toAccountLabel, dateLabel, descriptionLabel, noteLabel,
saveButton, continueButton,
deleteTransactionConfirmTitle, deleteTransactionConfirmBody,
deleteTransactionConfirmButton, deleteTransactionCancelButton,
noAccountsEmptyState, noCategoriesEmptyState,
futureDateLabel, amountMustBePositive,
noTransactionsEmptyState, statsScreenTitle,
noStatsDataEmptyState, incomeTotalLabel, expenseTotalLabel, totalLabel,
dataRecoveryTitle, dataRecoveryBody, dataRecoveryResetButton,
securingDataMessage
```

Run `flutter gen-l10n` (or `flutter pub get` with `generate: true`) after editing.

---

### T-32: Widget tests for Trans. tab Daily view

**Est.:** 2 h
**Deps:** T-25

Files to create:
- `test/features/transactions/presentation/screens/transactions_screen_test.dart` [new]

Tests:
- Empty month → empty state widget visible.
- Two transactions on different days → two day group headers rendered.
- Month navigator left tap → previous month loaded (provider family re-evaluated).
- Summary bar shows correct income/expense totals.

---

### T-33: Widget tests for Stats screen

**Est.:** 2 h
**Deps:** T-29

Files to create:
- `test/features/statistics/presentation/screens/stats_screen_test.dart` [new]

Tests:
- Empty month → placeholder ring and "No data" text visible.
- Three categories → three pie sections rendered.
- Switching Income/Expense toggle → provider re-queried with different type.

---

### T-34: Final quality gate

**Est.:** 1 h
**Deps:** all tasks above

Commands (must all pass):
```
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

Fix any remaining lints, formatting issues, or test failures before handing off
to code-reviewer.

---

## Summary Table

| ID | Title | Phase | Est. (h) | Deps | US |
|----|-------|-------|----------|------|----|
| T-01 | Replace sqlite3 with sqlcipher in pubspec | 0 | 1 | — | US-017 |
| T-02 | CipherKeyService | 0 | 3 | T-01 | US-017 |
| T-03 | CipherMigrationService | 0 | 4 | T-02 | US-017 |
| T-04 | Cipher executor + database.dart update | 0 | 2 | T-02, T-03 | US-017 |
| T-05 | DataRecoveryScreen | 0 | 2 | T-04 | US-017 |
| T-06 | TransactionsTable + schema migration v3 | 1 | 1 | T-04 | US-010 |
| T-07 | TransactionDao | 1 | 3 | T-06 | US-010 |
| T-08 | Transaction entity + TransactionType enum | 1 | 1 | T-06 | US-010 |
| T-09 | TransactionRepository | 1 | 3 | T-07, T-08 | US-010 |
| T-10 | Add/Update/Delete use cases | 1 | 2 | T-09 | US-010, US-013, US-014 |
| T-11 | AddTransactionFormState provider | 2 | 4 | T-10 | US-010, US-011, US-012 |
| T-12 | AddTransactionScreen shell + type toggle | 2 | 3 | T-11 | US-010, US-011, US-012 |
| T-13 | AmountInputField widget | 2 | 2 | T-12 | US-010 |
| T-14 | CategoryPickerModal | 2 | 2 | T-12 | US-010, US-011 |
| T-15 | AccountPickerModal | 2 | 2 | T-12 | US-010, US-011, US-012 |
| T-16 | DatePickerField | 2 | 1 | T-12 | US-010 |
| T-17 | Wire modal to go_router + FAB | 2 | 1 | T-12 | US-010 |
| T-18 | Edit mode pre-fill | 2 | 2 | T-17 | US-013 |
| T-19 | Delete action in edit modal | 2 | 1 | T-18 | US-014 |
| T-20 | TransactionsByMonthProvider + DailyGroup | 3 | 3 | T-09 | US-015 |
| T-21 | MonthNavigatorWidget (shared) | 3 | 1 | T-20 | US-015, US-016 |
| T-22 | MonthlySummaryBar | 3 | 1 | T-20 | US-015 |
| T-23 | DailyGroupHeader widget | 3 | 1 | T-20 | US-015 |
| T-24 | TransactionListTile widget | 3 | 2 | T-23 | US-015 |
| T-25 | TransactionsScreen — Daily view wired | 3 | 3 | T-21–T-24 | US-015 |
| T-26 | CategoryTotalsProvider | 4 | 2 | T-09 | US-016 |
| T-27 | DonutPieChart widget | 4 | 3 | T-26 | US-016 |
| T-28 | CategoryRankedList widget | 4 | 1 | T-26 | US-016 |
| T-29 | StatsScreen — wired with real data | 4 | 3 | T-27, T-28, T-21 | US-016 |
| T-30 | Segment-tap navigation | 4 | 2 | T-29, T-25 | US-016 |
| T-31 | ARB i18n keys for all Sprint 3 strings | 5 | 2 | T-12, T-19, T-25, T-29 | all |
| T-32 | Widget tests — TransactionsScreen | 5 | 2 | T-25 | US-015 |
| T-33 | Widget tests — StatsScreen | 5 | 2 | T-29 | US-016 |
| T-34 | Final quality gate | 5 | 1 | all | all |

**Total estimated hours: ~61 h (approx. 10–12 engineering days at 5–6 focused hours/day)**

---

## build_runner Checkpoint Schedule

Run after each of these tasks to keep generated code in sync:

| After task | Why |
|-----------|-----|
| T-04 | database.dart `@riverpod` annotation updated |
| T-06 | TransactionsTable added to `@DriftDatabase` |
| T-08 | `@freezed` TransactionEntity added |
| T-11 | `@freezed` AddTransactionFormState added; `@riverpod` notifier added |
| T-20 | New `@riverpod` family provider |
| T-26 | New `@riverpod` family provider |

Command (each checkpoint):
```
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
```
