# ADR-002: Use Drift (SQLite) for Local Database

## Status
Accepted — 2026-04-28

## Context
MoneyWise stores financial data locally (transactions, accounts, categories, budgets). Needs: type-safe queries, reactive streams, migrations, encryption for sensitive data, testability.

Options considered:
- Drift (formerly Moor) on SQLite
- Hive / Isar (NoSQL)
- ObjectBox

## Decision
Use Drift 2.18+ with NativeDatabase. Encrypt with SQLCipher in Sprint 2+.

## Consequences

### Positive
- Type-safe SQL queries via code generation
- Reactive Stream-based queries (integrates with Riverpod)
- Schema migration system
- In-memory database for tests (NativeDatabase.memory())
- SQLCipher encryption available via sqlcipher_flutter_libs

### Negative
- SQL knowledge required for complex queries
- Code-gen step required

## Alternatives Rejected
- **Hive/Isar**: NoSQL; relational finance data is better modelled with SQL
- **ObjectBox**: Less mature tooling for reactive queries
