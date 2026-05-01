# Story EPIC8A-08 — InsightCard Shell + InsightProvider Interface

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-03, EPIC8A-04, EPIC8A-UX
**Phase:** 2

## Description

Implement two things in one atomic story because they are tightly coupled and neither is useful without the other:

1. **The `InsightProvider` abstract interface and domain layer** — all files under `lib/features/insights/domain/` and the `RuleBasedInsightProvider` shell in `lib/features/insights/data/`. The shell provider returns an empty list — **no rules are implemented in Epic 8a** (rules are Epic 8b). The architecture must be fully in place so Epic 8b can add each rule as a separate class without touching UI or scaffold code.

2. **The `InsightCard` presentational widget** — a generic card that accepts `iconData`, `iconColor`, `iconBackgroundColor`, `title`, `subtitle`, and an optional `onTap`. The Home tab renders a list of these cards in the `ThisWeekSection` slot, sourced from `insightsProvider`. When `insightsProvider` returns an empty list, the entire section is hidden.

The `insightsProvider` (`FutureProvider<List<Insight>>`) is fully wired per ADR-011 — it assembles `InsightContext` from existing providers and calls `provider.generate(context)`. Because `RuleBasedInsightProvider` returns an empty list in 8a, the section is hidden in the UI, which is the correct V1 empty state.

## Inputs (agent must read)

- `docs/decisions/ADR-011-insight-provider-interface.md` — complete spec: file layout, interface definitions, Riverpod wiring code, Flutter Engineer implementation notes, first-month fallback behavior, pull-to-refresh and tab focus invalidation references
- `docs/designs/home-tab/spec.md` — InsightCard UI spec
- `docs/designs/home-tab/redlines.md` — card tokens: `bgSecondary`, 1dp border, 14dp radius, 12×14dp padding; icon container 32×32, 8dp radius
- `lib/features/home/presentation/providers/user_settings_providers.dart` — `effectiveBudgetProvider` (EPIC8A-04 output)
- `lib/features/budget/presentation/providers/budget_providers.dart` — `budgetsForMonthProvider`
- `lib/features/transactions/` — transaction providers and entities
- `EPIC_home_tab_redesign_v2.md` Section "InsightEngine"

## Outputs (agent must produce)

Per ADR-011 file layout:
- `lib/features/insights/domain/insight.dart` — `Insight` entity, `InsightSeverity` enum
- `lib/features/insights/domain/insight_context.dart` — `InsightContext` value class (domain entities only, no Drift types)
- `lib/features/insights/domain/insight_provider.dart` — `abstract class InsightProvider`
- `lib/features/insights/domain/insight_rule.dart` — `abstract class InsightRule`
- `lib/features/insights/domain/rules/` — directory created; four empty placeholder files (`concentration_rule.dart`, `savings_goal_rule.dart`, `daily_overpacing_rule.dart`, `big_transaction_rule.dart`) with class stubs that return `null` and a `// TODO: Epic 8b` comment
- `lib/features/insights/data/rule_based_insight_provider.dart` — `RuleBasedInsightProvider implements InsightProvider`; `generate()` returns empty list until rules are added in Epic 8b
- `lib/features/insights/presentation/providers/insights_providers.dart` — `insightProviderInstanceProvider` and `insightsProvider` per ADR-011 Riverpod wiring
- `lib/features/insights/insights.dart` — barrel export
- `lib/features/home/presentation/widgets/insight_card.dart` — `InsightCard` presentational widget
- `lib/features/home/presentation/screens/home_screen.dart` — `ThisWeekSection` slot: watches `insightsProvider`; renders list of `InsightCard` widgets; hides section when list is empty
- `test/features/insights/domain/insight_rule_test.dart` — test skeleton with `// TODO: Epic 8b` stubs for the four rules
- `test/features/home/widgets/insight_card_test.dart` — widget tests: with `onTap` (card is tappable), without `onTap` (no InkWell), title ellipsis, subtitle ellipsis
- `docs/prs/epic8a-08.md`

## Acceptance Criteria

- [ ] `InsightProvider` is an abstract class; `RuleBasedInsightProvider` implements it
- [ ] `InsightCard` renders icon container (32×32, 8dp radius), title (1 line, ellipsis), subtitle (1 line, ellipsis)
- [ ] With `onTap = null`: no `InkWell` ripple; card is not tappable
- [ ] With `onTap` provided: full card has `InkWell` with ripple on tap
- [ ] `ThisWeekSection` is hidden (zero height, not rendered) when `insightsProvider` returns an empty list
- [ ] `insightsProvider` assembles `InsightContext` from existing transaction, budget, and effective-budget providers per ADR-011 wiring
- [ ] `Insight.id` field is a stable constant string per rule (even for placeholder stubs)
- [ ] `InsightContext` imports only domain entity types; no Drift table type imports
- [ ] `insightProviderInstanceProvider` is overridable via `ProviderContainer.overrideWith` (verified in widget test)
- [ ] Four rule stub files exist in `domain/rules/` with the correct class name and `// TODO: Epic 8b` comment
- [ ] All widget and unit tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- Implementing any insight rule logic (all 4 rules are Epic 8b)
- Animated transitions between insight cards
- "More insights" screen
- Analytics `insight_card_tapped` event (EPIC8A-12)

## Quality Bar

The abstract interface design is the primary output. A code reviewer must be able to confirm that adding a new `InsightRule` in Epic 8b requires zero changes to `InsightCard`, `HomeScreen`, `insightsProvider`, or `RuleBasedInsightProvider.generate()` — only a new rule class and a registration line in `insightProviderInstanceProvider`.
