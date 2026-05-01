# Epic 8a — Home Tab + Information Architecture Refresh

**Status:** Ready for engineering
**PM:** pm-agent
**Sponsor approval:** 2026-05-01
**Total estimate:** 22 points
**Epic 8b:** Insight rule implementations + real data integration (separate document, separate sprint)

---

## Sponsor-Approved Decisions (authoritative — do not change without PM escalation)

| Topic | Decision |
|-------|----------|
| Tab structure | 4 tabs: Home \| Transactions \| Budget \| More |
| Accounts location | Moved under More tab |
| Default tab | Home (app launch) |
| Stats tab | Removed; donut → Home (Epic 8b); Budget promoted |
| Balance label | "Total Balance" (EN) / "Toplam Bakiye" (TR) |
| Budget model | Global field in UserSettings Drift table — ADR-010 |
| Sparkline | Stream-based Dart aggregation — ADR-012 |
| InsightProvider | Abstract interface, FutureProvider — ADR-011 |
| Pull-to-refresh | Mandatory on Home tab |
| Tab focus invalidation | Mandatory; approach documented in PR |
| Analytics | `home_tab_viewed` + `insight_card_tapped` only |
| Empty state | Auto-dismiss only, 3 cards, no dismiss button |
| V2 placeholders | Clean V1 — no commented-out scaffolding in UI |
| TR translations | PM owns content; engineer adds `// TODO: TR review` stubs |
| A/B test | No — full commit to Home tab |
| Feature flag | `homeTabEnabled` via dart_define |

---

## Story List

| ID | Title | Assigned to | Points | Phase | Status |
|----|-------|-------------|--------|-------|--------|
| EPIC8A-01 | IA Refactor: 4-Tab Shell + Accounts Relocation | Flutter Engineer | 2 | 1 | Ready |
| EPIC8A-02 | Stats Tab Removal & Codebase Cleanup | Flutter Engineer | 2 | 1 | Ready |
| EPIC8A-03 | HomeScreen Scaffold + Routing | Flutter Engineer | 1 | 1 | Ready |
| EPIC8A-04 | UserSettings Table + Migration + Providers | Flutter Engineer | 2 | 1 | Ready |
| EPIC8A-UX | UX Designer: Home Tab Component Mockups | UX Designer | 3 | 1 (parallel) | Ready |
| EPIC8A-05 | HomeHeader Component | Flutter Engineer | 1 | 2 | Blocked: EPIC8A-03, EPIC8A-UX |
| EPIC8A-06 | NetWorthCard (Total Balance + Sparkline) | Flutter Engineer | 3 | 2 | Blocked: EPIC8A-03, EPIC8A-04, EPIC8A-UX |
| EPIC8A-07 | BudgetPulseCard Component | Flutter Engineer | 2 | 2 | Blocked: EPIC8A-03, EPIC8A-04, EPIC8A-UX |
| EPIC8A-08 | InsightCard Shell + InsightProvider Interface | Flutter Engineer | 2 | 2 | Blocked: EPIC8A-03, EPIC8A-04, EPIC8A-UX |
| EPIC8A-09 | RecentTransactionsList Component | Flutter Engineer | 1 | 2 | Blocked: EPIC8A-03, EPIC8A-UX |
| EPIC8A-10 | Empty State: 3 Onboarding Cards | Flutter Engineer | 2 | 3 | Blocked: EPIC8A-05..09 |
| EPIC8A-11 | Pull-to-Refresh + Tab Focus Invalidation | Flutter Engineer | 1 | 3 | Blocked: EPIC8A-06..08 |
| EPIC8A-12 | Analytics Events | Flutter Engineer | 1 | 3 | Blocked: EPIC8A-03, EPIC8A-08 |
| EPIC8A-13 | Accessibility Audit & Fixes | Flutter Engineer | 2 | 4 | Blocked: EPIC8A-05..10 |
| EPIC8A-14 | Performance Profiling | Flutter Engineer | 1 | 4 | Blocked: EPIC8A-05..11 |
| EPIC8A-15 | QA Test Plan | QA Engineer | 1 | 4 | Blocked: EPIC8A-01..14 |
| EPIC8A-16 | QA Execution | QA Engineer | 2 | 4 | Blocked: EPIC8A-15 |
| EPIC8A-17 | Feature Flag + DevOps | DevOps Engineer | 1 | 4 | Blocked: EPIC8A-16 |

**Total: 30 story points** (22 engineering + 3 UX + 3 QA + 2 DevOps)

> Note: The task brief estimated ~22 points. This breakdown uses the detailed phase structure from the epic document and adds points for the 3 QA/DevOps stories to the 22-point engineering estimate. Engineering-only total is 22 points.

---

## Phase Structure

```
Phase 1 — Foundation (7 points + 3 UX parallel)
  EPIC8A-01  IA Refactor: 4-Tab Shell + Accounts Relocation      [Flutter Eng, 2pt]
  EPIC8A-02  Stats Tab Removal & Codebase Cleanup                 [Flutter Eng, 2pt]
  EPIC8A-03  HomeScreen Scaffold + Routing                        [Flutter Eng, 1pt]
  EPIC8A-04  UserSettings Table + Migration + Providers           [Flutter Eng, 2pt]
  EPIC8A-UX  UX Designer: Home Tab Component Mockups              [UX Designer, 3pt] ← PARALLEL

Phase 2 — Components (9 points)
  EPIC8A-05  HomeHeader Component                                  [Flutter Eng, 1pt]
  EPIC8A-06  NetWorthCard (Total Balance + Sparkline)              [Flutter Eng, 3pt]
  EPIC8A-07  BudgetPulseCard Component                            [Flutter Eng, 2pt]
  EPIC8A-08  InsightCard Shell + InsightProvider Interface         [Flutter Eng, 2pt]
  EPIC8A-09  RecentTransactionsList Component                      [Flutter Eng, 1pt]

Phase 3 — Polish (4 points)
  EPIC8A-10  Empty State: 3 Onboarding Cards                      [Flutter Eng, 2pt]
  EPIC8A-11  Pull-to-Refresh + Tab Focus Invalidation             [Flutter Eng, 1pt]
  EPIC8A-12  Analytics Events                                      [Flutter Eng, 1pt]

Phase 4 — QA + Release (7 points)
  EPIC8A-13  Accessibility Audit & Fixes                          [Flutter Eng, 2pt]
  EPIC8A-14  Performance Profiling                                 [Flutter Eng, 1pt]
  EPIC8A-15  QA Test Plan                                         [QA Engineer, 1pt]
  EPIC8A-16  QA Execution                                         [QA Engineer, 2pt]
  EPIC8A-17  Feature Flag + DevOps                                [DevOps Eng, 1pt]
```

---

## Dependency Graph

```
EPIC8A-UX ──────────────────────────────────────────┐
(day 1, parallel)                                    │
                                                     │
EPIC8A-01 ──► EPIC8A-02                             │
          └──► EPIC8A-03 ─┐                         │
          └──► EPIC8A-04 ─┤                         │
               (sequential │                         │
               after 01)   │                         │
                           └─────────────────────────┤
                                                     ▼
       ┌─────────────────────────────────────┐
       │ Phase 2 (all need 03 + UX; 06/07/08 │
       │ also need 04)                        │
       │  EPIC8A-05 (HomeHeader)              │
       │  EPIC8A-06 (NetWorthCard)            │
       │  EPIC8A-07 (BudgetPulseCard)         │
       │  EPIC8A-08 (InsightCard + Interface) │
       │  EPIC8A-09 (RecentTransactions)      │
       └───────────────┬─────────────────────┘
                       │
            ┌──────────┼──────────┐
            ▼          ▼          ▼
       EPIC8A-10   EPIC8A-11  EPIC8A-12
       (EmptyState)(PtR+Focus)(Analytics)
            │          │
            └────┬─────┘
                 ▼
           ┌────────────┐
           │EPIC8A-13   │
           │(A11y)      │
           └────────────┘
                 │
           EPIC8A-14
           (Perf)
                 │
           EPIC8A-15
           (QA Plan)
                 │
           EPIC8A-16
           (QA Exec)
                 │
           EPIC8A-17
           (Feature Flag)
```

---

## Stories Parallel-Start Rules

> **Sponsor decision (2026-05-01):** EPIC8A-01 and EPIC8A-04 must run sequentially
> (not in parallel) to avoid routing/DB conflict risk. EPIC8A-04 starts only after
> EPIC8A-01 is merged.

1. **Day 1:** EPIC8A-01 + EPIC8A-UX start simultaneously. EPIC8A-04 waits.
2. **After EPIC8A-01 merges:** EPIC8A-02, EPIC8A-03, and EPIC8A-04 can start (02+03 parallel; 04 sequential after 01).
3. **EPIC8A-05 through EPIC8A-09** can start as soon as BOTH EPIC8A-03 AND EPIC8A-UX are complete. EPIC8A-06, 07, 08 additionally require EPIC8A-04.
4. Phase 2 stories (05–09) may run in parallel with each other.
5. **EPIC8A-10 and EPIC8A-11** require all Phase 2 stories complete.
6. **EPIC8A-12** requires EPIC8A-03 and EPIC8A-08 only (can start mid-Phase-2).
7. **EPIC8A-13 and EPIC8A-14** require all Phase 3 stories complete.
8. **EPIC8A-15** requires all Phase 1–4 engineering stories complete (13 + 14).
9. **EPIC8A-16** requires EPIC8A-15.
10. **EPIC8A-17** requires EPIC8A-16 QA sign-off.

---

## What Epic 8b Delivers (not in this sprint)

- ConcentrationRule implementation (1pt)
- SavingsGoalRule implementation (1pt)
- DailyOverpacingRule implementation (1pt)
- BigTransactionRule implementation (1pt)
- Real InsightContext data wiring to rules (2pt)
- Donut chart category breakdown detail screen (2pt)
- Global budget UI in Budget tab (2pt)
- 100% feature flag rollout + production release (2pt)
- Release monitoring and ADR-013 (if StreamProvider upgrade needed) (2pt)

---

## Key File Locations (reference for all agents)

| Concern | File(s) |
|---------|---------|
| Router | `lib/core/router/app_router.dart`, `lib/core/router/app_routes.dart` |
| Home feature | `lib/features/home/` |
| Insights domain | `lib/features/insights/domain/` |
| UserSettings table | `lib/data/local/tables/user_settings_table.dart` |
| UserSettings providers | `lib/features/home/presentation/providers/user_settings_providers.dart` |
| Sparkline provider | `lib/features/home/presentation/providers/sparkline_provider.dart` |
| Design tokens | `lib/core/constants/app_colors.dart`, `app_typography.dart`, `app_spacing.dart` |
| UX mockups | `docs/designs/home-tab/` |
| ADRs | `docs/decisions/ADR-010.md`, `ADR-011.md`, `ADR-012.md` |
| QA outputs | `docs/qa/epic8a-*.md` |
| Release outputs | `docs/releases/epic8a-*.md` |

---

## Definition of Done (Epic 8a)

- [ ] All 17 stories complete and merged to main
- [ ] All P0 and P1 bugs from EPIC8A-16 resolved
- [ ] Performance targets met: < 300ms cached, < 1s cold (EPIC8A-14)
- [ ] Accessibility audit passed: WCAG AA, Reduce Motion, Dynamic Type (EPIC8A-13)
- [ ] `homeTabEnabled` feature flag live on TestFlight + Play Internal (EPIC8A-17)
- [ ] No crash regressions in 7-day monitoring window
- [ ] Sponsor weekly review acceptance
- [ ] Epic 8b stories written and in backlog before Epic 8a closes
