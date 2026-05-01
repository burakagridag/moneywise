# Story EPIC8A-01 — IA Refactor: 4-Tab Shell + Accounts Relocation

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** none
**Phase:** 1

## Description

Restructure the bottom navigation shell from the current 4-tab layout (`Transactions | Stats | Accounts | More`) to the new 4-tab layout (`Home | Transactions | Budget | More`). The Accounts screen moves under the More tab as a navigable sub-page. The Stats tab is removed entirely. The Budget tab is promoted from a sub-tab inside Stats to a standalone top-level tab. The default tab on app launch changes from Transactions to Home.

This story establishes the routing skeleton that all subsequent Phase 2 component stories build on. Placeholder screens (empty `Scaffold` with a centered label) are acceptable for Home and the relocated Accounts page. The actual Budget screen already exists; it is simply re-registered as a top-level route.

## Inputs (agent must read)

- `lib/core/router/app_router.dart` — current go_router configuration and shell route
- `lib/core/router/app_routes.dart` — route constants
- `lib/features/more/presentation/screens/more_screen.dart` — current More tab content (add Accounts entry here)
- `lib/features/accounts/presentation/screens/accounts_screen.dart` — existing screen to move
- `lib/features/stats/` — full directory to understand what is being removed
- `lib/features/budget/presentation/screens/budget_screen.dart` — existing screen being promoted
- `docs/decisions/ADR-001-riverpod-state-management.md` — provider patterns to follow
- Sponsor decision table in `docs/stories/epic-8a/README.md`

## Outputs (agent must produce)

- `lib/core/router/app_router.dart` — updated shell with 4 tabs: `/home`, `/transactions`, `/budget`, `/more`; initial location set to `/home`
- `lib/core/router/app_routes.dart` — new route constants: `AppRoutes.home`, `AppRoutes.budget`; remove `AppRoutes.stats` and sub-routes
- `lib/features/home/presentation/screens/home_screen.dart` — empty scaffold placeholder (`HomeScreen`, centered text "Home — coming soon")
- `lib/features/more/presentation/screens/more_screen.dart` — add "Accounts" list tile that navigates to `/more/accounts`
- `lib/core/router/app_router.dart` — nested route `/more/accounts` pointing to `AccountsScreen`
- `docs/prs/epic8a-01.md` — PR description with before/after tab structure, screenshot placeholders, and edge cases tested

## Acceptance Criteria

- [ ] App launches with Home tab selected (index 0), not Transactions
- [ ] Bottom nav bar shows exactly 4 tabs in order: Home, Transactions, Budget, More; no Stats tab exists
- [ ] Tapping each tab navigates to its screen without error on both iOS and Android
- [ ] Budget tab loads the existing `BudgetScreen`; all existing budget functionality is preserved
- [ ] Accounts is accessible via More tab → "Accounts" list tile → `AccountsScreen`; all account data is intact
- [ ] No route references to `/stats` or its sub-routes remain in router or navigation code
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` passes
- [ ] Existing Transactions screen deep links (e.g., from add-transaction FAB) resolve correctly
- [ ] Android back button from a nested tab screen returns to the tab root, not exits the app

## Out of Scope

- Implementing the Home tab content (EPIC8A-03 and Phase 2 stories)
- Removing Stats feature files from `lib/features/stats/` (EPIC8A-02 handles cleanup)
- Any visual change to the Budget screen itself
- Accounts screen UI changes
- Analytics events (EPIC8A-12)

## Quality Bar

Any QA engineer should be able to launch the app on iOS simulator and Android emulator and confirm all 4 tabs navigate correctly with zero crashes. The routing change must not break any existing deep link or navigation flow used by the Transactions, Budget, or More screens.
