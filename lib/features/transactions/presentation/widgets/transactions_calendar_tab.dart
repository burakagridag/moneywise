// TransactionsCalendarTab — "Takvim" tab of the redesigned Transactions screen.
// Uses ARB i18n weekday headers. Tapping a day switches to Liste tab — EPIC8D-01.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/transactions_provider.dart';

/// Takvim tab — calendar grid with income/expense indicators per day.
/// [onDaySelected] is called when a day cell is tapped; the parent switches
/// to the Liste tab (sponsor decision: no bottom sheet in redesign).
class TransactionsCalendarTab extends ConsumerStatefulWidget {
  const TransactionsCalendarTab({
    super.key,
    required this.onDaySelected,
  });

  /// Called when a current-month day cell is tapped. Parent uses this to
  /// switch to the Liste tab.
  final ValueChanged<DateTime> onDaySelected;

  @override
  ConsumerState<TransactionsCalendarTab> createState() =>
      _TransactionsCalendarTabState();
}

class _TransactionsCalendarTabState
    extends ConsumerState<TransactionsCalendarTab> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(selectedPeriodNotifierProvider);
    final dailyAsync = ref.watch(calendarDailyTotalsProvider);

    final Map<DateTime, DayTotals> dayMap = {};
    dailyAsync.whenData((list) {
      for (final d in list) {
        dayMap[DateTime(d.date.year, d.date.month, d.date.day)] = d;
      }
    });

    return Column(
      children: [
        _WeekDayHeader(),
        Expanded(
          child: _CalendarGrid(
            year: period.year,
            month: period.month,
            dayTotals: dayMap,
            selectedDay: _selectedDay,
            onDaySelected: (day) {
              setState(() => _selectedDay = day);
              widget.onDaySelected(day);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Week-day header — uses ARB i18n keys, no weekend color differentiation.
// ---------------------------------------------------------------------------

class _WeekDayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Sponsor decision: no weekend color differentiation.
    final days = [
      l10n.transactionsCalendarWeekdayMon,
      l10n.transactionsCalendarWeekdayTue,
      l10n.transactionsCalendarWeekdayWed,
      l10n.transactionsCalendarWeekdayThu,
      l10n.transactionsCalendarWeekdayFri,
      l10n.transactionsCalendarWeekdaySat,
      l10n.transactionsCalendarWeekdaySun,
    ];

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          bottom: BorderSide(color: context.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: days
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTypography.caption1.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar grid
// ---------------------------------------------------------------------------

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.dayTotals,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final Map<DateTime, DayTotals> dayTotals;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  List<_GridDay> _buildGridDays() {
    final firstOfMonth = DateTime(year, month, 1);
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final days = <_GridDay>[];

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
    for (var i = leadingBlanks - 1; i >= 0; i--) {
      days.add(_GridDay(
        day: DateTime(prevYear, prevMonth, daysInPrevMonth - i),
        isCurrentMonth: false,
      ));
    }

    for (var d = 1; d <= daysInMonth; d++) {
      days.add(_GridDay(day: DateTime(year, month, d), isCurrentMonth: true));
    }

    final totalCells = (days.length / 7).ceil() * 7;
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    var nextDay = 1;
    while (days.length < totalCells) {
      days.add(_GridDay(
        day: DateTime(nextYear, nextMonth, nextDay++),
        isCurrentMonth: false,
      ));
    }

    return days;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final gridDays = _buildGridDays();
    final rowCount = gridDays.length ~/ 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final cellHeight = constraints.maxHeight / rowCount;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellWidth / cellHeight,
          ),
          itemCount: gridDays.length,
          itemBuilder: (context, index) {
            final entry = gridDays[index];
            final key = DateTime(
              entry.day.year,
              entry.day.month,
              entry.day.day,
            );
            final totals = dayTotals[key];
            final isSelected = selectedDay != null &&
                selectedDay == key &&
                entry.isCurrentMonth;

            return _CalendarDayCell(
              day: entry.day,
              isCurrentMonth: entry.isCurrentMonth,
              isToday: _isToday(entry.day),
              isSelected: isSelected,
              income: totals?.income,
              expense: totals?.expense,
              onTap: (entry.isCurrentMonth && dayTotals.containsKey(key))
                  ? () => onDaySelected(key)
                  : null,
            );
          },
        );
      },
    );
  }
}

class _GridDay {
  const _GridDay({required this.day, required this.isCurrentMonth});
  final DateTime day;
  final bool isCurrentMonth;
}

// ---------------------------------------------------------------------------
// Calendar day cell
// ---------------------------------------------------------------------------

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    this.income,
    this.expense,
    this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final double? income;
  final double? expense;
  final VoidCallback? onTap;

  bool _isFuture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final hasIncome = (income ?? 0) > 0;
    final hasExpense = (expense ?? 0) > 0;
    final isFuture = isCurrentMonth && _isFuture();

    // D7 — Cell state priority: selected wins over today-only.
    //   selected (incl. today+selected): brand fill, white text + amounts
    //   today-only: highlight bg, brand-colored bold day number
    //   plain: no special bg
    final bool effectiveSelected = isSelected && isCurrentMonth;

    // Cell background — applied to the whole cell container.
    Color? cellBg;
    if (effectiveSelected) {
      cellBg = AppColors.brandPrimary; // solid brand fill for selected
    } else if (isToday && isCurrentMonth) {
      cellBg = context.calendarHighlight; // subtle highlight for today
    }

    // Day number color.
    Color dayNumColor;
    if (effectiveSelected) {
      dayNumColor = Colors.white;
    } else if (isToday && isCurrentMonth) {
      dayNumColor = AppColors.brandPrimary; // brand-colored for today
    } else if (!isCurrentMonth || isFuture) {
      dayNumColor = context.textSecondary;
    } else {
      dayNumColor = context.textPrimary;
    }

    // Amount text color — white when selected, semantic colors otherwise.
    Color incomeAmtColor =
        effectiveSelected ? Colors.white : context.incomeColor;
    Color expenseAmtColor =
        effectiveSelected ? Colors.white : context.expenseColor;

    final l10n = AppLocalizations.of(context)!;
    final monthStr = DateFormat('MMMM').format(day);
    final incomeStr = income != null ? CurrencyFormatter.format(income!) : '0';
    final expenseStr =
        expense != null ? CurrencyFormatter.format(expense!) : '0';
    final semanticsLabel = l10n.transactionsCalendarCellSemantic(
      day.day,
      monthStr,
      incomeStr,
      expenseStr,
    );

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cellBg,
            border: Border(
              bottom: BorderSide(color: context.dividerColor, width: 1),
              right: BorderSide(color: context.dividerColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // D7 — Day number rendering priority:
              //   1. selected (covers today+selected): plain bold text in white
              //      (cell bg already provides the solid brand fill)
              //   2. today-only: plain bold text in brandPrimary
              //      (cell bg provides the highlight fill)
              //   3. Plain text for all other days.
              if (effectiveSelected)
                Text(
                  '${day.day}',
                  style: AppTypography.caption2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (isToday && isCurrentMonth)
                Text(
                  '${day.day}',
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '${day.day}',
                  style: AppTypography.caption1.copyWith(
                    color: dayNumColor,
                  ),
                ),
              const Spacer(),
              // Income / expense amounts (hidden for future dates).
              if (hasIncome && !isFuture)
                Text(
                  CurrencyFormatter.formatCompact(income!),
                  style: AppTypography.caption2.copyWith(
                    color: incomeAmtColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasExpense && !isFuture)
                Text(
                  CurrencyFormatter.formatCompact(expense!),
                  style: AppTypography.caption2.copyWith(
                    color: expenseAmtColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
