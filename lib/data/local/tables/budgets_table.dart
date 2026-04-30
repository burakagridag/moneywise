// Drift table definition for monthly category budgets — data/local feature.
import 'package:drift/drift.dart';

import 'categories_table.dart';

/// Stores monthly budget limits per category.
/// A budget is active for a given month when:
///   effectiveFrom <= month-start  AND  (effectiveTo IS NULL OR effectiveTo >= month-start)
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The category this budget applies to.
  TextColumn get categoryId =>
      text().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// Budget ceiling in the user's base currency (decimal-precise via money2).
  RealColumn get amount => real()();

  /// First day of the first month this budget is active (ISO8601 YYYY-MM-DD).
  TextColumn get effectiveFrom => text()();

  /// First day of the last month this budget is active (ISO8601 YYYY-MM-DD).
  /// NULL means the budget is open-ended (applies to all future months).
  TextColumn get effectiveTo => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
}
