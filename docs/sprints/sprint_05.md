# Sprint 05 — Stats Tab, Budget, and Note Views

**Duration:** 2 weeks (2026-05-13 → 2026-05-26)
**Goal:** Deliver the fully functional Stats tab with three sub-views (Stats pie chart,
BudgetView with progress bars, NoteView), the BudgetSettingScreen reachable from the More
tab, and the complete Budget data layer (Drift table, DAO, repository, carry-over use case)
— so that a user can visualise category spending, set monthly budget limits, track budget
progress with carry-over, and browse note-grouped transaction summaries.

At the end of this sprint, the Stats tab is fully functional with live data from the
transaction and budget repositories. A user can see where their money goes via a pie chart,
understand budget health at a glance via progress bars, configure budgets from the More tab,
and review note-grouped spending patterns.

**Source:** SPEC.md §16.1 ("Sprint 5: Stats & Budget"); SPEC.md §9.3 (StatsScreen,
Ekran 14–16); SPEC.md §9.11 (BudgetSettingScreen, Ekran 4); SPEC.md §6.5 (budgets table).

---

## Stories

| ID | Title | Estimate | Status | Owner | Dependencies |
|----|-------|----------|--------|-------|--------------|
| US-027 | Budget DB layer — Drift table, DAO, repository, carry-over use case | M | Ready | flutter-engineer | US-003 (categories), US-010 (transactions) |
| US-026 | StatsScreen scaffold + pie chart (fl_chart) | M | Ready | flutter-engineer | US-027, US-010, US-003 |
| US-028 | BudgetView — summary card + per-category progress bars | M | Ready | flutter-engineer | US-027, US-026, US-029 |
| US-029 | BudgetSettingScreen — create/edit category budgets | M | Ready | flutter-engineer | US-027, US-003 |
| US-030 | NoteView — note-grouped transaction summary list | S | Ready | flutter-engineer | US-026, US-010 |

---

## Execution Order and Rationale

Stories must be executed in this sequence due to data-layer dependencies:

1. **US-027** — Budget DB layer must be implemented first. It is the foundation for US-028
   and US-029. The Drift schema migration, BudgetDAO, BudgetRepository, and CarryOverBudget
   use case must all be in place and tested before any UI story touches budget data.
   Estimated: Days 1–4.

2. **US-026** — StatsScreen scaffold provides the three-sub-tab shell (Stats / Budget / Note)
   with the shared Month/Year navigator, Income/Exp. toggle, and period selector. It also
   delivers the Stats sub-tab with the fl_chart pie chart and category legend list. This
   story can begin in parallel with US-027 for the scaffold portion (no budget data needed
   for the pie chart), then wire the Stats sub-tab to live data once US-027 is done.
   Estimated: Days 1–6.

3. **US-029** — BudgetSettingScreen can begin as soon as US-027 is done (Day 5 at the
   earliest). It requires only the BudgetRepository.upsert API and the category list; it
   does not depend on US-026 (it is a separate route under More tab).
   Estimated: Days 5–8.

4. **US-028** — BudgetView depends on US-026 (for the sub-tab host), US-027 (for budget
   data), and US-029 (for the "Budget Setting >" navigation target). It can start once
   US-027 and the US-026 scaffold are in place (Day 5).
   Estimated: Days 5–9.

5. **US-030** — NoteView is the simplest story (S estimate). It depends only on US-026
   for the sub-tab host and the existing transaction repository. It can begin in parallel
   with US-028 from Day 5 onwards.
   Estimated: Days 5–7.

### Suggested Parallel Allocation (after US-027 unblocks)
- Track A: US-026 (pie chart completion) → US-028 (BudgetView)
- Track B: US-029 (BudgetSettingScreen) → US-030 (NoteView)

UX specs for US-026, US-028, US-029, and US-030 must be delivered by ux-designer by
end of Day 3 (2026-05-15) to avoid blocking flutter-engineer on UI implementation.

---

## Sprint Goal Acceptance Criteria

The sprint is accepted when **all** of the following are true:

- [ ] Navigating to the Stats tab opens the Stats sub-tab by default on both iOS and Android
- [ ] The three-sub-tab control ("Stats" / "Budget" / "Note") is visible and tappable;
      the active sub-tab has a brand-color fill; inactive tabs are in textSecondary
- [ ] The period selector ("M ▼") opens a picker with W / M / Y options; selecting one
      updates the Month/Year navigator and all sub-tab data
- [ ] The Month/Year navigator (`< Apr 2026 >`) advances and retreats the selected period;
      all three sub-tabs update reactively
- [ ] The Income / Exp. toggle switches between income and expense aggregation across all
      three sub-tabs
- [ ] Stats sub-tab: a donut pie chart is rendered using fl_chart with expense (or income)
      data for the selected month; each segment uses a distinct brand-palette color; the
      category legend list shows emoji + category name + amount + percentage badge
- [ ] Stats sub-tab: tapping a pie segment navigates to DailyView filtered by that category
- [ ] Stats sub-tab: empty period shows an empty-state illustration and "No data for this
      period" text with no chart rendered
- [ ] Budget sub-tab: the summary card shows overall remaining budget, total budget,
      spent amount, a progress bar, and a "Today" indicator
- [ ] Budget sub-tab: the "Budget Setting >" link navigates to BudgetSettingScreen
- [ ] Budget sub-tab: per-category progress bars reflect the correct spent/budget ratio;
      colors are brand (normal), warning orange (≥ 80%), error red (≥ 100%)
- [ ] Budget sub-tab: carry-over is applied when carryOverEnabled = true; the effective
      budget displayed is base + prior month remainder (clamped to 0)
- [ ] Note sub-tab: transactions are grouped by note value and sorted by amount descending;
      the count column shows how many transactions share each note; "(no note)" group appears
      for transactions with an empty Note field
- [ ] Note sub-tab: tapping a note row opens a detail view or bottom sheet with individual
      transactions for that note
- [ ] BudgetSettingScreen is reachable from More tab → "Budget Setting" row
- [ ] BudgetSettingScreen lists all expense (or income) categories with current budget values;
      TOTAL row is always first
- [ ] Tapping a category row opens the BudgetEditModal; saving with "Only this month"
      unchecked applies to all future months; saving with it checked creates a
      month-bounded override
- [ ] Budget DB layer: Drift migration adds the budgets table cleanly on existing installs
      (no data loss from Sprint 3/4 data)
- [ ] Carry-over logic: negative carry-over is clamped to 0 (overspending does not reduce
      the next month's budget below its configured value)
- [ ] All monetary values use the main currency and money2-based formatter; no float
      rounding artifacts in totals or percentages
- [ ] `flutter analyze` passes with zero warnings
- [ ] All unit and widget tests pass (`flutter test`)
- [ ] All acceptance criteria verified by QA on both iOS Simulator and Android Emulator

---

## Definition of Ready Check (all stories)

| Story | AC in Gherkin | UX Spec noted | Estimate | Dependencies | Edge Cases | Test Scenarios |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|
| US-027 | Yes | N/A (data layer) | M | Identified | Yes | Yes |
| US-026 | Yes | TBD (Sprint 5) | M | Identified | Yes | Yes |
| US-028 | Yes | TBD (Sprint 5) | M | Identified | Yes | Yes |
| US-029 | Yes | TBD (Sprint 5) | M | Identified | Yes | Yes |
| US-030 | Yes | TBD (Sprint 5) | S | Identified | Yes | Yes |

All stories are **Ready** per the project Definition of Ready.

---

## UX Design Tasks (parallel, Sprint 5)

The ux-designer must deliver the following specs by Day 3 (2026-05-15) to avoid blocking
flutter-engineer UI implementation:

| Spec file | Required by |
|-----------|-------------|
| `docs/specs/SPEC-014-stats-screen.md` | US-026 |
| `docs/specs/SPEC-015-budget-view.md` | US-028 |
| `docs/specs/SPEC-016-budget-setting-screen.md` | US-029 |
| `docs/specs/SPEC-017-note-view.md` | US-030 |

Reference screens in SPEC.md: Ekran 16 (StatsScreen — pie chart), Ekran 15 (BudgetView),
Ekran 14 (NoteView), Ekran 4 (BudgetSettingScreen); §9.3 (full StatsScreen spec).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| fl_chart pie chart performance with many segments causes frame drops on older devices | Medium | Medium | Cap chart segments at 9 + "Other"; run DevTools timeline before PR; test on low-end Android emulator |
| Drift schema migration (adding budgets table) breaks existing Sprint 3/4 DB state | Medium | High | Write migration under `schemaVersion` bump with `onCreate` guard; test with in-memory DB snapshot from Sprint 4 |
| Carry-over calculation logic has off-by-one month boundary bug | Medium | High | Unit-test edge cases: first day of month, last day of month, February boundary; QA verifies on real device clock |
| BudgetSettingScreen modal state leaks between categories (tapping Food pre-fills Gym) | Low | Medium | Each BudgetEditModal instance receives its own local state; modal is recreated on each open |
| "Today" indicator on progress bar overflows on first or last day of month | Low | Medium | Clamp position to [0.0, 1.0] range before passing to the progress bar widget |
| NoteView Drift GROUP BY query performance on large datasets (thousands of transactions) | Low | Low | Index on `(note, date)` already available; Drift watch stream re-runs only on mutation events |
| UX specs not ready in time | Medium | Medium | ux-designer has hard deadline of Day 3 (2026-05-15); PM escalates on Day 2 if not on track |
| Sprint 4 PR still open when Sprint 5 begins | Low | High | Per CLAUDE.md branching rules: Sprint 5 branch is created from `origin/main` only after Sprint 4 merges; if Sprint 4 is delayed, Sprint 5 branches from Sprint 4's branch and rebases post-merge |

---

## Out of Scope for Sprint 5

- AccountDetailScreen with balance trend chart (Sprint 6)
- MoreScreen full implementation (Sprint 6)
- TransactionSettingsScreen carry-over toggle persistence (Sprint 6 — toggle exists in Sprint 5 DB layer but UI settings screen is Sprint 6)
- Recurring transaction scheduling (Sprint 7)
- Excel export from SummaryView (Sprint 8)
- Passcode / biometric lock (Sprint 8)
- Backup / restore (Sprint 8)
- Cloud sync (Phase 2)
- Description View full implementation in Trans. tab (still placeholder)
- Search / filter modal in Trans. tab (Sprint 6)

---

## Team Capacity

| Member | Available days (2 weeks) |
|--------|--------------------------|
| flutter-engineer | 10 |
| ux-designer | 4 (4 screen specs by Day 3) |
| code-reviewer | 3 (rolling PR reviews) |
| QA | 3 (end-of-sprint acceptance on iOS + Android) |
| devops | 1 (CI health check; no new pipeline changes expected) |

---

## Sprint Retrospective Placeholder

*(To be filled in on 2026-05-26)*

- What went well:
- What could improve:
- Action items:
