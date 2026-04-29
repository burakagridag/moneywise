// Donut pie chart widget for category breakdown — stats feature.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A data class representing one slice of the pie chart.
class PieSegment {
  const PieSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  final String label;
  final double amount;
  final Color color;
  final double percentage;
}

/// Donut pie chart using fl_chart.
/// Renders an empty ring when [segments] is empty.
class PieChartWidget extends StatelessWidget {
  const PieChartWidget({super.key, required this.segments});

  final List<PieSegment> segments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sections: segments.isEmpty
              ? [
                  PieChartSectionData(
                    value: 1,
                    color: AppColors.bgTertiary,
                    radius: 80,
                    title: '',
                  )
                ]
              : segments
                  .map(
                    (s) => PieChartSectionData(
                      value: s.amount,
                      color: s.color,
                      radius: 80,
                      title: '${s.percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
          centerSpaceRadius: 60,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}
