// Riverpod providers for the Transactions feature — period navigation,
// daily list, monthly totals, calendar data, and write operations — features/transactions.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/transaction.dart' as domain;
import '../../../../domain/entities/transaction_with_details.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import 'transaction_mutation_signal_provider.dart';

export '../../../../data/repositories/transaction_repository.dart'
    show DayTotals, MonthTotals, TransactionWithNames;
export '../../../../domain/entities/transaction.dart'
    show Transaction, TransactionType;
export '../../../../domain/entities/transaction_with_details.dart'
    show TransactionWithDetails;

part 'transactions_provider.g.dart';

// ---------------------------------------------------------------------------
// Period state
// ---------------------------------------------------------------------------

/// Holds the currently selected (year, month) for Daily / Calendar / Summary
/// tabs.
class SelectedPeriod {
  const SelectedPeriod({required this.year, required this.month});

  final int year;
  final int month;

  SelectedPeriod copyWith({int? year, int? month}) {
    return SelectedPeriod(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  /// Navigate one month back, rolling over year boundary.
  SelectedPeriod previousMonth() {
    if (month == 1) return SelectedPeriod(year: year - 1, month: 12);
    return SelectedPeriod(year: year, month: month - 1);
  }

  /// Navigate one month forward, rolling over year boundary.
  SelectedPeriod nextMonth() {
    if (month == 12) return SelectedPeriod(year: year + 1, month: 1);
    return SelectedPeriod(year: year, month: month + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is SelectedPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// The selected month/year for Daily, Calendar, and Summary views.
@riverpod
class SelectedPeriodNotifier extends _$SelectedPeriodNotifier {
  @override
  SelectedPeriod build() {
    final now = DateTime.now();
    return SelectedPeriod(year: now.year, month: now.month);
  }

  void goToPreviousMonth() => state = state.previousMonth();
  void goToNextMonth() => state = state.nextMonth();
  void goToMonth(int year, int month) =>
      state = SelectedPeriod(year: year, month: month);
}

/// The selected year for Monthly view (navigates by year, not month).
@riverpod
class SelectedYearNotifier extends _$SelectedYearNotifier {
  @override
  int build() => DateTime.now().year;

  void goToPreviousYear() => state = state - 1;
  void goToNextYear() => state = state + 1;
  void goToYear(int year) => state = year;
}

// ---------------------------------------------------------------------------
// Sprint 3 — Selected month (legacy, kept for TransactionAddEditScreen
// compatibility)
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
// Transaction stream providers
// ---------------------------------------------------------------------------

/// Emits a reactive list of non-deleted transactions for the selected month
/// (Sprint 3 compatibility — used by TransactionAddEditScreen providers).
@riverpod
Stream<List<domain.Transaction>> transactionsByMonth(
  TransactionsByMonthRef ref,
) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchByMonth(month.year, month.month);
}

/// Emits all transactions for the currently selected month (Daily / Calendar).
@riverpod
Stream<List<domain.Transaction>> monthlyTransactions(
  MonthlyTransactionsRef ref,
) {
  final period = ref.watch(selectedPeriodNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactionsForMonth(period.year, period.month);
}

/// Emits transactions with resolved category and account names for the
/// currently selected month — used by DailyView (BUG-003).
@riverpod
Stream<List<TransactionWithDetails>> monthlyTransactionsWithDetails(
  MonthlyTransactionsWithDetailsRef ref,
) {
  final period = ref.watch(selectedPeriodNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactionsWithDetailsForMonth(period.year, period.month);
}

/// Emits income/expense totals for the currently selected month.
@riverpod
Stream<MonthTotals> monthlyTotals(MonthlyTotalsRef ref) {
  final period = ref.watch(selectedPeriodNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchMonthlyTotals(period.year, period.month);
}

/// Emits daily totals map for the currently selected month (CalendarView).
@riverpod
Stream<List<DayTotals>> calendarDailyTotals(CalendarDailyTotalsRef ref) {
  final period = ref.watch(selectedPeriodNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchDailyTotals(period.year, period.month);
}

/// Emits all transactions for a specific [date] (DayDetailPanel in Calendar).
@riverpod
Stream<List<domain.Transaction>> dayTransactions(
  DayTransactionsRef ref,
  DateTime date,
) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactionsForDay(date);
}

/// Emits weekly totals for a given [year]/[month], keyed by week-start date.
/// Client-side aggregation over the monthly transaction stream (BUG-006).
@riverpod
Stream<Map<DateTime, MonthTotals>> weeklyTotalsForMonth(
  WeeklyTotalsForMonthRef ref,
  int year,
  int month,
) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactionsForMonth(year, month).map((txList) {
    final Map<DateTime, ({int incomeCents, int expenseCents})> acc = {};

    for (final tx in txList) {
      if (tx.isExcluded) continue;
      // Week start = most recent Monday on or before tx.date
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));

      final cur = acc[weekStart] ?? (incomeCents: 0, expenseCents: 0);
      if (tx.transactionType == domain.TransactionType.income) {
        acc[weekStart] = (
          incomeCents: cur.incomeCents + (tx.amount * 100).round(),
          expenseCents: cur.expenseCents,
        );
      } else if (tx.transactionType == domain.TransactionType.expense) {
        acc[weekStart] = (
          incomeCents: cur.incomeCents,
          expenseCents: cur.expenseCents + (tx.amount * 100).round(),
        );
      }
    }

    return acc.map(
      (weekStart, v) => MapEntry(
        weekStart,
        MonthTotals(
          income: v.incomeCents / 100.0,
          expense: v.expenseCents / 100.0,
        ),
      ),
    );
  });
}

/// Emits per-month totals for the currently selected year (MonthlyView).
@riverpod
Stream<Map<int, MonthTotals>> yearlyMonthlyTotals(
  YearlyMonthlyTotalsRef ref,
) {
  final year = ref.watch(selectedYearNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchYearlyMonthlyTotals(year);
}

/// Emits income/expense totals for the full selected year (MonthlyView summary
/// bar).
@riverpod
Stream<MonthTotals> yearlyTotals(YearlyTotalsRef ref) {
  final year = ref.watch(selectedYearNotifierProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchYearlyMonthlyTotals(year).map((monthMap) {
    double income = 0;
    double expense = 0;
    for (final t in monthMap.values) {
      income += t.income;
      expense += t.expense;
    }
    return MonthTotals(income: income, expense: expense);
  });
}

// ---------------------------------------------------------------------------
// Account and category lists exposed to presentation layer (Sprint 3)
// ---------------------------------------------------------------------------

/// Reactive account list for use in the transactions feature.
@riverpod
Stream<List<Account>> transactionAccountList(TransactionAccountListRef ref) =>
    ref.watch(accountRepositoryProvider).watchAccounts();

/// Reactive category list for use in the transactions feature.
@riverpod
Stream<List<Category>> transactionCategoryList(
  TransactionCategoryListRef ref,
) =>
    ref.watch(categoryRepositoryProvider).watchAll();

// ---------------------------------------------------------------------------
// Write operations (Sprint 3)
// ---------------------------------------------------------------------------

/// Notifier that exposes add / update / delete operations for transactions.
@riverpod
class TransactionWriteNotifier extends _$TransactionWriteNotifier {
  @override
  void build() {}

  /// Persists a new [transaction] via the repository.
  Future<void> addTransaction(domain.Transaction transaction) async {
    await ref.read(transactionRepositoryProvider).addTransaction(transaction);
    ref.invalidate(statsTxnsProvider);
    ref.read(transactionMutationSignalProvider.notifier).increment();
  }

  /// Updates an existing [transaction] via the repository.
  Future<void> updateTransaction(domain.Transaction transaction) async {
    await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(transaction);
    ref.invalidate(statsTxnsProvider);
    ref.read(transactionMutationSignalProvider.notifier).increment();
  }

  /// Soft-deletes the transaction with the given [id] via the repository.
  Future<void> deleteTransaction(String id) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    ref.invalidate(statsTxnsProvider);
    ref.read(transactionMutationSignalProvider.notifier).increment();
  }
}
