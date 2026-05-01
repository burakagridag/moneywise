# ADR-011: InsightProvider Interface Design

## Status
Accepted — 2026-05-01 (Sponsor approved with pull-to-refresh, tab-focus invalidation, and first-month fallback addenda)

## Context
Epic 8 adds an "Insights" section to the Home Tab. V1 ships four hard-coded
rule-based insights (Concentration, Savings Goal, Daily Overpacing, Big
Transaction). The Product Sponsor requires that the architecture is designed
so a future V2 AI-driven insight engine can slot in behind the same interface
without any UI changes.

The core design constraint is: **the UI must not know which provider is active.**

### What an "insight" is
An insight is a short, actionable observation derived from the user's recent
financial data. Examples:
- "Food & Dining is 62 % of your spending this month — higher than last month."
- "You're on track to overspend by €120 at today's daily rate."

Each insight has a severity (info / warning / critical), a headline, a body, and
an optional deep-link action (e.g., navigate to the Budget screen).

### Where the interface and models should live
Features in this codebase follow the `features/<name>/domain/` pattern for
pure business logic (entities, use cases, interfaces). Insights are a distinct
feature; their domain layer must not import from `features/transactions/` or
`features/budget/` directly — those are injected via `InsightContext`.

Proposed location: `lib/features/insights/domain/`.

### What `InsightContext` must contain
The rule engine needs enough data to evaluate all four V1 rules without
querying the database itself:

| Field | Source |
|---|---|
| `currentMonthTransactions` | `TransactionDao.watchTransactionsByMonth` |
| `previousMonthTransactions` | `TransactionDao.getTransactionsByMonth` |
| `currentMonthBudgets` | `BudgetRepository.watchBudgetsForMonth` |
| `effectiveBudget` | `effectiveBudgetProvider` (ADR-010) |
| `referenceDate` | provided by caller (facilitates testing with fixed dates) |

`InsightContext` is a plain immutable Dart class (no Drift types; entities only),
ensuring the domain layer has zero data-layer imports.

### V1 rules
1. **ConcentrationRule** — top category > 50 % of total spending.
2. **SavingsGoalRule** — net (income − expense) < 10 % of income (configurable
   threshold from `UserSettings` in a future sprint; hard-coded for V1).
3. **DailyOverpacingRule** — current daily burn rate × remaining days >
   remaining budget.
4. **BigTransactionRule** — any single transaction > 30 % of monthly budget.

Each rule is a separate class implementing a `InsightRule` interface. The
`RuleBasedInsightProvider` collects all rules and runs them in order.

### Riverpod integration options

**Option A — `Provider<InsightProvider>`**
Synchronous provider; the implementation receives a pre-built `InsightContext`
snapshot. Caller is responsible for assembling the context asynchronously.

Cons: The `InsightContext` assembly is async (needs DB queries); a synchronous
`Provider` would force the caller to block or maintain stale data.

**Option B — `FutureProvider<List<Insight>>`**
The provider assembles `InsightContext` internally, awaits all data, then calls
`insightProvider.generate(context)`. Returns `AsyncValue<List<Insight>>`.

Pros: Standard pattern in this codebase; `AsyncValue` gives loading/error for
free; the UI watches a single provider.

Cons: Re-runs the whole chain on any dependency change; no streaming.

**Option C — `StreamProvider<List<Insight>>`**
Watches the underlying `watchTransactionsByMonth` stream; re-evaluates rules
whenever the DB emits. Pure reactive pipeline.

Pros: Automatically re-evaluates when transactions change (e.g., user adds a
transaction while Home Tab is open).
Cons: More complex composition; budget and previous-month data are `Future`s,
not streams, requiring `asyncExpand` / `switchMap` to combine.

## Decision
Use **Option B — `FutureProvider<List<Insight>>`** for V1.

The provider assembles a complete `InsightContext` from three async sources
(current transactions, previous transactions, budgets) using `ref.watch` on
existing Riverpod providers, then calls `insightProvider.generate(context)`.

`InsightProvider` is an **abstract class** injected into the Riverpod graph via
`insightProviderInstanceProvider` (`Provider<InsightProvider>`). V1 binds
`RuleBasedInsightProvider` at the app root. V2 replaces the binding via a single
`overrideWith` without touching the `FutureProvider` or any UI.

### File layout
```
lib/features/insights/
├── domain/
│   ├── insight.dart                  -- Insight entity + InsightSeverity enum
│   ├── insight_context.dart          -- InsightContext value class
│   ├── insight_provider.dart         -- abstract class InsightProvider
│   ├── insight_rule.dart             -- abstract class InsightRule
│   └── rules/
│       ├── concentration_rule.dart
│       ├── savings_goal_rule.dart
│       ├── daily_overpacing_rule.dart
│       └── big_transaction_rule.dart
├── data/
│   └── rule_based_insight_provider.dart  -- RuleBasedInsightProvider
└── presentation/
    └── providers/
        └── insights_providers.dart   -- insightProviderInstanceProvider
                                      -- insightsProvider (FutureProvider)
    insights.dart                     -- public barrel
```

### Interface definitions
```dart
// lib/features/insights/domain/insight.dart
enum InsightSeverity { info, warning, critical }

class Insight {
  const Insight({
    required this.id,
    required this.severity,
    required this.headline,
    required this.body,
    this.actionRoute,
  });

  final String id;
  final InsightSeverity severity;
  final String headline;
  final String body;
  final String? actionRoute;  // go_router path; null = no CTA
}

// lib/features/insights/domain/insight_provider.dart
abstract class InsightProvider {
  List<Insight> generate(InsightContext context);
}

// lib/features/insights/domain/insight_rule.dart
abstract class InsightRule {
  /// Returns an [Insight] if the rule fires, or null if the condition is not met.
  Insight? evaluate(InsightContext context);
}
```

### Riverpod wiring
```dart
// insightProviderInstanceProvider — swappable binding
@riverpod
InsightProvider insightProviderInstance(InsightProviderInstanceRef ref) {
  return RuleBasedInsightProvider(rules: [
    ConcentrationRule(),
    SavingsGoalRule(),
    DailyOverpacingRule(),
    BigTransactionRule(),
  ]);
}

// insightsProvider — assembles context, calls generate()
@riverpod
Future<List<Insight>> insights(InsightsRef ref) async {
  final now = DateTime.now();
  final provider = ref.watch(insightProviderInstanceProvider);

  // Watch reactive sources
  final currentTxns = await ref.watch(
    transactionsByMonthProvider(now.year, now.month).future,
  );
  final budgets = await ref.watch(
    budgetsForMonthProvider(now).future,
  );
  final effectiveBudget = await ref.watch(
    effectiveBudgetProvider(now).future,
  );

  // One-shot fetch for previous month (not reactive — acceptable for insights)
  final prevMonth = DateTime(now.year, now.month - 1);
  final repo = ref.watch(transactionRepositoryProvider);
  final prevTxns = await repo.getTransactionsByMonth(
    prevMonth.year,
    prevMonth.month,
  );

  final context = InsightContext(
    currentMonthTransactions: currentTxns,
    previousMonthTransactions: prevTxns,
    currentMonthBudgets: budgets,
    effectiveBudget: effectiveBudget,
    referenceDate: now,
  );

  return provider.generate(context);
}
```

## Consequences

### Positive
- UI is fully decoupled from the insight engine; V2 AI provider is a drop-in
  `overrideWith` at app startup.
- Each `InsightRule` is independently unit-testable with a synthetic
  `InsightContext` — no DB required.
- `RuleBasedInsightProvider` is also testable: pass a list of mock rules.
- `FutureProvider` + `AsyncValue` give the UI a standard loading/error/data
  pattern consistent with the rest of the app.
- No new dependencies.

### Negative
- `insightsProvider` is a `FutureProvider`, not a `StreamProvider`: it does not
  automatically re-evaluate when the user adds a transaction on the Home Tab.
  The provider will refresh on the next `ref.invalidate` or navigation event.
  This is acceptable for V1; upgrade to `StreamProvider` if real-time refresh
  is required.
- Previous-month transactions are fetched with a one-shot `Future` rather than
  being watched; a background sync in a future sprint could cause them to be
  stale. This is documented as a known limitation.

### Flutter Engineer implementation notes
- `InsightContext` must only use domain entity types (`TransactionEntity`,
  `BudgetWithSpending`) — never raw Drift table types. Map at the repository
  layer.
- Each `InsightRule.evaluate()` must be pure and side-effect-free; no async, no
  I/O.
- `RuleBasedInsightProvider.generate()` iterates rules, calls `evaluate()`,
  filters nulls, and returns the list. Order of rules in the constructor
  determines display order.
- `InsightSeverity` drives the card accent color via `AppColors` — do not
  hard-code colors in the widget.
- The `actionRoute` field uses go_router path strings (e.g., `'/budget'`).
  The Home Tab widget calls `context.go(insight.actionRoute!)` only after a
  `mounted` check.
- Tests must inject `InsightProvider` via `ProviderContainer.overrideWith` —
  never instantiate `RuleBasedInsightProvider` directly in widget tests.
- The `id` field on `Insight` must be stable across re-evaluations (use a
  constant string per rule, e.g., `'concentration'`) so the UI can apply keyed
  animations.

## Reactive Behaviour — V1 Compensating Mechanisms

`insightsProvider` is a `FutureProvider` and does not automatically re-evaluate
when transactions change. The Sponsor accepted this limitation for V1 with two
mandatory compensating mechanisms:

### 1. Pull-to-Refresh
The Home Tab must wrap its scrollable content in a `RefreshIndicator`. On drag-to-
refresh, the widget calls `ref.invalidate(insightsProvider)` (and
`ref.invalidate(sparklineDataProvider)` for consistency). This gives the user an
explicit refresh gesture.

### 2. Tab Focus Invalidation
When the user navigates back to the Home Tab after a transaction mutation
(add / edit / delete), `insightsProvider` must be invalidated so it re-fetches
on the next build. Implementation options (Flutter Engineer chooses):
- Listen to the go_router `RouteInformationProvider` and invalidate on route
  change back to `/home`.
- Use a `WidgetsBindingObserver` or a Riverpod `Listener` on
  `transactionMutationSignalProvider` (a simple `StateProvider<int>` incremented
  on any mutation).

The chosen approach must be documented in the PR description.

V2 upgrade path: replace `FutureProvider` with `StreamProvider` + `asyncExpand`
once per-route reactive refresh is insufficient. A dedicated ADR-013 must be
written at that point.

## First-Month Fallback Behaviour

When `InsightContext.previousMonthTransactions` is empty (new user or first month
of app use), each rule must degrade gracefully rather than divide by zero or
surface a misleading insight.

| Rule | Previous-month data absent | Behaviour |
|---|---|---|
| **ConcentrationRule** | Not needed — current month only | No change |
| **SavingsGoalRule** | Savings rate calculated from current month only | Fire if data sufficient; suppress if income = 0 |
| **DailyOverpacingRule** | Not needed — current month only | Suppress if `effectiveBudget` is null |
| **BigTransactionRule** | Not needed — current month only | Suppress if `effectiveBudget` is null |

General principle: **a rule must return `null` (no insight) rather than crash or
show incorrect data** when any required input is absent or zero. This is enforced
by unit tests.

### Mandatory edge-case unit tests (per rule)

Each `InsightRule` implementation must include test cases for:
- Empty `currentMonthTransactions` list → returns `null`
- `effectiveBudget` is `null` (for rules that depend on it) → returns `null`
- `previousMonthTransactions` is empty (for `SavingsGoalRule`) → rule fires
  using current-month income only, or returns `null` if income = 0
- Division-by-zero guard: income = 0, budget = 0, daysInMonth = currentDay

Flutter Engineer must add a `// EDGE CASE` comment above each guard clause for
reviewability.

## Alternatives Rejected
- **StreamProvider**: better real-time behaviour but complex `asyncExpand`
  composition for mixed stream/future sources; deferred to V2.
- **Single monolithic function (no abstract class)**: prevents V2 AI swap
  without UI changes — violates the Sponsor's explicit requirement.
- **Placing InsightProvider in `core/`**: insights are a feature, not an
  infrastructure concern; `features/insights/domain/` is the correct layer.

## References
- ADR-001: Riverpod state management patterns
- ADR-010: `effectiveBudgetProvider` (global budget / fallback)
- Existing budget providers: `lib/features/budget/presentation/providers/budget_providers.dart`
- Clean Architecture layers: SPEC.md Section 4
