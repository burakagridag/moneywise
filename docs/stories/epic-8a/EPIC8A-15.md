# Story EPIC8A-15 — QA Test Plan

**Assigned to:** QA Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-01 through EPIC8A-14 (all Phase 1–4 stories must be complete before QA starts)
**Phase:** 4

## Description

Write the comprehensive QA test plan for Epic 8a. The test plan covers: the IA refactor (tab structure, routing), all 5 Home tab components, the empty state, pull-to-refresh, tab focus invalidation, analytics events, accessibility, and regression for existing features (Transactions, Accounts, Budget, Bookmarks).

The QA Engineer does not execute tests (no device access) — the plan must be written so that a human QA engineer or the flutter-engineer can execute them step by step. Each test case must have: a test ID, preconditions, steps, expected result, and platform tags (iOS / Android / both).

The plan must include a dedicated regression suite for the Stats tab removal: confirm that `StatsNoteView` references are gone, that transaction-level notes still work, and that Bookmarks (Sprint 6) still function.

## Inputs (agent must read)

- All story acceptance criteria from EPIC8A-01 through EPIC8A-14 (these are the source of truth for test cases)
- `docs/designs/home-tab/spec.md` — state variants to verify against mockups
- `EPIC_home_tab_redesign_v2.md` Success Criteria section
- `docs/decisions/ADR-010-global-budget-field.md` — fallback behavior to test
- `docs/decisions/ADR-011-insight-provider-interface.md` — pull-to-refresh and tab focus invalidation behaviors
- `docs/decisions/ADR-012-sparkline-data-flow.md` — sparkline zero-fill, transfer exclusion behaviors

## Outputs (agent must produce)

- `docs/qa/epic8a-test-plan.md` — full test plan with:
  - P0 (blocking) test cases: tab navigation, data integrity, crash-free on both platforms
  - P1 (high priority): all component states, empty state flow, pull-to-refresh
  - P2 (medium): analytics events, accessibility, Dynamic Type
  - Regression suite: Stats removal, transaction notes, Bookmarks, Budget tab
  - Platform matrix: which tests are iOS-only, Android-only, or both

## Acceptance Criteria

- [ ] Test plan covers all acceptance criteria from EPIC8A-01 through EPIC8A-14 (at least one test case per acceptance criterion)
- [ ] Each test case has: ID, preconditions, numbered steps, expected result, platform tag
- [ ] Stats removal regression suite includes: grep confirmation for no Stats references, transaction note field visible on detail sheet, Bookmarks screen loads without error
- [ ] Empty state flow test: fresh install → 3 cards visible → add transaction → card 1 disappears → set budget → card 3 disappears
- [ ] BudgetPulseCard tests cover all 3 states: no budget, normal, over-budget
- [ ] NetWorthCard tests cover: zero balance, positive balance with trend chip, negative trend chip, sparkline flat (no data), sparkline with data
- [ ] Pull-to-refresh test: add transaction in Transactions tab → return to Home tab → pull to refresh → insight section updated
- [ ] Tab focus invalidation test: add transaction → navigate to Home → insights updated without pull-to-refresh
- [ ] Performance test case: document how to measure < 300ms cached load using DevTools

## Out of Scope

- Executing the tests (QA execution is EPIC8A-16)
- Writing automated test code (that is the Flutter Engineer's responsibility)
- Testing Epic 8b features (insight rules)

## Quality Bar

A human QA engineer with no prior context should be able to execute the entire test plan from the document alone, without asking for clarification. Every edge case from the story acceptance criteria must appear as a traceable test case.
