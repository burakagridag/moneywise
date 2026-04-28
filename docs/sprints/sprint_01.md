# Sprint 01 — Project Setup & Foundation

**Duration:** 2 weeks (2026-04-28 → 2026-05-09)
**Goal:** Establish the project skeleton, design token system, navigation shell, encrypted database, folder structure, i18n foundation, CI pipeline, and verify end-to-end launch on both iOS and Android. No feature screens are built this sprint — only the infrastructure every future story depends on.
**Source:** SPEC.md §16.1 "Sprint 1: Proje Kurulumu"

---

## Stories

| ID | Title | Estimate | Status | Owner |
|----|-------|----------|--------|-------|
| US-001 | Flutter project with dev/staging/prod flavors | S | Ready | flutter-engineer |
| US-005 | Folder structure per SPEC.md §5 | S | Ready | flutter-engineer |
| US-007 | pubspec.yaml — all Sprint 1 dependencies | S | Ready | flutter-engineer |
| US-002 | Theme system (AppColors, AppTypography, AppSpacing, AppRadius, AppHeights) | S | Ready | flutter-engineer |
| US-003 | go_router + 4-tab bottom navigation + placeholder screens | S | Ready | flutter-engineer |
| US-004 | Drift DB initialised with SQLCipher encryption + initial migration | M | Ready | flutter-engineer |
| US-006 | i18n setup — TR + EN ARB files, locale switching | S | Ready | flutter-engineer |
| US-008 | CI pipeline — GitHub Actions pr_checks.yml | S | Ready | devops |
| US-010 | Light/Dark/System theme toggle with persistence | M | Ready | flutter-engineer |
| US-009 | End-to-end launch verification on iOS and Android (all flavors) | S | Ready | flutter-engineer + QA |

### Execution order rationale
Stories must be executed in roughly this sequence because of hard dependencies:
1. US-001 (skeleton) → enables everything else
2. US-005 (folders) + US-007 (pubspec) → parallel, both depend only on US-001
3. US-002 (theme) → depends on US-001 + US-005
4. US-004 (DB) → depends on US-001 + US-007
5. US-003 (navigation) → depends on US-001, US-002, US-007
6. US-006 (i18n) → depends on US-001, US-005, US-007
7. US-008 (CI) → depends on US-001, US-007 (repo must be on GitHub with a passing baseline)
8. US-010 (theme toggle) → depends on US-002, US-003, US-005
9. US-009 (launch verification) → depends on all of the above

---

## Sprint Goal Acceptance Criteria

The sprint is accepted when **all** of the following are true:

- [ ] `flutter run --flavor dev` launches successfully on an iOS Simulator and shows "MoneyWise.dev" app name
- [ ] `flutter run --flavor dev` launches successfully on an Android Emulator and shows "MoneyWise.dev" app name
- [ ] `flutter run --flavor prod --release` launches on both platforms with plain "MoneyWise" app name and no debug banner
- [ ] The 4-tab bottom navigation bar is visible and all 4 tabs are tappable with correct route transitions
- [ ] Tab 1 label shows today's date in "DD.M." format
- [ ] Navigating to More > Style allows switching between Dark, Light, and System themes; the selected theme persists after a cold restart
- [ ] The Drift database opens without error on first launch; the raw DB file is confirmed encrypted (unreadable by sqlite3 without passphrase)
- [ ] The app displays in Turkish when device locale is Turkish, and in English when locale is English or unsupported
- [ ] `flutter analyze` produces zero warnings on the full codebase
- [ ] `dart format --set-exit-if-changed .` passes (no unformatted files)
- [ ] All unit tests pass (`flutter test`)
- [ ] GitHub Actions `pr_checks.yml` workflow runs automatically on a test PR and all steps pass (lint, format, test, coverage upload)
- [ ] All 10 user stories have been reviewed and accepted by code-reviewer agent

---

## Definition of Ready Check (all stories)

| Story | AC in Gherkin | UX Spec noted | Estimate | Dependencies | Edge Cases | Test Scenarios |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|
| US-001 | Yes | N/A | S | None | Yes | Yes |
| US-002 | Yes | TBD | S | US-001 | Yes | Yes |
| US-003 | Yes | TBD | S | US-001, US-002, US-007 | Yes | Yes |
| US-004 | Yes | N/A | M | US-001, US-007 | Yes | Yes |
| US-005 | Yes | N/A | S | US-001 | Yes | Yes |
| US-006 | Yes | TBD | S | US-001, US-005, US-007 | Yes | Yes |
| US-007 | Yes | N/A | S | US-001 | Yes | Yes |
| US-008 | Yes | N/A | S | US-001, US-007 | Yes | Yes |
| US-009 | Yes | N/A | S | US-001..US-007 | Yes | Yes |
| US-010 | Yes | TBD | M | US-002, US-003, US-005 | Yes | Yes |

All stories are **Ready** per the project Definition of Ready.

---

## UX Design Tasks (parallel, Sprint 1)

The ux-designer must deliver the following specs during this sprint to unblock Sprint 2 feature work:

| Spec | Required by |
|------|-------------|
| Bottom tab bar visual specification | US-003 |
| Design token reference sheet (color + type) | US-002 |
| Style screen (Dark/Light/System toggle) layout | US-010 |
| Language selection bottom-sheet layout | US-006 |

---

## Out of Scope for Sprint 1

- Any transaction CRUD (Sprint 3)
- Account or category management (Sprint 2)
- Statistics or budget screens (Sprint 5)
- Backup, passcode, or biometric (Sprint 8)
- Cloud sync or authentication (Phase 2)
- DE or ES ARB translations (i18n foundation only; full translations Sprint 6)

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| SQLCipher native build setup fails on one platform | Medium | High | flutter-engineer spikes on Day 1; escalate to Orchestrator if not resolved within 4h |
| `flutter gen-l10n` integration issues with CI | Low | Medium | Run locally and commit generated files; CI regenerates as safety net |
| GitHub Actions billing minutes exceeded on macOS runner | Low | Low | PR checks use ubuntu-latest; iOS build workflow is out of scope for Sprint 1 |
| Flavor bundle ID conflicts with existing App Store/Play Store listings | Low | High | Sponsor to confirm app identifiers before flavor config is finalised (Day 1) |

---

## Team Capacity

| Member | Available days (2 weeks) |
|--------|--------------------------|
| flutter-engineer | 10 |
| devops | 2 (US-008 only) |
| ux-designer | 3 (parallel UX specs) |
| QA | 2 (end-of-sprint US-009 acceptance) |

---

## Sprint Retrospective Placeholder
*(To be filled in on 2026-05-09)*

- What went well:
- What could improve:
- Action items:
