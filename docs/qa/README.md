# QA Documentation

This directory contains all QA artifacts for MoneyWise.

## Structure

- `test_plans/` — Test plans per user story (`TP-USXXX.md`)
- `bugs/` — Bug reports (`BUG-NNN-title.md`)
- `regression_suite.md` — Master regression test suite (run before every release)
- `test_data.md` — Test data and seed scenarios

## Conventions

- Test plans are written in parallel with development (not after).
- Bug severity: P0 (blocker), P1 (major), P2 (minor), P3 (cosmetic).
- Every bug report includes: reproduction steps, expected vs actual, environment, severity, screenshots/logs.
- Cross-platform parity (iOS + Android) is verified for every story.
