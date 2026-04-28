# SPEC-007: Currency Screen

**Related:** Sprint 2 — Currency settings
**Reference:** SPEC.md Section 9.16, SPEC.md Section 6.10 (currencies table), SPEC.md Section 6.9 (settings table keys: `mainCurrency`, `subCurrencies`)
**Routes:** `/more/currency-main` (Main Currency) | `/more/currency-sub` (Sub Currency)
**Components:**
- `lib/features/more/presentation/screens/currency_screen.dart` — hosts both sub-screens
- Optionally reached from `MoreScreen` via two separate list items: "Main Currency Setting" and "Sub Currency Setting"

---

## Purpose

Allows users to set their primary (main) currency and optionally configure one or more secondary (sub) currencies. Main currency is a single selection and is the base denomination for all balances, budgets, and statistics. Sub currencies are optional additional currencies displayed alongside the main currency value.

---

## Architecture Note (for UX flow only)

Both main and sub currency selection live at sibling routes. They are structurally similar screens with different selection behavior:
- Main Currency: single-select, immediate effect on save.
- Sub Currency: multi-select with per-currency exchange rate input.

Both screens share the search bar + currency list pattern. They may share a common `CurrencyListScreen` widget parameterised by mode.

---

## Screen 1: Main Currency

**Route:** `/more/currency-main`

### Layout

```
┌─────────────────────────────────────────────────┐
│  < Settings      Main Currency                  │  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │  ← Search bar 48dp
│  │  🔍  Search currencies...               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  SELECTED                                       │  ← Section header (if a currency is selected)
│  ─────────────────────────────────────────────  │
│  🇪🇺  EUR    Euro                 €      ✓    │  ← 56dp row, brand check
│                                                 │
│  ALL CURRENCIES                                 │  ← Section header
│  ─────────────────────────────────────────────  │
│  🇹🇷  TRY    Turkish Lira         ₺            │
│  🇺🇸  USD    US Dollar            $            │
│  🇬🇧  GBP    British Pound        £            │
│  🇯🇵  JPY    Japanese Yen         ¥            │
│  🇨🇭  CHF    Swiss Franc          Fr           │
│  🇨🇳  CNY    Chinese Yuan         ¥            │
│  ...  (full ISO 4217 list, scrollable)          │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Search Bar

- Height: 48dp.
- Background: `AppColors.bgSecondary`, `AppRadius.md` (10dp).
- Horizontal margin: `AppSpacing.lg` (16dp) each side. Top margin: `AppSpacing.lg`.
- Leading icon: Phosphor `MagnifyingGlass`, 18dp, `AppColors.textTertiary`.
- Placeholder: "Search currencies…" (`AppTypography.body` + `AppColors.textTertiary`).
- Input text: `AppTypography.body` + `AppColors.textPrimary`.
- Cursor color: `AppColors.brandPrimary`.
- Clear button (×): appears when text is non-empty; Phosphor `X`, 16dp, `AppColors.textSecondary`. Tap clears the field.
- Filters list in real time (debounce 300ms). Matches against currency code, name, and symbol.
- When search is active, the "SELECTED" section header is hidden; results show only matching rows.

### Currency Row (56dp)

```
│  [Flag 24dp]  [Code 48dp min]  [Name]        [Symbol]  [Check] │
```

| Element | Position | Spec |
|---|---|---|
| Flag emoji | Leading, 24dp | Country flag emoji (or generic globe 🌐 for multi-nation currencies like XOF). Followed by 12dp gap. |
| Currency code | After flag | `AppTypography.bodyMedium` + `AppColors.textPrimary` (16/500). Min width 48dp. |
| Currency name | Center, flexible | `AppTypography.subhead` + `AppColors.textSecondary` (15/400). Truncate with ellipsis. |
| Currency symbol | Trailing, before check | `AppTypography.bodyMedium` + `AppColors.textSecondary` (16/500). Min width 32dp, right-aligned. |
| Check icon | Trailing, rightmost | Phosphor `Check`, 20dp, `AppColors.brandPrimary`. Visible only on selected row. |

- Row horizontal padding: `AppSpacing.lg` (16dp) each side.
- Row divider: `AppColors.divider`, 1dp, inset 16dp left.
- Selected row background: `AppColors.bgTertiary`.
- Unselected row background: `AppColors.bgSecondary`.
- Tap: immediately selects this currency as main currency. Previous selection deselects (check removed). The "SELECTED" section at top updates.
- Selection is persisted immediately to the settings store (no "Save" button needed). The change takes effect across the app reactively.

### Section Headers

- Text: all-caps, `AppTypography.caption1` + `AppColors.textSecondary` (12/400).
- Padding: `AppSpacing.lg` left, `AppSpacing.sm` top, `AppSpacing.xs` bottom.
- Background: `AppColors.bgPrimary` (matches screen background, makes it appear like a floating header).
- "SELECTED" section: only shown if a currency is selected. Contains exactly one row.
- "ALL CURRENCIES" section: contains all currencies in the list, sorted alphabetically by currency code. The currently selected currency is excluded from this section (it appears in SELECTED only).

### Prioritized Currencies

The following currencies are pinned to the top of the ALL CURRENCIES list (before alphabetical sorting of the rest):
TRY, EUR, USD, GBP, JPY, CHF, CAD, AUD, CNY, SEK, NOK, DKK, PLN, HUF, CZK, RON, BGN, HRK, RSD

This ordering ensures the most common currencies are visible without scrolling.

---

## Screen 2: Sub Currency

**Route:** `/more/currency-sub`

### Purpose

Sub currencies are optional additional currencies displayed alongside the main currency. When configured, the app shows amounts in both main and sub currency (using a stored or user-defined exchange rate).

### Layout

```
┌─────────────────────────────────────────────────┐
│  < Settings      Sub Currency                   │  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │  ← Search bar 48dp
│  │  🔍  Search currencies...               │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  SELECTED (2)                                   │  ← Section header with count
│  ─────────────────────────────────────────────  │
│  🇺🇸  USD    US Dollar         $    1.08  ✎ ✓ │  ← selected row + rate + edit
│  🇬🇧  GBP    British Pound     £    0.86  ✎ ✓ │
│                                                 │
│  ALL CURRENCIES                                 │
│  ─────────────────────────────────────────────  │
│  🇹🇷  TRY    Turkish Lira     ₺    [toggle ○] │  ← toggleable
│  🇯🇵  JPY    Japanese Yen     ¥    [toggle ○] │
│  ...                                            │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Differences from Main Currency Screen

| Aspect | Main Currency | Sub Currency |
|---|---|---|
| Selection mode | Single-select (tap replaces) | Multi-select (toggle per row) |
| Selection affordance | Full-row tap + check icon | Per-row toggle switch (right side) |
| Exchange rate display | Not shown | Shown on selected rows |
| Exchange rate edit | N/A | Inline edit via pencil icon |
| "Save" button | Not needed (immediate) | Not needed (immediate per toggle) |

### Sub Currency Row (ALL CURRENCIES section, 56dp)

```
│  [Flag]  [Code]  [Name]         [Symbol]  [Toggle] │
```

- Toggle: standard switch, ON = `AppColors.brandPrimary`, OFF = `AppColors.bgTertiary`.
- Toggle width: 51dp (system default).
- Toggling ON: moves the row to the SELECTED section immediately (animated: row slides up to SELECTED, 300ms). Prompts the user to set an exchange rate (see Rate Entry below).
- Toggling OFF: removes from SELECTED section, exchange rate discarded.

### Selected Sub Currency Row (SELECTED section, 64dp)

Taller (64dp) to accommodate the exchange rate display below the currency name.

```
│  [Flag 24dp]  [Code]  [Name]           [Rate input]  [✎]  [✓] │
│               [sub: 1 EUR = X.XX Code]                         │
```

| Element | Spec |
|---|---|
| Rate display | Sub-label beneath name: "1 [MainCode] = [rate] [SubCode]". `AppTypography.caption1` + `AppColors.textSecondary`. |
| Rate value | Shown inline. Editable via the pencil icon. |
| Pencil icon | Phosphor `PencilSimple`, 18dp, `AppColors.textSecondary`. Tap opens the Rate Entry inline or bottom sheet. |
| Check icon | Phosphor `Check`, 20dp, `AppColors.brandPrimary`. Indicates this currency is active. |

### Rate Entry

When the user taps the pencil icon on a selected sub currency:

Option A (inline): the rate value transforms into a text input field in-place. The user types the rate and taps "Done" on the keyboard. The sub-label updates immediately.

Option B (bottom sheet): a compact bottom sheet slides up with:
- Title: "Exchange Rate" (56dp header)
- Sub-title: "1 [MainCode] = ?"
- A single numeric input field showing the current rate.
- Hint: "Rate to [MainCode]"
- "Done" button (`AppButton` primary, 52dp).

Recommendation: Option B (bottom sheet) for a cleaner interaction, especially on small screens where inline editing can be occluded by the keyboard.

The exchange rate is stored in the local `currencies` table (`rateToBase` column). Rates are user-defined in V1; automatic FX fetch is Phase 2.

### API Auto-Fetch (Phase 2 placeholder)

A "Fetch rates automatically" informational row at the bottom of the SELECTED section:

```
│  [cloud icon]  Fetch rates automatically        Coming soon  │
```

- 56dp row, non-interactive in V1. `AppColors.textTertiary` for all text and icon.
- Acts as a visual cue that automatic rates are planned.

---

## Tokens (Both Screens)

| Element | Token | Value |
|---|---|---|
| Screen background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar height | `AppHeights.appBar` | 44dp |
| AppBar title | `AppTypography.headline` + `AppColors.textPrimary` | 17/600 |
| AppBar back label | `AppTypography.body` + `AppColors.brandPrimary` | 17/400 |
| Search bar background | `AppColors.bgSecondary` | #24252A |
| Search bar radius | `AppRadius.md` | 10dp |
| Search bar height | 48dp | — |
| Search margin (horizontal) | `AppSpacing.lg` | 16dp |
| Section header text | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400, uppercase |
| Section header padding left | `AppSpacing.lg` | 16dp |
| Currency row height (main, unselected) | `AppHeights.listItem` | 56dp |
| Currency row height (sub, selected) | 64dp | — |
| Currency row background (default) | `AppColors.bgSecondary` | #24252A |
| Currency row background (selected) | `AppColors.bgTertiary` | #2E2F35 |
| Currency row horizontal padding | `AppSpacing.lg` | 16dp |
| Currency code typography | `AppTypography.bodyMedium` + `AppColors.textPrimary` | 16/500 |
| Currency name typography | `AppTypography.subhead` + `AppColors.textSecondary` | 15/400 |
| Currency symbol typography | `AppTypography.bodyMedium` + `AppColors.textSecondary` | 16/500 |
| Check icon color | `AppColors.brandPrimary` | #FF6B5C |
| Check icon size | 20dp | — |
| Row divider | `AppColors.divider` | #2E2F35, 1dp |
| Toggle (on) | Track `AppColors.brandPrimary`, thumb white | — |
| Toggle (off) | Track `AppColors.bgTertiary`, thumb white | — |
| Rate sub-label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400 |
| Pencil icon color | `AppColors.textSecondary` | #B0B3B8 |
| "Coming soon" text | `AppColors.textTertiary` | #6B6E76 |

---

## States

### Loading
- Search bar visible and interactive (input disabled until load completes).
- List area: 8 skeleton rows, each 56dp. Shimmer between `AppColors.bgSecondary` and `AppColors.bgTertiary`.

### Default (currencies loaded, one already selected)
- SELECTED section shows current main currency (main screen) or selected sub currencies (sub screen).
- ALL CURRENCIES shows the full list, sorted with prioritized currencies first.

### Empty search results
```
│                                                 │
│           [Phosphor MagnifyingGlass 40dp]       │
│           No currencies found for               │
│           "[search term]"                       │
│                                                 │
```
- Icon: `AppColors.textTertiary`.
- Text: `AppTypography.subhead` + `AppColors.textSecondary`.

### Error
- List area replaced by centered Phosphor `WarningCircle` (40dp, `AppColors.error`) + "Could not load currencies" + "Try again" ghost button.

---

## User Flows

### Set main currency (happy path)
```
User navigates to Main Currency screen
  → Sees current selection in SELECTED section
  → Types "TRY" in search bar
    → List filters to Turkish Lira row
  → Taps TRY row
    → TRY moves to SELECTED section (check appears)
    → EUR disappears from SELECTED
    → Settings store updated immediately
    → All balance displays across app use TRY
```

### Add sub currency (happy path)
```
User navigates to Sub Currency screen
  → Toggles USD row ON
    → USD moves to SELECTED section
    → Rate Entry bottom sheet appears automatically ("1 EUR = ? USD")
      → User enters "1.08"
      → Taps Done
        → Rate stored
        → Sheet dismisses
        → USD row in SELECTED shows "1 EUR = 1.08 USD"
```

### Edit sub currency rate
```
User taps pencil icon on selected USD row
  → Rate Entry bottom sheet opens, pre-filled with "1.08"
    → User changes to "1.09"
    → Taps Done
      → Rate updated, sub-label refreshes
```

### Remove sub currency
```
User toggles USD row OFF (in SELECTED or ALL section)
  → USD row removed from SELECTED (animated)
  → Rate discarded
  → USD re-appears in ALL CURRENCIES section with toggle OFF
```

---

## Accessibility

### Main Currency Screen
- Screen announced: "Main Currency. Select your primary currency."
- Search field: semanticLabel "Search currencies."
- SELECTED section header: semanticLabel "Selected currency."
- Currency row (selected): semanticLabel "[Flag] [Code], [Name], [Symbol]. Selected. Tap to change."
- Currency row (unselected): semanticLabel "[Flag] [Code], [Name], [Symbol]. Tap to select as main currency."

### Sub Currency Screen
- Screen announced: "Sub Currency. Select additional currencies."
- SELECTED section header: semanticLabel "Selected sub currencies, [N] selected."
- Currency row (selected): semanticLabel "[Code], [Name], selected. Rate: 1 [MainCode] equals [rate] [Code]. Edit rate."
- Currency row (unselected): semanticLabel "[Code], [Name], not selected. Toggle to add."
- Toggle: semanticLabel "[Code] sub currency, [on/off]."
- Rate pencil: semanticLabel "Edit exchange rate for [Code]."

### Both Screens
- Color is never the sole differentiator: selection is indicated by both the check icon and the `bgTertiary` background.
- All interactive elements: minimum 44x44dp tap target.
- Focus order: AppBar back → Search bar → SELECTED rows (if any) → ALL CURRENCIES rows in order.
- Dynamic Type: currency name truncates with ellipsis; code and symbol never truncate.

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Screen entry | Slide from right | 300ms | easeOutCubic |
| Search filter | List cross-fade | 150ms | easeInOut |
| Main: selection change | Check appear/disappear + bg | 150ms | easeInOut |
| Main: row move to SELECTED | Row slides to top | 300ms | easeOutCubic |
| Sub: toggle ON, move to SELECTED | Row slides up | 300ms | easeOutCubic |
| Sub: toggle OFF, remove from SELECTED | Row slides down + fade | 250ms | easeInCubic |
| Rate bottom sheet entry | Slide up | 300ms | easeOutCubic |
| Rate bottom sheet exit | Slide down | 250ms | easeInCubic |

---

## Open Questions

- Q: When the user changes the main currency, should all existing transaction amounts be kept as-is (not converted) or converted at current rate? Assumption: kept as-is (currency change is display-only for existing records; new transactions use new main currency). PM should confirm.
- Q: Should the Sub Currency screen allow a maximum number of sub currencies? Assumption: no hard limit in V1, but UX recommend keeping it to 3 or fewer.
- Q: Should flags be rendered as emoji (simplest, OS-dependent rendering) or as a flags asset library? Assumption: native flag emoji in V1 for simplicity.
- Q: For the "Fetch rates automatically" Phase 2 feature, will rates refresh on app open, on demand, or on a schedule? Out of scope for this spec; noted as a placeholder.
