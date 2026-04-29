# SPEC-009: Transactions List Screen — Daily View

**Related:** US-015, US-010, US-011, US-012
**Reference:** SPEC.md Section 9.1 (Ekran 17–20), Section 6.4 (transactions table)
**Route:** `/transactions`
**Component:** `lib/features/transactions/presentation/screens/transactions_screen.dart`

---

## Purpose

The primary "Trans." tab. Shows all transactions grouped by day for the selected month, with a summary bar (income / expense / total), month navigation, and a floating action button to add new transactions. This is the screen a user sees most frequently — it must load fast, scroll smoothly, and surface key information at a glance.

---

## Top-Level Structure

The screen has three persistent horizontal layers visible at all times, plus the scrollable list body:

1. AppBar (top, 44dp)
2. Month Navigator + Summary Bar (sticky, 48dp + 60dp = 108dp combined)
3. Sub-Tab Bar (5 tabs, scrollable horizontally, ~44dp)
4. List body (scrollable)
5. FAB cluster (bottom-right overlay)
6. Banner Ad (bottom, free tier only, 50dp, above tab bar)

This spec covers the **Daily sub-tab** in full. Other sub-tabs (Calendar, Monthly, Summary, Description) are noted structurally but their full interactions are out of scope for Sprint 3.

---

## Layout

```
┌─────────────────────────────────────────────────┐
│  🔍  Trans.                        ⭐   ≡       │  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│  <         Apr 2026          >                  │  ← Month navigator 48dp
├─────────────────────────────────────────────────┤
│  Income        Exp.           Total             │  ← Summary bar 60dp
│  € 0,00      € 651,13       - € 651,13          │
├─────────────────────────────────────────────────┤
│  Daily  Calendar  Monthly  Summary  Description │  ← Sub-tab bar ~44dp
│  ─────                                          │    (2dp underline active)
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌───────────────────────────────────────────┐  │  ← Day group header
│  │  28   Mon          € 0,00     € 53,95     │  │    48dp
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │  ← Transaction row
│  │ 🍜          Restaurant                    │  │    56dp
│  │ Food        Bank Account (Every Month)    │  │
│  │                              - € 198,44   │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │  ← Transaction row
│  │ 🛒          Groceries                     │  │
│  │ Food        Debit Card                    │  │
│  │                              - € 163,55   │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  [more day groups below...]                     │
│                                                 │
├─────────────────────────────────────────────────┤
│  [Banner Ad — free tier only, 50dp]             │
└─────────────────────────────────────────────────┘
                                     ┌──────┐
                                     │  ≡+  │  ← Bookmark FAB (secondary)
                                     ├──────┤
                                     │  +   │  ← Add FAB (primary)
                                     └──────┘
```

---

## Tokens

| Element | Token | Value |
|---|---|---|
| Screen background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar height | `AppHeights.appBar` | 44dp |
| AppBar title | `AppTypography.headline` + `AppColors.textPrimary` | "Trans." |
| AppBar search icon | Phosphor `MagnifyingGlass`, 22dp, `AppColors.textSecondary` | — |
| AppBar bookmark icon | Phosphor `BookmarkSimple`, 22dp, `AppColors.textSecondary` | — |
| AppBar filter icon | Phosphor `SlidersHorizontal`, 22dp, `AppColors.textSecondary` | — |
| Month navigator height | 48dp | — |
| Month navigator background | `AppColors.bgPrimary` | — |
| Month navigator arrows | Phosphor `CaretLeft` / `CaretRight`, 20dp, `AppColors.textSecondary` | — |
| Month navigator label | `AppTypography.title3` + `AppColors.textPrimary` | "Apr 2026" |
| Month navigator label tap target | 120dp wide min | — |
| Summary bar height | 60dp | — |
| Summary bar background | `AppColors.bgSecondary` | #24252A |
| Summary bar top divider | `AppColors.divider`, 1dp | — |
| Summary bar "Income" label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400 |
| Summary bar income value | `AppTypography.moneySmall` + `AppColors.income` | 15/500, blue |
| Summary bar "Exp." label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400 |
| Summary bar expense value | `AppTypography.moneySmall` + `AppColors.expense` | 15/500, coral |
| Summary bar "Total" label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400 |
| Summary bar total value (positive) | `AppTypography.moneySmall` + `AppColors.textPrimary` | 15/500, white |
| Summary bar total value (negative) | `AppTypography.moneySmall` + `AppColors.expense` | 15/500, coral |
| Sub-tab bar height | 44dp | — |
| Sub-tab bar background | `AppColors.bgPrimary` | — |
| Sub-tab bar bottom border | `AppColors.divider`, 1dp | full width |
| Sub-tab active text | `AppTypography.subhead` + `AppColors.textPrimary` | 15/400 |
| Sub-tab active underline | `AppColors.brandPrimary`, 2dp, full tab width | — |
| Sub-tab inactive text | `AppTypography.subhead` + `AppColors.textSecondary` | 15/400 |
| Day group header height | 48dp | — |
| Day group header background | `AppColors.bgPrimary` | — |
| Day number | `AppTypography.title2` + `AppColors.textPrimary` | 22/700 |
| Day label badge (weekday) | `AppTypography.caption2` + `AppColors.textSecondary`, `AppColors.bgTertiary` bg, `AppRadius.sm` 6dp | 11/400 |
| Day label badge Saturday | `AppColors.income` text, `AppColors.income` at opacity 0.15 bg | — |
| Day label badge Sunday | `AppColors.expense` text, `AppColors.expense` at opacity 0.15 bg | — |
| Day group income total | `AppTypography.moneySmall` + `AppColors.income` | 15/500 |
| Day group expense total | `AppTypography.moneySmall` + `AppColors.expense` | 15/500 |
| Day group income/expense shown only when > 0 | — | — |
| Transaction row height | `AppHeights.listItem` | 56dp |
| Transaction row background | `AppColors.bgPrimary` | — |
| Transaction row selected/pressed bg | `AppColors.bgTertiary` | — |
| Transaction row divider | `AppColors.divider`, 1dp, inset 60dp left | — |
| Category icon container | 40dp circle, category color or `AppColors.bgSecondary` | — |
| Category emoji / icon | 20dp emoji or Phosphor icon inside circle | — |
| Transaction primary label | `AppTypography.bodyMedium` + `AppColors.textPrimary` | 16/500, category name |
| Transaction secondary label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400, account name |
| Transaction recurring sub-label | `AppTypography.caption2` + `AppColors.textTertiary` | 11/400, "Every Month" |
| Transaction amount (expense) | `AppTypography.moneySmall` + `AppColors.expense` | 15/500, coral, "- € X,XX" |
| Transaction amount (income) | `AppTypography.moneySmall` + `AppColors.income` | 15/500, blue, "+ € X,XX" |
| Transaction amount (transfer) | `AppTypography.moneySmall` + `AppColors.textSecondary` | 15/500, grey |
| Transaction excluded style | All text `AppColors.textTertiary`, amount strikethrough | — |
| Primary FAB size | 56dp circle | — |
| Primary FAB background | `AppColors.brandPrimary` | coral |
| Primary FAB icon | Phosphor `Plus`, 24dp, white | — |
| Secondary FAB size | 44dp circle | — |
| Secondary FAB background | `AppColors.bgTertiary` | — |
| Secondary FAB icon | Phosphor `BookmarkSimple` + `Plus`, 20dp, `AppColors.textSecondary` | — |
| FAB gap (vertical) | `AppSpacing.sm` | 8dp |
| FAB right/bottom margin | `AppSpacing.lg` | 16dp |

---

## AppBar

Fixed at top of screen. Does not scroll.

- Left: Phosphor `MagnifyingGlass` icon button (22dp, `AppColors.textSecondary`). Tap: opens SearchModal (Phase 2; in Sprint 3, shows "Coming soon" snackbar).
- Center: "Trans." text label (`AppTypography.headline`, `AppColors.textPrimary`).
- Right 1: Phosphor `BookmarkSimple` icon button — opens BookmarkPickerModal (Phase 2; Sprint 3 "Coming soon").
- Right 2: Phosphor `SlidersHorizontal` icon button — opens FilterModal (Phase 2; Sprint 3 "Coming soon").
- Minimum tap target for all icons: 44x44dp.

---

## Month Navigator

Sticky immediately below the AppBar. Does not scroll with the list.

```
│  <         Apr 2026          >     │
```

- Left: Phosphor `CaretLeft` button (20dp). Tap: navigate to previous month. Tapping rapidly should not skip months — debounce or disable during data load.
- Center: "Apr 2026" label. Tap: opens `MonthYearPicker` bottom sheet (Cupertino drum-roll, month + year). On selection, the list and summary bar update to the chosen month.
- Right: Phosphor `CaretRight` button (20dp). Tap: navigate to next month. Disabled (opacity 0.4) if the current month is the current calendar month (cannot navigate into future months beyond the current one — revisit this constraint in Sprint 4).

Month label format: abbreviated month name + 4-digit year (locale-aware, e.g. "Apr 2026").

---

## Summary Bar

Sticky immediately below the Month Navigator. Does not scroll with the list. Three equal-flex columns.

```
│  Income        Exp.           Total            │
│  € 0,00      € 651,13       - € 651,13         │
```

- Column 1 (Income): label "Income" + sum of all non-excluded income transactions in the month. Color: `AppColors.income` (blue). Shows "€ 0,00" when zero. Always shows sign-less amount (income is inherently positive).
- Column 2 (Exp.): label "Exp." + sum of all non-excluded expense transactions in the month. Color: `AppColors.expense` (coral). Shows "€ 0,00" when zero.
- Column 3 (Total): label "Total" + (Income total - Expense total). Color: `AppColors.textPrimary` if >= 0, `AppColors.expense` if < 0. Prefix "+" if positive, "-" if negative. "€ 0,00" when zero (neutral white).
- Amounts formatted with `AppTypography.moneySmall`, tabular figures.
- Tapping a column is a no-op in Sprint 3. (Phase 2: tap to filter the list to that type.)

---

## Sub-Tab Bar

Horizontally scrollable row of 5 tabs immediately below the Summary Bar.

| Position | Label | Sprint 3 Status |
|---|---|---|
| 1 | "Daily" | Fully implemented (this spec) |
| 2 | "Calendar" | Placeholder (shows empty state body) |
| 3 | "Monthly" | Placeholder |
| 4 | "Summary" | Placeholder |
| 5 | "Description" | Placeholder |

- Active tab: `AppColors.textPrimary` text + 2dp `AppColors.brandPrimary` underline.
- Inactive tab: `AppColors.textSecondary` text, no underline.
- Switching tabs: instant (no animation required; 150ms fade on the underline is acceptable).
- Tab bar scrolls horizontally if labels overflow screen width; always shows all 5 labels on typical phone widths (no clipping needed on 375dp+ screens).

---

## Daily View — List Body

Scrollable list (lazy, virtualized). Sorted in reverse-chronological order: most recent day at the top.

### Day Group Header

Appears once per calendar day that has at least one non-deleted transaction.

```
│  28   [Mon]       € 0,00 ↑     € 53,95 ↓      │
│                   (income)      (expense)       │
```

- Left: day number ("28") in `AppTypography.title2` + `AppColors.textPrimary`, 32dp wide.
- Day label badge: weekday abbreviation ("Mon") in a small pill badge, `AppRadius.sm`. Default: `AppColors.bgTertiary` background + `AppColors.textSecondary` text. Saturday: `AppColors.income` at opacity 0.15 background + `AppColors.income` text. Sunday: `AppColors.expense` at opacity 0.15 background + `AppColors.expense` text.
- Right side: income total (blue, `AppColors.income`) and expense total (coral, `AppColors.expense`), each preceded by a small up/down arrow icon. Only shown if that type has a non-zero total for the day. If a day has only expenses, only the expense total appears on the right.
- Amount format: currency symbol + amount (e.g. "€ 53,95"), `AppTypography.moneySmall`.
- Day header does not disappear when all its transactions are deleted within the same session — it disappears only after a data reload / reactive stream update that confirms zero transactions remain for that day.
- Height: 48dp.
- Background: `AppColors.bgPrimary`.
- Sticky within day group while scrolling (iOS-style sticky headers preferred; Android: non-sticky is acceptable for Sprint 3).

### Transaction Row

One row per transaction. Height: 56dp.

```
│  ┌──────┐  Restaurant                 - € 198,44 │
│  │  🍜  │  Food · Bank Account                   │
│  └──────┘  (Every Month)                         │
```

Columns:

**Left (60dp wide):** Category icon circle (40dp diameter). Background: category's `colorHex` (from the categories table) or `AppColors.bgTertiary` as fallback. Inside: emoji character (20dp) or Phosphor icon if no emoji.

**Center (flex 1):** Two-line text block.
- Line 1 (primary): category name or transaction description if available. `AppTypography.bodyMedium` + `AppColors.textPrimary`.
- Line 2 (secondary): account name. `AppTypography.caption1` + `AppColors.textSecondary`. If transaction has a recurring source, append the frequency label in the same line, e.g. "Bank Account · Every Month", `AppColors.textTertiary`.

**Right (auto width):** Amount.
- Expense: "- € X,XX", `AppTypography.moneySmall` + `AppColors.expense`.
- Income: "+ € X,XX", `AppTypography.moneySmall` + `AppColors.income`.
- Transfer: "€ X,XX" (no sign), `AppTypography.moneySmall` + `AppColors.textSecondary`.
- Amounts right-aligned. Tabular figures.

**Excluded transactions (`isExcluded = true`):** All text in `AppColors.textTertiary`. Amount has a strikethrough decoration. Row still appears in the list but is clearly muted. Excluded transactions do not contribute to summary bar totals or day header totals.

**Row divider:** 1dp `AppColors.divider`, inset 60dp from left (aligns with end of icon column).

**Tap:** Opens the edit modal for the tapped transaction (navigates to `/transactions/edit/:id`).

**Swipe to delete (iOS):** Trailing swipe action reveals a red "Delete" button (44dp tall). Tap "Delete": shows the same confirmation dialog as the trash icon in the edit modal. On confirm: soft-deletes the transaction, row animates out (200ms slide-left + fade). Android: long-press context menu with "Edit" and "Delete" options.

---

## Floating Action Buttons

Two vertically stacked FABs in the bottom-right corner of the screen body (above the banner ad and tab bar safe area).

**Primary FAB (bottom, larger):**
- 56dp circle, `AppColors.brandPrimary` fill, white Phosphor `Plus` icon (24dp).
- Tap: opens Add Transaction modal (`/transactions/add`).
- Shadow: 4dp elevation, `AppColors.brandPrimary` at opacity 0.3.

**Secondary FAB (top, smaller):**
- 44dp circle, `AppColors.bgTertiary` fill.
- Icon: Phosphor `BookmarkSimple` with a small `Plus` overlay (20dp, `AppColors.textSecondary`).
- Tap: opens BookmarkPickerModal (Phase 2; Sprint 3: "Coming soon" snackbar).
- Gap between primary and secondary FAB: 8dp.

Both FABs have 16dp margin from right edge and bottom edge of the list body.

---

## Empty State

Shown in the list body area when no transactions exist for the selected month.

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              📋  (illustration)                 │
│                                                 │
│         No transactions for this period         │
│                                                 │
│     Tap + to add your first transaction          │
│                                                 │
└─────────────────────────────────────────────────┘
```

- Uses `EmptyStateView` component.
- Illustration: Phosphor `Receipt` icon (80dp, `AppColors.textTertiary`) or a simple line illustration.
- Title: "No transactions for this period" — `AppTypography.title3` + `AppColors.textPrimary`.
- Subtitle: "Tap + to add your first transaction" — `AppTypography.subhead` + `AppColors.textSecondary`.
- No CTA button (the FAB already provides the action).
- Summary bar still shows "€ 0,00" across all three columns in this state.
- Day group headers: none (no headers rendered).

---

## Loading State

Shown immediately when the screen mounts or when the user navigates to a different month, before the data stream emits.

```
┌─────────────────────────────────────────────────┐
│                   [Spinner]                     │
└─────────────────────────────────────────────────┘
```

- Single centered `LoadingIndicator` (24dp, `AppColors.brandPrimary`).
- Summary bar shows placeholder dashes ("---") in all three value positions.
- Month navigator remains interactive (user can change month during load; previous load is cancelled).
- Duration: typically < 200ms on a local DB query; no skeleton screen needed in Sprint 3.

---

## Error State

If the data stream emits an error (e.g. DB read failure).

- Replace list body with `EmptyStateView`:
  - Icon: Phosphor `Warning` (80dp, `AppColors.error`).
  - Title: "Something went wrong."
  - Subtitle: "Could not load transactions. Please try again."
  - CTA: "Retry" (`AppButton` primary, `AppColors.brandPrimary`). Tap: re-triggers the stream.
- Summary bar shows "---" placeholders.

---

## Month Navigation Behavior

- State: selected year-month (default: current calendar month on first open).
- Navigating to a month: Riverpod provider re-queries the DB for that month's transactions. List updates reactively.
- Navigation is not rate-limited in Sprint 3 (rapid taps accepted; each emits a new query).
- Future month restriction: Phosphor `CaretRight` becomes opacity 0.4 when the displayed month equals the current calendar month. This is a soft guard (no hard block in code beyond UI feedback).

---

## Sub-Tab Placeholder Behavior (Non-Daily Tabs — Sprint 3)

Calendar, Monthly, Summary, and Description tabs show a placeholder body:

```
[Empty area]
      📅
  Coming soon
  This view will be available in a future update.
```

- Icon: relevant Phosphor icon (Calendar, ChartBar, etc.), 64dp, `AppColors.textTertiary`.
- Title: "Coming soon" — `AppTypography.title3`.
- Subtitle: "This view will be available in a future update." — `AppTypography.subhead` + `AppColors.textSecondary`.
- FABs remain visible on all sub-tabs.

---

## User Flows

### View Transactions for a Month

```
User opens Trans. tab
  → Screen loads; default month = current month
  → Summary bar populates (income / expense / total)
  → Daily list renders, newest day at top
  → Each day header shows day totals
  → Each transaction row shows icon, name, account, amount
```

### Navigate to Previous Month

```
User taps < (left arrow)
  → Month label changes to "Mar 2026"
  → Loading indicator replaces list
  → Data loads, list and summary bar update
  → If no transactions: empty state shows
```

### Tap a Transaction

```
User taps a row
  → Edit modal opens pre-filled with transaction data
  → User edits or cancels
  → On save: row updates reactively in Daily view
```

### Swipe to Delete (iOS)

```
User swipes transaction row left
  → Red "Delete" button reveals
  → Tap Delete
  → Confirmation dialog appears
  → Confirm
  → Row animates out
  → Day header totals update
  → Summary bar totals update
  → If last transaction in day: day header disappears
```

---

## Accessibility

- Screen announced on focus: "Transactions screen. [Month label]. Daily view."
- Month navigator arrows: semanticLabel "Previous month" / "Next month". Disabled state: "Next month, unavailable."
- Month label: semanticLabel "[Month name] [Year]. Tap to change month."
- Summary bar columns: semanticLabel "Income [value]", "Expense [value]", "Total [value]".
- Sub-tab bar: standard tab semantics. Active tab announced as "selected".
- Day group header: semanticLabel "Transactions for [Weekday], [Date]. Income [amount]. Expense [amount]."
- Transaction row: semanticLabel "[Category name]. [Account name]. [Amount]. [Expense/Income/Transfer]." If excluded: append "excluded from totals." If recurring: append "recurring, [frequency]."
- Primary FAB: semanticLabel "Add transaction."
- Secondary FAB: semanticLabel "Add from bookmark."
- Swipe-to-delete (iOS): also accessible via long-press "Delete" action in the row's accessibility menu.
- All text contrast: WCAG AA minimum 4.5:1.
- Minimum tap target: 44x44dp on all interactive elements.
- Focus order: AppBar Search → Bookmark → Filter → Month Previous → Month Label → Month Next → Summary Bar → Sub-tabs → List rows (top to bottom) → Secondary FAB → Primary FAB.
- Dynamic Type: row height grows proportionally if text scales. Category icon stays 40dp.

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Screen entry | Fade in (tab switch) | 150ms | easeIn |
| Month change | List cross-fade (old out → loading → new in) | 200ms | linear |
| Transaction row delete | Slide left + height collapse | 200ms | easeInCubic |
| Sub-tab switch | Underline slides horizontally | 150ms | easeOut |
| Edit modal open | Slide up from bottom | 300ms | easeOutCubic |

---

## Open Questions

- Q: Should daily headers be sticky (pinned while scrolling through that day's transactions)? Decision: Sticky on iOS (SliverPersistentHeader), non-sticky on Android in Sprint 3. Revisit in Sprint 4.
- Q: Should the Summary bar totals include transfer amounts in any column? Decision: No. Transfers are excluded from Income and Expense totals. The Total column also excludes transfers. Only the per-day headers and transaction rows reflect transfers (grey amount, no sign).
- Q: What is the maximum number of transactions rendered without virtualization? Decision: Use Flutter's ListView.builder (lazy) from Sprint 3 start. No pagination needed for Phase 1 (local DB).
- Q: Should the future-month restriction on the right arrow be absolute (no navigation into future months at all) or soft (allow future months but they show empty state)? Decision for Sprint 3: soft restriction — right arrow becomes 0.4 opacity at current month but remains tappable; future months show the empty state.
