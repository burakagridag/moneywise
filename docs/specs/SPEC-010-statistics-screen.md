# SPEC-010: Statistics Screen

**Related:** US-016
**Reference:** SPEC.md Section 9.3 (Ekran 14–16), Section 6.3 (categories), Section 6.4 (transactions)
**Route:** `/stats`
**Component:** `lib/features/stats/presentation/screens/stats_screen.dart`

---

## Purpose

The Stats tab. Shows spending (or income) broken down by category for a selected month as a donut pie chart, with a ranked category list below. Users can toggle between Expense and Income views, navigate between months, and tap a pie slice to drill into that category's transactions. Budget and Note sub-tabs are present as placeholders in Sprint 3.

---

## Top-Level Structure

Four sticky layers at the top, followed by the scrollable content body:

1. Sub-tab bar: "Stats" / "Budget" / "Note" + period selector (44dp)
2. Month Navigator (48dp)
3. Income / Expense toggle (44dp)
4. Content body (scrollable)
5. Banner Ad (bottom, free tier only, 50dp, above tab bar)

---

## Layout

```
┌─────────────────────────────────────────────────┐
│  [Stats]  Budget   Note              [M ▼]       │  ← Sub-tab + period 44dp
├─────────────────────────────────────────────────┤
│  <         Apr 2026          >                  │  ← Month navigator 48dp
├─────────────────────────────────────────────────┤
│  Income                Exp. € 651,13            │  ← Income/Exp toggle 44dp
│                        ─────────────            │    (active underline)
├─────────────────────────────────────────────────┤
│                                                 │
│                  ┌─────────┐                    │
│                  │  donut  │                    │
│             30.5%│  chart  │25.1%               │  ← Pie chart ~280dp
│                  │         │                    │
│          Food    └─────────┘  Groceries         │
│                                                 │
│  ─────────────────────────────────────────────  │
│                                                 │
│  [30%] 🍴  Restaurant .............  € 198,44   │  ← Category rows 56dp each
│  [25%] 🛒  Groceries ...............  € 163,55  │
│  [14%] 🚕  Transport ...............  € 91,14   │
│  [11%] 🏠  Rent ......................  € 71,70  │
│  [ 7%] 🧘  Health ....................  € 45,60  │
│  [ 5%] 📚  Education .................  € 32,55  │
│  [ 8%] ●   Other .....................  € 52,15  │
│                                                 │
├─────────────────────────────────────────────────┤
│  [Banner Ad — free tier only, 50dp]             │
└─────────────────────────────────────────────────┘
```

---

## Tokens

| Element | Token | Value |
|---|---|---|
| Screen background | `AppColors.bgPrimary` | #1A1B1E |
| Sub-tab bar background | `AppColors.bgPrimary` | — |
| Sub-tab bar bottom border | `AppColors.divider`, 1dp | — |
| Sub-tab bar height | 44dp | — |
| Sub-tab active text | `AppTypography.subhead` + `AppColors.textPrimary` | 15/400 |
| Sub-tab active underline | `AppColors.brandPrimary`, 2dp | — |
| Sub-tab inactive text | `AppTypography.subhead` + `AppColors.textSecondary` | 15/400 |
| Period selector button | `AppTypography.subhead` + `AppColors.textPrimary` | "M ▼" |
| Period selector background | `AppColors.bgTertiary`, `AppRadius.sm` | — |
| Period selector padding | `AppSpacing.sm` horizontal, `AppSpacing.xs` vertical | — |
| Month navigator height | 48dp | — |
| Month navigator background | `AppColors.bgPrimary` | — |
| Month navigator arrows | Phosphor `CaretLeft` / `CaretRight`, 20dp, `AppColors.textSecondary` | — |
| Month navigator label | `AppTypography.title3` + `AppColors.textPrimary` | "Apr 2026" |
| Income/Exp toggle height | 44dp | — |
| Income/Exp toggle background | `AppColors.bgPrimary` | — |
| Income/Exp toggle bottom border | `AppColors.divider`, 1dp | — |
| Income/Exp active label | `AppTypography.bodyMedium` + `AppColors.textPrimary` | 16/500 |
| Income/Exp active amount | `AppTypography.moneySmall` + `AppColors.textPrimary` | 15/500, right of label |
| Income/Exp active underline | `AppColors.brandPrimary`, 2dp | — |
| Income/Exp inactive label | `AppTypography.bodyMedium` + `AppColors.textSecondary` | 16/500 |
| Income/Exp inactive amount | omitted | — |
| Pie chart container height | 280dp | — |
| Pie chart outer diameter | ~220dp | centered in container |
| Pie chart hole radius | ~45% of radius | creates donut shape |
| Pie chart hole background | `AppColors.bgPrimary` | matches screen bg |
| Pie chart segment colors | See Color Palette section below | — |
| Pie chart segment spacing | 2dp gap between segments | — |
| Pie chart label text | `AppTypography.caption2` + `AppColors.textPrimary` | 11/400 |
| Pie chart label percentage | `AppTypography.caption2` + `AppColors.textSecondary` | 11/400 |
| Category list divider | `AppColors.divider`, 1dp, full-width | — |
| Category row height | `AppHeights.listItem` | 56dp |
| Category row background | `AppColors.bgPrimary` | — |
| Category row selected bg | `AppColors.bgTertiary` | — |
| Percentage badge width | 40dp | — |
| Percentage badge height | 24dp | — |
| Percentage badge radius | `AppRadius.sm` | 6dp |
| Percentage badge text | `AppTypography.caption1` + `AppColors.textPrimary` | 12/400, white on badge bg |
| Category emoji/icon | 20dp, inside 36dp circle with category color bg | — |
| Category name | `AppTypography.bodyMedium` + `AppColors.textPrimary` | 16/500 |
| Category amount | `AppTypography.moneySmall` + `AppColors.textPrimary` | 15/500, right-aligned |
| "Other" row badge color | `AppColors.textTertiary` | — |
| Banner ad height | `AppHeights.bannerAd` | 50dp |

---

## Pie Chart Color Palette

Eight distinct colors assigned sequentially to categories ranked by amount (highest first). Palette is brand-aligned and chosen for sufficient contrast on dark backgrounds:

| Index | Color Hex | Role |
|---|---|---|
| 1 | `#FF6B5C` | coral (brand primary — top category) |
| 2 | `#FF9F40` | orange |
| 3 | `#FFD166` | yellow |
| 4 | `#06D6A0` | green |
| 5 | `#4A90E2` | blue (income color) |
| 6 | `#9B59B6` | purple |
| 7 | `#F78FB3` | pink |
| 8 | `#48CAE4` | teal |

If there are more than 8 categories, all categories beyond the 8th are grouped into an "Other" segment that uses `AppColors.textTertiary` (#6B6E76) as its color. This "Other" segment appears last in both the chart and the list, regardless of its amount rank.

If a category segment would be < 3% of the total, it is grouped into "Other" regardless of rank. Exception: if there are only 1–2 categories total, the 3% rule is not applied (render all segments individually).

The color palette is fixed in assignment order (rank 1 always gets coral, rank 2 always gets orange, etc.) within a given dataset. Color assignments reset with each data reload.

---

## Sub-Tab Bar

Three tabs on the left; period selector on the right.

```
│  [Stats]  Budget   Note              [M ▼]  │
```

- "Stats": active by default. This spec describes the Stats sub-tab content.
- "Budget": placeholder in Sprint 3 (see Placeholder section).
- "Note": placeholder in Sprint 3.
- Period selector "M ▼" (or "W ▼" / "Y ▼"): tap opens a compact dropdown or action sheet:
  - W — Weekly
  - M — Monthly (default)
  - Y — Yearly
  - Period — Custom date range (Phase 2; disabled in Sprint 3)
  In Sprint 3, only M (Monthly) is fully implemented. W and Y options are shown but tap produces a "Coming soon" snackbar and do not change the displayed data.

---

## Month Navigator

Identical in structure to SPEC-009 (Transactions List Screen).

```
│  <         Apr 2026          >  │
```

- Left arrow: navigate to previous month. No restriction.
- Right arrow: opacity 0.4 when at current month (soft guard only — still tappable, future months show empty state).
- Center label tap: opens `MonthYearPicker` bottom sheet (Cupertino drum-roll).
- Data reloads when month changes. Pie chart and category list both update.

---

## Income / Expense Toggle

Two-option inline toggle below the month navigator.

```
│  Income                  Exp. € 651,13  │
│                          ─────────────  │
```

- Left option: "Income". Shows the total income amount for the selected month when active (e.g. "Income  € 3,000.00").
- Right option: "Exp." Shows the total expense amount when active (e.g. "Exp.  € 651,13").
- Active option: `AppColors.textPrimary` text, 2dp `AppColors.brandPrimary` underline beneath the entire option area.
- Inactive option: `AppColors.textSecondary` text, no underline, no amount shown.
- Default on screen open: "Exp." active (expense view).
- Switching toggles: pie chart and category list immediately reload with filtered data. The month navigator stays the same. Animation: 150ms cross-fade of chart content.
- The amount displayed next to the active label is the total for that type/month (formatted with `AppTypography.moneySmall`, tabular figures).

---

## Stats Sub-Tab Content Body

### Donut Pie Chart

Rendered using `fl_chart` `PieChart` widget.

**Dimensions:** Chart widget occupies a 280dp tall container centered horizontally. The pie itself is approximately 220dp in outer diameter with a hole radius of 45% (donut shape). Background of the hole: `AppColors.bgPrimary`.

**Segments:**
- One segment per category (after "Other" grouping rules applied).
- Segment color: assigned from the 8-color palette by rank.
- Segment gap: 2dp between each adjacent segment.
- Tapping a segment: highlights it (lifts outward by 8dp, 200ms easeOutCubic), and navigates to the Transactions List screen filtered to that category and month. On return, the highlight resets.

**Labels:**
- Labels are rendered outside the pie, connected by a short line to their segment.
- Each label shows: category name (possibly truncated at 12 chars with "…") on line 1, percentage on line 2.
- Labels use `AppTypography.caption2` + `AppColors.textPrimary`. Percentage: `AppColors.textSecondary`.
- Label placement: auto-positioned by fl_chart to minimize overlaps. For very small segments (< 5%), the label may be suppressed and only the percentage appears inside the segment area.
- Long category names (> 12 chars): truncated with "…". Full name visible in the category list below.

**Center of donut:** Empty (no text or value in the center hole). The hole shows the screen background.

**Segment-tap navigation:**
- Tapping the "Food" segment: opens `/transactions?filter=category:food_id&month=2026-04` (exact route parameter format to be confirmed by flutter-engineer).
- In Sprint 3, if filtered navigation is not yet implemented, tap produces a "Coming soon" snackbar.

### Category List

Appears directly below the pie chart, separated by a full-width 1dp divider. No section header. The list is part of the same scroll view as the chart (the chart scrolls away as the user scrolls down).

Each row (56dp):

```
│  [30%] 🍴  Restaurant .............  € 198,44   │
```

**Left (40dp):** Percentage badge. Width: 40dp, height: 24dp, radius: `AppRadius.sm`. Background: segment color. Text: percentage integer + "%" (e.g. "30%"), `AppTypography.caption1` + `AppColors.textPrimary` (white).

**Left-center gap:** `AppSpacing.sm` (8dp).

**Center-left (36dp):** Category icon circle. Background: category's `colorHex` or segment color as fallback. Inside: emoji (20dp) or Phosphor icon.

**Center-left gap:** `AppSpacing.sm`.

**Center (flex 1):** Category name. `AppTypography.bodyMedium` + `AppColors.textPrimary`. Single line, truncated with "…" at 20+ chars.

**Right:** Amount in local currency. `AppTypography.moneySmall` + `AppColors.textPrimary`. Right-aligned. Tabular figures.

**Divider:** `AppColors.divider`, 1dp, full-width (not inset).

**"Other" row (if present):**
- Percentage badge background: `AppColors.textTertiary`.
- No emoji/icon — uses a plain dot (Phosphor `CircleFill`, 12dp, `AppColors.textTertiary`) in the icon column.
- Category name: "Other".
- Amount: sum of all grouped-in categories.
- Not tappable (no navigation action — tap is a no-op in Sprint 3).

**Tap on any non-Other row:** navigates to filtered Transactions List (same as segment tap). Sprint 3 fallback: "Coming soon" snackbar.

**Ranking:** Rows are always sorted by amount descending (highest amount first). "Other" row is always last.

---

## States

### Default (Data Available)
- Income/Expense toggle: Expense active.
- Pie chart: renders segments for current month's expense categories.
- Category list: ranked by expense amount.
- Summary bar (toggle area): shows total expense amount next to "Exp.".

### Loading
- Triggered on: initial screen mount, month navigation, toggle switch.
- Pie chart area: replaced by a centered `LoadingIndicator` (24dp, `AppColors.brandPrimary`).
- Category list: replaced by 3–5 placeholder rows (shimmering skeleton: 56dp height, `AppColors.bgTertiary` background fill animated with a sweep from left to right at 1.2s cycle). In Sprint 3, a simple centered spinner is acceptable as a fallback.
- Income/Expense toggle amounts: show "---" until data loads.

### Empty (No Data for Period)
- Applies when: no transactions of the selected type exist for the selected month.
- Pie chart area: replaced by an empty donut ring (full circle outline in `AppColors.bgTertiary`, same dimensions as the chart, 4dp stroke width) with a centered empty-state message inside the hole area.

```
          ╭──────────────╮
        ╭─┤              ├─╮
       │  │   No data    │  │
       │  │   for this   │  │
       │  │   period     │  │
        ╰─┤              ├─╯
          ╰──────────────╯
```

- Empty ring center text: "No data for this period" in `AppTypography.caption1` + `AppColors.textTertiary`, centered.
- Category list: replaced by a single `EmptyStateView` row:
  - Title: "No data for this period."
  - Subtitle: "Add transactions to see your spending breakdown."
  - No CTA button.
- Income/Expense toggle amounts: "€ 0,00".
- Summary bar toggle shows "€ 0,00".

### Error (Stream Failure)
- Pie chart area: replaced by `EmptyStateView`:
  - Icon: Phosphor `Warning` (64dp, `AppColors.error`).
  - Title: "Could not load statistics."
  - Subtitle: "Please try again."
  - CTA: "Retry" (`AppButton` primary). Tap: re-triggers the provider.
- Category list: not shown (replaced by the same EmptyStateView).

### Single Category
- Pie chart: a single full-circle segment (no gap, no other segments). The lone category occupies 100%.
- Category list: one row.
- No "Other" grouping applied.
- Label: positioned at the top of the circle pointing outward.

### Many Categories (20+)
- All categories with < 3% of total are merged into "Other".
- Chart renders up to 8 named segments + 1 "Other" segment maximum.
- Category list renders: 8 named rows + 1 "Other" row.
- Scroll area accommodates all rows without truncation.

---

## Budget Sub-Tab (Placeholder — Sprint 3)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│              [ChartBar icon 64dp]               │
│                                                 │
│                Budget tracking                  │
│                                                 │
│    Budget management will be available soon.    │
│                                                 │
└─────────────────────────────────────────────────┘
```

- Icon: Phosphor `ChartBar`, 64dp, `AppColors.textTertiary`.
- Title: "Budget tracking" — `AppTypography.title3` + `AppColors.textPrimary`.
- Subtitle: "Budget management will be available soon." — `AppTypography.subhead` + `AppColors.textSecondary`.
- No CTA.

---

## Note Sub-Tab (Placeholder — Sprint 3)

```
┌─────────────────────────────────────────────────┐
│                                                 │
│               [Note icon 64dp]                  │
│                                                 │
│              Spending notes                     │
│                                                 │
│   Note-based summaries will be available soon.  │
│                                                 │
└─────────────────────────────────────────────────┘
```

- Icon: Phosphor `Note`, 64dp, `AppColors.textTertiary`.
- Title: "Spending notes" — `AppTypography.title3` + `AppColors.textPrimary`.
- Subtitle: "Note-based summaries will be available soon." — `AppTypography.subhead` + `AppColors.textSecondary`.

---

## User Flows

### View Monthly Expense Breakdown

```
User taps Stats tab
  → Screen loads; Expense toggle active, current month
  → Spinner briefly visible
  → Donut chart renders with expense category segments
  → Category list renders ranked by amount
  → User reads breakdown
```

### Switch to Income View

```
User taps "Income" on toggle
  → Active indicator slides to Income (150ms)
  → Spinner briefly visible
  → Chart re-renders with income category segments
  → List re-renders with income categories
  → Income total displayed next to "Income" label
```

### Navigate to Previous Month

```
User taps < arrow
  → Month label changes to "Mar 2026"
  → Loading state shown
  → Chart and list update to March data
  → If no data: empty ring + empty state message
```

### Tap a Pie Segment

```
User taps "Food" segment
  → Segment lifts outward 8dp (200ms)
  → Navigation to Trans. tab with category filter
    → Shows only Food transactions for the same month
  → On back: Stats screen restores; segment highlight resets
```

### Tap a Category Row

```
User taps "Restaurant" row
  → Same navigation as tapping the segment
  → Trans. tab opens filtered to Restaurant for the month
```

---

## Interactions

| Trigger | Action |
|---|---|
| Tap Income/Expense toggle | Switch view; chart and list reload |
| Tap < month arrow | Previous month; data reloads |
| Tap > month arrow | Next month (soft guard at current month) |
| Tap month label | Open MonthYearPicker bottom sheet |
| Tap pie segment | Highlight + navigate to filtered Transactions (Sprint 3: "Coming soon") |
| Tap category row | Navigate to filtered Transactions (Sprint 3: "Coming soon") |
| Tap "Other" row | No-op (Sprint 3) |
| Tap period selector "M ▼" | Show W / M / Y options; W and Y show "Coming soon" |
| Tap sub-tab "Budget" | Show Budget placeholder |
| Tap sub-tab "Note" | Show Note placeholder |
| Tap Retry (error state) | Re-trigger data provider |

---

## Accessibility

- Screen announced on entry: "Statistics screen. [Month]. Expense view." (or Income view).
- Income/Expense toggle: semanticLabel "View mode. [Income/Expense] selected. Tap to switch."
- Month navigator arrows: same as SPEC-009.
- Pie chart: semanticLabel for the chart widget: "Spending breakdown pie chart. [N] categories. [Category1] [%1]. [Category2] [%2]. ..." (reads out all segments). Tappable segments individually have semanticLabel "[Category name]. [Percentage]%. [Amount]. Tap to view transactions."
- Category list rows: semanticLabel "[Category name]. [Amount]. [Percentage]% of total. Tap to view transactions."
- "Other" row: semanticLabel "Other categories combined. [Amount]. [Percentage]%."
- Loading state: semanticLabel "Loading statistics. Please wait."
- Empty state: semanticLabel "No data. No transactions found for this period."
- Error state: semanticLabel "Error loading statistics. Tap Retry to try again."
- All text contrast: WCAG AA minimum 4.5:1.
- Minimum tap target: 44x44dp. Note: pie chart segments may be smaller than 44dp if the chart is small or segments are thin. In those cases, the category list row provides the accessible equivalent tap target for the same action.
- Focus order: Sub-tabs (Stats → Budget → Note) → Period selector → Month Previous → Month Label → Month Next → Income/Expense toggle → Pie chart (single focusable widget) → Category rows (top to bottom).
- Dynamic Type: row heights grow with text scaling. Chart remains fixed at 280dp (does not scale with Dynamic Type to preserve chart integrity).

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Chart data change (month/toggle) | Cross-fade entire chart | 200ms | easeOut |
| Segment tap highlight | Segment offset outward 8dp | 200ms | easeOutCubic |
| Segment highlight reset | Segment returns to position | 150ms | easeInCubic |
| Sub-tab switch underline | Horizontal slide | 150ms | easeOut |
| Income/Expense toggle underline | Horizontal slide | 150ms | easeOut |
| Loading spinner appear | Fade in | 100ms | linear |
| Category list cross-fade | Fade new list in | 200ms | easeOut |

---

## Component Inventory (New Components for Sprint 3)

The following shared widgets are identified as needed for this screen and SPEC-008 / SPEC-009:

| Component | File | Used In | Notes |
|---|---|---|---|
| `TransactionListItem` | `features/transactions/presentation/widgets/transaction_list_item.dart` | SPEC-009 Daily view | 56dp row. Leading category icon circle (40dp), center two-line text, trailing amount with color coding. Supports excluded (muted) style. |
| `DayGroupHeader` | `features/transactions/presentation/widgets/day_group_header.dart` | SPEC-009 Daily view | 48dp sticky-compatible header. Day number, weekday badge (color-coded Sat/Sun), day income + expense totals. |
| `MonthNavigator` | `core/widgets/month_navigator.dart` | SPEC-009, SPEC-010 | 48dp row. Prev/next arrows + month-year label. Emits month-change events. |
| `SummaryBar` | `features/transactions/presentation/widgets/summary_bar.dart` | SPEC-009 | 60dp 3-column bar: income (blue), expense (coral), total (white or coral). |
| `PieChartWidget` | `features/stats/presentation/widgets/pie_chart_widget.dart` | SPEC-010 | fl_chart PieChart wrapper. Props: segments list (category, amount, color), onSegmentTap callback. 280dp container. |
| `CategoryLegendRow` | `features/stats/presentation/widgets/category_legend_row.dart` | SPEC-010 | 56dp row. Percentage badge + icon circle + category name + amount. Color prop for badge. |
| `IncomeExpenseToggle` | `core/widgets/income_expense_toggle.dart` | SPEC-010, future Budget screen | 44dp two-option inline toggle. Active state: brand underline + primary text. Props: activeMode, incomeTotal, expenseTotal, onChanged. |
| `AppTextField` | `core/widgets/app_text_field.dart` | SPEC-008 (Note, Description) | Label left, value right. Single-line and multi-line variants. Validation support (inline error caption). Max-length counter. |
| `CurrencyText` | `core/widgets/currency_text.dart` | SPEC-008 Amount, SPEC-009 amounts, SPEC-010 amounts | Tabular figures. Props: amount, color (income/expense/neutral), showSign (bool), style. |
| `MonthYearPicker` | `core/widgets/month_year_picker.dart` | SPEC-009, SPEC-010 | Bottom sheet. Cupertino drum-roll: month name + year. Emits selected DateTime. |

---

## Open Questions

- Q: Should tapping a pie segment navigate to the Transactions tab directly (breaking out of the Stats tab navigator), or open a modal list within the Stats tab? Decision for Sprint 3: navigate to the Trans. tab with filter params. The exact go_router route and query parameter format to be confirmed by flutter-engineer.
- Q: Is the 3% "group into Other" threshold the right value? Decision: use 3% as the threshold for Sprint 3. Revisit after user testing in Sprint 4.
- Q: Should "Other" in the category list be expandable to show its constituent categories? Decision: not in Sprint 3. Phase 2 enhancement.
- Q: Should the donut chart center display the total amount or remain empty? Decision: empty (matches reference app). If the Product Sponsor prefers a total in the center, that is a one-line design change and should be raised in the weekly review.
- Q: What happens when the user has expenses in multiple currencies in Phase 1? Decision: treat all as main currency (EUR), exchange rate = 1.0, per SPEC.md §6.4. No currency conversion indicator shown in Sprint 3.
