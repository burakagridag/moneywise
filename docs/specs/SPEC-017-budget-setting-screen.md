# SPEC-017: Budget Setting Screen

**Sprint:** 5
**Related:** US-BudgetSetting (Sprint 5)
**Reference:** SPEC.md Section 9.11, Reference screenshot 4
**Route:** `/more/budget-setting`
**Component:** `lib/features/more/presentation/screens/budget_setting_screen.dart`

---

## Purpose

BudgetSettingScreen, kullanicinin her kategori icin aylik (veya haftalik/yillik) butce limiti belirledigi ayar ekranidir. More tab altindan (`/more/budget-setting`) ve BudgetView'in "Budget Setting >" linkinden erisebilir. TOTAL satiri her zaman ilk sirada gorunur ve tum kategorilerin toplam harcama limitini temsil eder. Her kategori satirina tiklandikta `BudgetEditModal` alt sayfasi acilir; kullanici tutari girebilir ve "Only this month" secenegini isaretleyip degisikligin sadece mevcut ay icin mi yoksa tum gelecek aylar icin mi gecerli olacagini belirleyebilir. Negatif ve non-numerik girisler engellenir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│  [<] Settings  Budget Setting    [M ▼] 56dp │  <- AppBar
├─────────────────────────────────────────────┤
│  [<]      Apr 2026              [>]   48dp  │  <- MonthNavigator
├─────────────────────────────────────────────┤
│  Income  (inaktif)  │  Exp. (aktif)   44dp  │  <- IncomeExpenseToggle
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ TOTAL                      € 0,00 > │   │  <- TOTAL row (always first)
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Restaurant         € 0,00 > │   │  <- CategoryBudgetSettingRow
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Groceries          € 300,00>│   │
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Food               € 0,00 > │   │
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Transport          € 100,00>│   │
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Health             € 400,00>│   │
│  ├──────────────────────────────────────┤   │
│  │ ...                                 │   │
│  └──────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘

── BudgetEditModal (bottom sheet, opens on row tap) ──────────
┌─────────────────────────────────────────────┐
│  ▬  (drag handle)                   20dp   │
├─────────────────────────────────────────────┤
│  [emoji] Groceries             Budget       │  <- Sheet header
├─────────────────────────────────────────────┤
│                                             │
│  Currency symbol   [  300,00            ]  │  <- Amount input field (48dp)
│                                             │
│  [✓] Only this month (Apr 2026)            │  <- Checkbox row (44dp)
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │                Save                 │   │  <- AppButton primary (52dp)
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │              Clear budget           │   │  <- AppButton ghost/destructive (44dp)
│  └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
BudgetSettingScreen (Scaffold)
├── AppBar
│   ├── Leading: BackButton (< Settings)
│   ├── Title: "Budget Setting"
│   └── Actions: PeriodDropdownButton (M ▼)
├── Column (body)
│   ├── MonthNavigator (48dp)
│   ├── IncomeExpenseToggle (44dp)
│   └── Expanded
│       └── ListView.builder
│           ├── TotalBudgetRow (always index 0)
│           └── List<CategoryBudgetSettingRow>
└── BudgetEditModal (bottom sheet — modal layer, not in tree until triggered)
    ├── DragHandle (20dp)
    ├── ModalHeader (emoji + category name + "Budget" label)
    ├── AmountInputField (48dp)
    ├── OnlyThisMonthCheckbox (44dp)
    ├── SaveButton (AppButton primary, 52dp)
    └── ClearBudgetButton (AppButton ghost, 44dp)
```

---

## Token Specs

### AppBar
| Element | Token |
|---------|-------|
| Height | 56dp |
| Background | `AppColors.bgPrimary` |
| Leading | Phosphor `ArrowLeft` 24dp, `AppColors.textSecondary`; label "Settings" `AppTypography.body` `AppColors.textSecondary` beside icon |
| Title | "Budget Setting" `AppTypography.headline` `AppColors.textPrimary` |
| Period button (M ▼) | Same as SPEC-014: `AppColors.bgSecondary` fill, `AppColors.textPrimary`, `AppRadius.sm`, height 32dp, right-aligned in actions |

### MonthNavigator
Shared widget — same as SPEC-008. `showYearOnly: false`.

### IncomeExpenseToggle
Same as SPEC-014. Defaults to Expense.

### TotalBudgetRow (special first row)
| Element | Token |
|---------|-------|
| Height | 56dp |
| Background | `AppColors.bgSecondary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Label | "TOTAL" `AppTypography.headline` `AppColors.textPrimary` (no emoji, all-caps) |
| Amount | Right-aligned `AppTypography.moneySmall` `AppColors.textPrimary`; "€ 0,00" if no total budget set |
| Trailing | Phosphor `CaretRight` 16dp `AppColors.textTertiary` |
| Bottom divider | 1dp `AppColors.divider` |
| Tap action | Opens BudgetEditModal with category = null (total budget) |

### CategoryBudgetSettingRow
| Element | Token |
|---------|-------|
| Height | 56dp |
| Background | `AppColors.bgSecondary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Leading emoji | 22dp font size, directly in row (no containing circle) |
| Gap: emoji to name | `AppSpacing.sm` (8dp) |
| Category name | `AppTypography.body` `AppColors.textPrimary` |
| Amount | Right-aligned `AppTypography.moneySmall`; `AppColors.textPrimary` if budget set; `AppColors.textTertiary` "€ 0,00" if no budget configured |
| Trailing | Phosphor `CaretRight` 16dp `AppColors.textTertiary` |
| Bottom divider | 1dp `AppColors.divider`, full width |
| Tap target | Full 56dp row, min 44x44dp |

### List Container
| Element | Token |
|---------|-------|
| Background | `AppColors.bgSecondary` |
| No border radius (full-width list) | — |
| Top margin | `AppSpacing.md` (12dp) from IncomeExpenseToggle |

### BudgetEditModal (bottom sheet)
| Element | Token |
|---------|-------|
| Background | `AppColors.bgSecondary` |
| Top border radius | `AppRadius.xl` (24dp) |
| Drag handle | 36x4dp `AppColors.border`, radius `AppRadius.pill`, centered, 12dp top margin |
| Modal header height | 56dp |
| Header: emoji | 24dp font size, left-aligned with `AppSpacing.lg` padding |
| Header: category name | `AppTypography.headline` `AppColors.textPrimary`; "TOTAL" for total budget row |
| Header: "Budget" label | `AppTypography.subhead` `AppColors.textSecondary`, right-aligned |
| Amount input container | `AppColors.bgTertiary` fill, `AppRadius.md` (10dp) radius, height 48dp, horizontal padding `AppSpacing.lg` |
| Currency symbol | `AppTypography.moneyMedium` `AppColors.textSecondary`, left inside input |
| Amount text input | `AppTypography.moneyMedium` `AppColors.textPrimary`, right of currency symbol, numeric keyboard with decimal; focus border `AppColors.brandPrimary` 2dp |
| "Only this month" checkbox | Standard checkbox, `AppColors.brandPrimary` when checked; label `AppTypography.body` `AppColors.textPrimary`; right side shows "(Apr 2026)" `AppColors.textTertiary` `AppTypography.footnote` |
| Checkbox row height | 44dp minimum tap target |
| Save button | `AppButton` primary (full width), "Save", height 52dp, `AppRadius.md` |
| Save button disabled state | `AppColors.brandPrimary` opacity 0.5, no interaction |
| "Clear budget" button | `AppButton` ghost, full width, "Clear budget" `AppColors.error` text, height 44dp; hidden if no budget is set for this category |
| Bottom safe area | `MediaQuery.of(context).viewInsets.bottom` for keyboard avoidance + `AppSpacing.xl` (20dp) padding |

---

## States

### Default (populated list)
- TOTAL row first
- All expense (or income) categories listed below in their configured display order
- Categories with configured budget show formatted amount
- Categories with no budget show "€ 0,00" in `AppColors.textTertiary`
- IncomeExpenseToggle defaults to Expense

### Loading
- TOTAL row: skeleton (56dp grey rectangle)
- Category rows: 8 skeleton rows (56dp each)
- MonthNavigator arrows disabled

### Empty (no categories)
- Theoretically impossible (default categories always exist); if it occurs: `EmptyStateView` with title "No categories" and subtitle "Add categories in Category Settings."

### Error (data load failure)
- `EmptyStateView` with `Warning` icon, "Could not load budgets", Retry snackbar action

### BudgetEditModal States

#### Editing (amount field focused)
- Keyboard slides up; modal shifts above keyboard via `viewInsets.bottom`
- Save button enabled when amount field is not empty and value > 0

#### Submitting (Save tapped)
- Save button shows inline `LoadingIndicator` (16dp white spinner), text hidden
- List row behind the sheet updates optimistically

#### Validation error
- Amount field gets 2dp `AppColors.error` border
- Inline error text below field: "Please enter a valid amount" `AppTypography.caption1` `AppColors.error`
- Conditions that trigger error: empty field, value = 0 (optionally allowed — see edge cases), non-numeric input (blocked at keyboard level)

#### Success
- Modal dismisses with slide-down animation (250ms easeInCubic)
- CategoryBudgetSettingRow amount updates reactively
- No success toast needed (the updated amount in the row is confirmation)

---

## Interactions & Animations

### CategoryBudgetSettingRow / TotalBudgetRow Tap
- Opens BudgetEditModal as a modal bottom sheet
- Sheet slides up 300ms easeOutCubic
- If existing budget: amount field pre-filled
- If no existing budget: amount field empty, cursor ready for input
- "Clear budget" button visible only if a budget already exists for this row

### BudgetEditModal — "Only this month" Checkbox
- Unchecked (default): saving creates or updates the budget entry with `effectiveFrom = start of month`, `effectiveTo = null` (applies to all future months)
- Checked: saving creates an override entry with `effectiveFrom = start of selected month`, `effectiveTo = end of selected month` (only this month is affected; subsequent months retain previous setting or no budget)
- Label dynamically shows selected month: "Only this month (Apr 2026)"

### BudgetEditModal — Save
- Validates amount > 0 and is numeric
- Persists budget via repository; Riverpod provider invalidates
- Modal dismisses, list row updates

### BudgetEditModal — "Clear budget"
- Confirm dialog: "Remove budget for [category]? This will affect all future months unless 'Only this month' is checked."
  - "Remove" (destructive, `AppColors.error`)
  - "Cancel"
- On confirm: budget record soft-deleted; row amount resets to "€ 0,00" `AppColors.textTertiary`

### BudgetEditModal Dismiss (swipe down or tap-outside)
- If amount field is dirty (changed): confirm dialog "Discard changes?" with "Discard" and "Keep editing"
- If field unchanged: dismiss immediately

### Month Navigation
- `<` / `>` navigation changes displayed budgets; if a month has an override, override amount shown; otherwise the recurring budget amount shown
- Budget amounts are per-month (can differ month to month via "Only this month" mechanism)

### Period Dropdown (W / M / Y)
- Changes budget period scope:
  - W: rows show weekly budget amounts
  - M: monthly (default)
  - Y: annual
- Note: underlying storage is monthly; W and Y are display conversions (monthly / weeks_in_month for W; monthly * 12 for Y)

### Income/Expense Toggle
- Switches list to show Income categories with their budgets
- TOTAL row still appears first but reflects total income budget

---

## Validation Rules

| Field | Rule | Error message |
|-------|------|---------------|
| Amount | Must be numeric | Blocked at numeric keyboard level — no non-numeric input possible |
| Amount | Must be > 0 | "Please enter an amount greater than zero." Inline below field. |
| Amount | Must be <= 999,999,999 | "Amount is too large." Inline below field. |
| Amount | No negative sign | Numeric keyboard with no minus sign key; blocked at input level |

---

## Accessibility

- **AppBar back button:** "Back to Settings" semantic label.
- **Period button:** "Period: Monthly. Tap to change." Minimum 44x44dp.
- **TotalBudgetRow:** "Total budget. [Amount or 'not set']. Tap to edit."
- **CategoryBudgetSettingRow:** "[Category emoji and name]. Budget: [amount or 'not set']. Tap to edit."
- **BudgetEditModal:**
  - Amount field: "Budget amount for [category]. Required. Enter a positive number." Announces current value when focused.
  - "Only this month" checkbox: "Only apply this budget to [Month Year]. Currently [checked/unchecked]. Double-tap to toggle."
  - Save button: "Save budget. [Disabled until valid amount entered.]"
  - "Clear budget" button: "Clear budget for [category]."
- **Keyboard focus order (screen):** AppBar back -> Period button -> MonthNavigator -> IncomeExpenseToggle -> TOTAL row -> CategoryBudgetSettingRows top-to-bottom.
- **Keyboard focus order (modal):** Amount field -> "Only this month" checkbox -> Save -> Clear budget.
- **Dynamic Type:** Category names truncate with ellipsis at 1 line for all scale factors. Row heights remain at 56dp spec.
- **Color independence:** "€ 0,00" vs amount distinction uses both color (`textTertiary` vs `textPrimary`) and can be understood from context (screen title + category name).

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Setting budget to 0 | Treated as "clear budget"; same flow as "Clear budget" button. Show confirm dialog. |
| Setting total budget less than sum of category budgets | Allowed; no validation. Surplus is shown in BudgetView summary. No warning in BudgetSettingScreen. |
| "Only this month" override on a month with no prior budget | Creates a month-scoped entry; future months remain without a budget. |
| Navigating to a past month | Budget amounts for that month are shown (historical). Editing past months is allowed but "Only this month" checkbox affects only that past month entry. |
| Navigating to a future month with no override | Recurring budget amount shown (from effectiveFrom with null effectiveTo). |
| Category deleted (soft-deleted) after budget set | Row is hidden; budget record remains but orphaned. BudgetView also hides it. |
| Very long category name | Truncated at 1 line with ellipsis in row; full name shown in modal header (wraps to 2 lines max). |
| Income selected, no income categories have budgets | All rows show "€ 0,00"; no empty state shown (categories exist even if budgets are 0). |
| Multiple currencies | Budget input uses main currency; currency symbol shown left of input. |
| Decimal input | Decimal separator respects locale (comma for TR/DE, period for EN); enforced by numeric formatter. |

---

## New Components Required (Sprint 5)

| Component | File | Notes |
|-----------|------|-------|
| `TotalBudgetRow` | `features/more/presentation/widgets/total_budget_row.dart` | Special 56dp row for the TOTAL budget entry. No emoji. Bold "TOTAL" label. |
| `CategoryBudgetSettingRow` | `features/more/presentation/widgets/category_budget_setting_row.dart` | 56dp row with emoji, category name, budget amount, caret. Reuses `SettingsRow` token conventions. |
| `BudgetEditModal` | `features/more/presentation/widgets/budget_edit_modal.dart` | Bottom sheet with amount input, "Only this month" checkbox, Save and Clear buttons. Accepts `categoryId` (nullable for TOTAL), `existingAmount` (nullable), `selectedMonth`. |
| `BudgetProgressBar` | `core/widgets/budget_progress_bar.dart` | If not already created in Sprint 5 via SPEC-015. Shared with BudgetView. |
