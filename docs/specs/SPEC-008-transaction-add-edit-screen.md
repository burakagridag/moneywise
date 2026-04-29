# SPEC-008: Transaction Add / Edit Screen

**Related:** US-010, US-011, US-012, US-013, US-014
**Reference:** SPEC.md Section 9.2 (Ekran 1), Section 6.4 (transactions table)
**Route:** `/transactions/add` (add mode) | `/transactions/edit/:id` (edit mode)
**Component:** `lib/features/transactions/presentation/screens/add_transaction_screen.dart`

---

## Purpose

A full-screen modal (slide-up on iOS, full-screen on Android) for creating a new transaction or editing an existing one. Supports three transaction types — Expense, Income, Transfer — via a type toggle at the top. Edit mode pre-fills all fields and provides a delete action. The screen must be completable in three taps or fewer for a standard expense entry.

---

## Mode Differentiation

| Attribute | Add Mode | Edit Mode |
|---|---|---|
| Route | `/transactions/add` | `/transactions/edit/:id` |
| AppBar center title | Selected type ("Expense" / "Income" / "Transfer") | Selected type (same, reflects actual type) |
| AppBar right action | Bookmark icon (star) | Bookmark icon (star) + Trash icon |
| Type toggle | All three tabs enabled | All three tabs enabled (type can be changed) |
| Initial field values | Defaults (see States section) | Pre-populated from existing transaction record |
| Save action outcome | Creates new transaction, pops modal | Updates transaction + recalculates balances, pops modal |
| Continue button | Visible | Hidden (not applicable in edit mode) |

---

## Layout

```
┌─────────────────────────────────────────────────┐
│  < Trans.         Expense           ⭐  [🗑 edit]│  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│  ┌───────────┐ ┌──────────────┐ ┌───────────┐  │
│  │  Income   │ │   Expense    │ │ Transfer  │  │  ← Type toggle 44dp
│  └───────────┘ └──────────────┘ └───────────┘  │
├─────────────────────────────────────────────────┤
│  Date     Tue 28.4.2026          [↻ Rep/Inst]   │  ← 56dp row
│  ─────────────────────────────────────────────  │
│  Amount   € ____________                        │  ← 56dp row
│  ─────────────────────────────────────────────  │
│  Category ____________________________          │  ← 56dp row (hidden for Transfer)
│  ─────────────────────────────────────────────  │
│  Account  Debit Card  (€ 974.50)                │  ← 56dp row
│  ─────────────────────────────────────────────  │
│  To Acct  ____________________________          │  ← 56dp row (Transfer only)
│  ─────────────────────────────────────────────  │
│  Note     ____________________________          │  ← 56dp row
├─────────────────────────────────────────────────┤
│  Description                        [📷]        │  ← multi-line, min 80dp
│  ______________________________________         │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────┐ ┌──────────────────┐  │
│  │        Save          │ │    Continue      │  │  ← 52dp, add mode only
│  └──────────────────────┘ └──────────────────┘  │
│  ┌────────────────────────────────────────────┐ │
│  │              Save (edit mode)              │ │  ← 52dp, edit mode only (full width)
│  └────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│  [Banner Ad — free tier only, 50dp]             │
└─────────────────────────────────────────────────┘
```

The entire form area scrolls vertically when the keyboard is active. Button row and banner ad pin to the bottom (outside the scroll area), using `SafeArea` bottom padding.

---

## Tokens

| Element | Token | Value |
|---|---|---|
| Screen background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar height | `AppHeights.appBar` | 44dp |
| AppBar back label text | `AppTypography.body` + `AppColors.brandPrimary` | 17/400 |
| AppBar center title | `AppTypography.headline` + `AppColors.textPrimary` | 17/600 |
| AppBar icon (bookmark, trash) | Phosphor icon, 22dp, `AppColors.textSecondary` | — |
| Type toggle row height | 44dp | — |
| Type toggle horizontal padding | `AppSpacing.lg` each side | 16dp |
| Type toggle gap between buttons | `AppSpacing.sm` | 8dp |
| Type toggle active: border | `AppColors.brandPrimary`, 2dp | — |
| Type toggle active: text | `AppTypography.bodyMedium` + `AppColors.brandPrimary` | 16/500 |
| Type toggle inactive: border | `AppColors.border`, 1dp | — |
| Type toggle inactive: text | `AppTypography.bodyMedium` + `AppColors.textSecondary` | 16/500 |
| Type toggle button radius | `AppRadius.sm` | 6dp |
| Type toggle background | `AppColors.bgSecondary` | #24252A |
| Form section background | `AppColors.bgSecondary` | #24252A |
| Form section radius | `AppRadius.md` | 10dp |
| Form section horizontal margin | `AppSpacing.lg` | 16dp |
| Form row height | `AppHeights.listItem` | 56dp |
| Form row label | `AppTypography.body` + `AppColors.textSecondary` | 17/400 |
| Form row label min width | 100dp | alignment |
| Form row value | `AppTypography.body` + `AppColors.textPrimary` | 17/400 |
| Form row empty placeholder | `AppTypography.body` + `AppColors.textTertiary` | 17/400 |
| Form row divider | `AppColors.divider`, 1dp, inset 16dp left | — |
| Amount input text | `AppTypography.moneyMedium` + `AppColors.textPrimary` | 17/600 |
| Amount currency symbol | `AppTypography.body` + `AppColors.textSecondary` | 17/400, left of input |
| Account balance sub-label | `AppTypography.caption1` + `AppColors.textTertiary` | 12/400, right-aligned |
| Note field | `AppTypography.body` + `AppColors.textPrimary` | 17/400 |
| Description area background | `AppColors.bgSecondary` | #24252A |
| Description area top divider | `AppColors.divider`, 1dp full-width | — |
| Description placeholder | `AppTypography.body` + `AppColors.textTertiary` | 17/400 |
| Description camera icon | Phosphor `Camera`, 22dp, `AppColors.textSecondary` | — |
| Rep/Inst icon | Phosphor `ArrowsClockwise`, 20dp, `AppColors.textSecondary` | top-right of Date row |
| Save button style | `AppButton` primary, `AppColors.brandPrimary` fill, white text | 52dp, `AppRadius.md` |
| Continue button style | `AppButton` secondary, `AppColors.brandPrimary` outline, brand text | 52dp, `AppRadius.md` |
| Save:Continue flex ratio | 3:2 | — |
| Disabled button opacity | 0.5 | — |
| Button row padding | `AppSpacing.lg` horizontal, `AppSpacing.md` top, `AppSpacing.lg` bottom | — |
| Banner ad height | `AppHeights.bannerAd` | 50dp |
| Input focus underline | `AppColors.brandPrimary`, 2dp | — |
| Input unfocused underline | none (row already has a divider) | — |
| Input cursor | `AppColors.brandPrimary` | — |
| Validation error text | `AppTypography.caption1` + `AppColors.error` | 12/400 |

---

## Type Toggle Behavior

Three equal-width buttons in a horizontal row: **Income**, **Expense**, **Transfer**.

- Default selection on open (add mode): Expense (or last-used type if settings track it).
- Tapping a different type:
  - AppBar title updates to the newly selected type name.
  - Category field: resets to empty and re-filters picker to match the new type. Amount, Account, Date, Note, Description values are retained.
  - Transfer type: Category row animates out (250ms, animated size). "To Account" row animates in.
  - Income / Expense type: "To Account" row animates out. Category row animates in.
- Animation: 150ms color fade on the active border and text.

---

## Form Fields

### Date Row

- Label: "Date"
- Displayed value: weekday abbreviation + day.month.year, e.g. "Tue 28.4.2026".
- If date is in the future: append a small "Future" label badge (`AppColors.warning`, `AppTypography.caption2`) immediately after the date value.
- Right side: Repeat/Installment icon button (Phosphor `ArrowsClockwise`, 20dp). Tap: opens the RepeatInstallmentSheet (Phase 2; in Sprint 3 this can be a "Coming soon" toast).
- Tap on the row (excluding the icon): opens a Cupertino-style date picker in a bottom sheet (see Date Picker section below).

### Amount Row

- Label: "Amount"
- Left prefix inside field area: currency symbol (e.g. "€"). Symbol color: `AppColors.textSecondary`.
- Input: numeric, decimal-safe, tabular figures. Keyboard: number pad with decimal separator. No negative sign accepted; strip any leading minus.
- Decimal precision: maximum 2 decimal places enforced on input (additional digits ignored).
- Large amount display: uses tabular figures and never truncates. Horizontal scroll within field if overflow.
- When focus is active: AppBar right zone adds a calculator icon (Phosphor `Calculator`, 22dp) — tapping it opens an inline calculator sheet (Phase 2; in Sprint 3 this icon may be suppressed or show a "Coming soon" toast).
- Validation: amount must be > 0 to enable Save/Continue.

### Category Row (Expense and Income only)

- Label: "Category"
- Displayed value (empty): no placeholder text — the field appears blank with the empty placeholder color.
- Displayed value (selected): emoji + category name.
- Tap: opens `CategoryPickerSheet` (see below), filtered to income or expense categories matching the current type.
- When switching types, this field resets silently (no animation on the value, only the category picker filter changes).
- Validation: must be selected to enable Save/Continue.

### Account Row

- Label: "Account" (for Expense / Income) or "From" (for Transfer).
- Displayed value: account name. Right of account name, in smaller text: current computed balance in parentheses, e.g. "(€ 974.50)". Balance is formatted with `AppTypography.caption1` + `AppColors.textTertiary`.
- Default: last-used account (read from settings), or first account alphabetically if no last-used.
- Tap: opens `AccountPickerSheet`.
- Validation: must have at least one account selected to enable Save/Continue.

### To Account Row (Transfer only)

- Label: "To"
- Displayed value (empty): blank (placeholder color).
- Displayed value (selected): account name + balance (same format as Account row).
- Tap: opens `AccountPickerSheet` with the source account disabled/grayed out to prevent self-transfer.
- Validation: must be selected (and different from source) to enable Save/Continue.

### Note Row

- Label: "Note"
- Single-line text input, no placeholder text.
- Max length: 500 characters.
- When character count ≥ 450, a counter appears right-aligned below the row: "[n]/500" in `AppTypography.caption2` + `AppColors.textSecondary`.
- Right of field: Phosphor `Warning` icon (18dp, `AppColors.textTertiary`), visible only when autocomplete is enabled in Settings (indicates autocomplete is active).
- Optional. Does not block Save.

### Description Area

- Separated from the form card by a full-width 1dp divider (`AppColors.divider`).
- Background: `AppColors.bgSecondary`, flush to screen edges (no horizontal margin).
- Multi-line text input. Min height 80dp, expands with content.
- Placeholder: "Description" (`AppColors.textTertiary`).
- Max length: 2000 characters. Counter appears at 1800+: "[n]/2000" `AppTypography.caption2`.
- Right side: Phosphor `Camera` icon (22dp, `AppColors.textSecondary`). Tap: requests camera/gallery permission, then opens system image picker. Multiple photos supported. Thumbnails appear in a horizontal row below the description field (48dp height, 48dp wide each, `AppRadius.sm` corners).
- Optional. Does not block Save.

---

## Date Picker Sheet

Slide-up bottom sheet (`AppBottomSheet`). Header: "Select Date".

```
┌─────────────────────────────────────────────────┐
│           Select Date          [Done]            │  ← 56dp header
│  ─────────────────────────────────────────────  │
│                                                  │
│       [Day drum]  [Month drum]  [Year drum]      │  ← Cupertino CupertinoPicker style
│                                                  │
└─────────────────────────────────────────────────┘
```

- Cupertino-style drum-roll: day (1–31), month name (Jan–Dec), year (2000–2099).
- Defaults to the current Date field value when opened.
- "Done" button: confirms selection, closes sheet, updates Date row.
- Tap outside sheet or swipe down: dismisses without change.
- Invalid dates (e.g. Feb 30) are silently adjusted to the last valid day of the selected month.

---

## Category Picker Sheet

Slide-up bottom sheet, `AppBottomSheet`. Title: "Category".

```
┌─────────────────────────────────────────────────┐
│                  Category                        │  ← 56dp header
│  ─────────────────────────────────────────────  │
│  🍜  Food                                   >   │  ← 56dp row, tappable
│  👫  Social Life                            >   │
│  🐶  Pets                                   >   │
│  🚕  Transport                              >   │
│  ...                                            │
│  ─────────────────────────────────────────────  │
│  [Cancel]                                        │
└─────────────────────────────────────────────────┘
```

- Lists only categories matching the current transaction type (income or expense). Transfer does not show this sheet.
- Rows: emoji + category name, 56dp height.
- If a category has sub-categories: tapping the row reveals a sub-list inline (expand-in-place) or navigates to a sub-sheet. For Sprint 3: sub-categories are single-level; a chevron `>` indicates sub-categories are available.
- Tapping a leaf category: selects it, dismisses the sheet.
- Empty state (no categories for type): shows `EmptyStateView` with title "No categories" and a CTA "Add Category" that navigates to `CategoryManagementScreen`.
- "Cancel" ghost button at the bottom.

---

## Account Picker Sheet

Slide-up bottom sheet, `AppBottomSheet`. Title: "Account" or "To Account".

```
┌─────────────────────────────────────────────────┐
│                   Account                        │  ← 56dp header
│  ─────────────────────────────────────────────  │
│  [●] Debit Card                      € 974.50   │  ← selected: brandPrimary dot
│      Bank Account                    € 2,000.00  │
│      Cash                            € 150.00   │
│      Savings                         € 800.00   │
│  ─────────────────────────────────────────────  │
│  [Cancel]                                        │
└─────────────────────────────────────────────────┘
```

- Each row: account name left, computed balance right (`AppColors.textPrimary` if positive, `AppColors.expense` if negative).
- When opened as "To Account" picker: source account row is grayed out (`AppColors.textTertiary` name, `AppColors.textTertiary` balance) and not tappable.
- Selected account row: `AppColors.bgTertiary` background + `AppColors.brandPrimary` dot (10dp) right of name.
- Empty state (no accounts): `EmptyStateView` with title "No accounts yet" and CTA "Add Account" navigating to `AccountAddEditScreen`. Save button on main form is disabled in this state.
- "Cancel" ghost button at the bottom.

---

## Validation Rules

| Condition | Save | Continue |
|---|---|---|
| Amount empty or zero | Disabled (0.5 opacity) | Disabled |
| Category empty (Expense or Income) | Disabled | Disabled |
| Account (from) empty | Disabled | Disabled |
| To Account empty (Transfer) | Disabled | Disabled |
| To Account = From Account (Transfer) | Disabled | Disabled |
| No accounts exist in DB | Disabled; inline note shown | Disabled |
| Amount negative (user bypasses strip) | Strip sign; treat as positive | — |
| Amount > 0, all required fields filled | Enabled | Enabled |

Validation is evaluated reactively on every field change. No toast or error message for disabled state — the button appearance (opacity 0.5) communicates it. Inline error messages only appear for fields that fail after a Save attempt:
- Amount = 0 after tap: inline caption "Amount must be greater than zero" below Amount row.
- No category after tap: field row shows a red left border strip (4dp) momentarily (300ms, then fades).

---

## No-Accounts Inline Empty State

When no accounts exist in the database, the Account row is replaced by an inline message instead of a picker:

```
│  Account   Please create an account first.  [Add >] │
```

- "Please create an account first." in `AppTypography.subhead` + `AppColors.textSecondary`.
- "[Add >]" is an inline ghost button in `AppColors.brandPrimary`, `AppTypography.subhead`.
- Tap "[Add >]": navigates to `AccountAddEditScreen`. When user returns, the picker reflects the newly created account.
- Save and Continue remain disabled.

---

## States

### Default (Add Mode)
- Type: Expense selected.
- Date: today, formatted as "Weekday DD.M.YYYY".
- Amount: empty.
- Category: empty.
- Account: last-used account (or first account in DB).
- To Account: empty (not visible).
- Note: empty.
- Description: empty.
- Save: disabled (0.5 opacity).
- Continue: disabled (0.5 opacity).

### Default (Edit Mode)
- All fields pre-populated from the existing transaction.
- Type toggle reflects the actual transaction type.
- Category and Account show their current values.
- "Continue" button is hidden.
- Delete icon visible in AppBar.
- Save: enabled if any field has been modified.

### Loading (Submitting)
- Tap Save or Continue: both buttons become non-interactive. Save button replaces its label with a 16dp `LoadingIndicator` (white, spinning). All form fields become non-interactive.
- On success (Save): modal pops with slide-down animation. Parent screen (Daily view or Accounts) reactively updates.
- On success (Continue): spinner clears, Amount and Category fields reset to empty. Account, Date, Note retain their values. Modal stays open. Focus returns to Amount field.
- On error: buttons restore to interactive state. Snackbar appears at the bottom: "[Error message]. Try again." with a "Retry" action. Form remains populated.

### Error (Submission Failure)
- Snackbar: background `AppColors.bgTertiary`, text `AppColors.textPrimary`, action label `AppColors.brandPrimary`.
- Form re-enabled. All previously entered values preserved.

### Dirty State (Form Modified)
- If user attempts to dismiss the modal (swipe down or tap back) while any field has changed from its initial value, present a discard confirmation:
  - Title: "Discard changes?"
  - Body: "Your changes will not be saved."
  - Actions: "Keep editing" (default), "Discard" (destructive, `AppColors.error` text).

---

## Delete Transaction (Edit Mode Only)

Trash icon (Phosphor `Trash`, 22dp) appears in the AppBar right zone, to the left of the bookmark icon.

- Tap trash: shows a confirmation alert dialog (system alert, not a custom sheet).
  - Title: "Delete this transaction?"
  - Body: "This cannot be undone."
  - Actions: "Cancel" (default, `AppColors.textPrimary`) and "Delete" (`AppColors.error`).
- Confirm "Delete": soft-deletes the transaction (`isDeleted = true`). Balance of affected account(s) is recalculated via the reactive stream. Modal pops with slide-down animation.
- Cancel: dialog closes, edit modal remains open unchanged.

---

## Continue Button Behavior

Applicable only in Add mode.

After a successful save:
1. The saved transaction is written to the database.
2. Amount field resets to empty.
3. Category field resets to empty.
4. Account field, Date field, Note field, and Description field retain their values.
5. Focus is placed back on the Amount field automatically (keyboard appears).
6. A brief success confirmation is shown: a single green checkmark icon (Phosphor `CheckCircle`, 20dp, `AppColors.success`) fades in and out (300ms fade in, holds 600ms, 300ms fade out) in the top-right of the form area.

---

## User Flows

### Add Expense (Happy Path)

```
User on any tab
  → Tap FAB (+)
  → Modal slides up
  → Type toggle: Expense (default)
  → Tap Amount field → enter "25.50"
  → Tap Category row → CategoryPickerSheet opens
    → Tap "Food" → sheet dismisses, Category shows "🍜 Food"
  → Save becomes enabled
  → Tap Save
    → Save button shows spinner
    → DB write succeeds
    → Modal slides down
    → Daily view shows new transaction
    → Debit Card balance updates
```

### Add Transfer

```
User opens modal
  → Tap "Transfer" toggle
    → Category row animates out
    → "To Account" row animates in
    → AppBar title changes to "Transfer"
  → Tap Amount → enter "300"
  → Tap Account (From) row → AccountPickerSheet
    → Select "Bank Account"
  → Tap To Account row → AccountPickerSheet
    → "Bank Account" is grayed out
    → Select "Savings"
  → Save becomes enabled
  → Tap Save → modal closes, both balances update
```

### Edit Transaction

```
User on Daily view
  → Tap transaction row
  → Edit modal opens pre-filled
  → User changes Amount from 25.50 to 30.00
  → Tap Save
    → DB update: old amount reversed, new amount applied
    → Balance recalculated
    → Modal closes
    → Daily view row shows updated amount
```

### Delete Transaction

```
User in Edit modal
  → Tap trash icon in AppBar
  → Confirmation dialog appears
  → Tap "Delete"
    → Soft-delete written
    → Balance recalculated
    → Modal closes
    → Transaction disappears from Daily view
    → If it was the only transaction for that day, the day header also disappears
```

---

## Interactions

| Trigger | Action |
|---|---|
| Tap Date row | Open date picker bottom sheet |
| Tap Category row | Open category picker bottom sheet |
| Tap Account / From row | Open account picker bottom sheet |
| Tap To Account row | Open account picker bottom sheet (source disabled) |
| Tap camera icon | Request permission → system image picker |
| Tap bookmark icon | Open bookmark save dialog (ask for name) — Phase 2 in Sprint 3 shows "Coming soon" |
| Tap Rep/Inst icon | Open repeat/installment sheet — "Coming soon" in Sprint 3 |
| Swipe down on modal | Dismiss (with discard confirmation if dirty) |
| Tap back (AppBar) | Dismiss (with discard confirmation if dirty) |
| Android hardware back | Dismiss (with discard confirmation if dirty) |
| Tap trash (edit mode) | Confirmation dialog → soft-delete |

---

## Accessibility

- Screen announced on entry (add mode): "Add transaction. Expense selected."
- Screen announced on entry (edit mode): "Edit transaction. [Type]."
- Type toggle: semanticLabel "Transaction type. [Current type] selected. Tap to change to Income, Expense, or Transfer."
- Date row: semanticLabel "Date. [Formatted date]. Tap to open date picker."
- Amount field: semanticLabel "Amount. Required. Enter transaction amount in [currency]."
- Category row: semanticLabel "Category. [Value or 'Required']. Tap to select."
- Account row: semanticLabel "Account. [Account name], balance [amount]. Tap to change."
- To Account row: semanticLabel "To account. [Value or 'Required']. Tap to select."
- Note field: semanticLabel "Note. Optional."
- Description field: semanticLabel "Description. Optional."
- Save button (enabled): semanticLabel "Save transaction."
- Save button (disabled): semanticLabel "Save transaction. Disabled. Fill in required fields."
- Continue button: semanticLabel "Save and add another transaction."
- Trash icon: semanticLabel "Delete transaction."
- Bookmark icon: semanticLabel "Save as bookmark."
- Camera icon: semanticLabel "Attach photo."
- All text contrast: WCAG AA minimum 4.5:1.
- Minimum tap target: 44x44dp on all interactive elements.
- Focus order (add mode): Back → Bookmark → Type Toggle → Date → Rep/Inst → Amount → Category → Account → Note → Description → Camera → Save → Continue.
- Focus order (edit mode): Back → Bookmark → Trash → Type Toggle → Date → Rep/Inst → Amount → Category → Account → Note → Description → Camera → Save.
- Dynamic Type / text scaling: all text fields and labels must scale correctly. Row height grows to accommodate scaled text.

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Modal entry | Slide up from bottom | 300ms | easeOutCubic |
| Modal exit | Slide down | 250ms | easeInCubic |
| Type toggle color change | Border + text color | 150ms | linear |
| Category row hide (Transfer) | Animated size collapse | 250ms | easeInCubic |
| Category row show | Animated size expand | 250ms | easeOutCubic |
| To Account row show | Animated size expand | 250ms | easeOutCubic |
| To Account row hide | Animated size collapse | 250ms | easeInCubic |
| Validation error red strip | Fade in | 200ms | easeIn |
| Submit spinner appear | Fade in (replaces button label) | 100ms | linear |
| Continue success checkmark | Fade in + hold + fade out | 300ms + 600ms + 300ms | linear |
| Bottom sheet entry | Slide up | 300ms | easeOutCubic |
| Bottom sheet exit | Slide down | 250ms | easeInCubic |
| Image thumbnail appear | Fade in | 200ms | easeOut |

---

## Empty States

| Context | Empty State Copy | Action |
|---|---|---|
| No accounts in DB | "Please create an account first." inline in Account row | "Add >" navigates to AccountAddEditScreen |
| No categories for type | "No categories" in CategoryPickerSheet | "Add Category" CTA navigates to CategoryManagementScreen |
| No photo attached | Camera icon visible; no thumbnails row | — |

---

## Open Questions

- Q: Should "Continue" retain the Note field or reset it? Decision (per US-010 AC): Note is retained. Only Amount and Category reset.
- Q: Should the type toggle be available in edit mode, allowing expense-to-income conversions? Decision: Yes (per US-013 edge cases). Category resets on type switch; all balance recalculations handled by TransactionRepository.update.
- Q: Should the calculator (AppBar icon on amount focus) be present in Sprint 3? Decision: suppress in Sprint 3; add in Sprint 4 as a dedicated story.
- Q: Should bookmark saving (star icon) be interactive in Sprint 3? Decision: tapping shows a "Coming soon" snackbar in Sprint 3. Full bookmark flow is Phase 2.
