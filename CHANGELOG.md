# Changelog

All notable changes to MoneyWise will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [1.0.0+2] - 2026-05-08 — EPIC8C-01 Budget Screen Redesign

### Added
- Budget screen hero card: slate-blue gradient, remaining/over-budget display, animated progress bar
- Budget metric cards: DAILY (burn rate + safe daily pace) and LAST MONTH (delta %)
- Budget categories section: per-category progress bars, collapsible row for unbudgeted categories
- Budget distribution section: donut chart
- Concentration insight slot on budget screen surface

### Changed
- `budgetHeroSpentOf` TR string revised to `{spent} / {budget}` format (sponsor-approved)
- `budgetMetricDeltaSame` EN+TR: removed "= " prefix (sponsor-approved)
- TR formality fixes: siz -> sen across 5 strings

### Fixed
- Bulgu #5: Over-budget state now displays "OVER BUDGET" / "BUTCE ASILDI" label with correct footer wording
- Bulgu #6: Card surface parity — white surface + #C8C4BC border + 0 2px 8px shadow matching Home screen cards

### Localization
- `budgetCategoriesCollapsedCount` EN: added ICU pluralization support

---

## [1.0.0+1] - 2026-01-01

### Added
- Project initialized with full team and agent structure
- SPEC.md with complete technical specification
- CLAUDE.md with team rules and pipeline
- 6 agent definitions in `.claude/agents/`
- ADR-001: Riverpod state management decision

### Project Setup
- Sprint 1 planned: Project skeleton & foundation

---

## Release Format Going Forward

Each release entry follows this template:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing features

### Fixed
- Bug fixes

### Removed
- Removed features

### Security
- Security-relevant changes
```
