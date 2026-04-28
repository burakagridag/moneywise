# DevOps Documentation

This directory contains operational documentation for MoneyWise.

## Files

- `code_signing.md` — iOS certificates, Android keystore management (created by devops agent)
- `release_checklist.md` — Pre-release checklist (template in agent file)
- `rollback.md` — Rollback procedures (template in agent file)
- `postmortems/` — Incident postmortems

## Conventions

- All operational changes documented before being executed
- Postmortems required within 7 days of any incident
- Secrets never committed — use GitHub Secrets and fastlane match
