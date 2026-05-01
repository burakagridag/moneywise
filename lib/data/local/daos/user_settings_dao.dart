// Data access object for the singleton user settings row — data/local feature.
import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

/// Provides reactive read and typed write access to the [UserSettings] table.
///
/// Enforces the singleton constraint: only the row with id = 1 is ever
/// written. No arbitrary-id insert method is exposed.
@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.db);

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reactive stream of the singleton settings row.
  ///
  /// Emits immediately with the current state and re-emits on every update.
  /// The row is guaranteed to exist after [AppDatabase] runs onCreate or the
  /// schema-version-7 migration, so the stream should never error on a fresh
  /// or upgraded install.
  Stream<UserSetting> watchSettings() {
    return (select(userSettings)..where((s) => s.id.equals(1))).watchSingle();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Sets or clears the global monthly budget.
  ///
  /// Passing [amount] = null marks the value as unset; the app then falls back
  /// to the category-budget sum. Uses `insertOnConflictUpdate` with id = 1 so
  /// subsequent calls always update the same row and never insert a second row.
  Future<void> upsertGlobalBudget(double? amount) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion(
        id: const Value(1),
        globalMonthlyBudget: Value(amount),
      ),
    );
  }
}
