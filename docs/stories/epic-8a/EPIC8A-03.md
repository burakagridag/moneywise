# Story EPIC8A-03 — HomeScreen Scaffold + Routing

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-01
**Phase:** 1

## Description

Replace the placeholder `HomeScreen` created in EPIC8A-01 with the structural scaffold that all Phase 2 component stories will slot into. The scaffold is a `CustomScrollView` (or `SingleChildScrollView`) wrapped in a `RefreshIndicator`, containing named section slots for each component in the correct order: `HomeHeader`, `NetWorthCard`, `BudgetPulseCard`, `ThisWeekSection` (insight cards), `RecentSection`, and `EmptyState`. Each slot is a placeholder widget for now (e.g., `SizedBox.shrink()` or a labeled `Placeholder`).

The `RefreshIndicator` must call `ref.invalidate` on `insightsProvider` and `sparklineDataProvider` when triggered (even though those providers do not exist yet — use `// TODO: EPIC8A-10 invalidate insightsProvider` comments). The pull-to-refresh wiring is established here so that Phase 2 stories can connect real providers without touching the scaffold structure.

Tab focus invalidation scaffolding (a `transactionMutationSignalProvider` listener or go_router listener) is also stubbed here with a TODO comment referencing EPIC8A-13.

## Inputs (agent must read)

- `lib/features/home/presentation/screens/home_screen.dart` — the placeholder from EPIC8A-01
- `docs/designs/home-tab/` — UX mockup files (produced by EPIC8A-UX in parallel; if not yet available, use the epic component order as specification)
- `EPIC_home_tab_redesign_v2.md` Section "Home Tab Anatomy" — the 6-section order
- `docs/decisions/ADR-011-insight-provider-interface.md` — pull-to-refresh and tab focus invalidation requirements
- `lib/core/router/app_router.dart` — current routing (EPIC8A-01 output)

## Outputs (agent must produce)

- `lib/features/home/presentation/screens/home_screen.dart` — full scaffold with `RefreshIndicator`, `CustomScrollView`, and 6 named section slots (placeholders); Riverpod `ConsumerWidget`
- `lib/features/home/presentation/providers/` — directory created (empty, ready for Phase 2 providers)
- `docs/prs/epic8a-03.md` — PR description with scroll behavior notes and pull-to-refresh test instructions

## Acceptance Criteria

- [ ] Home tab renders a scrollable view without overflow errors on both iOS (375pt) and Android (360dp) viewports
- [ ] `RefreshIndicator` is present and triggers visually when pulled down (no-op action acceptable at this stage)
- [ ] Six section slots exist in source code in the correct order matching the epic anatomy
- [ ] Pull-to-refresh invalidation TODOs are present with correct EPIC8A-10 and EPIC8A-13 references
- [ ] Tab focus invalidation stub (comment or empty listener) is present
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` passes
- [ ] Screen renders correctly in both light and dark themes (no hardcoded colors)

## Out of Scope

- Implementing any actual component (HomeHeader, NetWorthCard, etc.)
- Wiring real Riverpod providers
- Any animation or transition logic
- Analytics events

## Quality Bar

The scaffold must be structurally complete enough that a second engineer picking up EPIC8A-05 (HomeHeader) can add their widget to the correct slot without modifying the scaffold structure.
