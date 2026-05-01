# Story EPIC8A-14 — Performance Profiling

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-05, EPIC8A-06, EPIC8A-07, EPIC8A-08, EPIC8A-09, EPIC8A-10, EPIC8A-11
**Phase:** 4

## Description

Profile the Home tab under realistic data conditions and confirm it meets the Sponsor-mandated performance targets: open in < 300ms with cached data, < 1s with cold load. Fix any violations found. This story is not about feature implementation — it is about measurement, documentation, and targeted fixes.

**Profiling conditions:**
- Device: mid-range Android (e.g., Pixel 3a or equivalent) and iPhone 12 (or simulator in profile mode)
- Data volume: seed the DB with 500 transactions over the last 90 days across 3 accounts, 2 with budgets set, global budget set
- Measure: time from tab tap to first meaningful paint (all 5 components rendered with real data, shimmer gone)

**Expected bottleneck areas to check:**
- `watchDailyNetAmounts` Dart-side aggregation with 500 transactions (should be < 5ms per ADR-012)
- `insightsProvider` Future assembly time (3 async awaits)
- Widget build time for the 6-section scroll view

The engineer must use Flutter DevTools (Timeline) in profile mode. Screenshots or exported traces are not required in the PR — only the measured times and a narrative description of what was profiled.

If any measured time exceeds the target, the engineer must implement a targeted fix and re-measure. Common fixes: memoize expensive computations, defer non-critical sections with `SchedulerBinding.addPostFrameCallback`, or reduce widget rebuild scope.

## Inputs (agent must read)

- `EPIC_home_tab_redesign_v2.md` Success Criteria: "< 300ms cached, < 1s cold load"
- `docs/decisions/ADR-012-sparkline-data-flow.md` — performance analysis: "≤1 500 rows → negligible; >5 000 → ~5ms"
- All Home tab widget and provider files produced in Phases 2 and 3

## Outputs (agent must produce)

- Any performance fixes as in-place edits to existing files
- `docs/prs/epic8a-14.md` — PR description must include:
  - Profiling methodology (device, mode, data seed)
  - Measured times for cached and cold load scenarios (iOS and Android)
  - List of any fixes applied and re-measured times
  - Confirmation that targets are met, OR a documented decision to accept a miss with rationale

## Acceptance Criteria

- [ ] Home tab first meaningful paint (all components with real data, shimmers gone) < 300ms with warm Riverpod providers on a mid-range device
- [ ] Home tab first meaningful paint < 1s on cold launch (app start → Home tab rendered with real data)
- [ ] `watchDailyNetAmounts` stream emission time with 500 transactions is < 10ms (measured via stopwatch in a dev build)
- [ ] No jank (frame drops below 60fps) during scroll through the Home tab with all components rendered
- [ ] PR includes the measured times for both iOS and Android
- [ ] `flutter analyze` and `dart format` pass after any fixes

## Out of Scope

- SQL-aggregation optimisation for `watchDailyNetAmounts` (deferred per ADR-012 unless >5 000 transactions)
- Performance of other tabs
- App startup time (separate concern)

## Quality Bar

Measured numbers must appear in the PR description. "It feels fast" is not acceptable. If performance targets cannot be met, the engineer escalates with a documented proposal before merging.
