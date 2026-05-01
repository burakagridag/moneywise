# Home Tab — Master Redlines

**Reads:** `spec.md`, `tokens.json`, per-component `redlines.md` files
**Target screen:** `lib/features/home/presentation/screens/home_screen.dart`

This document covers screen-level engineering concerns only. For per-component dimensions, colors, and typography, read the component-level `redlines.md` files.

---

## HomeScreen Widget Structure

```
Scaffold(
  backgroundColor: pageBackground,
  body: RefreshIndicator(
    color: AppColors.brandPrimary,
    onRefresh: _onRefresh,
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: HomeHeader(...)),
        SliverToBoxAdapter(child: TotalBalanceCard(...)),
        SliverToBoxAdapter(child: BudgetPulseCard(...)),
        if (insights.isNotEmpty)
          SliverToBoxAdapter(child: _ThisWeekSection(insights: insights)),
        if (transactions.isNotEmpty)
          SliverToBoxAdapter(child: _RecentSection(transactions: transactions)),
        if (transactions.isEmpty)
          SliverToBoxAdapter(child: EmptyState(...)),
        SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    ),
  ),
)
```

---

## Pull-to-Refresh Handler

```
Future<void> _onRefresh() async {
  ref.invalidate(insightsProvider);
  ref.invalidate(sparklineDataProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(budgetPulseProvider);
  ref.invalidate(totalBalanceProvider);
  // Await at least one provider to complete so the indicator dismisses
  await ref.read(totalBalanceProvider.future);
}
```

---

## Tab Focus Invalidation (ADR-011 requirement)

On each navigation back to `/home`, invalidate `insightsProvider`. Choose one approach and document it in the PR:

**Option A — transactionMutationSignalProvider**
```
// In home_screen.dart initState or build:
ref.listen(transactionMutationSignalProvider, (_, __) {
  ref.invalidate(insightsProvider);
});
```

**Option B — go_router listener**
```
// Listen to routeInformationProvider; invalidate when location == '/home'
```

Document chosen approach in `docs/prs/{pr-id}.md`.

---

## Conditional Section Rendering

```
// ThisWeekSection shown only when insights list is non-empty
final insights = ref.watch(insightsProvider);
final showInsights = insights.whenOrNull(data: (list) => list.isNotEmpty) ?? false;

// RecentSection shown only when transactions list is non-empty
final recentTxns = ref.watch(recentTransactionsProvider);
final showRecent = recentTxns.whenOrNull(data: (list) => list.isNotEmpty) ?? false;

// EmptyState shown only when transactions list is empty (ever)
final allTxns = ref.watch(allTransactionsCountProvider);
final showEmpty = allTxns.whenOrNull(data: (count) => count == 0) ?? false;
```

---

## Dynamic Type Clamping

Apply at the `HomeScreen` build method level:

```
@override
Widget build(BuildContext context) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.of(context).textScaler.clamp(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.30,
      ),
    ),
    child: _homeContent(context),
  );
}
```

---

## Reduce Motion

```
final reduceMotion = MediaQuery.of(context).disableAnimations;
// Pass to TotalBalanceCard: animateSparkline: !reduceMotion
// Pass to shimmer widgets: animate: !reduceMotion
```

---

## Page Background Color

```
final isDark = Theme.of(context).brightness == Brightness.dark;
final bgColor = isDark ? AppColors.bgPrimary : AppColors.bgPrimaryLight;
```

Applied via `Scaffold.backgroundColor`.

---

## Loading Strategy

Show each component's shimmer independently as soon as its provider state is `AsyncLoading`. Do not gate the entire screen behind a single loading state. This allows progressive rendering: header and balance card appear first (typically cached), insights and recent appear once fetched.

---

## Empty State Card Auto-Dismiss Logic

Track completion in a local `StateProvider<Set<String>>` (or existing `UserSettings` if a `completedOnboardingSteps` field exists). On each Home build, derive which cards to show:

```
final completedSteps = ref.watch(onboardingStepsProvider);
final showAddTxCard     = !completedSteps.contains('add_transaction');
final showAccountsCard  = !completedSteps.contains('setup_accounts');
final showBudgetCard    = !completedSteps.contains('set_budget');
```

Conditions for auto-dismiss:
- `add_transaction`: `allTransactionsCount > 0`
- `setup_accounts`: `userAccountsCount > 1` (default account always exists)
- `set_budget`: `currentMonthBudget != null && currentMonthBudget > 0`

When all three are dismissed, `showEmpty = false` and full Home tab renders.

---

## No New AppColors Tokens

All widget-local color constants are confined to their respective widget files. `AppColors` must not be modified as part of this epic.

---

## Component Redline Cross-References

| Component | Redlines file |
|-----------|--------------|
| HomeHeader | `home-header/redlines.md` |
| TotalBalanceCard | `total-balance-card/redlines.md` |
| BudgetPulseCard | `budget-pulse-card/redlines.md` |
| InsightCard | `insight-card/redlines.md` |
| RecentTransactionsList | `recent-transactions/redlines.md` |
