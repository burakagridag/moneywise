# SPEC-019: Search Screen

**Sprint:** 6
**Related:** US-019
**Reference:** SPEC.md Section 9, `TransactionListItem` (SPEC-009/SPEC-010)
**Route:** `/search` (full-screen push from TransactionsScreen app bar search icon)
**Component:** `lib/features/search/presentation/screens/search_screen.dart`

---

## Purpose

Allow users to find any transaction quickly by free-text search across description, category name, account name, and note fields. Refine results with filter chips for transaction type, category, and date range. Tapping a result navigates to the edit screen.

---

## Why Full-Screen (Not Modal)

A full-screen push is chosen over a bottom-sheet modal for the following reasons:

1. **Filter chip area height is variable.** When multiple filters are active the chip row may wrap to two lines. A bottom sheet with a wrapping header would need a complex dynamic handle area that creates unpredictable layout shifts.
2. **Result list can be long.** A full-screen scaffold lets the user naturally scroll the result list while keeping the search bar pinned at the top, consistent with how native iOS/Android search screens behave (e.g., iOS Spotlight, Android system search).
3. **Navigation depth is shallow.** Tapping a result pushes the add/edit screen on top. With a modal approach this would be a sheet-on-sheet stack, which has poor dismissal UX on both platforms.
4. **Keyboard persistence.** A full-screen `Scaffold` is the most reliable way to keep the software keyboard raised while the user types and simultaneously show results below the fold, because `Scaffold.resizeToAvoidBottomInset` is standard.

The screen is entered via a hero-animated icon in the TransactionsScreen AppBar (search icon). The back-arrow dismisses it, returning to the exact scroll position of the originating screen.

---

## Screen / Component Hierarchy

```
SearchScreen (Scaffold)
├── AppBar (44dp) — contains SearchTextField (full width)
│   ├── Back arrow (leading)
│   └── SearchTextField (expands to fill AppBar)
├── FilterChipRow (48dp, scrollable horizontal)
│   ├── ChipFilter — Type (All / Income / Expense / Transfer)
│   ├── ChipFilter — Category (any selected category)
│   └── ChipFilter — Date Range (quick range or custom)
├── ActiveFilterSummaryBar (32dp, visible only when ≥1 filter active)
│   └── "N results for '[query]'" label + "Clear all" ghost button
└── Expanded
    └── SearchResultList
        ├── Loading state: skeleton rows
        ├── Empty state: EmptyStateView
        ├── Error state: EmptyStateView (error variant)
        └── Populated: ListView of TransactionListItem (grouped by date)
```

---

## Layout

```
┌─────────────────────────────────────────────┐
│ ←  [🔍 Search transactions...      ✕] 44dp │  ← AppBar + SearchTextField
├─────────────────────────────────────────────┤
│  [All Types ▼] [Category ▼] [Date ▼]  48dp  │  ← FilterChipRow (horizontal scroll)
├─────────────────────────────────────────────┤
│  24 results for "coffee"     [Clear all] 32dp│  ← ActiveFilterSummaryBar (conditional)
├─────────────────────────────────────────────┤
│  Thu 28 Apr 2026                            │  ← DayHeaderRow (reuse)
│  [●] Coffee Shop    Debit card  − €4,50     │  ← TransactionListItem
│  [●] Coffee & Work  Cash        − €3,20     │
├─────────────────────────────────────────────┤
│  Wed 27 Apr 2026                            │
│  [●] Morning Coffee Cash        − €2,80     │
│   ·   ·   ·                                 │
└─────────────────────────────────────────────┘
```

---

## Token Specs

### AppBar with SearchTextField
| Element | Token |
|---------|-------|
| Height | 44dp (`AppHeights.appBar`) |
| Background | `AppColors.bgSecondary` |
| Back arrow | `AppColors.textPrimary`, 44x44dp tap target |
| SearchTextField background | `AppColors.bgTertiary`, radius `AppRadius.pill` (999dp) |
| SearchTextField height | 36dp |
| SearchTextField horizontal padding | `AppSpacing.md` (12dp) left/right |
| SearchTextField text style | `AppTypography.body`, `AppColors.textPrimary` |
| Placeholder text | `AppTypography.body`, `AppColors.textTertiary`, "Search transactions…" |
| Leading search icon inside field | 18dp, `AppColors.textTertiary` |
| Clear (✕) button | 18dp, `AppColors.textTertiary`, visible only when field is non-empty, 44x44dp tap target |
| Keyboard type | `TextInputType.text`, `TextInputAction.search` |
| Auto-focus | true — keyboard raises immediately on screen entry |

### FilterChipRow
| Element | Token |
|---------|-------|
| Container height | 48dp |
| Background | `AppColors.bgPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) leading, `AppSpacing.lg` trailing |
| Gap between chips | `AppSpacing.sm` (8dp) |
| Chip scroll behavior | Single-line horizontal `ListView`, no snap |
| Chip height | 32dp |
| Chip radius | `AppRadius.pill` (999dp) |
| Chip (inactive) background | `AppColors.bgTertiary` |
| Chip (inactive) label | `AppTypography.footnote`, `AppColors.textSecondary` |
| Chip (inactive) trailing icon | `▼` 12dp, `AppColors.textTertiary` |
| Chip (active) background | `AppColors.brandPrimaryGlow` |
| Chip (active) border | 1dp `AppColors.brandPrimary` |
| Chip (active) label | `AppTypography.footnote`, `AppColors.brandPrimary` |
| Chip (active) trailing icon | `✕` 12dp, `AppColors.brandPrimary`; tapping removes just that filter |
| Chip animation | background color 150ms easeInOut on toggle |

### ActiveFilterSummaryBar
| Element | Token |
|---------|-------|
| Height | 32dp |
| Background | `AppColors.bgPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Result count text | `AppTypography.footnote`, `AppColors.textSecondary`, left-aligned |
| "Clear all" button | `AppTypography.footnote`, `AppColors.brandPrimary`, right-aligned, ghost style, 44x44dp min tap target |
| Visibility | Visible only when query is non-empty OR at least one filter chip is active |
| Bottom divider | 1dp `AppColors.divider` |

### SearchResultList
- Grouped by date using `DayHeaderRow` (reuse existing widget, SPEC-009)
- Each transaction row: `TransactionListItem` (reuse existing widget, SPEC-009)
- `DayHeaderRow` shows date label only (no income/expense summary in search context)
- List padding: `AppSpacing.xs` (4dp) top, `AppSpacing.lg` (16dp) bottom (clears banner ad area if applicable)
- Match highlighting: matched substring in transaction title/note is wrapped with `AppColors.brandPrimary` text color (not bold; color-only highlight). Contrast against `AppColors.bgPrimary` must remain ≥ 4.5:1 — `AppColors.brandPrimary` (#FF6B5C) on `AppColors.bgPrimary` (#1A1B1E) = 4.8:1 — passes.

---

## Filter Chip Pickers

### Type Filter Picker
Single-select, presented as an inline `DropdownMenu`-style bottom sheet.

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                                    │
│   Transaction Type                          │
├─────────────────────────────────────────────┤
│   All                             [●] 56dp  │
│   Income                          [○] 56dp  │
│   Expense                         [○] 56dp  │
│   Transfer                        [○] 56dp  │
└─────────────────────────────────────────────┘
```

- Sheet background: `AppColors.bgSecondary`, radius `AppRadius.xl` top
- Option row: 56dp, `AppTypography.body` `AppColors.textPrimary`, radio indicator (same style as ThemePickerSheet in SPEC-018)
- "All" is the default (no filter applied); selecting it clears type filter
- Selecting an option dismisses sheet and updates chip label (e.g., "Expense")

### Category Filter Picker
Multi-select, using `CategoryPickerSheet` (existing widget) with checkboxes instead of single-select mode.

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                                    │
│   [🔍 Search categories...         ]        │
├─────────────────────────────────────────────┤
│   EXPENSE CATEGORIES                        │
│   [✓] 🍽️  Restaurant                  56dp  │
│   [✓] 🛒  Groceries                   56dp  │
│   [ ]  🚌  Transport                  56dp  │
│   ...                                       │
├─────────────────────────────────────────────┤
│   INCOME CATEGORIES                         │
│   [ ]  💼  Salary                     56dp  │
│   ...                                       │
├─────────────────────────────────────────────┤
│              [Apply (2)]            52dp    │
└─────────────────────────────────────────────┘
```

- Sheet max height: 75% of screen height; remainder is scrollable
- Leading checkbox: 24dp, `AppColors.brandPrimary` fill when checked, `AppColors.border` outline when unchecked
- Apply button: `AppButton` primary, full width, label includes count of selected categories in parentheses
- If 0 selected: button label "Apply" (clears category filter on tap)
- Chip label when active: first selected category name, e.g., "Restaurant" (if >1: "Restaurant +2")

### Date Range Filter Picker
Two-step: first choose a quick range preset; optionally switch to custom date range.

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                                    │
│   Date Range                                │
├─────────────────────────────────────────────┤
│   Today                           [○] 56dp  │
│   This Week                       [○] 56dp  │
│   This Month                      [●] 56dp  │  ← default selected
│   Last 3 Months                   [○] 56dp  │
│   This Year                       [○] 56dp  │
│   Custom Range…                   [○] 56dp  │
└─────────────────────────────────────────────┘
```

- Tapping "Custom Range…": inline date range picker expands within the same sheet (Flutter's built-in `DateRangePickerDialog` logic adapted to sheet, themed with `AppColors.brandPrimary`)
- On selection: sheet dismisses, chip label shows preset name or custom range (e.g., "1–30 Apr")

---

## States

### Idle (no query, no filters)
- SearchTextField shows placeholder "Search transactions…"
- FilterChipRow visible; all chips in inactive state
- Body area: `EmptyStateView` with magnifying-glass icon (`AppColors.textTertiary`, 64dp), title "Search your transactions", subtitle "Type to find by description, category, or account."
- `EmptyStateView` positioned at vertical center of body area

### Typing (query < 2 characters)
- FilterChipRow remains visible
- Body area: same idle `EmptyStateView` (avoid premature loading for single keystroke)

### Loading (query ≥ 2 characters, search in flight)
- FilterChipRow remains visible
- Body: 6 skeleton `TransactionListItem` rows (each 56dp, `AppColors.bgTertiary` shimmer rectangles for icon, label, and amount)
- Debounce: 300ms after last keystroke before triggering search

### Results (populated)
- `ActiveFilterSummaryBar` appears with result count
- Grouped result list with match highlighting

### Empty (query ≥ 2 characters, zero results)
- `ActiveFilterSummaryBar` visible showing "0 results for '[query]'"
- Body: `EmptyStateView` with Phosphor `MagnifyingGlass` icon (64dp, `AppColors.textTertiary`), title "No transactions found", subtitle "Try different keywords or remove filters."
- "Clear filters" `AppButton` ghost CTA visible if any filter is active

### Error (search provider throws)
- Body: `EmptyStateView` with Phosphor `Warning` icon (64dp, `AppColors.warning`), title "Something went wrong", subtitle "Could not complete the search."
- "Retry" `AppButton` ghost CTA

---

## Interactions

| Trigger | Action |
|---------|--------|
| Tap search icon in TransactionsScreen AppBar | Push `/search`; keyboard auto-focuses; icon hero-animates |
| Type in SearchTextField | Debounce 300ms → trigger search across description + category name + account name + note |
| Tap clear (✕) in SearchTextField | Clear query; return to idle state; keep active filters |
| Tap back arrow | Pop to previous screen |
| Tap "All Types" chip | Open Type Filter sheet |
| Tap active type chip ✕ | Remove type filter immediately (no sheet) |
| Tap "Category" chip | Open Category Filter sheet |
| Tap active category chip ✕ | Remove category filter immediately |
| Tap "Date" chip | Open Date Range Filter sheet |
| Tap active date chip ✕ | Remove date filter immediately |
| Tap "Clear all" in summary bar | Remove all active filters, keep query text |
| Tap a `TransactionListItem` | Push `/transactions/edit/:id` (TransactionAddEditScreen in edit mode) |
| Swipe-to-delete on a result row (iOS) | Show delete confirmation Snackbar with "Undo" action (3s window); on confirm: remove from DB, remove from result list with slide-out animation |
| Long-press result row (Android) | Show context menu: "Edit", "Delete" |
| Keyboard "Search" action button | Dismiss keyboard; keep results visible |

### Swipe-to-Delete Animation
- Row slides left revealing red delete background (same spec as `TransactionListItem` SPEC-009)
- Row collapses out with `AnimatedSize` 200ms `easeInCubic` after confirmation

---

## Accessibility

- **Screen reader label for AppBar:** "Search screen"
- **SearchTextField:** Semantic label "Search transactions. Text field. Double-tap to edit." Clear button: "Clear search text."
- **FilterChipRow:** Each chip announced as "[Label] filter chip. [active/inactive]. Double-tap to [open options / remove filter]."
- **ActiveFilterSummaryBar:** Announced as live region (`SemanticsProperties.liveRegion: true`) so result count updates are read automatically
- **Result list items:** Inherit `TransactionListItem` semantics (SPEC-009)
- **Empty state CTA buttons:** Minimum 44x44dp; labeled "Clear all filters" or "Retry search"
- **Color contrast:** Match highlight `AppColors.brandPrimary` (#FF6B5C) on `AppColors.bgPrimary` (#1A1B1E): 4.8:1 — passes AA
- **Focus order:** Back arrow → SearchTextField → Type chip → Category chip → Date chip → Clear all → Result list rows
- **Dynamic Type:** SearchTextField and chip labels scale; filter sheet rows maintain 56dp minimum height regardless of text scale

---

## Search Logic (for Engineer Reference — not implementation detail)

The spec describes expected behavior, not implementation:

- Search is **local only** (SQLite full-text scan or LIKE query)
- Fields searched: `transactions.description`, `categories.name`, `accounts.name`
- Results ordered by `transaction.date DESC`
- Minimum query length: 2 characters (to avoid returning the entire transaction history)
- Active filters are combined with AND logic (type AND category AND date range AND query text)
- Filter combinations that produce zero results show the empty state (not an error)

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Query contains special regex characters (e.g., "$") | Escaped before passing to SQLite; no crash |
| Very long transaction description | Label truncates to 2 lines in `TransactionListItem`; full text accessible via screen reader |
| All transactions match query (e.g., single character "e") | Minimum 2-character gate prevents this |
| 500+ results returned | Lazy-loaded list with pagination (page size 50); spinner at bottom when loading next page |
| Category filter active, no transactions in that category | 0-result empty state shown |
| Network unavailable | No impact — search is entirely local |
| User rotates device mid-search | Query, filters, and scroll position preserved via `StateController`; keyboard re-raises if previously open |

---

## New Components Required (Sprint 6)

| Component | File | Notes |
|-----------|------|-------|
| `SearchTextField` | `core/widgets/search_text_field.dart` | Pill-shaped, `bgTertiary` fill, leading icon, clear button. Reusable across search contexts. |
| `FilterChipRow` | `features/search/presentation/widgets/filter_chip_row.dart` | Horizontal scrollable row of `FilterChip` items. |
| `FilterChip` | `features/search/presentation/widgets/filter_chip.dart` | Single chip with active/inactive states and ✕ dismiss. |
| `ActiveFilterSummaryBar` | `features/search/presentation/widgets/active_filter_summary_bar.dart` | Result count + Clear all row. |
| `TypeFilterSheet` | `features/search/presentation/widgets/type_filter_sheet.dart` | Single-select type picker bottom sheet. |
| `CategoryFilterSheet` | `features/search/presentation/widgets/category_filter_sheet.dart` | Multi-select category picker with Apply button. |
| `DateRangeFilterSheet` | `features/search/presentation/widgets/date_range_filter_sheet.dart` | Preset + custom date range picker bottom sheet. |
