# MoneyWise

Personal finance manager — Flutter cross-platform mobile app (iOS + Android).

> Inspired by Money Manager (Realbyte). Built with double-entry bookkeeping at its core.

---

## 🎯 Vision

MoneyWise helps users track daily expenses, manage budgets, and visualize spending across multiple accounts (cash, bank, card). Single Flutter codebase, native experience on both platforms.

## 📋 V1 Scope

- Add/edit/delete income, expense, and transfer transactions
- Custom categories with emoji icons
- Multiple accounts (Cash, Bank, Credit Card, Debit Card, Savings, Loan, etc.)
- Statistics with pie charts and monthly totals
- Calendar view of daily spending
- Monthly category budgets with carry-over
- Multi-currency (EUR default, configurable)
- Local backup/restore (Excel + file)
- Passcode + biometric lock
- Light/Dark theme

## 🚫 Out of Scope (V1)

Cloud sync, bank integrations, AI categorization, web/desktop. See `CLAUDE.md` for full list and Phase 2+ plans.

---

## 🏗️ Tech Stack

- **Framework:** Flutter 3.22+ / Dart 3.4+
- **State:** Riverpod 2.5+ (with code-gen)
- **Local DB:** Drift (SQLite + SQLCipher)
- **Routing:** go_router
- **Charts:** fl_chart
- **CI/CD:** GitHub Actions + fastlane

See `SPEC.md` Section 4 for full dependency list.

---

## 👥 Team Structure (Claude Code Agents)

This project is built using six specialized Claude Code agents, each with a clear role:

| Agent | Role |
|-------|------|
| **pm** | Product Manager — user stories, acceptance criteria, weekly reviews |
| **flutter-engineer** | Senior Flutter Engineer — architecture, ADRs, implementation, tests |
| **ux-designer** | UX Designer — screen specs, flows, accessibility |
| **code-reviewer** | Code Reviewer — read-only PR reviews, quality gate |
| **qa** | QA Engineer — acceptance testing, bug reports, regression |
| **devops** | DevOps Engineer — CI/CD, builds, store releases |

Agent definitions live in `.claude/agents/`. See `CLAUDE.md` for the orchestration rules.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.22+
- Dart 3.4+
- Xcode 15+ (for iOS)
- Android Studio with SDK 34+ (for Android)
- Git

### Setup

```bash
# 1. Clone or initialize
git clone <repo-url> moneywise
cd moneywise

# 2. Initialize Flutter project (if not already)
flutter create . --org com.yourcompany --platforms=ios,android

# 3. Install dependencies
flutter pub get

# 4. Generate code (Drift, Riverpod, freezed)
dart run build_runner build --delete-conflicting-outputs

# 5. Run on simulator/emulator
flutter run --flavor dev -t lib/main_dev.dart
```

### Running Tests
```bash
flutter test
flutter test --coverage
```

### Building Release
```bash
# iOS
flutter build ipa --flavor prod -t lib/main_prod.dart

# Android
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

---

## 📚 Documentation Map

- **`CLAUDE.md`** — Read first. Team rules, agent roles, work pipeline.
- **`SPEC.md`** — Full technical specification (architecture, data model, screens, roadmap).
- **`docs/decisions/`** — ADRs (Architecture Decision Records).
- **`docs/sprints/`** — Sprint plans.
- **`docs/user_stories/`** — User stories.
- **`docs/specs/`** — UX screen specs.
- **`docs/reviews/`** — Weekly Sponsor review packets.
- **`docs/qa/`** — Test plans, bug reports, regression suite.
- **`docs/devops/`** — CI/CD docs, runbooks.

---

## 🤖 How to Use Claude Code Agents

Open this folder with `claude`, then delegate work via natural language:

```
@pm please write user stories for Sprint 1 based on SPEC.md Section 16.

@flutter-engineer implement US-001 following docs/specs/SPEC-001.

@code-reviewer review the latest commit on the feature/add-transaction branch.

@qa create a test plan for US-001.

@devops set up the PR checks GitHub Action.
```

See `kickoff_prompt.md` for the recommended first prompt to bootstrap the project.

---

## 🛡️ License & Legal

- **Internal project.** Not yet open-sourced.
- **Trademark notice:** "Money Manager" is a registered product of Realbyte Inc. MoneyWise is an independent application; UI inspiration must not extend to logo, brand name, or icon copying.
- **Privacy:** All user data stored locally and encrypted (SQLCipher). No telemetry without explicit opt-in.

---

## 📞 Contact

- **Product Sponsor:** burakagridag@gmail.com
- **Issues:** GitHub Issues (when repo is set up)
- **Decisions:** Logged in `docs/decisions/`
