// Riverpod providers for selected month navigation and transaction write operations — transactions feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../stats/presentation/providers/stats_provider.dart';

part 'transactions_provider.g.dart';

// ---------------------------------------------------------------------------
// Selected month navigation
// ---------------------------------------------------------------------------

/// Tracks the currently selected year-month for the transaction list view.
@riverpod
class SelectedMonth extends _$SelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Navigate to the previous month.
  void previous() {
    final s = state;
    state =
        s.month == 1 ? DateTime(s.year - 1, 12) : DateTime(s.year, s.month - 1);
  }

  /// Navigate to the next month — guarded so it cannot exceed the current month.
  void next() {
    final s = state;
    final now = DateTime.now();
    final next =
        s.month == 12 ? DateTime(s.year + 1, 1) : DateTime(s.year, s.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      state = next;
    }
  }
}

// ---------------------------------------------------------------------------
// Transaction stream for the selected month
// ---------------------------------------------------------------------------

/// Emits a reactive list of non-deleted transactions for the selected month.
@riverpod
Stream<List<Transaction>> transactionsByMonth(
  TransactionsByMonthRef ref,
) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchByMonth(month.year, month.month);
}

// ---------------------------------------------------------------------------
// Account and category lists exposed to presentation layer
// ---------------------------------------------------------------------------

/// Reactive account list for use in the transactions feature.
/// Avoids direct data/ imports in screens.
@riverpod
Stream<List<Account>> transactionAccountList(TransactionAccountListRef ref) =>
    ref.watch(accountRepositoryProvider).watchAccounts();

/// Reactive category list for use in the transactions feature.
/// Avoids direct data/ imports in screens.
@riverpod
Stream<List<Category>> transactionCategoryList(
  TransactionCategoryListRef ref,
) =>
    ref.watch(categoryRepositoryProvider).watchAll();

// ---------------------------------------------------------------------------
// Write operations
// ---------------------------------------------------------------------------

/// Notifier that exposes add / update / delete operations for transactions.
/// Screens must use this notifier instead of importing the repository directly.
@riverpod
class TransactionWriteNotifier extends _$TransactionWriteNotifier {
  @override
  void build() {}

  /// Persists a new [transaction] via the repository.
  Future<void> addTransaction(Transaction transaction) async {
    await ref.read(transactionRepositoryProvider).addTransaction(transaction);
    ref.invalidate(statsTxnsProvider);
  }

  /// Updates an existing [transaction] via the repository.
  Future<void> updateTransaction(Transaction transaction) async {
    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(transaction);
    ref.invalidate(statsTxnsProvider);
  }

  /// Soft-deletes the transaction with the given [id] via the repository.
  Future<void> deleteTransaction(String id) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    ref.invalidate(statsTxnsProvider);
  }
}
