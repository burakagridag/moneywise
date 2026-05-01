// Repository wrapping UserSettingsDao for the home feature — home feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/local/daos/user_settings_dao.dart';
import '../../../data/local/database.dart';

part 'user_settings_repository.g.dart';

/// Riverpod provider that wires [UserSettingsRepository] to [AppDatabase].
@riverpod
UserSettingsRepository userSettingsRepository(UserSettingsRepositoryRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserSettingsRepository(db.userSettingsDao);
}

/// Mediates between [UserSettingsDao] and the presentation layer.
///
/// Exposes typed, domain-friendly methods so callers never depend on Drift
/// generated types directly.
class UserSettingsRepository {
  UserSettingsRepository(this._dao);

  final UserSettingsDao _dao;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Reactive stream of the global monthly budget value.
  ///
  /// Emits `null` when the user has not configured a global budget.
  Stream<double?> watchGlobalBudget() {
    return _dao.watchSettings().map((row) => row.globalMonthlyBudget);
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Persists [amount] as the global monthly budget.
  ///
  /// Pass `null` to clear the value (app then falls back to category budgets).
  Future<void> setGlobalBudget(double? amount) {
    return _dao.upsertGlobalBudget(amount);
  }
}
