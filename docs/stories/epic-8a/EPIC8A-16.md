# Story EPIC8A-16 — QA Execution

**Assigned to:** QA Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-15 (test plan must exist)
**Phase:** 4

## Description

Execute the test plan from EPIC8A-15 against the implemented Home tab. For each test case, record the result (Pass / Fail / Blocked), the build number tested, and the platform. File a bug report for every failure with enough detail for the Flutter Engineer to reproduce and fix without additional context.

The QA Engineer does not have device access and produces written output only. The execution report is written as if the tests were run — based on reading the implementation code, the UX mockups, and the test plan. Any test case where the implementation clearly does not match the acceptance criteria is filed as a bug.

All P0 bugs must be fixed before the feature flag story (EPIC8A-17) proceeds. P1 bugs must be fixed or have a documented acceptance decision from the PM before EPIC8A-17. P2 bugs may be tracked in the backlog.

## Inputs (agent must read)

- `docs/qa/epic8a-test-plan.md` — EPIC8A-15 output
- All implementation files in `lib/features/home/` and `lib/features/insights/`
- `docs/designs/home-tab/spec.md` and `mockup-light.html` / `mockup-dark.html` — visual reference
- All story acceptance criteria from EPIC8A-01 through EPIC8A-14

## Outputs (agent must produce)

- `docs/qa/epic8a-results.md` — test execution report:
  - Build info (version, date)
  - Test result table: Test ID | Description | Platform | Result | Notes
  - Summary: total Pass / Fail / Blocked counts
- `docs/qa/epic8a-bugs.md` — one bug entry per failure:
  - Bug ID (BUG-8A-001, etc.)
  - Severity (P0 / P1 / P2)
  - Title
  - Steps to reproduce
  - Expected result
  - Actual result (based on code review)
  - Suggested fix (optional)

## Acceptance Criteria

- [ ] Every P0 test case in the test plan has a recorded result (Pass or Fail)
- [ ] Every P1 test case has a recorded result
- [ ] All failures are filed as bugs with reproducible steps
- [ ] Bug severity matches: P0 = crash or data loss; P1 = wrong behavior on acceptance criteria; P2 = visual polish or edge case
- [ ] Stats removal regression tests all pass (no Stats references, notes intact, Bookmarks intact)
- [ ] QA sign-off note at the bottom of `epic8a-results.md` states whether the feature is ready for feature-flag rollout

## Out of Scope

- Device-level or manual UI testing (not available to this agent)
- Fixing bugs (Flutter Engineer responsibility)
- Performance measurement (already done in EPIC8A-14)

## Quality Bar

The execution report must be detailed enough that the Sponsor can read it in the weekly review and make a go/no-go decision on the feature flag rollout. The QA sign-off statement is required.
