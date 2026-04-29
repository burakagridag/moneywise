// Riverpod providers for statistics screen — category breakdown, totals, month navigation — stats feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/transaction_repository.dart';

part 'stats_provider.g.dart';

// ---------------------------------------------------------------------------
// Selected month navigation for stats
// ---------------------------------------------------------------------------

/// Tracks the currently selected year-month for the stats view.
@riverpod
class SelectedStatsMonth extends _$SelectedStatsMonth {
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
// Stats type toggle
// ---------------------------------------------------------------------------

/// Controls whether the stats view shows 'income' or 'expense' breakdown.
@riverpod
class StatsType extends _$StatsType {
  @override
  String build() => 'expense';

  void setExpense() => state = 'expense';
  void setIncome() => state = 'income';
}

// ---------------------------------------------------------------------------
// Category breakdown
// ---------------------------------------------------------------------------

/// Emits a map of {categoryId → totalAmount} for the selected month and type.
/// The key is the categoryId, or 'Uncategorized' for transactions without a category.
@riverpod
Future<Map<String, double>> categoryBreakdown(
  CategoryBreakdownRef ref,
) async {
  final month = ref.watch(selectedStatsMonthProvider);
  final type = ref.watch(statsTypeProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  final txns = await repo.getByMonth(month.year, month.month);

  final breakdown = <String, double>{};
  for (final t in txns) {
    if (t.type != type) continue;
    final key = t.categoryId ?? 'Uncategorized';
    breakdown[key] = (breakdown[key] ?? 0.0) + t.amount;
  }
  return breakdown;
}

// ---------------------------------------------------------------------------
// Monthly totals
// ---------------------------------------------------------------------------

/// Total income for the selected month.
@riverpod
Future<double> statsIncomeTotal(StatsIncomeTotalRef ref) async {
  final month = ref.watch(selectedStatsMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final txns = await repo.getByMonth(month.year, month.month);
  return txns
      .where((t) => t.type == 'income')
      .fold<double>(0.0, (s, t) => s + t.amount);
}

/// Total expenses for the selected month.
@riverpod
Future<double> statsExpenseTotal(StatsExpenseTotalRef ref) async {
  final month = ref.watch(selectedStatsMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final txns = await repo.getByMonth(month.year, month.month);
  return txns
      .where((t) => t.type == 'expense')
      .fold<double>(0.0, (s, t) => s + t.amount);
}
