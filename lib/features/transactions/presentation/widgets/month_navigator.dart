// Month/Year navigator widget with previous/next arrows and a picker trigger.
// features/transactions — US-025.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/transactions_provider.dart';

/// Shared navigator bar placed above the PeriodTabBar.
///
/// When [showYearOnly] is true (Monthly tab) the label shows just the year
/// ("2026") and the arrows navigate by year; otherwise it shows "Apr 2026"
/// and the arrows navigate by month.
class MonthNavigator extends ConsumerWidget {
  const MonthNavigator({
    super.key,
    this.showYearOnly = false,
  });

  final bool showYearOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showYearOnly) {
      return _YearNavigator(key: key);
    }
    return _MonthNavigatorContent(key: key);
  }
}

class _MonthNavigatorContent extends ConsumerWidget {
  const _MonthNavigatorContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodNotifierProvider);
    final notifier = ref.read(selectedPeriodNotifierProvider.notifier);

    final date = DateTime(period.year, period.month);
    final label = DateFormat.yMMMM().format(date); // e.g. "April 2026"
    final prevDate = DateTime(
      period.month == 1 ? period.year - 1 : period.year,
      period.month == 1 ? 12 : period.month - 1,
    );
    final nextDate = DateTime(
      period.month == 12 ? period.year + 1 : period.year,
      period.month == 12 ? 1 : period.month + 1,
    );

    return _NavigatorBar(
      label: label,
      onPrevious: notifier.goToPreviousMonth,
      onNext: notifier.goToNextMonth,
      onLabelTap: () => _showMonthYearPicker(context, ref, period),
      previousSemanticsLabel:
          'Go to previous month, ${DateFormat.yMMMM().format(prevDate)}',
      nextSemanticsLabel:
          'Go to next month, ${DateFormat.yMMMM().format(nextDate)}',
      labelSemanticsHint: 'Current period: $label. Tap to change.',
    );
  }

  Future<void> _showMonthYearPicker(
    BuildContext context,
    WidgetRef ref,
    SelectedPeriod current,
  ) async {
    final result = await _MonthYearPickerSheet.show(
      context,
      initialYear: current.year,
      initialMonth: current.month,
      yearOnly: false,
    );
    if (result != null) {
      ref
          .read(selectedPeriodNotifierProvider.notifier)
          .goToMonth(result.year, result.month);
    }
  }
}

class _YearNavigator extends ConsumerWidget {
  const _YearNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearNotifierProvider);
    final notifier = ref.read(selectedYearNotifierProvider.notifier);

    return _NavigatorBar(
      label: year.toString(),
      onPrevious: notifier.goToPreviousYear,
      onNext: notifier.goToNextYear,
      onLabelTap: () => _showYearPicker(context, ref, year),
      previousSemanticsLabel: 'Go to previous year, ${year - 1}',
      nextSemanticsLabel: 'Go to next year, ${year + 1}',
      labelSemanticsHint: 'Current year: $year. Tap to change.',
    );
  }

  Future<void> _showYearPicker(
    BuildContext context,
    WidgetRef ref,
    int currentYear,
  ) async {
    final result = await _MonthYearPickerSheet.show(
      context,
      initialYear: currentYear,
      initialMonth: 1,
      yearOnly: true,
    );
    if (result != null) {
      ref.read(selectedYearNotifierProvider.notifier).goToYear(result.year);
    }
  }
}

// ---------------------------------------------------------------------------
// Shared layout
// ---------------------------------------------------------------------------

class _NavigatorBar extends StatelessWidget {
  const _NavigatorBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onLabelTap,
    required this.previousSemanticsLabel,
    required this.nextSemanticsLabel,
    required this.labelSemanticsHint,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLabelTap;
  final String previousSemanticsLabel;
  final String nextSemanticsLabel;
  final String labelSemanticsHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: context.bgPrimary,
      child: Row(
        children: [
          Semantics(
            label: previousSemanticsLabel,
            button: true,
            child: InkWell(
              onTap: onPrevious,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: context.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              hint: labelSemanticsHint,
              button: true,
              child: GestureDetector(
                onTap: onLabelTap,
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.title2.copyWith(
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: nextSemanticsLabel,
            button: true,
            child: InkWell(
              onTap: onNext,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: context.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month/Year picker bottom sheet
// ---------------------------------------------------------------------------

class _PickerResult {
  const _PickerResult({required this.year, required this.month});
  final int year;
  final int month;
}

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({
    required this.initialYear,
    required this.initialMonth,
    required this.yearOnly,
  });

  final int initialYear;
  final int initialMonth;
  final bool yearOnly;

  static Future<_PickerResult?> show(
    BuildContext context, {
    required int initialYear,
    required int initialMonth,
    required bool yearOnly,
  }) {
    return showModalBottomSheet<_PickerResult>(
      context: context,
      backgroundColor: context.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _MonthYearPickerSheet(
        initialYear: initialYear,
        initialMonth: initialMonth,
        yearOnly: yearOnly,
      ),
    );
  }

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.bgTertiary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.headline.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    _PickerResult(
                      year: _selectedYear,
                      month: _selectedMonth,
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Drum-roll pickers
          SizedBox(
            height: 180,
            child: Row(
              children: [
                if (!widget.yearOnly)
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: _selectedMonth - 1,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) =>
                          setState(() => _selectedMonth = i + 1),
                      children: List.generate(
                        12,
                        (i) => Center(
                          child: Text(
                            DateFormat.MMMM().format(DateTime(2000, i + 1)),
                            style: AppTypography.body.copyWith(
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _selectedYear - 2000,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (i) =>
                        setState(() => _selectedYear = 2000 + i),
                    children: List.generate(
                      201,
                      (i) => Center(
                        child: Text(
                          '${2000 + i}',
                          style: AppTypography.body.copyWith(
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
