// Search and filter state providers for the Transactions feature — features/transactions.
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/transaction_repository.dart';
import 'transactions_provider.dart';

part 'search_filter_provider.g.dart';

// ---------------------------------------------------------------------------
// Search query
// ---------------------------------------------------------------------------

/// Current text search query entered in the search bar.
@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void setQuery(String query) => state = query;

  void clear() => state = '';
}

// ---------------------------------------------------------------------------
// Filter value class
// ---------------------------------------------------------------------------

/// Immutable filter criteria applied to the transaction list.
class TransactionFilter {
  const TransactionFilter({
    this.types = const {},
    this.categoryId,
    this.dateRange,
  });

  /// Selected types — empty means no type filter (show all).
  final Set<String> types;

  /// When non-null, only transactions matching this category id are shown.
  final String? categoryId;

  /// When non-null, only transactions within this date range are shown.
  final DateTimeRange? dateRange;

  bool get hasActiveFilter =>
      types.isNotEmpty || categoryId != null || dateRange != null;

  int get activeCount {
    int count = 0;
    if (types.isNotEmpty) count++;
    if (categoryId != null) count++;
    if (dateRange != null) count++;
    return count;
  }

  TransactionFilter copyWith({
    Set<String>? types,
    String? categoryId,
    DateTimeRange? dateRange,
    bool clearCategoryId = false,
    bool clearDateRange = false,
  }) {
    return TransactionFilter(
      types: types ?? this.types,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter notifier
// ---------------------------------------------------------------------------

/// Manages the active [TransactionFilter] state.
@riverpod
class TransactionFilterNotifier extends _$TransactionFilterNotifier {
  @override
  TransactionFilter build() => const TransactionFilter();

  void toggleType(String type) {
    final current = state.types;
    final updated = current.contains(type)
        ? current.difference({type})
        : {...current, type};
    state = state.copyWith(types: updated);
  }

  void setCategoryId(String? id) {
    state = id == null
        ? state.copyWith(clearCategoryId: true)
        : state.copyWith(categoryId: id);
  }

  void setDateRange(DateTimeRange? range) {
    state = range == null
        ? state.copyWith(clearDateRange: true)
        : state.copyWith(dateRange: range);
  }

  /// Replaces the entire filter state at once. Used by the filter modal's
  /// "Apply" button to atomically commit all selections in a single rebuild.
  void apply(TransactionFilter filter) => state = filter;

  void reset() => state = const TransactionFilter();
}

// ---------------------------------------------------------------------------
// Derived provider — filtered transactions
// ---------------------------------------------------------------------------

/// Derived StreamProvider that applies search + filter predicates on top of
/// the monthly transaction stream. Returns the unfiltered list when no
/// query/filter is active.
///
/// This provider re-evaluates whenever the selected period, search query,
/// or active filter changes, because it watches all three dependencies.
@riverpod
Stream<List<TransactionWithDetails>> filteredTransactions(
  FilteredTransactionsRef ref,
) {
  final query = ref.watch(searchQueryNotifierProvider).toLowerCase().trim();
  final filter = ref.watch(transactionFilterNotifierProvider);

  // Pull the upstream repository stream directly so that changing the query /
  // filter (i.e. calling ref.watch above) disposes and re-creates this
  // provider, giving us a fresh subscription to the underlying DB stream.
  final period = ref.watch(selectedPeriodNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  return repo
      .watchTransactionsWithDetailsForMonth(period.year, period.month)
      .map((items) => applySearchFilter(items, query, filter));
}

// ---------------------------------------------------------------------------
// Predicate logic — exported so unit tests can exercise without a provider graph
// ---------------------------------------------------------------------------

/// Filters [items] by [query] and [filter].
List<TransactionWithDetails> applySearchFilter(
  List<TransactionWithDetails> items,
  String query,
  TransactionFilter filter,
) {
  return items.where((item) {
    final tx = item.transaction;

    // Type filter
    if (filter.types.isNotEmpty && !filter.types.contains(tx.type)) {
      return false;
    }

    // Category filter
    if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
      return false;
    }

    // Date range filter
    if (filter.dateRange != null) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final start = filter.dateRange!.start;
      final end = filter.dateRange!.end;
      if (date.isBefore(start) || date.isAfter(end)) return false;
    }

    // Text search — matches description/note, category name, or account name
    if (query.isNotEmpty) {
      final description = (tx.description ?? '').toLowerCase();
      final categoryName = (item.categoryName ?? '').toLowerCase();
      final accountName = (item.accountName ?? '').toLowerCase();
      if (!description.contains(query) &&
          !categoryName.contains(query) &&
          !accountName.contains(query)) {
        return false;
      }
    }

    return true;
  }).toList();
}
