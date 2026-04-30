// CalendarView — monthly calendar grid with daily spend indicators.
// features/transactions — US-022 / SPEC-010.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/transactions_provider.dart';
import 'transaction_row.dart';

/// Calendar grid for the selected month. Tapping a day opens a bottom sheet
/// with that day's transactions.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
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
            onDaySelected: (day) => _onDayTapped(context, day),
          ),
        ),
      ],
    );
  }

  /// Shows the day-detail modal bottom sheet (BUG-004).
  void _onDayTapped(BuildContext context, DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(selectedDay: day),
    );
  }
}

// ---------------------------------------------------------------------------
// Week-day header row
// ---------------------------------------------------------------------------

class _WeekDayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Week starts Monday per SPEC
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border:
            Border(bottom: BorderSide(color: context.dividerColor, width: 1)),
      ),
      child: Row(
        children: days.map((d) {
          final isSat = d == 'Sat';
          final isSun = d == 'Sun';
          final color = isSat
              ? AppColors.income
              : isSun
                  ? AppColors.expense
                  : AppColors.textSecondary;
          return Expanded(
            child: Semantics(
              label: _fullDayName(d),
              child: Center(
                child: Text(
                  d,
                  style: AppTypography.caption1.copyWith(color: color),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fullDayName(String abbr) {
    const map = {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
    };
    return map[abbr] ?? abbr;
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
    required this.onDaySelected,
  });

  final int year;
  final int month;
  final Map<DateTime, DayTotals> dayTotals;
  final ValueChanged<DateTime> onDaySelected;

  /// Returns a flat list of day entries to fill the 7-column grid.
  /// Includes leading days from the previous month and trailing days from
  /// the next month.
  List<_GridDay> _buildGridDays() {
    final firstOfMonth = DateTime(year, month, 1);
    // weekday: Mon=1, Sun=7. We want Mon at column 0.
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final days = <_GridDay>[];

    // Previous month overflow
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
    for (var i = leadingBlanks - 1; i >= 0; i--) {
      days.add(_GridDay(
        day: DateTime(prevYear, prevMonth, daysInPrevMonth - i),
        isCurrentMonth: false,
      ));
    }

    // Current month
    for (var d = 1; d <= daysInMonth; d++) {
      days.add(_GridDay(day: DateTime(year, month, d), isCurrentMonth: true));
    }

    // Next month overflow
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
            return _CalendarDayCell(
              day: entry.day,
              isCurrentMonth: entry.isCurrentMonth,
              isToday: _isToday(entry.day),
              income: totals?.income,
              expense: totals?.expense,
              onTap: entry.isCurrentMonth ? () => onDaySelected(key) : null,
            );
          },
        );
      },
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
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
    this.income,
    this.expense,
    this.onTap,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
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

    // BUG-005: today gets a full-cell brand-primary tint background.
    Color? bgColor;
    if (isToday) {
      bgColor = AppColors.brandPrimary.withValues(alpha: 0.12);
    }

    // BUG-005: future dates use textTertiary; today uses textOnBrand-contrast
    // via the circle; past/current use textPrimary; off-month uses textTertiary.
    Color dayNumColor;
    if (!isCurrentMonth) {
      dayNumColor = context.textTertiary;
    } else if (isToday) {
      dayNumColor = AppColors.textOnBrand;
    } else if (isFuture) {
      dayNumColor = context.textTertiary;
    } else {
      dayNumColor = context.textPrimary;
    }

    final semanticsLabel = isToday
        ? 'Today, ${DateFormat('d MMMM').format(day)}.'
        : '${DateFormat('d MMMM').format(day)}.';

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: context.dividerColor, width: 1),
              right: BorderSide(color: context.dividerColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day number — wrapped in brand circle only for today.
              isToday
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.textOnBrand,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      '${day.day}',
                      style: AppTypography.caption1.copyWith(
                        color: dayNumColor,
                      ),
                    ),
              const Spacer(),
              // Amounts (bottom) — hidden for future dates.
              if (hasIncome && !isFuture)
                Text(
                  CurrencyFormatter.formatCompact(income!),
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.income,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasExpense && !isFuture)
                Text(
                  CurrencyFormatter.formatCompact(expense!),
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.expense,
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

// ---------------------------------------------------------------------------
// Day detail modal bottom sheet (BUG-004)
// ---------------------------------------------------------------------------

/// Modal bottom sheet showing transactions for a given [selectedDay].
/// Presented via [showModalBottomSheet] — not rendered inline in the calendar.
class _DayDetailSheet extends ConsumerWidget {
  const _DayDetailSheet({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTxs = ref.watch(dayTransactionsProvider(selectedDay));
    final title = DateFormat('EEEE, d MMMM yyyy').format(selectedDay);
    final maxHeight = MediaQuery.of(context).size.height * 0.5;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          // Sheet header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Semantics(
              label: '$title transactions',
              child: Text(
                title,
                style: AppTypography.headline.copyWith(
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.dividerColor),
          // Transaction list
          Flexible(
            child: asyncTxs.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  AppLocalizations.of(context)!.errorLoadTitle,
                  style: AppTypography.subhead.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!
                            .calendarDayPanelNoTransactions,
                        style: AppTypography.subhead.copyWith(
                          color: context.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: txs.length,
                  itemBuilder: (_, i) => TransactionRow(
                    transaction: txs[i],
                    currencySymbol: AppConstants.defaultCurrencySymbol,
                  ),
                );
              },
            ),
          ),
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
