// Drift AppDatabase — defines all tables, migrations, and seed data — data/local feature.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'encryption/db_encryption_service.dart';

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'seed_data.dart';
import 'tables/account_groups_table.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/transactions_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [AccountGroups, Accounts, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor used in unit tests — accepts a custom executor (e.g. memory DB).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(accountGroups);
            await m.createTable(accounts);
            await m.createTable(categories);
            await _seedDefaultData();
          }
          if (from < 3) {
            await m.createTable(transactions);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tx_account ON transactions (account_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tx_date ON transactions (date)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tx_deleted ON transactions (is_deleted)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tx_type ON transactions (type)',
            );
          }
        },
      );

  // ---------------------------------------------------------------------------
  // DAOs — created lazily so each instance shares the same connection.
  // ---------------------------------------------------------------------------

  late final accountDao = AccountDao(this);
  late final categoryDao = CategoryDao(this);
  late final transactionDao = TransactionDao(this);

  // ---------------------------------------------------------------------------
  // Seed helpers
  // ---------------------------------------------------------------------------

  Future<void> _seedDefaultData() async {
    await _seedAccountGroups();
    await _seedCategories();
  }

  Future<void> _seedAccountGroups() async {
    final groups = defaultAccountGroups();
    await batch((b) => b.insertAll(accountGroups, groups));
  }

  Future<void> _seedCategories() async {
    final income = defaultIncomeCategories();
    final expense = defaultExpenseCategories();
    await batch((b) {
      b.insertAll(categories, income);
      b.insertAll(categories, expense);
    });
  }
}

// -----------------------------------------------------------------------------
// Database connection
// -----------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'moneywise.db'));
    final key = await DbEncryptionService.getEncryptionKey();
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // Apply the SQLCipher encryption key before Drift opens the schema.
        db.execute("PRAGMA key = \"x'$key'\";");
      },
    );
  });
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
