# Story EPIC8A-10 — Empty State: 3 Onboarding Cards

**Assigned to:** Flutter Engineer
**Estimated effort:** 2 points
**Dependencies:** EPIC8A-03, EPIC8A-05, EPIC8A-06, EPIC8A-09, EPIC8A-UX
**Phase:** 3

## Description

Implement the first-time user empty state for the Home tab. When the user has zero transactions ever (across all accounts), the Home tab shows a simplified layout: `HomeHeader`, `NetWorthCard` in placeholder state (balance 0, flat sparkline, no trend chip), a "Get started" section header, and 3 onboarding cards in a fixed order.

The 3 cards are:
1. **Add your first transaction** — "Track your income and expenses to see insights" — primary CTA button (brand color) → opens the Add Transaction modal
2. **Set up your accounts** — "Cash, bank, cards" — secondary link → navigates to `AppRoutes.accounts` (More tab → Accounts)
3. **Set a monthly budget** — "Stay on top of spending" — secondary link → navigates to `AppRoutes.budget`

Card completion behavior (auto-dismiss only — Sponsor decision):
- Card 1 disappears when `recentTransactionsProvider` emits at least 1 transaction
- Card 2 disappears when the user has at least 1 non-default account (engineer must define "default account" — if a seed account is created on install, card 2 may need a threshold of 2)
- Card 3 disappears when `effectiveBudgetProvider` emits a non-null value

When all 3 cards are gone, the full Home tab replaces the empty state (transition is immediate, no animation required for V1).

The first card is highlighted with a primary background tint; the other two use the standard outlined card style. There is no dismiss button (Sponsor decision: auto-dismiss only).

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — Empty State section, onboarding card layout, highlight styling
- `docs/designs/home-tab/mockup-light.html` and `mockup-dark.html`
- `lib/features/home/presentation/screens/home_screen.dart` — scaffold slot for EmptyState
- `lib/features/home/presentation/providers/recent_transactions_provider.dart` (EPIC8A-09)
- `lib/features/home/presentation/providers/user_settings_providers.dart` — `effectiveBudgetProvider` (EPIC8A-04)
- `lib/features/accounts/` — account repository for card 2 completion check
- `lib/features/transactions/` — add transaction modal navigation
- `EPIC_home_tab_redesign_v2.md` Section "Empty State Spec"
- Sponsor decisions: "auto-dismiss only, 3 cards, no dismiss button"

## Outputs (agent must produce)

- `lib/features/home/presentation/widgets/home_empty_state.dart` — `HomeEmptyState` widget containing the 3 onboarding cards
- `lib/features/home/presentation/widgets/onboarding_card.dart` — reusable card widget with `highlighted` bool prop, title, subtitle, and CTA widget slot
- `lib/features/home/presentation/providers/onboarding_state_provider.dart` — `onboardingCompleteProvider` (`StreamProvider<OnboardingState>`) tracking which of the 3 steps are done
- `lib/features/home/presentation/screens/home_screen.dart` — logic: if `recentTransactionsProvider` returns empty list AND onboarding not complete → show `HomeEmptyState`; otherwise show full tab content
- `lib/l10n/app_en.arb` — onboarding card string keys
- `lib/l10n/app_tr.arb` — TR placeholders
- `test/features/home/widgets/home_empty_state_test.dart` — widget tests
- `docs/prs/epic8a-10.md`

## Acceptance Criteria

- [ ] Empty state shown when `recentTransactionsProvider` emits empty list
- [ ] Full Home tab shown when `recentTransactionsProvider` emits at least 1 transaction (even if onboarding state shows some cards incomplete)
- [ ] Card 1 is highlighted (primary background tint); Cards 2 and 3 are outlined
- [ ] No dismiss/X button on any card
- [ ] Card 1 tap opens the Add Transaction modal on both platforms
- [ ] Card 2 tap navigates to Accounts screen
- [ ] Card 3 tap navigates to Budget tab
- [ ] Card 1 disappears (auto-dismiss) after user adds first transaction
- [ ] Card 3 disappears after global budget is set
- [ ] When all cards disappear, full Home tab is shown without requiring app restart
- [ ] `NetWorthCard` in placeholder state: shows 0,00 €, flat sparkline, no trend chip
- [ ] No hardcoded colors; all theme-aware
- [ ] All widget tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- Manual dismiss button (explicitly excluded by Sponsor)
- Animated card removal transitions (V2 polish)
- Progress indicator showing how many steps are completed
- Onboarding shown again after data is deleted

## Quality Bar

Widget tests must use provider overrides to simulate each completion state: 0 steps done (all 3 cards visible), 1 step done (card 1 gone), 2 steps done, 3 steps done (empty state replaced by full tab). Each state must be a separate test case.
