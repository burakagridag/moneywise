# Home Tab — Master Spec

**Epic:** Epic 8A — Home Tab Redesign
**Story:** EPIC8A-UX
**Status:** Design complete — ready for Flutter Engineer handoff

---

## Screen Purpose

The Home tab is the default landing screen on app launch. It surfaces the user's most critical financial information in a single scroll: total balance, budget health, rule-based insights, and recent activity. It is not a navigation hub — it is an at-a-glance summary that links to deeper screens.

---

## Tab Structure (Sponsor-approved)

`Home | Transactions | Budget | More` — 4 tabs

- Home is the default selected tab on launch
- Tab bar uses `NavigationBar` (Material 3) styled per `AppTheme`
- Active tab: `AppColors.brandPrimary` icon + label
- Inactive tab: `AppColors.textSecondaryLight` / `AppColors.textTertiary` icon + label

---

## Scroll Order (fixed — do not reorder)

1. HomeHeader
2. TotalBalanceCard
3. BudgetPulseCard
4. ThisWeekSection (InsightCards — hidden when 0 insights)
5. RecentSection (RecentTransactionsList — hidden when 0 transactions)
6. EmptyState (shown only when 0 transactions ever)

Sections 4 and 5 are conditionally rendered. Section 6 replaces sections 2–5 when the user has no transaction history.

---

## Pull-to-Refresh (mandatory per ADR-011)

The entire Home tab scroll content is wrapped in a `RefreshIndicator`. On pull-to-refresh:
- `ref.invalidate(insightsProvider)`
- `ref.invalidate(sparklineDataProvider)`
- `ref.invalidate(recentTransactionsProvider)`
- `ref.invalidate(budgetPulseProvider)`

Indicator color: `AppColors.brandPrimary`.

---

## Page Background

- Light: `AppColors.bgPrimaryLight` (#F7F6F3)
- Dark: `AppColors.bgPrimary` (#0F1117)

---

## Horizontal Scroll Padding

All cards and section content use 16dp (`AppSpacing.lg`) horizontal margin/padding. This creates a consistent visual lane on both iOS and Android.

---

## Vertical Rhythm

| Element | Top spacing | Bottom spacing |
|---------|-------------|----------------|
| HomeHeader | 8dp (from status bar) | 20dp |
| TotalBalanceCard | 0 | 12dp |
| BudgetPulseCard | 0 | 12dp |
| ThisWeekSection header | 18dp | 10dp |
| InsightCard (each) | 0 | 8dp |
| RecentSection header | 18dp | 10dp |
| RecentTransactionsList | 0 | 24dp (bottom of scroll) |

---

## Empty State Spec

**Trigger:** `transactions.isEmpty` (user has never added a transaction).

**Layout:**
```
HomeHeader (normal)
TotalBalanceCard (zero-balance placeholder state)
"GET STARTED" section header
OnboardingCard 1 — highlighted (primary tint background)
OnboardingCard 2 — outlined
OnboardingCard 3 — outlined
```

### Onboarding Cards (in order)

**Card 1 — Add your first transaction** (highlighted)
- Background: `AppColors.brandPrimaryGlow` tint — `Color(0x303D5A99)` on light / `AppColors.brandSurface` (#1E2E52) on dark
- Border: `AppColors.brandPrimary` 1dp
- Title: "Add your first transaction" — `bodyMedium`, `textPrimaryLight` / `textPrimary`
- Subtitle: "Track your income and expenses to see insights" — `caption1`, `textSecondaryLight` / `textSecondary`
- CTA button: "Add transaction" — filled, `AppColors.brandPrimary` bg, white text, `AppRadius.md` (10dp) radius, 44dp height
- Tap CTA: opens AddTransactionModal
- Auto-dismisses when user adds first transaction

**Card 2 — Set up your accounts** (outlined)
- Background: `bgElevatedLight` / `bgSecondary`
- Border: `borderLight` / `border` 1dp
- Title: "Set up your accounts" — `bodyMedium`
- Subtitle: "Cash, bank, cards" — `caption1`
- CTA link: "Manage accounts →" — `brandPrimary` text, `caption1`
- Tap: navigate to `/accounts`
- Auto-dismisses when user has at least 1 account

**Card 3 — Set a monthly budget** (outlined)
- Same structure as Card 2
- Title: "Set a monthly budget"
- Subtitle: "Stay on top of spending"
- CTA link: "Set budget →" — `brandPrimary` text, `caption1`
- Tap: navigate to `/budget`
- Auto-dismisses when user has set a budget

### Empty State Behavior
- Cards dismiss individually as their condition is satisfied (auto-dismiss only — no X button per Sponsor decision)
- When all 3 conditions met: empty state replaced with full Home tab (no animation required, simple conditional render)
- "Get started" section header disappears when all cards are dismissed

### Onboarding Card Tokens
| Element | Light | Dark |
|---------|-------|------|
| Card 1 background | `Color(0x303D5A99)` | `AppColors.brandSurface` |
| Card 1 border | `AppColors.brandPrimary` 1dp | `AppColors.brandPrimary` 1dp |
| Card 2–3 background | `AppColors.bgElevatedLight` | `AppColors.bgSecondary` |
| Card 2–3 border | `AppColors.borderLight` 1dp | `AppColors.border` 1dp |
| Card radius | `AppRadius.lg` (14dp) | `AppRadius.lg` (14dp) |
| Card padding | 16dp all sides | 16dp all sides |
| Card spacing between | 8dp | 8dp |
| CTA button height | 44dp | 44dp |
| CTA button radius | `AppRadius.md` (10dp) | `AppRadius.md` (10dp) |

---

## Accessibility — Screen Level

- Screen semantic label: "Home tab"
- Scroll view: `CustomScrollView` with `Semantics(label: 'Home tab content')`
- Pull-to-refresh: `RefreshIndicator` has default accessibility label on both platforms
- All child components declare their own semantic labels (see individual specs)
- Reduce Motion: sparkline draw animation is skipped; shimmer animation is replaced with static placeholder
- Dynamic Type: all text scales with system size, clamped at 0.85×–1.3× (enforced via `MediaQuery.textScaler.clamp`)

---

## Performance Targets (from epic spec)

- Home tab opens in <300ms with cached data
- Home tab opens in <1s with cold load
- Shimmer shown for any async operation that exceeds 150ms

---

## Component File Locations

| Component | Widget file |
|-----------|------------|
| HomeHeader | `lib/features/home/presentation/widgets/home_header.dart` |
| TotalBalanceCard | `lib/features/home/presentation/widgets/total_balance_card.dart` |
| BudgetPulseCard | `lib/features/home/presentation/widgets/budget_pulse_card.dart` |
| InsightCard | `lib/features/home/presentation/widgets/insight_card.dart` |
| RecentTransactionsList | `lib/features/home/presentation/widgets/recent_transactions_list.dart` |
| HomeScreen | `lib/features/home/presentation/screens/home_screen.dart` |

---

## State Management (per ADR-011)

- `insightsProvider` — `FutureProvider<List<Insight>>` (see ADR-011)
- `sparklineDataProvider` — `FutureProvider<List<DataPoint>>`
- `recentTransactionsProvider` — `FutureProvider<List<TransactionEntity>>`
- `budgetPulseProvider` — `FutureProvider<BudgetPulseData>`
- `totalBalanceProvider` — `FutureProvider<TotalBalanceData>`

Each provider returns `AsyncValue`; the Home tab uses `.when(data:, loading:, error:)` per standard Riverpod pattern.

---

## Open Questions

None. All design decisions resolved. No `QUESTIONS.md` needed.
