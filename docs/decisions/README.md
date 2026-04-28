# Architecture Decision Records (ADRs)

This directory contains all architectural decisions for the MoneyWise project.

## What is an ADR?
An ADR is a short document capturing a significant architectural decision: its context, the chosen approach, alternatives considered, and consequences.

## When to write an ADR
flutter-engineer must write an ADR for:
- State management choices
- New external dependencies
- Schema changes affecting multiple tables
- Performance vs. simplicity trade-offs
- Patterns that affect multiple features
- Resolving disputes between agents

## Format
Use the template in `_TEMPLATE.md`. Number sequentially: `ADR-001-...`, `ADR-002-...`.

## Status values
- **Proposed** — under discussion
- **Accepted** — approved and being implemented
- **Deprecated** — no longer relevant
- **Superseded by ADR-XXX** — replaced by another decision

## Index
- [ADR-001: Use Riverpod for State Management](./ADR-001-riverpod-state-management.md)
