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
    this.query,
    this.type,
    this.amountMin,
  });

  /// Selected types — empty means no type filter (show all). Legacy multi-select.
  final Set<String> types;

  /// When non-null, only transactions matching this category id are shown.
  final String? categoryId;

  /// When non-null, only transactions within this date range are shown.
  final DateTimeRange? dateRange;

  /// Text search query. When non-null and non-empty, only matching transactions
  /// are shown. Used by the unified [SearchFilterNotifier].
  final String? query;

  /// Single transaction type filter: 'income', 'expense', or 'transfer'.
  /// Takes precedence over [types] when both are set.
  final String? type;

  /// Minimum absolute transaction amount filter.
  final double? amountMin;

  /// Returns true when no filter criteria are active.
  bool get isEmpty =>
      types.isEmpty &&
      categoryId == null &&
      dateRange == null &&
      (query == null || query!.isEmpty) &&
      type == null &&
      amountMin == null;

  bool get hasActiveFilter => !isEmpty;

  int get activeCount {
    int count = 0;
    if (types.isNotEmpty || type != null) count++;
    if (categoryId != null) count++;
    if (dateRange != null) count++;
    if (query != null && query!.isNotEmpty) count++;
    if (amountMin != null) count++;
    return count;
  }

  TransactionFilter copyWith({
    Set<String>? types,
    String? categoryId,
    DateTimeRange? dateRange,
    bool clearCategoryId = false,
    bool clearDateRange = false,
    Object? query = _sentinel,
    Object? type = _sentinel,
    Object? amountMin = _sentinel,
  }) {
    return TransactionFilter(
      types: types ?? this.types,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      query: identical(query, _sentinel) ? this.query : query as String?,
      type: identical(type, _sentinel) ? this.type : type as String?,
      amountMin:
          identical(amountMin, _sentinel) ? this.amountMin : amountMin as double?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.types == types &&
      other.categoryId == categoryId &&
      other.dateRange == dateRange &&
      other.query == query &&
      other.type == type &&
      other.amountMin == amountMin;

  @override
  int get hashCode =>
      Object.hash(types, categoryId, dateRange, query, type, amountMin);
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Unified search+filter notifier (EPIC8A / Sprint 8 simplified API)
// ---------------------------------------------------------------------------

/// Unified notifier that holds both search query and filter criteria in a
/// single [TransactionFilter] state object. Used by the search bar and the
/// filter sheet to atomically update all filter criteria.
@riverpod
class SearchFilterNotifier extends _$SearchFilterNotifier {
  @override
  TransactionFilter build() => const TransactionFilter();

  /// Updates the text search query.
  void setQuery(String query) =>
      state = state.copyWith(query: query.isEmpty ? null : query);

  /// Clears the text search query.
  void clearQuery() => state = state.copyWith(query: null);

  /// Replaces the entire filter state atomically.
  void apply(TransactionFilter filter) => state = filter;

  /// Resets all criteria to the empty filter.
  void reset() => state = const TransactionFilter();
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
