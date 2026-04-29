// Statistics screen showing spending breakdown by category — stats feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/month_navigator.dart';
import '../../../../data/repositories/category_repository.dart';
import '../providers/stats_provider.dart';
import '../widgets/category_legend_row.dart';
import '../widgets/pie_chart_widget.dart';

/// The Stats tab. Shows a donut pie chart + ranked category list for the
/// selected month, toggled between Expense and Income views.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedSubTab = 0; // 0=Stats, 1=Budget, 2=Note

  // Color palette per SPEC-010 (8 colors + "Other" = textTertiary)
  static const _palette = [
    Color(0xFFFF6B5C), // coral — brand primary
    Color(0xFFFF9F40), // orange
    Color(0xFFFFD166), // yellow
    Color(0xFF06D6A0), // green
    Color(0xFF4A90E2), // blue
    Color(0xFF9B59B6), // purple
    Color(0xFFF78FB3), // pink
    Color(0xFF48CAE4), // teal
  ];

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final statsType = ref.watch(statsTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Sub-tab bar + period selector
            _SubTabBar(
              selectedIndex: _selectedSubTab,
              onChanged: (i) => setState(() => _selectedSubTab = i),
            ),
            MonthNavigator(
              selectedMonth: selectedMonth,
              onPrevious: () =>
                  ref.read(selectedStatsMonthProvider.notifier).previous(),
              onNext: () =>
                  ref.read(selectedStatsMonthProvider.notifier).next(),
            ),
            if (_selectedSubTab == 0) ...[
              _IncomeExpenseToggle(
                statsType: statsType,
                onToggle: (t) {
                  if (t == 'income') {
                    ref.read(statsTypeProvider.notifier).setIncome();
                  } else {
                    ref.read(statsTypeProvider.notifier).setExpense();
                  }
                },
              ),
              const Expanded(child: _StatsContent(palette: _palette)),
            ] else
              Expanded(child: _PlaceholderSubTab(tabIndex: _selectedSubTab)),
          ],
        ),
      ),
    );
  }
}

class _SubTabBar extends StatelessWidget {
  const _SubTabBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Stats', 'Budget', 'Note'];
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          ...List.generate(tabs.length, (i) {
            final isActive = i == selectedIndex;
            return InkWell(
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          tabs[i],
                          style: AppTypography.subhead.copyWith(
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(height: 2, color: AppColors.brandPrimary),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          // Period selector
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              ),
              child: Text(
                'M ▼',
                style: AppTypography.subhead
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseToggle extends StatelessWidget {
  const _IncomeExpenseToggle({
    required this.statsType,
    required this.onToggle,
  });

  final String statsType;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Income',
            isActive: statsType == 'income',
            onTap: () => onToggle('income'),
          ),
          _ToggleOption(
            label: 'Exp.',
            isActive: statsType == 'expense',
            onTap: () => onToggle('expense'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isActive) Container(height: 2, color: AppColors.brandPrimary),
          ],
        ),
      ),
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({required this.palette});

  final List<Color> palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final statsType = ref.watch(statsTypeProvider);

    return breakdownAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_outlined,
                size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load statistics.',
              style:
                  AppTypography.title3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please try again.',
              style: AppTypography.subhead
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => ref.invalidate(categoryBreakdownProvider),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (breakdown) {
        final segments = _buildSegments(breakdown, palette);

        final catsAsync =
            ref.watch(categoryRepositoryProvider).watchByType(statsType);

        return StreamBuilder(
          stream: catsAsync,
          builder: (context, catSnap) {
            final cats = catSnap.data ?? [];

            final enrichedSegments = segments.map((s) {
              final cat = cats.where((c) => c.id == s.label).firstOrNull;
              return _EnrichedSegment(
                id: s.label,
                name: cat?.name ??
                    (s.label == 'Uncategorized' ? 'Other' : s.label),
                emoji: cat?.iconEmoji,
                amount: s.amount,
                color: s.color,
                percentage: s.percentage,
              );
            }).toList();

            if (enrichedSegments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No data for this period',
                      style: AppTypography.title3
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Add transactions to see your spending breakdown.',
                      style: AppTypography.subhead
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              children: [
                PieChartWidget(segments: segments),
                const Divider(height: 1, color: AppColors.divider),
                ...enrichedSegments.map(
                  (s) => Column(
                    children: [
                      CategoryLegendRow(
                        categoryName: s.name,
                        amount: s.amount,
                        percentage: s.percentage,
                        badgeColor: s.color,
                        emoji: s.emoji,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<PieSegment> _buildSegments(
    Map<String, double> breakdown,
    List<Color> palette,
  ) {
    if (breakdown.isEmpty) return [];

    final total = breakdown.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return [];

    // Sort by amount descending.
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Apply the 3% grouping rule (only when more than 2 categories).
    List<MapEntry<String, double>> named;
    double otherAmount = 0;

    if (sorted.length <= 2) {
      named = sorted;
    } else {
      named = sorted.where((e) => (e.value / total) >= 0.03).take(8).toList();
      final namedIds = named.map((e) => e.key).toSet();
      otherAmount = sorted
          .where((e) => !namedIds.contains(e.key))
          .fold(0.0, (s, e) => s + e.value);
    }

    final segments = <PieSegment>[];
    for (var i = 0; i < named.length; i++) {
      final pct = (named[i].value / total) * 100;
      segments.add(PieSegment(
        label: named[i].key,
        amount: named[i].value,
        color: palette[i % palette.length],
        percentage: pct,
      ));
    }

    if (otherAmount > 0) {
      segments.add(PieSegment(
        label: 'Uncategorized',
        amount: otherAmount,
        color: AppColors.textTertiary,
        percentage: (otherAmount / total) * 100,
      ));
    }

    return segments;
  }
}

class _EnrichedSegment {
  const _EnrichedSegment({
    required this.id,
    required this.name,
    this.emoji,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  final String id;
  final String name;
  final String? emoji;
  final double amount;
  final Color color;
  final double percentage;
}

class _PlaceholderSubTab extends StatelessWidget {
  const _PlaceholderSubTab({required this.tabIndex});

  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final isbudget = tabIndex == 1;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isbudget ? Icons.bar_chart_outlined : Icons.note_alt_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isbudget ? 'Budget tracking' : 'Spending notes',
            style: AppTypography.title3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isbudget
                ? 'Budget management will be available soon.'
                : 'Note-based summaries will be available soon.',
            style:
                AppTypography.subhead.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
