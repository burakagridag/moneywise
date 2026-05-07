# ADR-014: Sealed-Class Localization Dispatch for Insight Rules

## Status
Accepted — 2026-05-07

## Context

Sprint 8b domain rules produce `Insight` entities. The original approach embedded
English-language strings directly in `headline`/`body` fields inside each rule class. When
Turkish locale support was required, two options were attempted and rejected before the
current design was chosen:

- **Round 2** introduced `bodyParams: Map<String, dynamic>` on `Insight` to carry numeric
  parameters across the domain→presentation boundary. This was untyped and error-prone:
  the mapper had to know the key names and cast values, with no compile-time guarantee that
  a param existed or had the expected type. It was removed in Round 4.

- The domain layer must remain Flutter-free — it cannot import `AppLocalizations` or any
  Flutter SDK type. But `AppLocalizations` is only available in the presentation layer.

We therefore need a type-safe mechanism to transport the rule-specific numeric parameters
(e.g., `pct: 75`, `formattedAmount: '300,00 €'`, `exceedsBudget: false`) from the domain
rule to the presentation mapper, so the mapper can call the correct `l10n.*` method with
those parameters.

## Decision

Introduce a sealed class `InsightLocalizationData` in the domain layer
(`lib/features/insights/domain/insight_localization_data.dart`) with one concrete subclass
per V1 rule:

| Subclass | Rule | Parameters |
|---|---|---|
| `ConcentrationLocalizationData` | ConcentrationRule | `pct: int` |
| `SavingsGoalLocalizationData` | SavingsGoalRule | _(none — type tag only)_ |
| `DailyOverpacingLocalizationData` | DailyOverpacingRule | _(none — type tag only)_ |
| `BigTransactionLocalizationData` | BigTransactionRule | `pct: int`, `formattedAmount: String`, `exceedsBudget: bool` |

Each domain rule populates the `localizationData` field on the `Insight` it returns. The
presentation mapper (`insight_mapper.dart`) receives the `AppLocalizations` instance and
switches exhaustively on `InsightLocalizationData` subclasses:

```dart
return switch (data) {
  ConcentrationLocalizationData(:final pct) => (
    headline: l10n.insightConcentrationTitle,
    body: l10n.insightConcentrationBody(pct),
  ),
  SavingsGoalLocalizationData() => (
    headline: l10n.insightSavingsGoalTitle,
    body: l10n.insightSavingsGoalBody,
  ),
  DailyOverpacingLocalizationData() => (
    headline: l10n.insightDailyOverpacingTitle,
    body: l10n.insightDailyOverpacingBody,
  ),
  BigTransactionLocalizationData(:final pct, :final formattedAmount, :final exceedsBudget) => (
    headline: l10n.insightBigTransactionTitle,
    body: exceedsBudget
        ? l10n.insightBigTransactionBodyExceeds
        : l10n.insightBigTransactionBody(formattedAmount, pct),
  ),
};
```

When `localizationData` is `null` (e.g. `FifthRulePlaceholder` or any future rule added
before its mapper branch is written), the mapper falls back to the English `headline`/`body`
strings already present on the `Insight` entity — no crash, no missing translation.

## Consequences

### Positive

- **Domain stays Flutter-free.** `InsightLocalizationData` is pure Dart with no Flutter
  SDK imports. Rules can be tested without a Flutter test harness.
- **Compile-time exhaustiveness.** Dart's sealed-class exhaustiveness checker enforces that
  every subclass has a corresponding `switch` case in the mapper. Adding a new rule without
  a mapper branch produces a compile error, not a silent runtime fallback.
- **No string-equality coupling.** The mapper does not key on `insight.id` string constants
  to dispatch l10n — it keys on the type. Renaming a rule id does not break translations.
- **Type-safe parameter access.** Named fields on each subclass (`:final pct`) replace the
  untyped `Map<String, dynamic>` from Round 2. The compiler verifies field existence and type.
- **Safe fallback for future rules.** A rule that sets `localizationData: null` automatically
  falls back to its English strings; the presentation layer never crashes on an unknown subclass.

### Negative

- **Boilerplate per rule.** Every new rule requires a new subclass, even if it carries no
  parameters (empty subclasses act as type tags for exhaustiveness).
- **build_runner step required.** If `freezed` annotations are added to subclasses in the
  future, a code-gen step is needed. Currently subclasses are plain Dart (`const`
  constructors, no code-gen).
- **Presentation layer owns `AppLocalizations`.** The mapper is in
  `features/insights/presentation/` — it cannot be unit-tested without a Flutter test
  environment that can resolve `AppLocalizations.delegate.load(Locale('tr'))`. This is
  acceptable: mapper tests use `AppLocalizations.delegate.load()` directly (no widget pump
  needed), keeping them fast.

## Alternatives Rejected

### (a) Mapper keyed on `insight.id` string

The mapper would `switch (insight.id)` and cast parameters from a generic payload. This
approach has no compile-time guarantee: a new rule can be added without updating the mapper
and the code will still compile — silently producing English strings in a Turkish UI or
crashing on a cast. Rejected in Round 4.

### (b) `bodyParams: Map<String, dynamic>` (Sprint 8b Round 2)

Untyped key-value bag on `Insight`. The mapper called `params['pct'] as int` with no
compile-time verification. A renamed key or wrong type caused a runtime `CastError`.
Removed in Round 4 and superseded by this ADR.

### (c) Separate l10n resolver in domain

Passing an `AppLocalizations`-equivalent interface into the domain rules would violate the
Flutter-free constraint, require a domain-layer abstraction of every string method, and add
significant maintenance overhead. Rejected.

## References

- ADR-013: Insight Rule Engine — rule registry, `InsightContext`, severity-sort contract
- ADR-011: InsightProvider Interface — swappable provider binding, `ProviderContainer` override
- `lib/features/insights/domain/insight_localization_data.dart` — sealed class implementation
- `lib/features/insights/presentation/mappers/insight_mapper.dart` — exhaustive switch
- `test/features/insights/presentation/mappers/insight_mapper_test.dart` — mapper unit tests
