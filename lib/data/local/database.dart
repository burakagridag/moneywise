// Drift database definition — Sprint 1 stub, tables added in Sprint 2+.
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'moneywise.db'));
    // TODO(sprint-2): Replace NativeDatabase with SQLCipher-backed connection.
    // Dev builds will have an unencrypted DB — Sprint 2 adds a migration path.
    // See ADR-002 and sqlcipher_flutter_libs for implementation details.
    return NativeDatabase.createInBackground(file);
  });
}
