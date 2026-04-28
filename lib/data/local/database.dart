// Drift AppDatabase — defines all tables, migrations, and seed data — data/local feature.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'seed_data.dart';
import 'tables/account_groups_table.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [AccountGroups, Accounts, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor used in unit tests — accepts a custom executor (e.g. memory DB).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultData();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createAll();
            await _seedDefaultData();
          }
        },
      );

  // ---------------------------------------------------------------------------
  // DAOs — created lazily so each instance shares the same connection.
  // ---------------------------------------------------------------------------

  late final accountDao = AccountDao(this);
  late final categoryDao = CategoryDao(this);

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
    // NOTE: SQLCipher encryption is deferred to Sprint 3 (ADR-003).
    // sqlcipher_flutter_libs is already linked so the binary is ready.
    // Sprint 3 will add a key-derivation step and migration from plaintext.
    return NativeDatabase.createInBackground(file);
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
