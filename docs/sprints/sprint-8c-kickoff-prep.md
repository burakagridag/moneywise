# Sprint 8c — Kickoff Preparation

## Status
Pending kickoff — awaiting WeekendSpendingRule Sponsor approval.

## Scope (Confirmed — updated 2026-05-07)

| Sıra | Epic | Story | Estimate | Status |
|------|------|-------|----------|--------|
| 1 | EPIC8B-09 | WeekendSpendingRule | 2pt | ✅ Done (commit 3f678b7) |
| 2 | **EPIC8C-01** | **Budget Screen Redesign** | **5pt** | **🔜 Next — Sponsor mockup approved** |
| 3 | EPIC8B-07 | Global Budget Settings UI | 4pt | Blocked on EPIC8C-01 |
| 4 | EPIC8B-06 | Category breakdown + donut chart | 4pt | Blocked on EPIC8C-01 |

**Dependency chain:** EPIC8C-01 → EPIC8B-07 (edits hero card) → EPIC8B-06 (fills donut placeholder)

**Reference files:**
- `docs/user_stories/epic-8c/EPIC8C-01-budget-screen-redesign.md`
- `docs/specs/references/EPIC8C-01-v1-reference-light.html`
- `docs/specs/references/EPIC8C-01-v1-reference-dark.html`

**Out of scope (moved):**
- Account Onboarding Initial Balance Flow → **Sprint 8d** (Sponsor decision 2026-05-07)
- BudgetPulseCard TR wording fix → Done (hotfix #10, merged 2026-05-07)

## First-Day Tasks (Sprint 8c Day 1)
- [ ] BigTransaction ≤100% smoke test — 10 minutes, no code change needed
- [ ] WeekendSpendingRule kickoff (pending Sponsor approval of spec)

## Process Improvements Active in Sprint 8c
All 9 items from Sprint 8b Retrospective Section 5 are mandatory:
- Item 1: PM grep verification checklist
- Item 2: ADR Living Document — wording approval required
- Item 3: Mid-sprint Sponsor check (Day 3)
- Item 4: Pre-PR smoke test on iPhone 16 Pro Max
- Item 5: TR review pre-merge (Sponsor reviews app_tr.arb diff)
- Item 6: Test setup pre-validation (no stub-only tests)
- Item 7: Branch cleanup protocol after every merge
- Item 8: Simulator device standard — always iPhone 16 Pro Max
- **Item 9: PM reports internal process failures to Sponsor within 24h** — NEW, strict enforcement

## Decisions Carried Forward
- Account Onboarding: Sprint 8d
- OverBudgetRule: V1.x (after EPIC8B-07 ships)
- ThemeMode.system full fix: V1.x
- WeekendSpendingRule threshold: pending Sponsor approval

## Sprint 8b Retrospective
Approved by Sponsor 2026-05-07. File: `docs/retrospectives/sprint-8b-retrospective.md`
