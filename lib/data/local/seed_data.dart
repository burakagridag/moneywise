// Default account groups and categories seeded on first database creation — data/local feature.
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// Companion types (AccountGroupsCompanion, CategoriesCompanion) are generated
// into database.g.dart which is a part of database.dart.
import 'database.dart';

const _uuid = Uuid();

/// Returns companions for the 11 default account groups.
List<AccountGroupsCompanion> defaultAccountGroups() {
  final now = DateTime.now();
  final groups = [
    ('Cash', 'cash'),
    ('Accounts', 'accounts'),
    ('Card', 'card'),
    ('Debit Card', 'debitCard'),
    ('Savings', 'savings'),
    ('Top-Up/Prepaid', 'topUpPrepaid'),
    ('Investments', 'investments'),
    ('Overdrafts', 'overdrafts'),
    ('Loan', 'loan'),
    ('Insurance', 'insurance'),
    ('Others', 'others'),
  ];

  return groups.indexed
      .map(
        (entry) => AccountGroupsCompanion.insert(
          id: _uuid.v4(),
          name: entry.$2.$1,
          type: entry.$2.$2,
          sortOrder: Value(entry.$1),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      )
      .toList();
}

/// Returns companions for the default income categories.
List<CategoriesCompanion> defaultIncomeCategories() {
  final now = DateTime.now();
  const items = [
    ('Allowance', '🤑'),
    ('Salary', '💰'),
    ('Petty cash', '💵'),
    ('Bonus', '🥇'),
    ('Other', null),
    ('Dividend', '💸'),
    ('Interest', '💸'),
  ];

  return items.indexed
      .map(
        (entry) => CategoriesCompanion.insert(
          id: _uuid.v4(),
          name: entry.$2.$1,
          type: 'income',
          iconEmoji: Value(entry.$2.$2),
          sortOrder: Value(entry.$1),
          isDefault: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      )
      .toList();
}

/// Returns companions for the default expense categories.
List<CategoriesCompanion> defaultExpenseCategories() {
  final now = DateTime.now();
  const items = [
    ('Food', '🍜'),
    ('Social Life', '👫'),
    ('Pets', '🐶'),
    ('Transport', '🚕'),
    ('Culture', '🖼️'),
    ('Household', '🪑'),
    ('Apparel', '🧥'),
    ('Beauty', '💄'),
    ('Health', '🧘'),
    ('Education', '📚'),
    ('Gift', '🎁'),
    ('Other', null),
    ('Insurance', '🤵'),
    ('Rent', '🏠'),
    ('Cigarette', '🚬'),
    ('Groceries', '🛒'),
    ('Restaurant', '🍽️'),
    ('Parking', '🅿️'),
    ('Bills', '📋'),
    ('Gym', '🏋️'),
    ('Medicine', '💊'),
  ];

  return items.indexed
      .map(
        (entry) => CategoriesCompanion.insert(
          id: _uuid.v4(),
          name: entry.$2.$1,
          type: 'expense',
          iconEmoji: Value(entry.$2.$2),
          sortOrder: Value(entry.$1),
          isDefault: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      )
      .toList();
}
