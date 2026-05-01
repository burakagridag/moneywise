# Story EPIC8A-13 — Accessibility Audit & Fixes

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-05, EPIC8A-06, EPIC8A-07, EPIC8A-08, EPIC8A-09, EPIC8A-10
**Phase:** 4

## Description

Conduct an accessibility audit of all Home tab components and fix all WCAG AA violations. The audit covers three areas: contrast ratios, Reduce Motion compliance, and Dynamic Type clamping. The engineer must use Flutter's `Semantics` widget where native semantics are insufficient (e.g., the sparkline chart, the avatar, the progress bar today-marker).

**Contrast:** All text on the `NetWorthCard` gradient background must meet WCAG AA (4.5:1 for normal text, 3:1 for large text). The gradient blue (`#3D5A99`) against white text must be verified — use the contrast ratio formula or an online checker and record the result in the PR.

**Reduce Motion:** The sparkline draw animation and any other entrance animations must respect `MediaQuery.of(context).disableAnimations`. When true, widgets render in their final state immediately.

**Dynamic Type:** All text across Home tab components must clamp between 0.85× and 1.3× of the base font size using `TextScaler.clamp`. Layouts must not overflow at 1.3× on a 375pt width.

**Semantics:** The sparkline `fl_chart` widget must have an `ExcludeSemantics` wrapper (decorative chart) with a `Semantics` label above it containing the balance value for screen reader users. The progress bar and today-marker must have a `Semantics` description. The avatar must have a `Semantics` label ("Open settings").

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — accessibility notes per component (EPIC8A-UX output should include these)
- `EPIC_home_tab_redesign_v2.md` Success Criteria: "WCAG AA contrast on all text, Reduce Motion respected, Dynamic Type clamped 0.85–1.3×"
- All Home tab widget files produced in Phase 2 and Phase 3 stories
- Flutter `Semantics`, `ExcludeSemantics`, `MergeSemantics` documentation

## Outputs (agent must produce)

- Updates to any Home tab widget file where accessibility fixes are needed (in-place edits, no new files unless a shared accessibility utility is created)
- `test/features/home/accessibility_test.dart` — golden or semantic tree tests covering: Dynamic Type at 1.3× does not overflow, Reduce Motion disables sparkline animation, screen reader semantics labels present
- `docs/prs/epic8a-13.md` — PR description must include: contrast ratio measurements for NetWorthCard text, list of every `Semantics` widget added, and Reduce Motion test results

## Acceptance Criteria

- [ ] NetWorthCard white text on `#3D5A99` gradient: contrast ratio >= 4.5:1 (verified and ratio recorded in PR)
- [ ] BudgetPulseCard text on white background: all colors meet 4.5:1 for body text
- [ ] Sparkline animation does not play when `MediaQuery.disableAnimations = true`
- [ ] All Home tab text respects `TextScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3)`
- [ ] No layout overflow at 1.3× Dynamic Type on a 375pt width (verified with `textScaleFactor: 1.3` in widget tests)
- [ ] Sparkline chart has `ExcludeSemantics` wrapper; a `Semantics` label above it reads the balance value
- [ ] Avatar has `Semantics(label: 'Open settings')` and `Button` trait
- [ ] Progress bar and today-marker have descriptive `Semantics` labels
- [ ] `flutter analyze` passes with zero warnings after changes
- [ ] `dart format` passes

## Out of Scope

- Accessibility audit of any screen outside the Home tab
- Color blindness palette adjustments (V2)
- Focus traversal order (covered by Flutter defaults; only fix if a test reveals a regression)

## Quality Bar

The PR must include the specific contrast ratio values measured, not just "it passes". Widget tests at `textScaleFactor: 1.3` are mandatory; visual overflow failures are blocking.
