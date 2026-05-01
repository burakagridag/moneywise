# Story EPIC8A-UX — UX Designer: Home Tab Component Mockups

**Assigned to:** UX Designer
**Estimated effort:** 3 points
**Dependencies:** none (runs in parallel with Phase 1 engineering stories)
**Phase:** 1 (parallel)

## Description

Produce the complete design handoff package for all five Home tab components and the Empty State. The Flutter Engineer cannot start Phase 2 component stories until these files exist. This story is the critical path gate between Phase 1 and Phase 2.

The UX Designer must produce pixel-accurate HTML mockups (light and dark), a component spec, design tokens JSON, and engineer-facing redlines for each component. All output must be file-based — no external design tools or Figma links. The Flutter Engineer reads these files exclusively.

All design decisions (colors, radii, spacing, typography) must use existing tokens from `lib/core/constants/`. Do not introduce new tokens without flagging to PM first.

## Inputs (agent must read)

- `/Users/burakagridag/Documents/screenshots/newdesign/v1-reference-light.html` — approved light mode reference
- `/Users/burakagridag/Documents/screenshots/newdesign/v1-reference-dark.html` — approved dark mode reference
- `EPIC_home_tab_redesign_v2.md` Sections "Component Specs" and "Empty State Spec" — authoritative layout and token requirements
- `lib/core/constants/app_colors.dart` — existing color tokens
- `lib/core/constants/app_typography.dart` — existing typography tokens
- `lib/core/constants/app_spacing.dart` — existing spacing tokens
- `lib/core/theme/app_theme.dart` — light/dark theme definitions

## Outputs (agent must produce)

All files under `docs/designs/home-tab/`:

- `mockup-light.html` — self-contained HTML, 375px viewport, light theme, showing all 6 sections in scroll order
- `mockup-dark.html` — same, dark theme variant
- `spec.md` — per-component breakdown:
  - HomeHeader: greeting variants (morning/afternoon/evening), avatar, date format
  - NetWorthCard: gradient, balance display, trend chip, sparkline placeholder, zero state
  - BudgetPulseCard: progress bar, today marker, daily pace line, no-budget CTA state, over-budget state
  - InsightCard: icon container, title/subtitle, tappable and non-tappable variants
  - RecentTransactionsList: 2-row layout, "All" link, empty (hidden) state
  - EmptyState: 3 onboarding cards, highlight logic
- `tokens.json` — computed token values for each component
- `redlines.md` — engineer-facing mapping of every visual element to existing token names; flag any new tokens needed

If any design decision is ambiguous or requires a new token, create `docs/designs/home-tab/QUESTIONS.md` and stop; do not proceed with assumptions.

## Acceptance Criteria

- [ ] `mockup-light.html` and `mockup-dark.html` are self-contained (no external CDN links), render correctly in a browser at 375px width
- [ ] All 6 sections are visible in scroll order in the mockup: HomeHeader, NetWorthCard, BudgetPulseCard, ThisWeekSection (with 1 InsightCard sample), RecentSection (2 rows), EmptyState variant
- [ ] `spec.md` covers all state variants: default, loading (shimmer placeholder described), empty, error, over-budget, no-budget
- [ ] `tokens.json` references only existing token names from `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`; any new token is flagged with `"NEW_TOKEN_REQUIRED": true`
- [ ] `redlines.md` maps every dimension, color, and typography spec to a named token or exact value; no vague descriptions like "blue-ish"
- [ ] NetWorthCard gradient values match the exact hex values in the epic spec: light `#3D5A99 → #2E4A87`, dark `#4F46E5 → #3D5A99`
- [ ] BudgetPulseCard shows the today-marker (vertical line) at the correct proportional position in the mockup
- [ ] Dark mode mockup uses correct background tokens, not light mode colors

## Out of Scope

- Implementing any Flutter code
- Designing the Budget tab itself (only the BudgetPulseCard widget on the Home tab)
- V2 account sub-cards on NetWorthCard
- Any InsightCard content beyond a representative sample

## Quality Bar

A Flutter Engineer with no prior context should be able to implement all five components reading only `spec.md` and `redlines.md`, without asking any clarifying questions. If that is not achievable, the UX Designer must write `QUESTIONS.md` and escalate.
