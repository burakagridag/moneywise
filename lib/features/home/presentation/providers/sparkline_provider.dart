// Riverpod provider for sparkline (30-day daily net) data — home feature (EPIC8A-06).
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/daos/transaction_dao.dart';
import '../../../../data/local/database.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

part 'sparkline_provider.g.dart';

/// Emits the 30-day daily net amounts for the sparkline chart on the Home tab.
///
/// Accounts with [Account.includeInTotals] == false are excluded so that loan
/// or excluded accounts do not distort the trend line.
/// The stream re-emits whenever any transaction or account changes.
@riverpod
Stream<List<DailyNet>> sparklineData(SparklineDataRef ref) {
  final accounts = ref.watch(allAccountsProvider).valueOrNull ?? [];
  final excluded =
      accounts.where((a) => !a.includeInTotals).map((a) => a.id).toSet();

  return ref
      .watch(appDatabaseProvider)
      .transactionDao
      .watchDailyNetAmounts(excludedAccountIds: excluded);
}
