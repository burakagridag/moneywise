# SPEC-005: Account Add / Edit Screen

**Related:** Sprint 2 — Accounts feature
**Reference:** SPEC.md Section 9.5 (Ekran 12), SPEC.md Section 6.2 (accounts table)
**Route:** `/accounts/add` (add mode) | `/accounts/edit/:id` (edit mode)
**Component:** `lib/features/accounts/presentation/screens/account_add_edit_screen.dart`

---

## Purpose

A full-screen form (not a modal) for creating a new account or editing an existing one. Covers all account fields including group, name, currency, initial balance, icon, color, totals inclusion, and card-specific fields. In edit mode, also provides a delete action.

---

## Mode Differentiation

| Attribute | Add Mode | Edit Mode |
|---|---|---|
| Route | `/accounts/add` | `/accounts/edit/:id` |
| AppBar center title | (empty) | (empty) |
| AppBar right action | "Add" (text button, `AppColors.brandPrimary`) | "Save" (text button, `AppColors.brandPrimary`) |
| AppBar left action | `<` Accounts | `<` Accounts |
| Delete button | Not present | Shown at bottom, destructive |
| Initial field values | Defaults (see below) | Pre-populated from existing account |

---

## Layout

```
┌─────────────────────────────────────────────────┐
│  < Accounts                            Add/Save │  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← Icon + Color row (top of form)
│  │  [Account Icon 40dp]  [Color swatch row] │   │  24dp padding top
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← Form card (bgSecondary)
│  │ Group           Cash               >    │   │  56dp row
│  │ ─────────────────────────────────────── │   │  divider
│  │ Name            [TextField          ]   │   │  56dp row
│  │ ─────────────────────────────────────── │   │
│  │ Currency        EUR (€)            >    │   │  56dp row
│  │ ─────────────────────────────────────── │   │
│  │ Initial Balance [0.00           ]       │   │  56dp row
│  │ ─────────────────────────────────────── │   │
│  │ Include in Totals                 [●─]  │   │  56dp row (toggle)
│  │ ─────────────────────────────────────── │   │
│  │ Description     [TextField          ]   │   │  56dp row (optional)
│  └─────────────────────────────────────────┘   │
│                                                 │
│  [Card-specific section — only when group =     │  ← Conditional section
│   Card / Overdrafts / Loan]                     │
│  ┌─────────────────────────────────────────┐   │
│  │ Statement Day   [1]                >    │   │  56dp row
│  │ ─────────────────────────────────────── │   │
│  │ Payment Due Day [1]                >    │   │  56dp row
│  │ ─────────────────────────────────────── │   │
│  │ Credit Limit    [0.00           ]       │   │  56dp row
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← Edit mode only
│  │  [Delete Account]  (destructive red)    │   │  52dp
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

The entire content is wrapped in a `SingleChildScrollView` so it scrolls when the keyboard is visible or when the card-specific section is shown.

---

## Icon and Color Row

Located above the main form card. Center-aligned horizontally.

```
┌──────────────────────────────────────────────────┐
│                                                  │
│         ┌──────────┐                             │
│         │  [icon]  │  ← 56dp circle, tappable    │
│         └──────────┘                             │
│           (tap to                                │
│            open icon picker)                     │
│                                                  │
│   ● ● ● ● ● ● ● ● ● ●  ← color swatches 28dp   │
│                                                  │
└──────────────────────────────────────────────────┘
```

- Icon container: 56dp circle, background = selected color or `AppColors.bgTertiary`.
- Inside: emoji character or Phosphor icon at 28dp. Default icon: Phosphor `Wallet`.
- Tap on icon container: opens the Icon Picker bottom sheet.
- Color swatches: a horizontal row of 10 preset color circles, each 28dp with 8dp spacing. Colors are a curated palette of 10 options (coral, blue, green, yellow, purple, orange, teal, red, grey, indigo — exact hex values to be confirmed by flutter-engineer from a brand-aligned set).
- Selected swatch: 2dp `AppColors.textPrimary` border ring around the swatch.
- Tap a swatch: immediately updates icon container background. No confirmation needed.
- Row padding: `AppSpacing.lg` horizontal, `AppSpacing.xl` vertical.

---

## Tokens

| Element | Token | Value |
|---|---|---|
| Screen background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar height | `AppHeights.appBar` | 44dp |
| AppBar back label | `AppTypography.body` + `AppColors.brandPrimary` | 17/400 |
| AppBar action label | `AppTypography.body` + `AppColors.brandPrimary` | 17/400 |
| AppBar action (disabled) | `AppColors.brandPrimary` at opacity 0.4 | — |
| Form card background | `AppColors.bgSecondary` | #24252A |
| Form card radius | `AppRadius.md` | 10dp |
| Form card margin (horizontal) | `AppSpacing.lg` | 16dp |
| Form row height | `AppHeights.listItem` | 56dp |
| Row label | `AppTypography.body` + `AppColors.textSecondary` | 17/400 |
| Row label min width | 120dp | (for alignment consistency) |
| Row value (picker) | `AppTypography.body` + `AppColors.textPrimary` | 17/400 |
| Row value (empty / placeholder) | `AppTypography.body` + `AppColors.textTertiary` | 17/400 |
| Row chevron | Phosphor `CaretRight`, 16dp, `AppColors.textTertiary` | — |
| Row divider | `AppColors.divider` | #2E2F35, 1dp, inset 16dp left |
| Toggle (on) | Track `AppColors.brandPrimary`, thumb white | — |
| Toggle (off) | Track `AppColors.bgTertiary`, thumb white | — |
| TextField input text | `AppTypography.body` + `AppColors.textPrimary` | 17/400 |
| TextField cursor | `AppColors.brandPrimary` | — |
| TextField focus underline | `AppColors.brandPrimary`, 2dp | — |
| TextField unfocused underline | `AppColors.border`, 1dp | — |
| Section header text (card-specific) | `AppTypography.footnote` + `AppColors.textSecondary` | 13/400, uppercase |
| Section header padding | `AppSpacing.lg` left, `AppSpacing.sm` top/bottom | — |
| Delete button height | `AppHeights.button` | 52dp |
| Delete button style | `AppButton` ghost, label color `AppColors.error` | — |
| Delete button margin | `AppSpacing.xxxl` top | 32dp |

---

## Form Fields

### Group (required)
- Label: "Group"
- Default value (add mode): "Cash"
- Displayed value: group name (`AppColors.textPrimary`) + chevron
- Tap: opens Account Group Picker bottom sheet (see below).
- Changing group affects which conditional fields are shown.

### Name (required)
- Label: "Name"
- Input type: single-line text field.
- Max length: 50 characters.
- Placeholder: empty (no placeholder text).
- Validation: must not be empty. If empty on save attempt, field underline turns `AppColors.error` and an inline error message ("Name is required") appears in `AppTypography.caption1` + `AppColors.error` beneath the row.

### Currency (required)
- Label: "Currency"
- Default value (add mode): user's main currency (from settings), e.g. "EUR (€)".
- Displayed value: ISO code + symbol, e.g. "EUR (€)".
- Tap: opens Currency Picker bottom sheet (same component as SPEC-007, single-select mode, no sub-currency toggle).

### Initial Balance (required, defaults to 0)
- Label: "Initial Balance"
- Input type: numeric, decimal-safe. Displays currency symbol as a left prefix inside the field area.
- Default: "0.00".
- No negative values for asset accounts. For liability accounts (Card, Loan, Overdrafts), negative input is permitted.
- Keyboard type: number pad with decimal separator.

### Include in Totals (toggle, default ON)
- Label: "Include in Totals"
- Right-aligned toggle switch.
- When OFF: this account's balance is excluded from the Assets/Liabilities/Total summary on the Accounts screen. A secondary sub-label appears below: "This account will be hidden from totals." (`AppTypography.caption1` + `AppColors.textTertiary`)

### Description (optional)
- Label: "Description"
- Input type: single-line text field.
- Max length: 200 characters.
- Placeholder: empty.
- No validation required.

---

## Card-Specific Fields (Conditional)

Shown when group is one of: Card, Overdrafts, Loan. Hidden otherwise. Section animates in/out (animated size, 250ms, easeOutCubic).

Section header label: "CARD DETAILS" (all caps, `AppTypography.footnote` + `AppColors.textSecondary`).

### Statement Day
- Label: "Statement Day"
- Value: integer 1–31, displayed as "Day [N]".
- Tap: opens a compact number picker (bottom sheet, drum-roll style, 1–31).
- Default: 1.

### Payment Due Day
- Label: "Payment Due Day"
- Same picker as Statement Day.
- Default: 1.

### Credit Limit
- Label: "Credit Limit"
- Input type: numeric (same as Initial Balance field).
- Default: empty (0.00).
- Optional.

---

## Account Group Picker (Bottom Sheet)

Slide-up bottom sheet. `AppBottomSheet` component. Title: "Account Group".

```
┌─────────────────────────────────────────────────┐
│                 Account Group                   │  ← header 56dp
│  ─────────────────────────────────────────────  │
│  Cash                                     (●)   │  ← selected: brandPrimary dot
│  Accounts                                       │
│  Card                                           │
│  Debit Card                                     │
│  Savings                                        │
│  Top-Up/Prepaid                                 │
│  Investments                                    │
│  Overdrafts                                     │
│  Loan                                           │
│  Insurance                                      │
│  Others                                         │
│  ─────────────────────────────────────────────  │
│  [Cancel]                                       │  ← ghost button, 52dp
└─────────────────────────────────────────────────┘
```

- Each row: 56dp, `AppTypography.body` + `AppColors.textPrimary`.
- Selected row: `AppColors.bgTertiary` background + `AppColors.brandPrimary` dot (10dp) on the right.
- Tapping a row: updates the Group field, dismisses the sheet.
- Tapping Cancel or swiping down: dismisses without change.
- Bottom sheet background: `AppColors.bgSecondary`, top corners `AppRadius.xl` (24dp), drag handle visible.

---

## Icon Picker (Bottom Sheet)

Slide-up bottom sheet. Title: "Choose Icon".

Two sections, toggled by a segmented control at the top of the sheet:
1. "Emoji" — shows a scrollable grid of curated finance-relevant emoji (wallet, card, coins, house, car, etc.). Grid: 6 columns, each cell 52dp with 8dp spacing.
2. "Icon" — shows Phosphor Icons grid (same dimensions).

- Selected item: `AppColors.brandPrimary` border (2dp) + `AppColors.bgTertiary` background.
- Tapping an item: updates icon preview, dismisses the sheet.
- Sheet height: 60% of screen height, internally scrollable.

---

## States

### Default (add mode)
- Group: "Cash".
- Name: empty.
- Currency: user's main currency.
- Initial Balance: "0.00".
- Include in Totals: ON.
- Description: empty.
- Card-specific fields: hidden (Cash is not a card type).
- AppBar "Add" action: disabled (opacity 0.4) until Name is non-empty.

### Default (edit mode)
- All fields pre-populated from the existing account record.
- AppBar shows "Save" (enabled once any field changes).
- Delete button visible at bottom.

### Validating
- Name non-empty → AppBar action becomes enabled (full opacity, tappable).
- Name empty + save attempted → Name field error state (red underline + error caption).
- Inline validation fires on field blur, not on every keystroke.

### Submitting
- User taps "Add" / "Save" → AppBar action text replaced by a 16dp `LoadingIndicator` (white). All form fields become non-interactive.
- On success → screen pops back to `AccountsScreen`. The new/updated account appears in the list via the reactive stream.
- On error → AppBar action text restores. A snackbar appears: "[Error message]. Try again." Form remains populated.

### Delete confirmation (edit mode)
- User taps "Delete Account" → confirmation alert dialog.
- Alert title: "Delete account?"
- Alert body (if account has transactions): "All transactions linked to [Account Name] will also be permanently deleted."
- Alert body (if account has no transactions): "This will permanently delete [Account Name]."
- Actions: "Cancel" (default) and "Delete" (`AppColors.error`).
- On confirm: screen pops to `AccountsScreen` with account removed.

---

## Interactions

### Back navigation
- iOS: swipe right (native gesture) or tap `< Accounts`.
- Android: hardware back button or tap `< Accounts`.
- If the form is dirty (any field changed from initial value), present a discard confirmation:
  - Title: "Discard changes?"
  - Body: "Your changes will not be saved."
  - Actions: "Keep editing" (default) and "Discard" (destructive).

### Currency picker tap
- Opens `CurrencyPickerSheet` (single-select, derived from SPEC-007 list, no sub-currency section).

### Number day picker (Statement Day / Payment Due Day)
- Bottom sheet with a vertically scrollable drum-roll list of integers 1–31.
- "Done" button at top right confirms selection.

### Keyboard dismissal
- Tapping outside an active text field dismisses the keyboard.
- The scroll position adjusts so the active field is visible above the keyboard.

---

## Accessibility

- Screen title announced on entry: "Add Account" or "Edit Account [Name]".
- Group picker row: semanticLabel "Account group, [current value]. Tap to change."
- Name field: semanticLabel "Account name, required."
- Currency row: semanticLabel "Currency, [current value]. Tap to change."
- Initial Balance field: semanticLabel "Initial balance, [value] [currency symbol]."
- Include in Totals toggle: semanticLabel "Include in totals, [on/off]."
- Statement Day row: semanticLabel "Statement day, day [N]. Tap to change."
- Payment Due Day row: semanticLabel "Payment due day, day [N]. Tap to change."
- Credit Limit field: semanticLabel "Credit limit, [value]."
- Delete button: semanticLabel "Delete account. Destructive action."
- AppBar Add/Save action: semanticLabel "Save account." or "Add account." — disabled state announced when name is empty.
- Color contrast: all text tokens meet WCAG AA (4.5:1 minimum).
- Minimum tap target on all interactive elements: 44x44dp.
- Focus order: AppBar Back → AppBar Add/Save → Icon picker → Color swatches → Group → Name → Currency → Initial Balance → Include in Totals → Description → (Card fields if visible) → Delete (edit only).

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Screen entry | Slide from right | 300ms | easeOutCubic |
| Card-specific section reveal | Animated size | 250ms | easeOutCubic |
| Card-specific section hide | Animated size | 200ms | easeInCubic |
| Bottom sheet entry | Slide up | 300ms | easeOutCubic |
| Bottom sheet exit | Slide down | 250ms | easeInCubic |
| Validation error inline | Fade in | 150ms | easeIn |
| Submitting loader | Fade in (replaces text) | 100ms | linear |

---

## Open Questions

- Q: Should the icon picker include a "None / No Icon" option? Assumption: yes, first cell is "No icon" (empty state shows the group's default Phosphor icon).
- Q: For the color palette, should users be able to input a custom hex color? Assumption for V1: only preset swatches, custom input is Phase 2.
- Q: When editing a Savings or Investment account, should interest rate and maturity date fields be shown as "Coming Soon" placeholders or hidden entirely? Assumption: hidden in V1.
