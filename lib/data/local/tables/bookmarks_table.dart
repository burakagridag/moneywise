// Drift table definition for transaction bookmarks (templates) — data/local feature.
import 'package:drift/drift.dart';

/// Stores saved transaction templates (bookmarks) for quick re-use.
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Transaction direction: 'income', 'expense', or 'transfer'.
  TextColumn get type => text()();

  /// Pre-filled amount (optional — null means user must enter it each time).
  RealColumn get amount => real().nullable()();

  /// ISO 4217 currency code.
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('EUR'))();

  TextColumn get accountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get note => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
