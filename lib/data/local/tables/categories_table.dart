// Drift table definition for income and expense categories — data/local feature.
import 'package:drift/drift.dart';

/// User-defined and default categories for classifying transactions.
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Transaction direction: 'income' or 'expense'.
  TextColumn get type => text()();

  /// Optional parent category id for sub-categories (self-referential FK).
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get iconEmoji => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
