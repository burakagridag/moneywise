# Epic 8a — BudgetPulseCard Hotfix Stories

**Source:** Product Sponsor bug reports (2026-05-01)
**Component:** `BudgetPulseCard`
**Priority:** P0 — UI correctness regressions, blocking weekly review acceptance

---

## HOTFIX-01: Negative zero display ("−€0.00")

### Story
**As** a MoneyWise user who has spent exactly their full budget
**I want** the remaining amount to display as "€0.00"
**So that** I do not see a misleading "−€0.00" sign that implies I am over budget

### Root Cause
When `remaining == spent` (budget fully consumed), floating-point arithmetic produces
`-0.0`, which renders as "−€0.00".

### Acceptance Criteria

```gherkin
Scenario: Remaining amount is negative zero
  Given I have a budget of €10.00
  And I have spent exactly €10.00
  When BudgetPulseCard renders the remaining amount
  Then the displayed amount is "€0.00"
  And no minus sign is shown

Scenario: Remaining amount is a small negative epsilon (< 0.005)
  Given the computed remaining value is −€0.004
  When BudgetPulseCard renders the remaining amount
  Then the displayed amount is "€0.00"
  And no minus sign is shown

Scenario: Remaining amount is a genuine negative value (>= 0.005 absolute)
  Given the computed remaining value is −€0.50
  When BudgetPulseCard renders the remaining amount
  Then the displayed amount is "−€0.50" (or the over-budget format per HOTFIX-02)
```

**Rule:** If `remaining.abs() < 0.005`, render "€0.00" with no sign.

### Edge Cases
- [ ] Exactly `remaining == 0.0` — must display "€0.00"
- [ ] Exactly `remaining == -0.0` (IEEE 754) — must display "€0.00"
- [ ] `remaining == -0.004` (epsilon below threshold) — must display "€0.00"
- [ ] `remaining == -0.005` (at threshold boundary) — displays as over-budget per HOTFIX-02
- [ ] Large negative remainings — unaffected by this rule

### Test Scenarios for QA
1. Spend exactly 100% of budget — confirm "€0.00" displayed, no minus sign
2. Spend 100% + €0.004 — confirm "€0.00" displayed (epsilon clamp)
3. Spend 100% + €0.005 — confirm over-budget formatting kicks in (HOTFIX-02)
4. Spend 50% of budget — confirm normal positive remaining unaffected

### UX Spec
N/A — logic fix only; no layout change.

### Estimate
S (< 1 day)

### Dependencies
- HOTFIX-02 (over-budget formatting) — implement together to avoid double-touches

---

## HOTFIX-02: Incorrect "left" label when remaining is negative

### Story
**As** a MoneyWise user who has exceeded their budget
**I want** the subtitle to read "€X.XX over budget" instead of "−€X.XX left of €Y.YY budget"
**So that** the message is semantically correct and immediately actionable

### Acceptance Criteria

```gherkin
Scenario: Remaining is positive — standard label
  Given remaining is €3.50 of a €10.00 budget
  When BudgetPulseCard renders the subtitle
  Then the subtitle reads "€3.50 left of €10.00 budget"

Scenario: Remaining is zero — handled by HOTFIX-01 and HOTFIX-03
  Given remaining is €0.00 (after HOTFIX-01 clamp)
  When BudgetPulseCard renders the subtitle
  Then the subtitle reads "€0.00 left of €10.00 budget"

Scenario: Remaining is negative — over-budget label
  Given remaining is −€0.50 of a €10.50 budget
  When BudgetPulseCard renders the subtitle
  Then the subtitle reads "€0.50 over budget"
  And the "of €10.50 budget" portion is NOT shown
  And the amount displayed is the absolute value of remaining (€0.50)
```

**Rule:**
- `remaining >= 0` → `"€{remaining} left of €{budget} budget"`
- `remaining < 0` (and `remaining.abs() >= 0.005`) → `"€{remaining.abs()} over budget"` (budget label hidden)

### Edge Cases
- [ ] `remaining == 0` — positive branch applies (per HOTFIX-01, rendered as "€0.00 left of …")
- [ ] `remaining == -0.004` — clamped to zero by HOTFIX-01, positive branch applies
- [ ] Very large overspend (e.g., −€9999.99) — over-budget label, no truncation
- [ ] Currency symbol position varies by locale — label must remain grammatically correct

### Test Scenarios for QA
1. Positive remaining — confirm "X left of Y budget" on iOS and Android
2. Zero remaining (after clamp) — confirm "€0.00 left of Y budget"
3. Negative remaining −€0.50 — confirm "€0.50 over budget", no "budget" suffix label
4. Negative remaining −€9999.99 — confirm large over-budget renders without overflow

### UX Spec
N/A — copy and logic fix only.

### Estimate
S (< 1 day)

### Dependencies
- HOTFIX-01 (negative-zero clamp must be applied before label logic)

---

## HOTFIX-03: "Over budget" shown when remaining == 0

### Story
**As** a MoneyWise user who has spent exactly their budget
**I want** the status indicator to read "On budget"
**So that** I am not incorrectly alarmed by an "Over budget" warning when I am precisely on target

### Acceptance Criteria

```gherkin
Scenario: remaining > 0 — on track
  Given remaining is €3.50
  When BudgetPulseCard renders the status chip
  Then the status reads "On track"
  And the chip color is green or neutral

Scenario: remaining == 0 — exactly on budget
  Given remaining is €0.00 (including values clamped by HOTFIX-01)
  When BudgetPulseCard renders the status chip
  Then the status reads "On budget"
  And the chip color is warning yellow

Scenario: remaining < 0 — over budget
  Given remaining is −€0.50 (after HOTFIX-01 clamp, abs >= 0.005)
  When BudgetPulseCard renders the status chip
  Then the status reads "Over budget"
  And the chip color is red
```

**Three-state rule:**

| Condition | Label | Color token |
|---|---|---|
| `remaining > 0` | "On track" | `colorSuccess` / green-neutral |
| `remaining == 0` (post-clamp) | "On budget" | `colorWarning` / warning yellow |
| `remaining < 0` (post-clamp) | "Over budget" | `colorError` / red |

### Edge Cases
- [ ] `remaining == 0.0` — "On budget", not "Over budget"
- [ ] `remaining == -0.0` — treated as zero after HOTFIX-01 clamp, "On budget"
- [ ] `remaining == -0.004` — clamped to zero, "On budget"
- [ ] `remaining == -0.005` — over-budget branch, "Over budget"
- [ ] Color tokens must respect Light/Dark theme (no hardcoded hex values)
- [ ] Status chip must be visible with sufficient contrast in both themes (WCAG AA)

### Test Scenarios for QA
1. remaining > 0 — "On track" chip, green color, iOS + Android
2. remaining == 0 (exact) — "On budget" chip, yellow color
3. remaining == -0.004 (clamped) — "On budget" chip, yellow color
4. remaining == -0.005 (just over) — "Over budget" chip, red color
5. remaining < 0 (large) — "Over budget" chip, red color
6. Dark theme — all three states, contrast check

### UX Spec
N/A — label and color-token fix only; chip shape/size unchanged.

### Estimate
S (< 1 day)

### Dependencies
- HOTFIX-01 (clamp must run before state evaluation)
- HOTFIX-02 (subtitle label uses same state branch; implement together)

---

## HOTFIX-04: BudgetPulseCard Spent Scope Mismatch in Fallback Mode

**Source:** Product Sponsor bug report (2026-05-01)

### Problem
In fallback mode (no global budget set, only category-level budgets exist), `BudgetPulseCard`
computes `spent` as the sum of ALL transactions for the current month, while `budget` is the
sum of only the budgeted categories. This compares two different scopes and produces a
misleading remaining / over-budget figure.

### Story
**As** a MoneyWise user who uses category budgets without a global budget
**I want** the BudgetPulseCard to count only the spending in budgeted categories as "spent"
**So that** the Home tab and Budget tab show the exact same numbers

### Correct Logic

| Mode | `spent` | `budget` |
|------|---------|----------|
| Global budget is set | SUM(all transactions, current month) | globalBudget amount |
| Fallback (category budgets only) | SUM(transactions WHERE category HAS a budget, current month) | SUM(categoryBudgets) |

The Transactions tab total (all spending) is unaffected by this rule and must remain unchanged.

### Acceptance Criteria

```gherkin
Scenario: Global budget is set — all spending counts
  Given a global budget of €500.00
  And Food spending of €11.00 (Food has a category budget)
  And Social Life spending of €10.00 (Social Life has no category budget)
  When BudgetPulseCard renders
  Then spent is €21.00
  And budget is €500.00

Scenario: Fallback mode — only budgeted-category spending counts
  Given no global budget is set
  And a Food category budget of €11.50
  And Food spending of €11.00
  And Social Life spending of €10.00 (Social Life has no budget)
  When BudgetPulseCard renders
  Then spent is €11.00
  And budget is €11.50
  And remaining is €0.50

Scenario: Home tab and Budget tab show identical figures in fallback mode
  Given no global budget is set
  And a Food category budget of €11.50
  And Food spending of €11.00
  And Social Life spending of €10.00
  When I view BudgetPulseCard on the Home tab
  Then spent is €11.00, budget is €11.50, remaining is +€0.50
  When I view the Budget tab
  Then the same spent, budget, and remaining values are displayed

Scenario: Transactions tab total is unaffected
  Given the same setup as the fallback mode scenario above
  When I view the Transactions tab
  Then the total spending displayed is €21.00
```

### Edge Cases
- [ ] No transactions in any budgeted category — spent = €0.00, budget = SUM(categoryBudgets)
- [ ] All spending is in unbudgeted categories — spent = €0.00 in fallback mode (not negative, not zero-budget warning)
- [ ] A category budget is deleted mid-month — transactions for that category are excluded from spent retroactively
- [ ] Global budget is set to €0.00 — treated as "global budget IS set"; all transactions count as spent
- [ ] Mixed scenario: some categories have budgets, some do not — only budgeted ones contribute to spent
- [ ] Currency precision — no float rounding errors when summing category-filtered transactions
- [ ] Offline — filter logic is local-first, no network dependency

### Test Scenarios for QA
1. Global budget active: confirm spent = all-transaction total, not category-filtered (iOS + Android)
2. Fallback mode: confirm spent = budgeted-category transactions only
3. Home BudgetPulseCard vs Budget tab: numbers match exactly in fallback mode
4. Transactions tab total: confirm it remains the unfiltered all-transaction sum
5. No budgeted-category spending: spent shows €0.00, card does not crash
6. Category budget deleted mid-month: confirm that category's transactions drop out of spent
7. Currency precision: sub-cent sums do not produce rounding artifacts

### UX Spec
N/A — logic and data-layer fix only; card layout unchanged.

### Estimate
M (2–3 days — requires provider/repository filter logic change and Home + Budget tab verification)

### Dependencies
- HOTFIX-01, HOTFIX-02, HOTFIX-03 (negative-zero and label fixes — implement in same batch)
- Budget tab InsightProvider (must share the same filtered-spent computation)

### V2 Backlog
P3 — "BudgetPulseCard: show unbudgeted spending warning" — display unbudgeted-category spending
as a separate informational line (e.g., "€10.00 additional untracked spending this month").

---

## BACKLOG-01: Daily pace early-month UX (P3 — V2)

**Priority:** P3 — Phase 3 / V2 backlog. Not a blocker for current sprint.

### Story
**As** a MoneyWise user early in the month
**I want** the BudgetPulseCard to show "Spent this month: €X" instead of "Daily pace €X"
**So that** a daily pace calculated from very few days does not mislead me

### Rationale
During the first 5 days of a month, the daily-pace projection is statistically unreliable
(small sample size, atypical spend clustering). Showing raw month-to-date spend is more
honest and actionable.

### Proposed Rule (to be refined at V2 planning)
- Days 1–5 of month: display "Spent this month: €X.XX"
- Days 6+: display "Daily pace €X.XX / day"

### Acceptance Criteria (draft — to be finalized in V2 sprint)

```gherkin
Scenario: Early month (day <= 5)
  Given today is within the first 5 days of the month
  When BudgetPulseCard renders the pace line
  Then it displays "Spent this month: €X.XX"

Scenario: Mid/late month (day > 5)
  Given today is day 6 or later
  When BudgetPulseCard renders the pace line
  Then it displays "Daily pace €X.XX / day"
```

### Edge Cases (draft)
- [ ] Month boundary (day 5 → day 6) — transition at midnight, no flicker
- [ ] No spend in first 5 days — "Spent this month: €0.00"
- [ ] Locale-aware date check (device timezone, not UTC)

### Estimate
S (< 1 day) — deferred to V2

### Dependencies
- None blocking current sprint
