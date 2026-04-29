// Drift table definition for financial transactions — data/local feature.
import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

/// Stores all financial transactions (income, expense, transfer).
/// Balance is computed on read from initialBalance + transaction deltas.
class Transactions extends Table {
  TextColumn get id => text()();

  /// Transaction direction: 'income', 'expense', or 'transfer'.
  TextColumn get type => text()();

  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();

  /// ISO 4217 currency code, e.g. "EUR", "TRY".
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// Exchange rate to base currency (default 1.0).
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  /// Source account (required).
  @ReferenceName('fromTransactions')
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Destination account for transfers (null for income/expense).
  @ReferenceName('toTransactions')
  TextColumn get toAccountId => text().nullable().references(Accounts, #id)();

  /// Primary category (optional).
  @ReferenceName('categoryTransactions')
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Sub-category (optional).
  @ReferenceName('subcategoryTransactions')
  TextColumn get subcategoryId =>
      text().nullable().references(Categories, #id)();

  TextColumn get description => text().nullable()();

  /// When true, transaction is visible but excluded from balance calculations.
  BoolColumn get isExcluded => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Timestamp of the last mutation — used for sync conflict resolution.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft-delete flag — true means the row is hidden but retained for sync.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
