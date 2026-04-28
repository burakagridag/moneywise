# Sprint 02 — Account & Category Management

**Duration:** 2 weeks (2026-05-12 → 2026-05-23)
**Goal:** Deliver the full data layer for accounts and categories (Drift tables, DAOs, Repositories),
ship the AccountsScreen and AccountAddEditScreen with live balance data, ship
CategoryManagementScreen with add/edit/delete/reorder, add the main + sub currency selector,
and enable SQLCipher encryption on the local database.

At the end of this sprint, the Accounts tab shows real data, account and category CRUD works
end-to-end, default seeds are present, and the database is encrypted at rest.

**Source:** SPEC.md §16.2 ("Sprint 2: Hesaplar ve Kategoriler"); ADR-003 (SQLCipher deferred
from Sprint 1).

---

## Stories

| ID | Title | Estimate | Status | Owner | Dependencies |
|----|-------|----------|--------|-------|--------------|
| US-019 | SQLCipher encryption — wire up sqlcipher_flutter_libs | M | Ready | flutter-engineer | US-004 |
| US-011 | AccountGroups Drift table + DAO + default seed data | S | Ready | flutter-engineer | US-004 |
| US-012 | Accounts Drift table + DAO | S | Ready | flutter-engineer | US-011 |
| US-013 | Categories Drift table + DAO + default seed data | S | Ready | flutter-engineer | US-004 |
| US-014 | AccountRepository + CategoryRepository | M | Ready | flutter-engineer | US-011, US-012, US-013 |
| US-015 | AccountsScreen — group list with live balances | M | Ready | flutter-engineer | US-014, US-016 |
| US-016 | AccountAddEditScreen — add/edit account form | M | Ready | flutter-engineer | US-014 |
| US-017 | CategoryManagementScreen — list, add, edit, delete, reorder | L | Ready | flutter-engineer | US-014 |
| US-018 | Currency setup — main + sub currency selector | M | Ready | flutter-engineer | US-004 |

---

## Execution Order and Rationale

The stories must be executed in roughly this sequence due to hard dependencies:

1. **US-019** — SQLCipher spike on Day 1 (highest risk; escalate within 4h if blocked). Can be
   developed in parallel with data-layer stories; integration test requires schema to be stable.
2. **US-011 + US-013** — Parallel. Both depend only on the Drift DB stub from Sprint 1. No
   dependency on each other.
3. **US-012** — Depends on US-011 (accounts FK → accountGroups).
4. **US-014** — Depends on US-011 + US-012 + US-013 (wraps all three DAOs).
5. **US-015 + US-016 + US-017 + US-018** — Parallel once US-014 is ready. US-015 has a soft
   dependency on US-016 (navigation target must exist before route can be wired).

UX specs for US-015, US-016, US-017, US-018 must be delivered by ux-designer by the end of
Day 3 (2026-05-14) to avoid blocking flutter-engineer.

---

## Sprint Goal Acceptance Criteria

The sprint is accepted when **all** of the following are true:

- [ ] The local database file is confirmed encrypted (unreadable by `sqlite3` CLI without passphrase) on both iOS and Android
- [ ] Database upgrade from Sprint 1 unencrypted build preserves existing data and opens without error
- [ ] The accountGroups table contains exactly 11 default rows after a fresh install on both platforms; no duplicates on restart
- [ ] The categories table contains exactly 21 default expense categories and 7 default income categories after a fresh install
- [ ] AccountsScreen (Accounts tab) displays account groups and accounts with correct balances pulled live from the database
- [ ] Assets / Liabilities / Total summary bar values are mathematically correct (tested with known data set)
- [ ] Add Account form saves a new account and it appears immediately in AccountsScreen
- [ ] Edit Account form pre-fills existing values and updates them correctly on save
- [ ] Duplicate account name within same group is rejected with an error message
- [ ] CategoryManagementScreen lists all default income and expense categories in correct order
- [ ] Add custom category persists and appears in the list
- [ ] Edit a default category name persists correctly
- [ ] Delete a custom category with transactions triggers the reassignment dialog; atomicity is verified
- [ ] Default categories cannot be deleted (blocked with message)
- [ ] Drag-to-reorder updates sortOrder and is reflected in the list
- [ ] Main currency defaults to EUR on first launch; user can change it and the setting persists across restarts
- [ ] Sub-currency toggle ON/OFF persists; manual exchange rate saves correctly
- [ ] `flutter analyze` passes with zero warnings on the full codebase
- [ ] All unit tests pass (`flutter test`)
- [ ] All acceptance criteria verified by QA on both iOS Simulator and Android Emulator
- [ ] ADR-004 (SQLCipher passphrase strategy) is written and merged

---

## Definition of Ready Check (all stories)

| Story | AC in Gherkin | UX Spec noted | Estimate | Dependencies | Edge Cases | Test Scenarios |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|
| US-011 | Yes | N/A | S | Identified | Yes | Yes |
| US-012 | Yes | N/A | S | Identified | Yes | Yes |
| US-013 | Yes | N/A | S | Identified | Yes | Yes |
| US-014 | Yes | N/A | M | Identified | Yes | Yes |
| US-015 | Yes | TBD (Sprint 2) | M | Identified | Yes | Yes |
| US-016 | Yes | TBD (Sprint 2) | M | Identified | Yes | Yes |
| US-017 | Yes | TBD (Sprint 2) | L | Identified | Yes | Yes |
| US-018 | Yes | TBD (Sprint 2) | M | Identified | Yes | Yes |
| US-019 | Yes | N/A | M | Identified | Yes | Yes |

All stories are **Ready** per the project Definition of Ready.

---

## UX Design Tasks (parallel, Sprint 2)

The ux-designer must deliver the following specs by Day 3 (2026-05-14) to avoid blocking
flutter-engineer implementation of UI stories:

| Spec file | Required by |
|-----------|-------------|
| `docs/specs/SPEC-004-accounts-screen.md` | US-015 |
| `docs/specs/SPEC-005-account-add-edit-screen.md` | US-016 |
| `docs/specs/SPEC-006-category-management-screen.md` | US-017 |
| `docs/specs/SPEC-007-currency-screen.md` | US-018 |

Reference screens in SPEC.md: Ekran 12 (AccountAddEditScreen), Ekran 13 (AccountsScreen),
Ekran 6 & 7 (CategoryManagementScreen), §9.16 (CurrencyScreen).

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| SQLCipher native build fails on one or both platforms (US-019) | High | High | flutter-engineer spikes Day 1; escalate to Orchestrator within 4h; ADR-004 must document fallback |
| UX specs not ready in time, blocking UI stories | Medium | Medium | ux-designer has hard deadline of Day 3; PM escalates on Day 2 if not on track |
| Drift schema migration from Sprint 1 causes data loss | Medium | High | Migration must be tested on a device with Sprint 1 DB before merging; QA scenario 7 in US-019 covers this |
| Drag-to-reorder (US-017) complex on both platforms | Medium | Low | Use Flutter's built-in ReorderableListView; scope subcategory drag for stretch goal only |
| CategoryRepository reassignAndDelete() atomicity | Low | High | Must use Drift transaction block; unit test verifies rollback on injected error |
| Sprint capacity insufficient for US-017 (L estimate) | Medium | Medium | US-017 can be split: list + add/edit in Sprint 2, drag reorder in Sprint 3 if needed |

---

## Out of Scope for Sprint 2

- Transaction CRUD (Sprint 3)
- Account balance trend charts / AccountDetailScreen (Sprint 4)
- Budget setting screen (Sprint 5)
- Statistics and pie chart (Sprint 5)
- Exchange rate API auto-fetch (Sprint 5 / Phase 2)
- Backup / restore / export (Sprint 8)
- Passcode / biometric (Sprint 8)
- Cloud sync (Phase 2)
- DE / ES translations (Sprint 6)
- Recurring transactions (Sprint 4)

---

## Team Capacity

| Member | Available days (2 weeks) |
|--------|--------------------------|
| flutter-engineer | 10 |
| ux-designer | 4 (4 screen specs by Day 3) |
| code-reviewer | 3 (rolling PR reviews) |
| QA | 3 (end-of-sprint acceptance) |
| devops | 1 (CI update for SQLCipher build timeout if needed) |

---

## Sprint Retrospective Placeholder

*(To be filled in on 2026-05-23)*

- What went well:
- What could improve:
- Action items:
