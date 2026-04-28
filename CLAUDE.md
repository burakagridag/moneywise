# MoneyWise — Expense & Budget Tracker

## Vision
MoneyWise is a Flutter mobile app for personal finance management. Users can track daily expenses, set budgets, manage multiple accounts (cash, bank, card), and visualize spending patterns through charts and summaries. Single Flutter codebase runs natively on both iOS and Android.

## Product Sponsor
burakagridag@gmail.com — final decision authority on scope, design, and releases.

---

## Team & Agents

| Agent | File | Role |
|-------|------|------|
| **pm** | `.claude/agents/pm.md` | Product requirements, user stories, acceptance criteria, weekly reviews |
| **flutter-engineer** | `.claude/agents/flutter-engineer.md` | Senior — technical design, ADRs, task breakdown, Flutter architecture patterns, Dart/Flutter implementation, unit + widget + integration tests |
| **ux-designer** | `.claude/agents/ux-designer.md` | Screen specs, flows, interaction design, accessibility |
| **code-reviewer** | `.claude/agents/code-reviewer.md` | Read-only code review (correctness, security, performance, architectural compliance) |
| **qa** | `.claude/agents/qa.md` | Acceptance testing, test plans, bug reports |
| **devops** | `.claude/agents/devops.md` | CI/CD, Flutter builds, TestFlight/Play Internal deploys, release management |

---

## Orchestrator Rules (CRITICAL — read every session)

**The Orchestrator is a coordinator, NOT an implementer.**

- The Orchestrator MUST NEVER write code, UI specs, content, or tests directly.
- Every Product Sponsor request MUST go through the full pipeline below.
- Skipping any pipeline step (PM, UX Designer, Flutter Engineer, Code Reviewer, QA) is a critical failure — even for "small" changes.
- The only exception: the Orchestrator may edit documentation files (CLAUDE.md, decisions.md, etc.) directly.

If you are tempted to write code yourself, stop and delegate instead.

When agents disagree, the Orchestrator may either:
1. Escalate to Product Sponsor
2. Decide based on existing `docs/decisions/` ADRs and tech stack constraints
3. Request flutter-engineer to write a new ADR resolving the conflict

---

## Delegation Rules

### Always ask Product Sponsor before:
- Production / App Store / Play Store deploys
- Adding paid third-party services
- Architectural pivots (e.g., changing state management library)
- Monetization or pricing changes
- Scope changes exceeding 3 days of work

### Proceed autonomously (via agents):
- Writing and reviewing code → flutter-engineer + code-reviewer
- Bug fixes and refactoring → flutter-engineer + code-reviewer
- Unit, widget, and integration tests → flutter-engineer + qa
- Documentation → pm
- Internal testing (TestFlight / Play Internal) → devops
- ADRs and task breakdowns → flutter-engineer

### Flag-and-proceed:
- Minor dependency bumps
- Performance optimizations
- Non-destructive schema changes

> Decision is logged in `docs/decisions/` and proceeds. Sponsor reviews in weekly session and may revert if needed.

---

## Work Pipeline

```
PM (user story + acceptance criteria + Definition of Ready)
        ↓
Flutter Engineer (task breakdown + ADR if needed) + UX Designer (screen specs)  [parallel]
        ↓
Flutter Engineer (single codebase → iOS + Android)
        ↓
Code Reviewer  [mandatory gate]
        ↓
QA  [acceptance verification on both platforms]
        ↓
DevOps  [TestFlight + Play Internal deploy]
        ↓
Product Sponsor  [weekly review & acceptance]
```

---

## Tech Stack

- **Framework:** Flutter 3.22+ / Dart 3.4+ (single codebase)
- **State management:** Riverpod (flutter_riverpod + riverpod_annotation)
- **Local database:** Drift (SQLite, type-safe, reactive) + SQLCipher for encryption
- **Navigation:** go_router
- **Charts:** fl_chart
- **Models:** freezed + json_serializable
- **Currency:** money2 (decimal-precise)
- **Architecture:** Feature-first + Repository pattern (Clean Architecture)
- **CI/CD:** GitHub Actions
- **iOS deploy:** TestFlight → App Store
- **Android deploy:** Play Internal → Play Store

> See `SPEC.md` Section 4 for full dependency list.

---

## Core Features (V1 Scope)

1. **Transactions** — Add/edit/delete income, expense & transfer entries (double-entry bookkeeping)
2. **Categories** — Predefined + custom categories with emoji icons (income & expense)
3. **Accounts** — Cash, Bank Account, Credit Card, Debit Card, Savings, Loan, etc. with balances
4. **Statistics** — Pie chart by category, monthly totals, trend charts
5. **Calendar View** — Daily spending visualized on calendar grid
6. **Budget** — Monthly budget limits per category with warnings & carry-over
7. **Multi-currency** — EUR default, user-configurable, sub-currencies supported
8. **Backup/Restore** — Local file + Excel export/import
9. **Passcode + Biometric** — App-level security
10. **Light/Dark theme** — System-aware, manual override

## Out of Scope for V1
- Cloud sync / backend
- Bank integrations (open banking)
- Automatic recurring transaction execution (templates exist, but Phase 2 schedules them)
- Widgets (home screen)
- Web or desktop support
- AI category suggestions

---

## Definition of Ready (DoR)

A story is "ready" for flutter-engineer to start only when ALL are true:
- [ ] Acceptance criteria written in Gherkin format
- [ ] UX spec exists (or N/A noted)
- [ ] Estimate provided (S/M/L or story points)
- [ ] Dependencies identified and resolved or unblocked
- [ ] Edge cases enumerated
- [ ] Test scenarios outlined

---

## Definition of Done (DoD)

A story is "done" only when ALL are true:
- [ ] Flutter code implemented (runs on both iOS and Android)
- [ ] Unit tests written and passing
- [ ] Widget tests for UI components
- [ ] `flutter analyze` passes with zero warnings
- [ ] `dart format` passes
- [ ] Code reviewed and approved by code-reviewer
- [ ] All acceptance criteria verified by QA (tested on iOS + Android)
- [ ] Deployed to TestFlight + Play Internal Testing
- [ ] Product Sponsor accepted in weekly review

---

## Escalation Protocol

1. Agent hits blocker → attempts peer resolution (e.g., engineer asks code-reviewer or pm)
2. Unresolved → flags Orchestrator
3. Orchestrator resolves or escalates to Product Sponsor
4. Decision logged at `docs/decisions/`
5. SLA: Orchestrator escalates within 4h; Sponsor responds within 24h

---

## Weekly Review Cadence
- PM prepares review packet every Friday → `docs/reviews/YYYY-MM-DD-review.md`
- Product Sponsor reviews and accepts/rejects
- ADRs from the week are linked in the review packet

---

## Reference Documents

- `SPEC.md` — Full technical specification (architecture, data model, screen specs, roadmap)
- `docs/decisions/` — ADR (Architecture Decision Records)
- `docs/sprints/` — Sprint plans and retrospectives
- `docs/user_stories/` — User stories (PM-authored)
- `docs/specs/` — UX screen specs (ux-designer-authored)
- `docs/reviews/` — Weekly review packets

---

## Communication Language

- **Code, ADRs, technical docs, agent outputs:** English
- **Product Sponsor communication:** Turkish (when needed)
- **Code comments and commit messages:** English
- **i18n source language:** English (TR is primary translation target)
