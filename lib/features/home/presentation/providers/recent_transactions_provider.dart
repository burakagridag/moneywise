// StreamProvider that exposes the 5 most recent non-deleted transactions — home feature.
// Feeds RecentTransactionsList with live data; widget renders only the first 2.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/transaction.dart';

part 'recent_transactions_provider.g.dart';

/// Emits the 5 most recent non-deleted transactions across all accounts,
/// ordered newest-first. The UI layer takes `.take(2)` for display.
///
/// Uses [TransactionRepository.watchAll] which already orders by date DESC.
/// The provider slices the first 5 to cap memory usage in the home stream.
@riverpod
Stream<List<Transaction>> recentTransactions(RecentTransactionsRef ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAll().map((all) => all.take(5).toList());
}
