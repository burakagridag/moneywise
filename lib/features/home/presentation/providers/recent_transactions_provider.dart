// StreamProvider that exposes the 5 most recent non-deleted transactions with
// enriched category/account details — home feature.
// Feeds RecentTransactionsList with live data; widget renders only the first 2.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/transaction_with_details.dart';

part 'recent_transactions_provider.g.dart';

/// Emits the 5 most recent non-deleted transactions across all accounts,
/// ordered newest-first, enriched with resolved category and account names.
/// The UI layer takes `.take(2)` for display.
///
/// The LIMIT is applied at the SQL level via [TransactionRepository.watchAllWithDetails]
/// — no Dart-side filtering is needed, ensuring only 5 rows are read from the DB.
///
/// Uses a LEFT OUTER JOIN on categories and accounts, enabling the 3-step
/// title fallback:
///   1. transaction.description (if non-empty)
///   2. categoryName (if available)
///   3. type string (via AppLocalizations)
@riverpod
Stream<List<TransactionWithDetails>> recentTransactions(
    RecentTransactionsRef ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAllWithDetails(limit: 5);
}
