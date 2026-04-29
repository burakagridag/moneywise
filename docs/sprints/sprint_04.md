# Sprint 04 — Trans. Tab Views

**Duration:** 2 weeks (2026-04-29 → 2026-05-12)
**Goal:** Deliver all four TransactionsScreen sub-views (Daily, Calendar, Monthly, Summary),
the shared Month/Year navigator, and the period tab bar — so that a user can browse and
review their transactions across every time dimension available in the app.

At the end of this sprint, the Trans. tab is fully functional with live data from the
transactions repository. A user can view transactions by day, navigate the calendar grid,
inspect monthly totals, and read a period summary — all within a single, navigable screen.

**Source:** SPEC.md §16.1 ("Sprint 4: Trans. Tab Görünümleri"); SPEC.md §9.1 (TransactionsScreen
and all sub-views, Ekran 17–20).

---

## Stories

| ID | Title | Estimate | Status | Owner | Dependencies |
|----|-------|----------|--------|-------|--------------|
| US-020 | TransactionsScreen scaffold + period tab bar | S | Ready | flutter-engineer | US-010 (Sprint 3 Transaction CRUD) |
| US-021 | DailyView — grouped daily transaction list | M | Ready | flutter-engineer | US-020 |
| US-022 | CalendarView — calendar grid with daily spend dots | M | Ready | flutter-engineer | US-020 |
| US-023 | MonthlyView — monthly list grouped by date with totals bar | M | Ready | flutter-engineer | US-020 |
| US-024 | SummaryView — period income / expense / balance / savings summary | M | Ready | flutter-engineer | US-020 |
| US-025 | Month/Year navigator — previous/next arrows + picker | S | Ready | flutter-engineer | US-020 |

---

## Execution Order and Rationale

Stories must be executed in roughly this sequence due to dependencies:

1. **US-025** — Implement the Month/Year navigator widget first. It is a shared widget consumed
   by all four views. Can be developed in parallel with US-020 from Day 1.
2. **US-020** — TransactionsScreen scaffold with the period tab bar (TabController, tab labels,
   Income/Exp/Total summary bar). Provides the hosting shell that all views live inside.
3. **US-021 + US-022 + US-023 + US-024** — All four views depend on US-020 and US-025 being
   available. They can be developed in parallel by slicing work per view once the shell is ready.
   Suggested parallel allocation:
   - Track A: US-021 (DailyView) + US-023 (MonthlyView) — both are list-based views.
   - Track B: US-022 (CalendarView) + US-024 (SummaryView) — CalendarView needs grid layout;
     SummaryView needs horizontal card scroll.

UX specs for US-021, US-022, US-023, US-024, and US-025 must be delivered by ux-designer by
the end of Day 3 (2026-05-01) to avoid blocking flutter-engineer.

---

## Sprint Goal Acceptance Criteria

The sprint is accepted when **all** of the following are true:

- [ ] Trans. tab opens to DailyView by default on both iOS and Android
- [ ] Period tab bar shows five tabs: Daily, Calendar, Monthly, Summary, Description; tapping
      each switches the active view; Description tab shows a placeholder (not in scope this sprint)
- [ ] The active tab shows a brand-color underline; inactive tabs show textSecondary label
- [ ] The Income / Exp. / Total summary bar is visible below the period tab bar for Daily,
      Calendar, and Monthly views; values reflect the currently selected month and are
      recalculated reactively when transactions change
- [ ] Month/Year navigator is present on all four views; tapping < or > changes the active month
      and all views update accordingly; tapping the month-year label opens the MonthYearPicker
- [ ] Monthly view shows "2026" (year only) in the navigator title per SPEC.md §9.1.2
- [ ] DailyView groups transactions by date; each date header shows day number, day-of-week
      badge, daily income (blue) and daily expense (coral); Sunday badge is red, Saturday badge
      is blue; transactions are listed under their date header with category, account, and amount
- [ ] DailyView is empty-state-aware: shows a centred illustration + "No transactions yet" when
      no transactions exist for the selected month
- [ ] CalendarView renders the correct calendar grid for the selected month; cells that have
      transactions show income (blue, top row) and expense (coral, bottom row) amounts; today's
      date cell has a highlighted background; previous/next month day numbers are shown in
      textTertiary; tapping a date cell opens a bottom sheet listing that day's transactions
- [ ] CalendarView empty cells (no transactions) show only the day number with no amount rows
- [ ] MonthlyView lists transactions grouped by date in descending order for the selected year;
      each month row shows the month range, Income, Expense, and Total; the current week row has
      a light-coral background highlight
- [ ] SummaryView Card 1 shows the period's Income, Exp., and Total values
- [ ] SummaryView Card 2 shows the Accounts expense breakdown
- [ ] SummaryView Card 3 shows the Budget card with a Today indicator and progress bar
- [ ] SummaryView Card 4 shows the "Export data to Excel" action row
- [ ] FABs are present on all views: primary brand-color `+` button (opens AddTransactionScreen)
      and secondary bookmark FAB; both are correctly layered above the banner ad placeholder
- [ ] All monetary values use the main currency (from settings) and the `money2`-based formatter;
      no float rounding artifacts in displayed totals
- [ ] `flutter analyze` passes with zero warnings
- [ ] All unit and widget tests pass (`flutter test`)
- [ ] All acceptance criteria verified by QA on both iOS Simulator and Android Emulator

---

## Definition of Ready Check (all stories)

| Story | AC in Gherkin | UX Spec noted | Estimate | Dependencies | Edge Cases | Test Scenarios |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|
| US-020 | Yes | TBD (Sprint 4) | S | Identified | Yes | Yes |
| US-021 | Yes | TBD (Sprint 4) | M | Identified | Yes | Yes |
| US-022 | Yes | TBD (Sprint 4) | M | Identified | Yes | Yes |
| US-023 | Yes | TBD (Sprint 4) | M | Identified | Yes | Yes |
| US-024 | Yes | TBD (Sprint 4) | M | Identified | Yes | Yes |
| US-025 | Yes | TBD (Sprint 4) | S | Identified | Yes | Yes |

All stories are **Ready** per the project Definition of Ready.

---

## UX Design Tasks (parallel, Sprint 4)

The ux-designer must deliver the following specs by Day 3 (2026-05-01) to avoid blocking
flutter-engineer implementation of UI stories:

| Spec file | Required by |
|-----------|-------------|
| `docs/specs/SPEC-008-transactions-screen.md` | US-020 |
| `docs/specs/SPEC-009-daily-view.md` | US-021 |
| `docs/specs/SPEC-010-calendar-view.md` | US-022 |
| `docs/specs/SPEC-011-monthly-view.md` | US-023 |
| `docs/specs/SPEC-012-summary-view.md` | US-024 |
| `docs/specs/SPEC-013-month-year-navigator.md` | US-025 |

Reference screens in SPEC.md: Ekran 17 (SummaryView), Ekran 18 (MonthlyView),
Ekran 19 (CalendarView), Ekran 20 (DailyView); §9.1.2 (Month/Year navigator behaviour).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| CalendarView grid layout complexity causes iOS/Android rendering differences | Medium | Medium | flutter-engineer spikes calendar cell widget on Day 2; use `GridView.builder` with fixed cross-axis count; QA tests on real devices, not only simulators |
| Reactive income/expense totals recomputed for every month navigation cause frame drops | Medium | Medium | Use Drift `.watch()` streams scoped to the visible month range; avoid full-table scans; flutter-engineer to run DevTools timeline before PR |
| SummaryView horizontal card scroll interaction conflicts with TransactionsScreen tab swipe gesture | Low | Medium | Use `PageView` or `ListView(scrollDirection: horizontal)` inside a `GestureDetector` with `HitTestBehavior.deferToChild`; escalate to Orchestrator if unresolved within 4h |
| MonthYearPicker widget not available in core/widgets yet | Medium | Low | US-025 creates `month_year_picker.dart` in `core/widgets/`; scaffold must reference it via a temporary stub if US-025 is delayed |
| Description tab placeholder leads to confusion in QA | Low | Low | Clearly labelled "Coming soon" placeholder widget; QA scenario explicitly covers this tab showing the placeholder |
| UX specs not ready in time | Medium | Medium | ux-designer has hard deadline of Day 3 (2026-05-01); PM escalates on Day 2 if not on track |

---

## Out of Scope for Sprint 4

- Description View full implementation (placeholder only)
- Transaction search / filter modal (Sprint 6)
- Bookmark picker modal interaction from FAB (Sprint 6)
- Stats tab / pie chart (Sprint 5)
- Budget view (Sprint 5)
- Account balance trend chart / AccountDetailScreen (Sprint 5)
- Recurring transaction scheduling (Sprint 7)
- Excel export from SummaryView (Sprint 8 — button is rendered but wired to a "not yet available" snackbar)
- Cloud sync (Phase 2)
- Passcode / biometric lock (Sprint 8)
- Backup / restore (Sprint 8)

---

## Team Capacity

| Member | Available days (2 weeks) |
|--------|--------------------------|
| flutter-engineer | 10 |
| ux-designer | 5 (6 screen specs by Day 3) |
| code-reviewer | 3 (rolling PR reviews) |
| QA | 3 (end-of-sprint acceptance on iOS + Android) |
| devops | 1 (CI health check; no new pipeline changes expected) |

---

## Sprint Retrospective Placeholder

*(To be filled in on 2026-05-12)*

- What went well:
- What could improve:
- Action items:
