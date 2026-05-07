# ADR-013: Insight Rule Engine — Static Rule List (V1)

## Status
Accepted — 2026-05-02

## Context
Epic 8a delivered the Home Tab scaffold: an `InsightCard` widget and
`insightsProvider` (`FutureProvider<List<Insight>>`) wired to a
`RuleBasedInsightProvider` that currently holds an empty rule list. The interface
contract (`InsightRule`, `InsightContext`, `InsightProvider`) was established in
ADR-011.

Epic 8b must fill that empty list with real rules. Before implementation begins,
this ADR records the architectural choices governing how rules are structured,
registered, and evaluated.

### The question
Given the `InsightRule` interface is already defined, the Sprint 8b decision is
specifically about:

1. How rules are registered into `RuleBasedInsightProvider` — static (Dart
   compile-time) vs. dynamic (runtime registration, plugin pattern, remote
   config).
2. How many results are shown — unlimited vs. top-N capped.
3. What the five V1 rules are and what triggers each one.
4. Whether a 5th rule slot is deferred, stubbed, or filled.

### Forces
- V1 must ship quickly; over-engineering is a known risk.
- The `InsightProvider` abstraction (ADR-011) already provides the V2 swap path
  (AI engine via `overrideWith`). No further extensibility mechanism is needed
  inside the rule engine for V1.
- Remote config and runtime rule toggling are explicitly out of scope (V1 has no
  backend).
- The Product Sponsor requested exactly four named rules; a fifth slot was
  acknowledged as TBD. Leaving it as a clearly named stub with `return null` is
  preferable to shipping a rule with poorly-defined semantics.

## Decision
The V1 insight rule engine uses a **static, compile-time rule list**. Rules are
plain Dart classes registered as constructor arguments to
`RuleBasedInsightProvider` inside `insightProviderInstanceProvider`. No plugin
system, no runtime registration API, no remote config.

`RuleBasedInsightProvider.generate()` evaluates all registered rules in
declaration order, filters null results, and sorts by severity
(`critical → warning → info`). There is no top-N cap in V1; the Home Tab widget
controls visibility by hiding the insights section when the list is empty.

The fifth rule is registered as `FifthRulePlaceholder` (`return null`) for Sprint 8b and will be named and fully implemented in Sprint 8c after the Product Sponsor confirms trigger semantics; `WeekendSpendingRule` is the leading candidate.

## Interface Contract

```dart
// lib/features/insights/domain/insight_rule.dart
abstract class InsightRule {
  /// Returns an [Insight] if the rule condition is met, or null if the
  /// condition is not met or required data is absent/invalid.
  ///
  /// Must be pure — no side effects, no async, no I/O.
  /// Must never throw — return null on any edge case.
  Insight? evaluate(InsightContext context);
}

// lib/features/insights/domain/insight_context.dart
class InsightContext {
  const InsightContext({
    required this.currentMonthTransactions,  // List<Transaction>
    required this.previousMonthTransactions, // List<Transaction> — may be empty
    required this.currentMonthBudgets,       // List<BudgetWithSpending>
    required this.effectiveBudget,           // double? — null when unconfigured
    required this.referenceDate,             // DateTime — injected for testability
  });
  // ... fields as defined in insight_context.dart
}
```

`InsightContext` contains only domain entity types (`Transaction`,
`BudgetWithSpending`) — zero Drift table imports. Data assembly is the
responsibility of `insightsProvider` in the presentation layer.

## V1 Rule Registry

Rules are registered in this priority order inside `insightProviderInstanceProvider`.
`RuleBasedInsightProvider` evaluates them left-to-right; the severity sort
determines final display order in the UI.

| # | Class | Stable ID | Trigger condition | Severity | Budget dependency |
|---|-------|-----------|-------------------|----------|-------------------|
| 1 | `ConcentrationRule` | `'concentration'` | Top expense category > 70% of total monthly spend (expense transactions only; income and transfers excluded) | `warning` | No |
| 2 | `SavingsGoalRule` | `'savings_goal'` | `context.referenceDate.day >= 5` AND `(income − expense) / income` < 10% (V1: fixed threshold; early-month suppression prevents false alarms on days 1–4 before meaningful income/expense data accumulates; user-configurable savings goal is V1.x scope) | `warning` | No |
| 3 | `DailyOverpacingRule` | `'daily_overpacing'` | `context.referenceDate.day >= 5` AND **`remainingBudget > 0`** AND `dailyBurnRate * remainingDays > remainingBudget` | `critical` | Yes — suppress when `effectiveBudget` is null or `remainingBudget <= 0` |
| 4 | `BigTransactionRule` | `'big_transaction'` | Any single expense transaction > 30% of effective budget, **only for categories that have an active budget** (unbudgeted categories: rule returns null). Body wording (≤100% case): `'Large transaction: {formattedAmount} ({pct}% of budget)'` where formattedAmount is a locale-aware currency string provided via `InsightContext.formatAmount` callback (e.g., '700,00 €' in DE locale). When ratio > 100%: `'Single transaction larger than your monthly budget'`. | `warning` | Yes — suppress when `effectiveBudget` is null |
| 5 | `WeekendSpendingRule` | `'weekend_spending'` | `weekendDailyAvg > weekdayDailyAvg * 2.0` where weekendDailyAvg = total Sat/Sun expense ÷ distinct weekend days with expense, weekdayDailyAvg = total Mon–Fri expense ÷ distinct weekday days with expense. Guards: `totalMonthlyIncome > 0`, `weekendDayCount >= 2`, `weekdayDayCount >= 3`, `weekdayDailyAvg > 0`. Headline: `"Weekend spending high"` / `"Hafta sonu harcaması yüksek"`. Body: `"Weekend {pct}% above weekday."` / `"Hafta sonu hafta içinden %{pct} yüksek."` (revised 2026-05-07: shortened from original approved wording to fit InsightCard maxLines=1). | `warning` | No |

### Threshold constants
Each rule exposes its threshold as a named `static const` so tests can reference
it without magic numbers:

```dart
class ConcentrationRule implements InsightRule {
  static const double threshold = 0.70; // 70 % — top category concentration
  static const String id = 'concentration';
  // Total monthly spend = SUM of expense transactions in the current month
  // (income and transfers excluded).
  // ...
}

class SavingsGoalRule implements InsightRule {
  // V1: fixed 10% threshold; user-configurable savings goal is V1.x scope.
  // Insight message: "Saving less than 10% this month"
  static const double threshold = 0.10; // 10 %
  static const int minimumDayOfMonth = 5; // suppress before day 5 (same rationale as DailyOverpacingRule)
  static const String id = 'savings_goal';
  // ...
}

class DailyOverpacingRule implements InsightRule {
  static const String id = 'daily_overpacing';
  // Fires only when ALL conditions are true:
  //   context.referenceDate.day >= 5   (suppresses false positives on day 1-4)
  //   remainingBudget > 0   ← NEW: suppress when budget already exhausted
  //   dailyBurnRate * remainingDays > remainingBudget
  // ...
}

class BigTransactionRule implements InsightRule {
  static const double threshold = 0.30; // 30 %
  static const String id = 'big_transaction';
  // Only triggers for transactions whose category has an active budget.
  // If the transaction's category is unbudgeted, the rule returns null.
  // ...
}

class FifthRulePlaceholder implements InsightRule {
  static const String id = 'fifth_rule_placeholder';

  @override
  Insight? evaluate(InsightContext context) => null;
}
```

### Registration (Sprint 8b target state)

```dart
@riverpod
InsightProvider insightProviderInstance(InsightProviderInstanceRef ref) {
  return const RuleBasedInsightProvider(rules: [
    ConcentrationRule(),
    SavingsGoalRule(),
    DailyOverpacingRule(),
    BigTransactionRule(),
    FifthRulePlaceholder(), // stub — returns null until Sprint 8c
  ]);
}
```

Adding or removing a rule in a future sprint requires only a line change in this
constructor. No changes to `RuleBasedInsightProvider`, `insightsProvider`, or any
UI widget are needed.

## Consequences

### Positive
- Zero new dependencies; leverages the abstraction already in place from ADR-011.
- Each rule is independently unit-testable with a synthetic `InsightContext` — no
  database, no widget tree, no Riverpod container required.
- Stable IDs (`'concentration'`, etc.) allow keyed UI animations and future
  per-rule dismissal without coupling widgets to class names.
- The stub `FifthRulePlaceholder` keeps the registry honest — it documents intent
  without shipping a rule with undefined semantics.

### Negative
- Threshold values (`0.70`, `0.10`, `0.30`) are hard-coded constants, not
  user-configurable. Persisting user overrides will require a `UserSettings`
  schema change and a new ADR.
- No top-N cap: if future sprints add many rules, all firing simultaneously could
  produce a noisy Home Tab. Mitigation: add a `maxInsights` parameter to
  `RuleBasedInsightProvider` before registering more than 6 rules.
- `FifthRulePlaceholder` ships as a no-op stub. It registers a stable ID and
  occupies position 5 in the list, but produces no user-visible output until
  implemented in Sprint 8c.
- The `day >= 5` guard on `SavingsGoalRule` was added during EPIC8B-02 implementation
  based on engineer judgment (same rationale as `DailyOverpacingRule`) and was not
  present in the original ADR-013 draft. The Product Sponsor accepted the logic;
  this update records it as the authoritative decision.
- `DailyOverpacingRule` does not fire when `remainingBudget <= 0` (budget already
  exhausted or exceeded). A future `OverBudgetRule` (V1.x) should surface the
  "you've exceeded your budget" state. Edge case discovered in Sprint 8b simulator
  testing (2026-05-06).

### Neutral
- Rule evaluation is O(N) where N is the number of registered rules. With 5 rules
  and O(T) inner scans (T = transactions in the month, typically < 300), this is
  negligible on device.

## Future Evolution
- **Threshold user settings (V1.x):** extract thresholds into `UserSettings`
  entity; load from DB in `InsightContext`; write a new ADR for the schema
  change.
- **FifthRulePlaceholder full implementation (Sprint 8c):** agree trigger with
  Product Sponsor; implement and remove stub comment; add unit tests.
  `WeekendSpendingRule` is the leading candidate.
- **User-configurable savings goal (V1.x):** expose the 10% savings threshold
  as a user-editable setting; requires a `UserSettings` schema change and a new ADR.
- **StreamProvider upgrade (V2):** replace `FutureProvider<List<Insight>>` with
  `StreamProvider` using `asyncExpand` over `watchTransactionsByMonth`. Requires
  a dedicated ADR. See ADR-011 §V2 upgrade path.
- **AI engine (V2):** register `AiInsightProvider` via `overrideWith` at app
  startup. The rule engine (this ADR's scope) is retired; ADR-011's interface
  contract is the only integration point.
- **Per-rule dismissal:** add a `dismissed` Set persisted in `UserSettings`;
  filter in `RuleBasedInsightProvider.generate()` before returning. No interface
  change needed.

## Alternatives Rejected

- **Plugin / registry pattern** — `InsightRule` implementations register
  themselves at startup (e.g., via a static `register()` call or a service
  locator). Rejected: unnecessary indirection for a fixed V1 set of 5 rules.
  Adding a rule still requires a code change; the registry buys nothing.
- **Remote-configurable rule thresholds** — fetch thresholds from a backend or
  Firebase Remote Config. Rejected: V1 has no backend; this is explicitly out of
  scope.
- **ML / AI suggestions** — generate insights from an on-device or cloud model.
  Rejected: out of scope for V1; the `InsightProvider` abstraction (ADR-011)
  reserves this slot for V2.
- **Single monolithic evaluate function** — one function with a chain of `if`
  statements for all rules. Rejected: untestable in isolation; adding a rule
  requires modifying the function body rather than adding a new class file.

## References
- ADR-011: `InsightProvider` interface, `InsightContext` data model, Riverpod
  wiring, first-month fallback behaviour, edge-case test requirements
- ADR-010: `effectiveBudgetProvider` (global budget / fallback)
- ADR-001: Riverpod state management patterns
- `lib/features/insights/` — current scaffold (stubs in place since Epic 8a)
- SPEC.md Section 4 (Clean Architecture layers)

### ADR Living-Document Policy (Sprint 8b)

Trigger condition changes made during implementation must be reflected in this ADR before the sprint PR is merged. PM is responsible for flagging discrepancies during sprint review. Engineers may add guards/conditions for sound technical reasons, but the change is not authoritative until it appears here and the Sponsor has been notified.

## Reviewers
- flutter-engineer (author)
- Product Sponsor (trigger conditions reviewed 2026-05-03)
