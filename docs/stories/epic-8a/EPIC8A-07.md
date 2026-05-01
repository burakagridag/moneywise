# Story EPIC8A-07 — BudgetPulseCard Component

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-03, EPIC8A-04, EPIC8A-UX
**Phase:** 2

## Description

Implement the `BudgetPulseCard` widget, which shows the user's budget health at a glance: remaining budget, a linear progress bar with a "today marker", and a daily pace line. The card consumes `effectiveBudgetProvider` (ADR-010) and an existing spending total provider for the current month.

The card has three distinct states:
1. **No budget set** (when `effectiveBudgetProvider` emits null): renders a CTA card "Set a monthly budget" with a link to the Budget tab
2. **Normal** (budget > 0, spent < budget): progress bar fills proportionally; today marker is a vertical line at `(currentDay / daysInMonth) * 100%`; daily pace line shows `safeDailyAmount`
3. **Over budget** (spent >= budget): progress bar fills to 100%; `remaining` shown as `-X €` in the expense color; `Over budget` text replaces the safe daily amount

The `safeDailyAmount` formula: `remaining / (daysInMonth - currentDay + 1)`. If the result is <= 0, show "Over budget" with the expense color. If `actualDailyPace > safeDailyAmount * 1.5`, the daily pace value is shown in the warning color.

The "View →" link in the card header navigates to the Budget tab (`AppRoutes.budget`).

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — BudgetPulseCard section, all state variants
- `docs/designs/home-tab/redlines.md` — card tokens: white surface, 1dp border, 14dp radius, 14dp padding; shadow (light) vs border-only (dark)
- `docs/designs/home-tab/mockup-light.html` and `mockup-dark.html`
- `docs/decisions/ADR-010-global-budget-field.md` — `effectiveBudgetProvider` spec, fallback logic, multi-currency V1 assumption, Flutter Engineer implementation notes
- `lib/features/home/presentation/providers/user_settings_providers.dart` — `effectiveBudgetProvider` (EPIC8A-04 output)
- `lib/features/budget/presentation/providers/budget_providers.dart` — `totalBudgetProvider` and monthly spending provider
- `lib/core/constants/app_colors.dart` — `expense`, `warning`, `brandPrimary`, `bgTertiary` tokens
- `EPIC_home_tab_redesign_v2.md` Section "BudgetPulseCard"

## Outputs (agent must produce)

- `lib/features/home/presentation/widgets/budget_pulse_card.dart` — `BudgetPulseCard` `ConsumerWidget` with all three states
- `lib/features/home/presentation/widgets/budget_pulse_progress_bar.dart` — extracted progress bar with today-marker (or inline if simpler; engineer decides)
- `lib/features/home/presentation/screens/home_screen.dart` — BudgetPulseCard slot filled
- `lib/l10n/app_en.arb` — new keys: `homeBudgetPulse`, `homeBudgetSetCta`, `homeBudgetRemaining`, `homeBudgetOverBudget`, `homeBudgetDailyPace`, `homeBudgetSafeSpend`
- `lib/l10n/app_tr.arb` — TR placeholders (marked `// TODO: TR review`)
- `test/features/home/widgets/budget_pulse_card_test.dart` — widget tests covering all three states
- `docs/prs/epic8a-07.md`

## Acceptance Criteria

- [ ] When `effectiveBudgetProvider` emits null: CTA card shown with "Set a monthly budget" text and link to Budget tab; no progress bar rendered
- [ ] When budget set and spent < budget: remaining amount displayed correctly; progress bar width = `(spent/budget)*100%` clamped 0–100%
- [ ] Today marker appears at `(currentDay / daysInMonth) * 100%` from the left edge of the progress bar
- [ ] `safeDailyAmount` calculated correctly; negative or zero value shows "Over budget" in expense color
- [ ] When `actualDailyPace > safeDailyAmount * 1.5`: daily pace value rendered in warning color
- [ ] When spent > budget: progress bar at 100%, remaining shown as negative in expense color, "Over budget" label displayed
- [ ] "View →" link navigates to Budget tab
- [ ] Card uses white surface, 1dp border, 14dp radius, 14dp padding in both themes; light mode has shadow, dark mode has border-only
- [ ] `AsyncValue.loading` from `effectiveBudgetProvider` shows a shimmer placeholder
- [ ] Primary currency symbol shown on all amounts; no mixed-currency warning (per ADR-010 V1 assumption)
- [ ] All widget tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- UI for setting the global budget value (Budget tab concern, separate story)
- Budget carry-over logic
- Per-category budget breakdown on the card (full Budget tab only)
- Multi-currency budget display (V2)

## Quality Bar

Widget tests must inject a mock `effectiveBudgetProvider` using `ProviderContainer.overrideWith` — never hardcode values inside the widget. Each of the three card states (no budget, normal, over-budget) must have a dedicated test case. Division-by-zero guard when `daysInMonth = currentDay` must be tested.
