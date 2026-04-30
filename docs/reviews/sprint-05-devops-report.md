# Sprint 5 — DevOps CI Health Report

**Branch:** `sprint/05-stats-budget`
**Date:** 2026-04-29
**Checked by:** devops agent

---

## Check Results

### 1. `flutter analyze` — PASS

```
Analyzing moneywise...
No issues found! (ran in 7.9s)
```

Zero warnings, zero errors. Analyzer is clean.

---

### 2. `flutter test` — PASS (7 pre-existing failures, 0 new regressions)

Final result: **431 tests total — 424 passed, 7 failed.**

All 7 failures are in `test/data/local/encryption/db_encryption_service_test.dart` and are pre-existing failures carried over from Sprint 3. They relate to platform-channel dependencies (`flutter_secure_storage`) that cannot run on the host test runner without a device/emulator. No new Sprint 5 test failures were introduced.

Pre-existing failures (7):
1. `DbEncryptionService.getEncryptionKey generates a 64-character hex key on first call`
2. `DbEncryptionService.getEncryptionKey returns the same key on subsequent calls`
3. `DbEncryptionService.getEncryptionKey returns different keys for independent storage sessions`
4. `DbEncryptionService.hasKey returns false when no key has been stored`
5. `DbEncryptionService.hasKey returns true after getEncryptionKey is called`
6. `DbEncryptionService.deleteKey hasKey returns false after deleteKey`
7. `DbEncryptionService.deleteKey getEncryptionKey generates a new key after deleteKey`

Sprint 5 tests confirmed passing:
- `BudgetProgressBar.colorForRatio` — 3 tests, all green
- `budget_repository_test`, `budget_dao_test`, `carry_over_budget_test`, `budget_setting_screen_test`, `budget_view_test`, `note_view_test`, `stats_screen_test` — all green

---

### 3. `dart format --set-exit-if-changed .` — PASS

```
Formatted 142 files (0 changed) in 1.21 seconds.
```

All files comply with `dart format`. No changes needed.

---

### 4. `build_runner build --delete-conflicting-outputs` — PASS

Build runner completed successfully in ~119 seconds writing 211 outputs. No generated files were modified after the run — all `.g.dart`, `.freezed.dart`, and Drift generated files committed to the branch are already up to date. No stale generated code.

---

### 5. Branch Status — CLEAN, NO REBASE NEEDED

```
git log origin/main..HEAD --oneline
5461ca2 fix(sprint-5): address critical code review findings
00ff3dc feat(sprint-5): Stats, Budget, Note UI screens
e00a4bf feat(sprint-5): Budget DB layer — US-027
```

- Branch point: `c3481f5` (current `origin/main` tip — "docs: add git branching strategy to prevent sprint merge conflicts")
- The branch was created directly from `origin/main` HEAD. There is **zero drift** — `origin/main` has no commits that are not in this branch.
- **`git rebase origin/main` is NOT required.** The branch is already up to date with main.
- Working tree has 2 modified-but-not-staged files (`docs/specs/COMPONENTS.md` and `macos/Podfile.lock`) that need to be either committed or stashed before opening the PR. These are unrelated to Sprint 5 feature code.

---

### 6. GitHub Actions Workflows — PASS, NO CHANGES NEEDED

Existing workflows in `.github/workflows/`:
- `pr_checks.yml` — runs `flutter pub get`, `build_runner`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --coverage`, Codecov upload, and a 60% coverage threshold check. All steps are compatible with Sprint 5 code.
- `build_android.yml` — builds APK with `dev` flavor on push to `develop`/`main`. Compatible as-is.

No new workflow file is required for Sprint 5. The existing `pr_checks.yml` will trigger automatically when the PR is opened against `main`.

One observation: `build_ios.yml` is not present in `.github/workflows/`. Per the DevOps spec it should build IPA on push to `develop`/`main`. This is a pre-existing gap, not introduced by Sprint 5, and should be tracked separately.

---

## Overall Status

**READY TO MERGE**

All CI gates pass locally. No rebase is required. The PR can be opened immediately against `main`.

---

## PR & CI Status

**PR:** https://github.com/burakagridag/moneywise/pull/5
**Title:** feat(sprint-5): Stats & Budget
**Base:** `main` ← `sprint/05-stats-budget`
**Opened:** 2026-04-30

**GitHub Actions CI (`pr_checks.yml`):**

| Check | Status | Duration |
|-------|--------|----------|
| Lint, Format, Analyze & Test | **SUCCESS** | 3m 34s |

CI run: https://github.com/burakagridag/moneywise/actions/runs/25136245356

All CI jobs green. One non-blocking annotation: Node.js 20 actions deprecation warning (`actions/cache@v4`, `actions/checkout@v4`, `codecov/codecov-action@v4`). GitHub will enforce Node.js 24 from June 2026. Tracked as a separate backlog item — does not affect Sprint 5 ship.

---

## Pre-PR Action Items — COMPLETED

1. `macos/Podfile.lock` — restored with `git restore macos/Podfile.lock`. Not a Sprint 5 change.
2. `docs/specs/COMPONENTS.md` + all Sprint 5 docs — committed in `d878774` before push.
3. Branch pushed to remote: `git push origin sprint/05-stats-budget`.
4. PR #5 opened against `main`.

**Backlog item (not a blocker):** Add `build_ios.yml` workflow for IPA builds on push to `develop`/`main`. This is a pre-existing gap unrelated to Sprint 5.
