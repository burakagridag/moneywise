// Drift table definition for account groups (e.g. Cash, Bank, Card) — data/local feature.
import 'package:drift/drift.dart';

/// Groups that categorise accounts (cash, bank accounts, cards, etc.).
class AccountGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Discriminator: cash|accounts|card|debitCard|savings|topUpPrepaid|
  /// investments|overdrafts|loan|insurance|others
  TextColumn get type => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get iconKey => text().nullable()();
  BoolColumn get includeInTotals =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
