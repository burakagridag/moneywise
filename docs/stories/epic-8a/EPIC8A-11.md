# Story EPIC8A-11 — Pull-to-Refresh + Tab Focus Invalidation

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-03, EPIC8A-06, EPIC8A-07, EPIC8A-08
**Phase:** 3

## Description

Complete the reactive refresh infrastructure for the Home tab. This story removes the TODO stubs placed in EPIC8A-03 and wires the actual invalidation logic.

**Pull-to-refresh:** The `RefreshIndicator` already wraps the `CustomScrollView` (EPIC8A-03). This story connects it: on drag-to-refresh, call `ref.invalidate(insightsProvider)`, `ref.invalidate(sparklineDataProvider)`, and `ref.invalidate(netWorthProvider)` (or whichever providers supply non-streaming data to the Home tab). The `RefreshIndicator` `onRefresh` callback must `await` the refresh before completing so the spinner does not dismiss prematurely.

**Tab focus invalidation:** When the user navigates back to the Home tab after a transaction mutation, `insightsProvider` must be invalidated so it re-fetches. Implement using a `transactionMutationSignalProvider` (`StateProvider<int>` incremented on any add/edit/delete transaction mutation) or by listening to the go_router route change back to `/home`. The chosen approach must be documented in the PR. The signal provider increment must be called from the transaction add/edit/delete confirmation handlers (point the engineer to the relevant files).

Per ADR-011: the chosen approach must be documented in the PR description. The `StreamProvider`-based providers (`sparklineDataProvider`, `recentTransactionsProvider`) do not need invalidation — they update automatically via the Drift stream.

## Inputs (agent must read)

- `docs/decisions/ADR-011-insight-provider-interface.md` — Section "Reactive Behaviour — V1 Compensating Mechanisms" (exact requirements)
- `lib/features/home/presentation/screens/home_screen.dart` — current scaffold with TODO stubs (EPIC8A-03 output)
- `lib/features/home/presentation/providers/` — all providers created in Phase 2
- `lib/features/transactions/presentation/` — add/edit/delete transaction handlers to find mutation points
- `lib/core/router/app_router.dart` — for go_router route-based invalidation option

## Outputs (agent must produce)

- `lib/features/home/presentation/screens/home_screen.dart` — TODO stubs replaced with real invalidation calls; `RefreshIndicator.onRefresh` properly awaits provider refresh
- `lib/features/transactions/presentation/providers/transaction_mutation_signal_provider.dart` — `transactionMutationSignalProvider` (if mutation-signal approach chosen), or equivalent
- Mutation points (add/edit/delete transaction success handlers) updated to increment/trigger the signal
- `docs/prs/epic8a-11.md` — PR description must explicitly state which of the two ADR-011 approaches was chosen and why

## Acceptance Criteria

- [ ] Pull-to-refresh spinner appears, invalidates non-streaming providers, and dismisses only after refresh completes
- [ ] After adding a transaction and returning to Home tab, the insight section reflects updated data without manual pull-to-refresh
- [ ] After editing a transaction and returning to Home tab, the insight section reflects updated data
- [ ] After deleting a transaction and returning to Home tab, the insight section reflects updated data
- [ ] `sparklineDataProvider` and `recentTransactionsProvider` (both `StreamProvider`) update without explicit invalidation — confirmed in PR
- [ ] No double-refresh race condition: pull-to-refresh while tab focus invalidation is in-flight must not cause duplicate network calls or crashes
- [ ] PR description states the chosen tab focus invalidation approach and references ADR-011
- [ ] `flutter analyze` and `dart format` pass

## Out of Scope

- Upgrading `insightsProvider` from `FutureProvider` to `StreamProvider` (deferred to V2 per ADR-011)
- Real-time insight updates while the user is actively on the Home tab (no transaction stream watching — V2 concern)
- Pull-to-refresh on other tabs

## Quality Bar

The invalidation behavior must be verifiable by a human QA engineer: add a transaction in the Transactions tab, navigate back to Home, and confirm the insights section has refreshed — without pulling to refresh manually. This flow must be documented in the PR as a manual test step.
