// Drift table definition for user financial settings — data/local feature.
import 'package:drift/drift.dart';

/// Stores user-configurable financial parameters as a single mandatory row (id = 1).
///
/// The singleton constraint is enforced at the application layer (DAO) via
/// `insertOnConflictUpdate` with a hardcoded id = 1. SQLite does not enforce
/// CHECK constraints natively through Drift, so the DAO must never expose an
/// arbitrary-id insert method.
class UserSettings extends Table {
  /// Singleton row identifier — always 1. Application layer enforces this.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// The user's global monthly budget ceiling in the primary currency.
  /// null means the user has not set a global budget; the app falls back
  /// to the sum of active category budgets (see effectiveBudgetProvider).
  RealColumn get globalMonthlyBudget => real().nullable()();

  /// Reserved for Epic 8b SavingsGoalRule — the savings target as a fraction
  /// of monthly income (e.g. 0.20 = 20 %). null = not configured.
  RealColumn get savingsGoalPct => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
