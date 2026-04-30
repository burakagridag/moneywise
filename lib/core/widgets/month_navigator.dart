// Reusable month navigation row widget shared by transactions and stats tabs — core/widgets.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors_ext.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// A 48dp sticky navigation bar that lets the user browse months.
/// Pressing the right chevron is disabled when [selectedMonth] is the current month.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    super.key,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final label = DateFormat('MMM yyyy').format(selectedMonth);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon:
                Icon(Icons.chevron_left, color: context.textPrimary, size: 24),
            onPressed: onPrevious,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: Text(
                label,
                style:
                    AppTypography.subhead.copyWith(color: context.textPrimary),
              ),
            ),
          ),
          Opacity(
            opacity: isCurrentMonth ? 0.4 : 1.0,
            child: IconButton(
              icon: Icon(Icons.chevron_right,
                  color: context.textPrimary, size: 24),
              onPressed: isCurrentMonth ? null : onNext,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
          ),
        ],
      ),
    );
  }
}
