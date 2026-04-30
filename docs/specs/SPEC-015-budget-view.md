# SPEC-015: Budget View (Stats Screen — Budget Sub-tab)

**Sprint:** 5
**Related:** US-Budget (Sprint 5)
**Reference:** SPEC.md Section 9.3.5, Reference screenshot 15
**Parent scaffold:** StatsScreen (SPEC-014)
**Route:** `/stats` (Budget sub-tab active)
**Component:** `lib/features/stats/presentation/screens/budget_view.dart`

---

## Purpose

BudgetView, StatsScreen'in "Budget" sub-tab'inda gorunur. Kullaniciya secili ay icin toplam butce durumunu ozet kart uzerinde, kategori bazli ilerleme cubuklu listede sunar. Bir "Budget Setting >" baglantisi araciligiyla BudgetSettingScreen'e navigasyon saglar. Carry-over aktifse etkin butce tutari onceki ay kalintilarini yansitir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│            Stats                     56dp   │  <- AppBar (StatsScreen'den)
├─────────────────────────────────────────────┤
│  [Stats][Budget][Note]         [M ▼]  48dp  │  <- SubTabAndPeriodBar (Budget aktif)
├─────────────────────────────────────────────┤
│  [<]      Apr 2026              [>]   48dp  │  <- MonthNavigator
├─────────────────────────────────────────────┤
│  Income  €0,00  │  Exp.  €651,13      44dp  │  <- IncomeExpenseToggle
├─────────────────────────────────────────────┤
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │ Remaining (Monthly)  Budget Setting > │  │  <- BudgetSummaryCard (expanded)
│  │ € 0,00                               │  │
│  │                                       │  │
│  │  [Monthly]  ─────────────  [Today▾]  │  │
│  │  € 0,00     ░░░░░░░░░░░░   0%        │  │
│  │  (spent)    (progress bar) (budget)   │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ [emoji] Restaurant                   │   │  <- CategoryBudgetRow
│  │         ██████░░░░░  €198 / €300     │   │
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Groceries                    │   │
│  │         ████████░░░  €163 / €200     │   │
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Transport                    │   │
│  │         ██████████  €120 / €100  !!  │   │  <- Over-budget (error color)
│  ├──────────────────────────────────────┤   │
│  │ [emoji] Health                       │   │
│  │         ██░░░░░░░░   €85 / €400     │   │
│  └──────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│  [Banner Ad — 50dp, free tier]              │
└─────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
BudgetView (ConsumerWidget)
└── SingleChildScrollView
    └── Column
        ├── BudgetSummaryCard
        │   ├── Header row: "Remaining (Monthly)" label + "Budget Setting >" link
        │   ├── Remaining amount display
        │   ├── Period label ("Monthly")
        │   ├── BudgetProgressBar (with Today indicator)
        │   └── Three-column footer: spent / bar / budget total
        └── CategoryBudgetList
            └── List<CategoryBudgetRow>
                ├── Leading: CategoryIcon (emoji, 40dp)
                ├── Center: category name + progress bar + spent/budget label
                └── (Optional) over-budget warning indicator
```

---

## Token Specs

### BudgetSummaryCard
| Element | Token |
|---------|-------|
| Background | `AppColors.bgSecondary` |
| Border radius | `AppRadius.lg` (16dp) |
| Margin | `AppSpacing.lg` (16dp) horizontal, `AppSpacing.md` (12dp) vertical |
| Padding | `AppSpacing.lg` (16dp) all sides |
| "Remaining (Monthly)" label | `AppTypography.subhead`, `AppColors.textSecondary` |
| "Budget Setting >" link | `AppTypography.subhead`, `AppColors.brandPrimary`; right-aligned; tap navigates to BudgetSettingScreen |
| Remaining amount | `AppTypography.title1` (28dp w700), `AppColors.textPrimary` when remaining > 0; `AppColors.error` when remaining <= 0 |
| Period label | `AppTypography.caption1`, `AppColors.textSecondary` |
| Progress bar height | 8dp |
| Progress bar background | `AppColors.bgTertiary` |
| Progress bar fill color thresholds | 0–69%: `AppColors.brandPrimary`; 70–99%: `AppColors.warning`; >=100%: `AppColors.error` |
| Progress bar radius | `AppRadius.pill` |
| Today indicator | Vertical 2dp line, `AppColors.textSecondary`, positioned at ratio = (today_day / days_in_month) along bar width |
| Today label | "Today" `AppTypography.caption2` `AppColors.textSecondary` above indicator line |
| Three-column footer | Left: spent label `AppTypography.footnote` `AppColors.textSecondary` + amount `AppTypography.moneySmall` `AppColors.expense`; Center: progress bar; Right: budget total `AppTypography.footnote` `AppColors.textSecondary` + amount `AppTypography.moneySmall` `AppColors.textPrimary` |

### CategoryBudgetRow
| Element | Token |
|---------|-------|
| Row height | 72dp (to accommodate icon + two-line content) |
| Background | `AppColors.bgSecondary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Leading icon container | 40x40dp, `AppColors.bgTertiary` fill, `AppRadius.sm` (6dp) radius; emoji centered at 22dp font size |
| Gap: icon to text | `AppSpacing.md` (12dp) |
| Category name | `AppTypography.bodyMedium`, `AppColors.textPrimary` |
| Progress bar height | 4dp, below name, full available width |
| Progress bar fill thresholds | Same as summary card: brand (<70%) / warning (70-99%) / error (>=100%) |
| Spent / budget label | `AppTypography.caption1`; spent portion `AppColors.textSecondary`; slash `AppColors.textTertiary`; budget portion `AppColors.textSecondary` |
| Over-budget indicator | Phosphor `WarningCircle` icon 16dp `AppColors.error`, right-aligned, shown only when ratio >=100% |
| No-budget row | Progress bar and label replaced by `AppTypography.caption1` `AppColors.textTertiary` "No budget set" — row still shown if category has spending |
| Divider | 1dp `AppColors.divider` between rows, inset 56dp from left (after icon) |
| Tap target | Full 72dp row |
| Tap action | Opens BudgetEditModal (see SPEC-017) pre-filled for this category |

### List Container
| Element | Token |
|---------|-------|
| Background | `AppColors.bgSecondary` |
| Border radius | `AppRadius.lg` (16dp) |
| Margin | `AppSpacing.lg` (16dp) horizontal, `AppSpacing.sm` (8dp) vertical |
| Clip behavior | `Clip.hardEdge` to respect border radius |

---

## States

### Loading
- BudgetSummaryCard: replaced by a 120dp skeleton rectangle (`AppColors.bgTertiary`, shimmer)
- CategoryBudgetList: 4 skeleton rows, each 72dp with grey rectangles for icon, name bar, progress bar

### Empty (no budgets configured)
- BudgetSummaryCard shows:
  - Remaining: "—"
  - Progress bar: empty fill (`AppColors.bgTertiary` only)
  - "Budget Setting >" link visible and prominent
- CategoryBudgetList replaced by `EmptyStateView`:
  - Icon: Phosphor `PiggyBank` (64dp, `AppColors.textTertiary`)
  - Title: "No budgets set"
  - Subtitle: "Tap 'Budget Setting' to configure monthly limits per category."
  - CTA button: "Set Up Budgets" (primary `AppButton`) → navigates to BudgetSettingScreen

### Populated (default)
- Summary card shows remaining = total budget - total spent
- Category list shows all expense categories that have either a budget or spending in the period
- Categories with no spending AND no budget are hidden

### Over-budget (partial)
- Categories where spent >= budget: progress bar fills entirely with `AppColors.error`, `WarningCircle` icon shown
- Summary card remaining amount shown in `AppColors.error`
- No blocking behaviour — user can still navigate normally

### Error (data load failure)
- Both card and list replaced by `EmptyStateView` with `Warning` icon
- Snackbar "Could not load budget data" with Retry action

---

## Interactions & Animations

### "Budget Setting >" Link Tap
- Navigates to BudgetSettingScreen: `router.push('/more/budget-setting')`
- On return, BudgetView data refreshes automatically via reactive Riverpod provider

### CategoryBudgetRow Tap
- Opens `BudgetEditModal` (SPEC-017 bottom sheet) for that specific category
- Modal pre-fills existing budget amount if one exists
- On save, row updates reactively without full screen reload

### Month Navigation
- Same as StatsScreen (SPEC-014): `<` / `>` navigate months, label updates, data reloads
- Carry-over: if `carryOverEnabled` is true in settings, effective budget for the month = configured budget + carry-over from previous month. Displayed in summary card with a footnote: "Includes €XX carry-over from Mar 2026"

### Income / Expense Toggle
- Budget view is expense-focused; switching to Income in `IncomeExpenseToggle` shows income categories and any income budgets configured
- If no income budgets: empty state specific to income "No income budgets set"

### Period Dropdown (W / M / Y)
- Changing period recalculates budget aggregates:
  - W: weekly budget prorated from monthly (monthly / weeks_in_month)
  - Y: annual budget (monthly * 12)
- Summary card period label updates: "Weekly" / "Monthly" / "Yearly"

### Pull-to-refresh
- Standard `RefreshIndicator`, triggers budget data provider invalidation

### Progress Bar Animation
- On initial load: bar fills from 0 to current ratio over 600ms with `easeOutCubic`
- On data update: bar animates from previous ratio to new ratio over 300ms

---

## Carry-over Display

When `carryOverEnabled` (from Settings) is true:
- Effective budget = configured amount + unspent amount from previous period
- Display: "€ 850,00 effective budget (€ 800 + €50 carry-over)"
- Carry-over amount shown in a secondary line below the main budget amount in the summary card, `AppTypography.caption1` `AppColors.textTertiary`

---

## Accessibility

- **Screen reader label for summary card:** "Budget summary. Remaining this month: 0 euros. You have spent 651 euros 13 cents of your budget. Budget Setting button."
- **Progress bar:** `Semantics` with label "Budget progress: 0 percent" (or appropriate value). Not reliant on color alone — percentage text always present.
- **CategoryBudgetRow:** "Restaurant category. Spent 198 euros of 300 euro budget. 66 percent used. Tap to edit budget."
- **Over-budget row:** "Transport category. Over budget. Spent 120 euros, budget was 100 euros. Tap to edit budget."
- **"Budget Setting >" link:** Minimum 44x44dp tap target. Announced as "Budget Setting, link."
- **Color:** Progress bar color change (brand/warning/error) is supplemented by the over-budget `WarningCircle` icon — never color alone.
- **Focus order:** BudgetSummaryCard -> "Budget Setting >" -> CategoryBudgetRow (top to bottom) -> bottom tab.
- **Dynamic Type:** Category names truncate with ellipsis at 1.5x scale; amounts wrap to second line only if needed.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Total budget = 0 (budget not set) | Summary card shows "—" for remaining and budget; progress bar empty; "No budget set" placeholder instead of 0%. |
| Spent = 0, budget > 0 | Progress bar empty fill; spent label "€ 0,00 / € X,XX". |
| Carry-over produces larger budget than configured | Effective budget displayed; progress ratio uses effective budget as denominator. |
| Category deleted after budget set | Budget row hidden; orphaned budget record not shown (filter at query layer). |
| More categories than fit on screen | List scrolls; no max category count. |
| Period = Weekly, month mid-way | Weekly budget = monthly budget / weeks; fractional weeks rounded to nearest integer. |
| Period = Yearly | Annual budget = monthly * 12; annual spent = sum of all months in year. |
| Remaining is negative | Shown in `AppColors.error`; prefix "-" symbol. |
| Multiple currencies | All converted to main currency; footnote shown below summary card. |

---

## New Components Required (Sprint 5)

| Component | File | Notes |
|-----------|------|-------|
| `BudgetSummaryCardExpanded` | `features/stats/presentation/widgets/budget_summary_card_expanded.dart` | Full stats-screen version of the budget card. Distinct from `BudgetSummaryCard` in COMPONENTS.md (which is the compact Summary View card). |
| `CategoryBudgetRow` | `features/stats/presentation/widgets/category_budget_row.dart` | 72dp row with icon, name, progress bar, spent/budget amounts, over-budget indicator. |
| `CategoryBudgetList` | `features/stats/presentation/widgets/category_budget_list.dart` | Container managing the list of `CategoryBudgetRow` items, with rounded card wrapper. |
| `BudgetProgressBar` | `core/widgets/budget_progress_bar.dart` | Reusable progress bar with threshold color logic and Today indicator. Used in both BudgetView and BudgetSettingScreen. |
