# Claude Code — Kickoff Prompt for MoneyWise

> Open the `moneywise/` folder with `claude`, then paste the prompt below as your first message.

---

## 🚀 First Prompt

```
Hi! I'm starting the MoneyWise project — a Flutter personal finance app inspired by Money Manager (Realbyte).

Before doing anything, please:

1. Read these files in this order:
   - CLAUDE.md (team rules, agents, pipeline)
   - SPEC.md (full technical specification — focus on Sections 1-3, 5, 6, 9, 16)
   - .claude/agents/*.md (agent definitions)

2. Confirm the team setup:
   - 6 agents: pm, flutter-engineer, ux-designer, code-reviewer, qa, devops
   - Orchestrator (you) is a coordinator, NOT an implementer
   - Every Sponsor request goes through the full pipeline

3. Then start Sprint 1:
   a. Delegate to @pm: write Sprint 1 user stories (8-12 stories) targeting "Project skeleton & foundation" per SPEC.md Section 16.1. Each story needs Gherkin acceptance criteria, edge cases, and test scenarios. Output to docs/user_stories/ and docs/sprints/sprint_01.md.

   b. Delegate to @flutter-engineer: 
      - Initialize the Flutter project (flavors: dev, staging, prod)
      - Set up the folder structure per SPEC.md Section 5
      - Add all dependencies to pubspec.yaml per SPEC.md Section 4.1
      - Implement the theme system (AppColors, AppTypography, AppSpacing) per SPEC.md Section 2
      - Set up go_router with 4 empty tab placeholders
      - Set up i18n with TR + EN ARB files
      - Create main_dev.dart, main_staging.dart, main_prod.dart entry points

   c. Delegate to @ux-designer: write UX specs for Sprint 1 screens (the empty 4-tab scaffold + theme switching).

   d. Delegate to @devops: create the basic .github/workflows/pr_checks.yml that runs lint, format, test on every PR.

4. After delegating, give me a summary:
   - What each agent is producing
   - Estimated timeline for Sprint 1
   - Decisions I (Sponsor) need to make
   - Next steps

Important: 
- Stay strictly in coordinator mode — do not write code yourself.
- If any agent disagrees with another, log the conflict and either resolve via existing ADRs or escalate to me.
- Treat SPEC.md as the source of truth. If something is unclear, ask me before guessing.

Let's begin.
```

---

## 🔄 Common Follow-up Prompts

### Starting a new user story
```
@flutter-engineer implement US-XXX following docs/user_stories/US-XXX.md and docs/specs/SPEC-XXX.md.

Before coding:
1. Break the story into sub-tasks (post in PR description)
2. Check if a new ADR is needed (e.g., introducing a new package or pattern)
3. Identify shared widgets that should go in core/widgets/

After coding:
1. Run dart run build_runner build --delete-conflicting-outputs
2. Run dart format .
3. Run flutter analyze (must pass with zero warnings)
4. Run flutter test (must pass; coverage targets per SPEC.md Section 11.4)
```

### Requesting a code review
```
@code-reviewer review the changes on branch feature/XXX. 

Focus areas:
- SPEC.md Section 9.X compliance (UI layout)
- SPEC.md Section 7 compliance (double-entry bookkeeping, if applicable)
- Test coverage (per SPEC.md Section 11.4)
- ADR compliance (per docs/decisions/)

Output: standard review format with [CRITICAL]/[SUGGESTION]/[NIT]/[PRAISE] tags and a final summary.
```

### Sprint planning
```
@pm prepare Sprint N+1 plan.

Inputs:
- Sprint N retrospective: what shipped, what carried over
- Sprint goal from SPEC.md Section 16.1 Sprint N+1
- Any new Sponsor priorities

Output:
- docs/sprints/sprint_NN.md with stories, estimates, dependencies
- Any new user stories needed (docs/user_stories/)
- Updated docs/ROADMAP.md
```

### Weekly review preparation
```
@pm prepare this week's review packet.

Output to docs/reviews/YYYY-MM-DD-review.md:
- What shipped (with TestFlight/Play Internal links if available)
- Open blockers
- Decisions needed from Sponsor
- Next week's plan
```

### Handling a bug report
```
@qa file a bug report for the issue I just described.

After QA files BUG-NNN, delegate to @flutter-engineer to investigate and fix.
After fix, route back to @qa for verification.
```

### Release preparation
```
@devops prepare release candidate vX.Y.Z.

Steps:
1. Update version in pubspec.yaml
2. Update CHANGELOG.md (auto-generate from PR titles since last tag)
3. Build iOS + Android
4. Upload to TestFlight + Play Internal
5. Notify @qa to run regression suite
6. Wait for Sponsor go/no-go before public release

Use the checklist at docs/devops/release_checklist.md.
```

---

## 🎯 Tips for Effective Orchestration

### Always reference the SPEC
When in doubt, point agents to specific SPEC.md sections instead of describing things from memory.

### Trust the pipeline
Even for "small" changes, route through the full pipeline (pm → engineer → reviewer → qa). The pipeline is what guarantees quality.

### Log decisions
Every non-trivial choice should end up in `docs/decisions/` (ADR) or `docs/reviews/` (weekly).

### Use parallel work where possible
While flutter-engineer implements, ux-designer can spec the next screen. While qa tests Sprint N, pm plans Sprint N+1.

### Escalate early
If an agent is blocked, don't let them spin. Surface the blocker to me (Sponsor) within 4 hours.
