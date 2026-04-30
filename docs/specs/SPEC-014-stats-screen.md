# SPEC-014: Stats Screen (Stats Sub-tab)

**Sprint:** 5
**Related:** US-Stats (Sprint 5)
**Reference:** SPEC.md Section 9.3, Reference screenshot 16
**Route:** `/stats`
**Component:** `lib/features/stats/presentation/screens/stats_screen.dart`

---

## Purpose

StatsScreen, bottom navigation Tab 2'nin root ekranıdır. Ust kisimda Stats / Budget / Note sub-tab toggler ile period secici barindirip, secilen sub-tab'a gore icerik alani degistirir. Stats sub-tab'inda secilen ay icin Income veya Expense harcamalarinin kategori bazli dagilimlari fl_chart donut pie chart ve alttaki legend listesiyle gosterilir. Period secimine gore haftalik, aylik veya yillik aggregation saglar.

---

## Screen / Component Hierarchy

```
StatsScreen (Scaffold)
├── AppBar (56dp)
│   └── Title: "Stats"
├── Column (body)
│   ├── SubTabAndPeriodBar (48dp)              ← Stats / Budget / Note + Period dropdown
│   ├── MonthNavigator (48dp)                  ← Shared widget (SPEC-008 ile ayni)
│   ├── IncomeExpenseToggle (44dp)             ← Income / Exp. iki segment
│   └── Expanded
│       └── StatsBody (IndexedStack veya PageView)
│           ├── StatsSubTab      (SPEC-014 — bu dosya)
│           ├── BudgetSubTab     (SPEC-015)
│           └── NoteSubTab       (SPEC-016)
└── (Banner Ad — 50dp, free tier)
```

---

## Layout

```
┌─────────────────────────────────────────────┐
│            Stats                     56dp   │  <- AppBar
├─────────────────────────────────────────────┤
│  [Stats][Budget][Note]         [M ▼]  48dp  │  <- SubTabAndPeriodBar
├─────────────────────────────────────────────┤
│  [<]      Apr 2026              [>]   48dp  │  <- MonthNavigator
├─────────────────────────────────────────────┤
│  Income  €0,00  │  Exp.  €651,13      44dp  │  <- IncomeExpenseToggle
│  (inaktif-gri)  │  (aktif-brand, underline) │
├─────────────────────────────────────────────┤
│                                             │
│         [Donut Pie Chart ~ 300dp]           │  <- PieChartWidget
│    label      label      label              │
│   (dis cevre, kategori adi + %)             │
│                                             │
├─────────────────────────────────────────────┤
│  [%30 renk badge] [emoji] Restaurant €198,44│  <- CategoryLegendList
│  [%25 renk badge] [emoji] Groceries  €163,55│
│  [%18 renk badge] [emoji] Transport  €120,00│
│  ...                                        │
├─────────────────────────────────────────────┤
│  [Banner Ad — 50dp, free tier]              │
└─────────────────────────────────────────────┘
```

---

## Token Specs

### AppBar
| Element | Token |
|---------|-------|
| Height | 56dp |
| Background | `AppColors.bgPrimary` |
| Title | `AppTypography.headline`, `AppColors.textPrimary` |
| No leading, no actions (sub-tab toggle handles navigation) | — |

### SubTabAndPeriodBar
| Element | Token |
|---------|-------|
| Height | 48dp |
| Background | `AppColors.bgPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Sub-tab group: Stats / Budget / Note | Segmented-control style; active: `AppColors.brandPrimary` fill + `AppColors.textOnBrand`; inactive: `AppColors.bgSecondary` fill + `AppColors.textSecondary` |
| Sub-tab height | 32dp, radius `AppRadius.sm` (6dp) |
| Sub-tab min width | 64dp each |
| Period button (M ▼) | Right-aligned; `AppColors.bgSecondary` fill, `AppColors.textPrimary`, `AppRadius.sm`, height 32dp, min width 48dp |
| Period dropdown options | W (Weekly) / M (Monthly) / Y (Yearly) |

### MonthNavigator
Shared widget — see SPEC-008. `showYearOnly: false` (always shows month + year here).

### IncomeExpenseToggle
| Element | Token |
|---------|-------|
| Height | 44dp |
| Background | `AppColors.bgPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Active segment | `AppColors.textPrimary`, 2dp `AppColors.brandPrimary` underline, shows total amount to the right of label |
| Inactive segment | `AppColors.textSecondary`, no underline |
| Amount display | `AppTypography.moneySmall`, same color as segment state |
| Animation | Underline slides 150ms easeInOut |

### PieChartWidget (fl_chart)
| Element | Token |
|---------|-------|
| Container height | ~300dp |
| Chart diameter | min(screenWidth * 0.7, 260dp) |
| Donut hole radius | 38% of chart radius |
| Donut hole content | Total amount `AppTypography.moneyMedium` `AppColors.textPrimary` + label "Total" `AppTypography.caption1` `AppColors.textSecondary` |
| Segment colors | Ordered palette: `#FF6B5C`, `#FF9F40`, `#FFCD56`, `#4BC0C0`, `#36A2EB`, `#9966FF`, `#FF6384`, `#C9CBCF` — cycle if >8 categories |
| Segment touch feedback | Selected segment offset: 8dp outward; 200ms easeOutCubic |
| Outer labels | Category name + percentage (`AppTypography.caption1`, `AppColors.textSecondary`); positioned radially, avoid overlap using fl_chart `PieTouchData` |
| "Other" aggregation | If more than 8 categories, categories ranked 9+ are merged into "Other" segment |
| Loading state | Skeleton circle placeholder |
| Empty state | Hollow circle with "No data" text centered |

### CategoryLegendList
| Element | Token |
|---------|-------|
| Row height | 52dp |
| Left badge | Rounded-rect 36x22dp, background = segment color, text `AppTypography.caption2` `AppColors.textOnBrand`, content = percentage (e.g. "30%") |
| Emoji + name | `AppTypography.bodyMedium` `AppColors.textPrimary`; emoji 20dp, gap `AppSpacing.sm` |
| Amount | Right-aligned `AppTypography.moneySmall` `AppColors.textPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) each side |
| Divider | 1dp `AppColors.divider` between rows |
| Tap target | Full row 52dp, min 44x44dp |

---

## States

### Default (populated)
- IncomeExpenseToggle defaults to Expense (matches reference screenshot 16)
- Period defaults to Monthly (M)
- Month defaults to current month
- Pie chart segments shown with labels
- CategoryLegendList shows all categories sorted by amount descending

### Loading
- MonthNavigator arrows disabled
- PieChartWidget: 260dp circle skeleton (`AppColors.bgTertiary`, animated shimmer)
- CategoryLegendList: 5 skeleton rows (badge, text, amount each a `AppColors.bgTertiary` rectangle)

### Empty (no transactions for selected period + type)
- PieChartWidget area: `EmptyStateView` with Phosphor `ChartPie` icon (64dp, `AppColors.textTertiary`), title "No data", subtitle "No [Income/Expense] transactions in this period."
- CategoryLegendList: hidden
- IncomeExpenseToggle: both segments show `€ 0,00`

### Error (data load failure)
- PieChartWidget area replaced by `EmptyStateView` with Phosphor `Warning` icon, title "Could not load data", subtitle "Pull down to retry."
- Pull-to-refresh triggers data reload
- Snackbar: error message with "Retry" action

---

## Interactions & Animations

### Sub-tab Switch
- Tapping Stats / Budget / Note: IndexedStack visibility change (no slide animation — instant swap); active segment color animates 150ms fade
- State (selected month, income/expense toggle, period) is preserved when switching between sub-tabs

### Period Dropdown (M ▼)
- Tap opens a compact dropdown-style bottom sheet (3 options: W / M / Y)
- Sheet height: 3 x 56dp rows + 16dp top/bottom padding
- Background: `AppColors.bgSecondary`, radius `AppRadius.xl` top corners
- Active option: `AppColors.brandPrimary` text + Phosphor `Check` icon right
- Selecting updates MonthNavigator label format:
  - W → "Week 18, 2026" (ISO week)
  - M → "Apr 2026"
  - Y → "2026"

### Income/Expense Toggle
- Tap switches active segment; chart and legend reload for selected type
- Reload triggers loading skeleton overlay on chart (300ms fade in/out)

### Month Navigation
- `<` / `>` taps: slide MonthNavigator label left/right (150ms), reload chart data
- Tapping month label: `MonthYearPicker` bottom sheet

### Pie Segment Tap
- Tapped segment offsets outward 8dp (200ms easeOutCubic)
- Corresponding legend row gets `AppColors.bgTertiary` highlight
- Navigation: `router.push('/transactions?categoryId=X&month=Y&type=expense')` — opens Daily View filtered to that category and month
- Back navigation returns to StatsScreen with same state

### Legend Row Tap
- Same navigation as pie segment tap
- Visually highlights corresponding pie segment briefly (150ms flash to offset state, then returns)

### Pull-to-refresh
- Standard `RefreshIndicator`, `AppColors.brandPrimary` color, triggers data provider invalidation

---

## Accessibility

- **Screen reader label for AppBar:** "Statistics screen"
- **Sub-tab toggle:** Each button announces "Stats tab, selected/unselected" etc.; role: tab
- **IncomeExpenseToggle:** "Income, 0 euros, tab, unselected" / "Expense, 651 euros 13 cents, tab, selected"
- **Pie chart:** The chart itself is decorative (`excludeFromSemantics: true`); the CategoryLegendList provides the accessible data equivalent. Screen reader focuses the legend directly.
- **CategoryLegendList rows:** "Restaurant, 30 percent, 198 euros 44 cents. Tap to view transactions."
- **Period button:** "Period: Monthly. Tap to change."
- **Month navigator:** See SPEC-008 accessibility notes.
- **Color contrast:** All text tokens pass WCAG AA 4.5:1 against their respective backgrounds.
- **Focus order:** AppBar title -> SubTabAndPeriodBar (left to right) -> MonthNavigator (< label >) -> IncomeExpenseToggle -> CategoryLegendList rows.
- **Dynamic Type / text scaling:** All `AppTypography` styles use relative scaling; pie chart labels truncate with ellipsis at 1.5x scale.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Single category (100% of spending) | Pie is one full segment (no donut gap at segment boundaries). Legend shows 1 row. |
| More than 8 categories | Categories 9+ merged into "Other" segment with aggregated amount and no emoji. |
| Zero-amount category | Excluded from pie and legend entirely. |
| Very small segment (<2%) | Label suppressed on chart; still appears in legend list. |
| Income selected, no income transactions | Empty state shown; pie area shows "No Income transactions this period." |
| Year period selected (Y) | MonthNavigator shows only year "2026"; `<`/`>` navigate by year. |
| Week period selected (W) | MonthNavigator shows "Week 18, 2026"; weeks that span two months use ISO week numbering. |
| Negative total (impossible for expense; defensive) | Show 0 in donut hole. |
| Currency mismatch (multi-currency accounts) | All amounts converted to main currency; footnote below chart: "Amounts converted to EUR at current rates." |

---

## New Components Required (Sprint 5)

| Component | File | Notes |
|-----------|------|-------|
| `SubTabAndPeriodBar` | `features/stats/presentation/widgets/sub_tab_and_period_bar.dart` | Stats/Budget/Note toggle + W/M/Y period selector. |
| `IncomeExpenseToggle` | `features/stats/presentation/widgets/income_expense_toggle.dart` | Two-segment toggle with amount display. Reused across BudgetView and NoteView. |
| `PieChartWidget` | `features/stats/presentation/widgets/pie_chart_widget.dart` | fl_chart wrapper with donut hole, outer labels, touch handling. |
| `CategoryLegendList` | `features/stats/presentation/widgets/category_legend_list.dart` | Scrollable list of legend rows; tapping navigates to Daily filtered view. |
| `CategoryLegendRow` | `features/stats/presentation/widgets/category_legend_row.dart` | Single row: color badge, emoji, name, amount. |
