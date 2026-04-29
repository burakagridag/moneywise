# Sprint 03 — Transaction Management, Statistics & SQLCipher Encryption

**Duration:** 2 weeks (2026-04-30 → 2026-05-13)
**Branch:** `sprint/03-transactions-stats-sqlcipher`
**Sprint Goal:** Users can record, view, edit, and delete income, expense, and transfer transactions. The Statistics screen replaces its placeholder with a real pie chart. All data is encrypted at rest with SQLCipher.

---

## Context

Sprint 1 delivered the app skeleton, navigation, and theme system.
Sprint 2 delivered the account and category management data layer and screens (merged to main on 2026-04-29).
Sprint 3 delivers the **core financial recording loop** — without transactions, the app has no user value. It also retires the SQLCipher deferral logged in ADR-004.

---

## Stories

| ID | Title | Estimate | Priority | Status |
|----|-------|----------|----------|--------|
| US-017 | Activate SQLCipher database encryption | M | P0 — must ship before transaction writes | Ready |
| US-010 | Add an expense transaction | M | P0 — core feature | Ready |
| US-011 | Add an income transaction | S | P0 — shares modal with US-010 | Ready |
| US-012 | Add a transfer between accounts | S | P0 — shares modal with US-010 | Ready |
| US-013 | Edit an existing transaction | M | P1 | Ready |
| US-014 | Delete a transaction | S | P1 | Ready |
| US-015 | View transactions in the Trans. tab Daily view | L | P0 — primary display surface | Ready |
| US-016 | Statistics screen — pie chart by category | L | P1 | Ready |

**Total estimate:** 3S + 3M + 2L — approximately 10–14 engineering days for one senior Flutter engineer.

---

## Sprint Goal Acceptance

The sprint is considered complete when ALL of the following are true:

- [ ] A fresh install creates an SQLCipher-encrypted database; existing Sprint 2 databases are re-keyed on upgrade
- [ ] Users can add expense, income, and transfer transactions via the Add Transaction modal
- [ ] Account balances update reactively after every transaction save, edit, or delete
- [ ] The Trans. tab Daily view lists all transactions for the selected month, grouped by day, with a correct Income / Expense / Total summary bar
- [ ] The Stats screen shows a donut pie chart broken down by category for the selected month (Expense and Income modes)
- [ ] Transactions can be edited (all fields) and deleted (with confirmation)
- [ ] All acceptance criteria in US-010 through US-017 are verified by QA on both iOS and Android
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` passes
- [ ] Code reviewed and approved
- [ ] Deployed to TestFlight + Play Internal

---

## Definition of Ready — Pre-Sprint Checklist

All stories carry Gherkin acceptance criteria, edge cases, QA test scenarios, estimates, and dependency maps in `docs/user_stories/sprint-03-transactions-stats-sqlcipher.md`. DoR is satisfied for all 8 stories.

---

## Work Ordering (Recommended Implementation Sequence)

### Week 1 (2026-04-30 → 2026-05-06)

**Day 1–2: US-017 — SQLCipher**
Start here. The encrypted database executor must be in place before any transaction data is written by other stories. Delivers:
- `sqlcipher_flutter_libs` replaces `sqlite3_flutter_libs` in pubspec.yaml
- `flutter_secure_storage` added
- Key generation + secure storage on first launch
- Upgrade migration (re-key existing unencrypted DB)
- CI verified (in-memory tests unaffected)

**Day 2–4: US-010 + US-011 + US-012 — Add Transaction (all types)**
Implement together since they share one modal and one new `TransactionRepository`. Delivers:
- `TransactionsTable` (Drift) + migration
- `TransactionDao` + `TransactionRepository`
- `AddTransactionScreen` modal with Income / Expense / Transfer toggle
- Category picker (filtered by type)
- Account picker (single for income/expense, dual for transfer)
- Date picker (Cupertino-style)
- Validation logic (disabled Save/Continue)
- Reactive account balance stream update
- Riverpod providers: `addTransactionProvider`, `transactionsProvider`

**Day 5: US-013 + US-014 — Edit & Delete**
Built on top of the Add modal (pre-fill + update/softDelete repository methods).

### Week 2 (2026-05-07 → 2026-05-13)

**Day 6–8: US-015 — Trans. tab Daily view**
Activate the placeholder `TransactionsScreen` with real data. Delivers:
- Grouped-by-day list with day headers (income/expense per day)
- Income / Expense / Total summary bar
- Month navigator (< Apr 2026 >)
- Empty state
- 5 sub-tabs scaffolded (Daily active; Calendar/Monthly/Summary/Description as placeholders)
- Performance: lazy list, Drift reactive stream

**Day 9–11: US-016 — Statistics screen**
Activate the placeholder `StatsScreen`. Delivers:
- Donut pie chart (fl_chart) with category breakdown
- Category list ranked by amount
- Income/Expense toggle
- Month navigator
- Segment tap → filtered transaction list navigation
- Empty state

**Day 12–13: QA + Bug Fixes**
QA runs full test scenarios on both platforms per the test scenario lists in each story. Engineer addresses findings.

**Day 14: Code review gate + DevOps deploy**
Code reviewer approves. DevOps cuts TestFlight + Play Internal builds.

---

## Technical Notes for Flutter Engineer

1. **TransactionRepository** is a new top-level dependency. It must be created before US-013/014/015/016 can be implemented.

2. **Double-entry balance formula** (SPEC §7.1) must be implemented as a Drift reactive query or computed view — NOT as a cached column. Balance = `initialBalance + SUM(income) - SUM(expense) - SUM(transfer out) + SUM(transfer in)`.

3. **Transfer is ONE database row**, not two. `type='transfer'`, `accountId=from`, `toAccountId=to`. The balance formula above handles both sides. (SPEC §7.2)

4. **SQLCipher upgrade path**: the re-key strategy is documented in ADR-004. The database.dart already has a deferred TODO comment. Sprint 3 must remove `sqlite3_flutter_libs` from pubspec.yaml (it was removed during Sprint 2 to fix a macOS build conflict per sponsor brief; Sprint 3 re-introduces `sqlcipher_flutter_libs` as the sole SQLite provider).

5. **fl_chart version**: 0.68+ per SPEC §4.1. Pie/donut chart. Color palette for segments must use the brand palette referenced in SPEC §2.1.

6. **Riverpod providers**: the existing `accountsProvider` and `categoriesProvider` from Sprint 2 will feed into new `transactionsProvider` and `statsProvider`. Keep providers in their respective feature directories (feature-first architecture, SPEC §5).

7. **ADR required** if there are disputes on: balance caching strategy, SQLCipher key derivation method, or pie chart segment grouping rule for small slices. Log any new ADRs in `docs/decisions/`.

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| SQLCipher re-key corrupts existing test data | Medium | High | Test on a separate device first; implement a backup-before-rekey step; show data-loss recovery screen on failure |
| fl_chart API changes break pie chart widget | Low | Medium | Pin to exact version in pubspec.yaml; read changelog before upgrade |
| Double-entry balance formula has off-by-one in reactive stream | Medium | High | Dedicate a unit test suite specifically to balance calculation scenarios (zero, all income, all expense, mix, transfers) |
| Stats aggregation query is slow on large datasets | Low | Medium | Add DB indexes per SPEC §6.4 before running QA perf tests |
| Two-week scope is too large for one engineer | Medium | Medium | US-016 (Stats) is the lowest-dependency story and can slip to Sprint 3.5 if needed; US-010–015 are non-negotiable |

---

## Dependencies on Prior Sprints

| Dependency | From Sprint | Status |
|-----------|-------------|--------|
| AccountRepository (read accounts list) | Sprint 2 | Merged to main |
| CategoryRepository (read categories, filtered by type) | Sprint 2 | Merged to main |
| Drift database schema (accounts, categories tables) | Sprint 2 | Merged to main |
| sqlcipher_flutter_libs binary linked in pubspec.yaml | Sprint 2 (ADR-004) | Linked but key not activated |
| go_router navigation (modal routes) | Sprint 1 | Merged to main |
| Theme system, AppButton, AppTextField widgets | Sprint 1 | Merged to main |

---

## Out of Scope for Sprint 3

The following are explicitly deferred and must not be implemented:
- Calendar view, Monthly view, Summary view, Description view (Trans. tab sub-tabs beyond Daily)
- Budget sub-tab in Stats screen
- Note sub-tab in Stats screen
- Recurring transactions
- Bookmark templates
- Attachment / receipt photos
- Passcode / biometric lock
- Backup / restore
- Multi-currency exchange rates (Phase 1: exchange rate = 1.0)
- isExcluded toggle in transaction form (field exists in DB; UI toggle deferred)

---

## Weekly Checkpoints

**End of Week 1 (2026-05-06):**
- [ ] SQLCipher encrypted DB running on both platforms
- [ ] Add Transaction modal works for all three types
- [ ] Edit and Delete flows work
- [ ] Account balances update reactively

**End of Week 2 (2026-05-13):**
- [ ] Trans. tab Daily view is live with real data
- [ ] Stats screen shows real pie chart
- [ ] Full QA pass on iOS and Android
- [ ] TestFlight + Play Internal deployed
- [ ] Weekly review packet prepared by PM

---

## Review Packet
PM will prepare `docs/reviews/2026-05-13-review.md` by end of day 2026-05-13.
