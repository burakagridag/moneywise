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
/// Uses [TransactionRepository.watchAllWithDetails] which joins categories and
/// accounts via LEFT OUTER JOIN, enabling the 3-step title fallback:
///   1. transaction.description (if non-empty)
///   2. categoryName (if available)
///   3. type string ("Income" / "Expense" / "Transfer")
@riverpod
Stream<List<TransactionWithDetails>> recentTransactions(
    RecentTransactionsRef ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAllWithDetails().map((all) => all.take(5).toList());
}
