# MoneyWise — Documentation

This directory contains all project documentation, organized by purpose.

## Structure

| Folder | Purpose | Owner |
|--------|---------|-------|
| `decisions/` | Architecture Decision Records (ADRs) | flutter-engineer |
| `sprints/` | Sprint plans and retrospectives | pm |
| `user_stories/` | User stories with acceptance criteria | pm |
| `specs/` | UX screen specifications | ux-designer |
| `reviews/` | Weekly review packets | pm |
| `qa/` | Test plans, bug reports, regression suite | qa |
| `devops/` | CI/CD docs, runbooks, postmortems | devops |

## Top-level Documents

- `../CLAUDE.md` — Team rules, agent roles, pipeline
- `../SPEC.md` — Full technical specification (single source of truth)
- `../README.md` — Project overview and getting started
- `ROADMAP.md` — Long-term roadmap (created by pm)
- `../CHANGELOG.md` — Release history (created by devops)

## Conventions

- All docs are Markdown (`.md`)
- File naming: `kebab-case` for descriptive names, `UPPER_CASE.md` for top-level documents
- ADRs and stories use sequential numbering: `ADR-001`, `US-001`, etc.
- Dates use ISO format: `YYYY-MM-DD`
