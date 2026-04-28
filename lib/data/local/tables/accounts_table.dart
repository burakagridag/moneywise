// Drift table definition for individual accounts — data/local feature.
import 'package:drift/drift.dart';

import 'account_groups_table.dart';

/// Individual accounts belonging to an AccountGroup (e.g. "My Wallet" in Cash).
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(AccountGroups, #id)();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();

  /// ISO 4217 currency code, e.g. "EUR", "USD".
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get includeInTotals =>
      boolean().withDefault(const Constant(true))();
  TextColumn get iconKey => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  /// Day of month on which credit-card statement closes (1–31).
  IntColumn get statementDay => integer().nullable()();

  /// Day of month on which credit-card payment is due (1–31).
  IntColumn get paymentDueDay => integer().nullable()();
  RealColumn get creditLimit => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
