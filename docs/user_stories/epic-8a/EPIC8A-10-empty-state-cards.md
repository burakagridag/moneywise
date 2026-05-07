# EPIC8A-10: Empty State Onboarding Cards

> **Source:** Epic 8 Sponsor approval (2026-05-01) — `docs/decisions/project_epic8_decisions.md`
> **Clarification:** Sponsor completion-check criteria update (2026-05-01)
> **Budget criteria change:** Sponsor request (2026-05-01) — "Set a monthly budget" card now hides when ANY budget exists (global OR category), not only globalMonthlyBudget
> **Epic:** 8a — IA Refactor + Home Tab Foundation

## Persona
A brand-new MoneyWise user who has just installed the app and has not yet set up any accounts, transactions, or budgets.

## Story
**As** a new MoneyWise user
**I want** to see contextual onboarding cards that guide me to complete my initial setup
**So that** I understand which key actions remain and the cards disappear as I complete each step

## Acceptance Criteria

```gherkin
# ─── Completion Rules ────────────────────────────────────────────────────────

Rule: Each card is shown only when its completion criterion is NOT yet met

  | Card                      | Hidden when                                                                               |
  |---------------------------|-------------------------------------------------------------------------------------------|
  | Add your first transaction| transactionCount > 0                                                                      |
  | Manage your accounts      | accountCount > 0 (at least one user account exists)                                       |
  | Set a monthly budget      | globalMonthlyBudget IS NOT NULL OR anyCategoryBudgetExists                                |
  |                           | (shown only when globalMonthlyBudget IS NULL AND noCategoryBudget)                        |

Rule: When all three cards are hidden, the "Get started" section header is also hidden
  (the entire empty-state section is removed from the widget tree)

# ─── State 1: Brand-new user ─────────────────────────────────────────────────

Scenario: All three cards are visible for a brand-new user
  Given I have just installed the app for the first time
  And transactionCount is 0
  And accountCount is 0
  And userSettings.globalMonthlyBudget is NULL
  When I open the Home tab
  Then I see the "Get started" section header
  And I see the "Add your first transaction" card
  And I see the "Manage your accounts" card
  And I see the "Set a monthly budget" card

# ─── State 2: Budget set + account exists, no transaction ────────────────────
# Budget can be a global monthly budget OR one or more category budgets.

Scenario: Only the transaction card is visible when budget (global) and account are already set
  Given transactionCount is 0
  And accountCount is 1 (user has at least one account)
  And userSettings.globalMonthlyBudget is NOT NULL
  And noCategoryBudget
  When I open the Home tab
  Then I see the "Get started" section header
  And I see the "Add your first transaction" card
  And I do NOT see the "Manage your accounts" card
  And I do NOT see the "Set a monthly budget" card

Scenario: Only the transaction card is visible when budget (category) and account are already set
  Given transactionCount is 0
  And accountCount is 1 (user has at least one account)
  And userSettings.globalMonthlyBudget is NULL
  And anyCategoryBudgetExists
  When I open the Home tab
  Then I see the "Get started" section header
  And I see the "Add your first transaction" card
  And I do NOT see the "Manage your accounts" card
  And I do NOT see the "Set a monthly budget" card

# ─── State 3: Only budget is set, no account, no transaction ─────────────────
# "Budget set" covers both global monthly budget and any category budget.

Scenario: Transaction and account cards are visible when only a global budget is set
  Given transactionCount is 0
  And accountCount is 0
  And userSettings.globalMonthlyBudget is NOT NULL
  And noCategoryBudget
  When I open the Home tab
  Then I see the "Get started" section header
  And I see the "Add your first transaction" card
  And I see the "Manage your accounts" card
  And I do NOT see the "Set a monthly budget" card

Scenario: Transaction and account cards are visible when only a category budget is set
  Given transactionCount is 0
  And accountCount is 0
  And userSettings.globalMonthlyBudget is NULL
  And anyCategoryBudgetExists
  When I open the Home tab
  Then I see the "Get started" section header
  And I see the "Add your first transaction" card
  And I see the "Manage your accounts" card
  And I do NOT see the "Set a monthly budget" card

# ─── State 4: All criteria met ───────────────────────────────────────────────

Scenario: Entire empty-state section is hidden when all criteria are met
  Given transactionCount is greater than 0
  And accountCount is greater than 0
  And userSettings.globalMonthlyBudget is NOT NULL
  When I open the Home tab
  Then I do NOT see the "Get started" section header
  And I do NOT see any onboarding card
  And the Home tab shows its normal populated content

# ─── Auto-dismiss behavior ───────────────────────────────────────────────────

Scenario: Card disappears immediately after completing the corresponding action
  Given I am on the Home tab
  And the "Add your first transaction" card is visible
  When I add a transaction successfully
  And I return to the Home tab
  Then the "Add your first transaction" card is no longer visible
  And the remaining incomplete cards are still visible

Scenario: Section header disappears when the last remaining card is completed via global budget
  Given only the "Set a monthly budget" card is visible
  And userSettings.globalMonthlyBudget is NULL
  And noCategoryBudget
  When I set a global monthly budget
  And I return to the Home tab
  Then the "Get started" section header is gone
  And no onboarding cards are rendered

Scenario: Section header disappears when the last remaining card is completed via category budget
  Given only the "Set a monthly budget" card is visible
  And userSettings.globalMonthlyBudget is NULL
  And noCategoryBudget
  When I add a category budget (e.g. Food € 20)
  And I return to the Home tab
  Then the "Get started" section header is gone
  And no onboarding cards are rendered

# ─── No manual dismiss ───────────────────────────────────────────────────────

Scenario: Cards cannot be manually dismissed
  Given at least one onboarding card is visible
  Then there is no X button or swipe-to-dismiss gesture on any card
```

## Edge Cases
- [ ] transactionCount becomes 0 again after deletion — card reappears (reactive, driven by DB stream)
- [ ] accountCount drops to 0 after deleting last account — card reappears
- [ ] globalMonthlyBudget reset to NULL AND no category budget exists — budget card reappears
- [ ] globalMonthlyBudget reset to NULL BUT a category budget still exists — budget card stays hidden
- [ ] Last category budget deleted AND globalMonthlyBudget is NULL — budget card reappears
- [ ] All three criteria met simultaneously in one action — section disappears in a single recompose, no flash
- [ ] Rapid navigation between tabs while completing an action — no stale state shown
- [ ] Offline: completion checks use local Drift counts, no network call required
- [ ] iOS vs Android: card layout must not overflow on small screens (SE 3rd gen / small Android)
- [ ] Dark mode: card styling consistent with system theme
- [ ] Accessibility: each card is a focusable semantic node with a descriptive label

## Test Scenarios for QA
1. State 1 (brand-new user) on iOS — all 3 cards visible
2. State 1 (brand-new user) on Android — all 3 cards visible
3. State 2a (global budget + account set, 0 transactions) — only transaction card shown
4. State 2b (category budget + account set, 0 transactions) — only transaction card shown
5. State 3a (only global budget set, no account, no transaction) — transaction + account cards shown
6. State 3b (only category budget set, no account, no transaction) — transaction + account cards shown
7. State 4 (all complete) on iOS — section fully hidden
8. State 4 (all complete) on Android — section fully hidden
9. Add a transaction from card CTA, return to Home — transaction card gone, others intact
10. Delete only account, return to Home — account card reappears reactively
11. Set then clear global budget (no category budget) — budget card reappears
12. Set then clear global budget while a category budget exists — budget card stays hidden
13. globalMonthlyBudget NULL + category budget €20 set — budget card is hidden (new behavior)
14. Delete last category budget (globalMonthlyBudget still NULL) — budget card reappears reactively
15. All 3 completed in sequence — header disappears after last card dismissed
16. No X button visible on any card in any state
17. Accessibility: VoiceOver / TalkBack reads card title and CTA correctly

## UX Spec
See `docs/specs/epic-8a/SPEC-EPIC8A-10-empty-state-cards.md`

## Estimate
M (3–5 days)

## Dependencies
- EPIC8A-01: Home tab IA refactor (tab navigation must exist)
- EPIC8A-05: Total Balance card (Home tab widget tree foundation)
- ADR-010: Global budget field in app_preferences (userSettings.globalMonthlyBudget source)
- Drift DAOs must expose reactive streams for transactionCount and accountCount
- Drift DAOs must expose a reactive stream or computed bool for anyCategoryBudgetExists (category budgets table row count > 0)
