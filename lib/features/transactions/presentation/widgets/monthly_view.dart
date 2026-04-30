// MonthlyView — year-based list with per-month and per-week totals.
// features/transactions — US-023 / SPEC-011.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/transactions_provider.dart';

// Muted highlight for current-week row — uses brand primary at low opacity (BUG-007).
const Color _currentWeekBg =
    Color(0x143D5A99); // brandPrimary.withOpacity(0.08)

/// Shows 12 month accordion cards for the selected year.
class MonthlyView extends ConsumerWidget {
  const MonthlyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearNotifierProvider);
    final asyncTotals = ref.watch(yearlyMonthlyTotalsProvider);

    return asyncTotals.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (e, __) => Center(
        child: Text(
          AppLocalizations.of(context)!.errorLoadTitle,
          style: AppTypography.headline.copyWith(color: context.textPrimary),
        ),
      ),
      data: (monthMap) => _MonthList(year: year, monthTotals: monthMap),
    );
  }
}

// ---------------------------------------------------------------------------
// Month list
// ---------------------------------------------------------------------------

class _MonthList extends StatefulWidget {
  const _MonthList({required this.year, required this.monthTotals});

  final int year;
  final Map<int, MonthTotals> monthTotals;

  @override
  State<_MonthList> createState() => _MonthListState();
}

class _MonthListState extends State<_MonthList> {
  /// Tracks which month indices are expanded.
  late Set<int> _expandedMonths;

  @override
  void initState() {
    super.initState();
    // Expand current month if viewing current year, else expand nothing.
    final now = DateTime.now();
    _expandedMonths = widget.year == now.year ? {now.month} : {};
  }

  @override
  void didUpdateWidget(_MonthList old) {
    super.didUpdateWidget(old);
    if (old.year != widget.year) {
      final now = DateTime.now();
      _expandedMonths = widget.year == now.year ? {now.month} : {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1; // 1–12
        final totals = widget.monthTotals[month] ??
            const MonthTotals(income: 0, expense: 0);
        final isExpanded = _expandedMonths.contains(month);
        final isCurrentMonth = _isCurrentMonth(month);

        return _MonthCard(
          year: widget.year,
          month: month,
          totals: totals,
          isExpanded: isExpanded,
          isCurrentMonth: isCurrentMonth,
          onToggle: () => setState(() {
            if (isExpanded) {
              _expandedMonths.remove(month);
            } else {
              _expandedMonths.add(month);
            }
          }),
        );
      },
    );
  }

  bool _isCurrentMonth(int month) {
    final now = DateTime.now();
    return widget.year == now.year && month == now.month;
  }
}

// ---------------------------------------------------------------------------
// Month card (accordion)
// ---------------------------------------------------------------------------

class _MonthCard extends ConsumerWidget {
  const _MonthCard({
    required this.year,
    required this.month,
    required this.totals,
    required this.isExpanded,
    required this.isCurrentMonth,
    required this.onToggle,
  });

  final int year;
  final int month;
  final MonthTotals totals;
  final bool isExpanded;
  final bool isCurrentMonth;
  final VoidCallback onToggle;

  List<_WeekRange> _computeWeeks() {
    // Week starts Monday per SPEC
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final weeks = <_WeekRange>[];

    DateTime weekStart = firstDay;
    while (weekStart.isBefore(lastDay) || weekStart == lastDay) {
      // End of week: Sunday (weekday 7)
      final daysToSunday = 7 - weekStart.weekday;
      final weekEnd = weekStart.add(Duration(days: daysToSunday));
      weeks.add(_WeekRange(start: weekStart, end: weekEnd));
      weekStart = weekEnd.add(const Duration(days: 1));
    }
    return weeks;
  }

  String get _dateRangeLabel {
    final start = '1.$month.';
    final end = '${DateTime(year, month + 1, 0).day}.$month.';
    return '$start ~ $end';
  }

  String get _monthLabel => DateFormat('MMMM').format(DateTime(year, month));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeks = _computeWeeks();
    // BUG-006: load real weekly totals via provider.
    final weeklyAsync = ref.watch(weeklyTotalsForMonthProvider(year, month));
    final expandedSemanticsLabel = isExpanded
        ? '$_monthLabel $year. Expanded. Tap to collapse.'
        : '$_monthLabel $year. '
            'Income: ${CurrencyFormatter.format(totals.income)}, '
            'Expense: ${CurrencyFormatter.format(totals.expense)}, '
            'Total: ${CurrencyFormatter.formatSigned(totals.net)}. '
            'Tap to expand.';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          // Month row (header)
          Semantics(
            label: expandedSemanticsLabel,
            expanded: isExpanded,
            child: InkWell(
              onTap: onToggle,
              child: Container(
                height: 52,
                color: isExpanded ? context.bgTertiary : context.bgSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    // Current month accent bar
                    if (isCurrentMonth)
                      Container(
                        width: 3,
                        height: 28,
                        color: AppColors.brandPrimary,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                      ),
                    // Expand chevron
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.chevron_right,
                        color: context.textTertiary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Month name
                    SizedBox(
                      width: 60,
                      child: Text(
                        _monthLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Date range
                    Text(
                      _dateRangeLabel,
                      style: AppTypography.caption1.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    // Totals
                    _TotalsGroup(totals: totals),
                  ],
                ),
              ),
            ),
          ),
          // Week rows (expanded) — BUG-006: real weekly totals.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: weeks.isEmpty
                        ? [_NoTransactionsRow()]
                        : weeks.map((w) {
                            final weekMap = weeklyAsync.valueOrNull ?? {};
                            // Match by week-start date (Monday).
                            final weekTotals = weekMap[w.start] ??
                                const MonthTotals(income: 0, expense: 0);
                            return _WeekRowWidget(
                              weekRange: w,
                              totals: weekTotals,
                            );
                          }).toList(),
                  )
                : const SizedBox.shrink(),
          ),
          Divider(height: 1, color: context.dividerColor),
        ],
      ),
    );
  }
}

class _NoTransactionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: context.bgSecondary,
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.monthlyNoTransactions,
          style: AppTypography.caption1.copyWith(
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week row
// ---------------------------------------------------------------------------

class _WeekRange {
  const _WeekRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  bool get isCurrentWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !today.isBefore(s) && !today.isAfter(e);
  }

  String get label {
    final s = '${start.day}.${start.month}.';
    final e = '${end.day}.${end.month}.';
    return '$s ~ $e';
  }
}

class _WeekRowWidget extends StatelessWidget {
  const _WeekRowWidget({required this.weekRange, required this.totals});

  final _WeekRange weekRange;
  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    // BUG-007: coral highlight for current week, not grey.
    final bg = weekRange.isCurrentWeek ? _currentWeekBg : context.bgSecondary;

    return Semantics(
      label: '${weekRange.label} week. '
          'Income: ${CurrencyFormatter.format(totals.income)}, '
          'Expense: ${CurrencyFormatter.format(totals.expense)}, '
          'Total: ${CurrencyFormatter.formatSigned(totals.net)}.',
      child: Container(
        height: 44,
        color: bg,
        padding: const EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.lg,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                weekRange.label,
                style: AppTypography.caption1.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            _TotalsGroup(totals: totals),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared totals group
// ---------------------------------------------------------------------------

class _TotalsGroup extends StatelessWidget {
  const _TotalsGroup({required this.totals});

  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            CurrencyFormatter.format(totals.income),
            style: AppTypography.moneySmall.copyWith(
              color:
                  totals.income > 0 ? AppColors.income : context.textTertiary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(
            CurrencyFormatter.format(totals.expense),
            style: AppTypography.moneySmall.copyWith(
              color: totals.expense > 0
                  ? context.expenseColor
                  : context.textTertiary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 76,
          child: Text(
            CurrencyFormatter.formatSigned(totals.net),
            style: AppTypography.moneySmall.copyWith(
              color: totals.net >= 0 ? AppColors.income : context.expenseColor,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
