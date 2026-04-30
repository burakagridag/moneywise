// Statistics screen showing spending breakdown by category — stats feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/month_navigator.dart';
import '../../../budget/presentation/widgets/budget_view.dart';
import '../providers/stats_provider.dart';
import '../widgets/category_legend_row.dart';
import '../widgets/note_view.dart';
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

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedStatsMonthProvider);
    final statsType = ref.watch(statsTypeProvider);
    final periodMode = ref.watch(statsPeriodProvider);

    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Sub-tab bar + period selector
            _SubTabBar(
              selectedIndex: _selectedSubTab,
              onChanged: (i) => setState(() => _selectedSubTab = i),
              periodMode: periodMode,
              onPeriodChanged: (mode) =>
                  ref.read(statsPeriodProvider.notifier).select(mode),
            ),
            // Month navigator only shown for month/year modes (not week)
            if (periodMode != StatsPeriodMode.week)
              MonthNavigator(
                selectedMonth: selectedMonth,
                onPrevious: () =>
                    ref.read(selectedStatsMonthProvider.notifier).previous(),
                onNext: () =>
                    ref.read(selectedStatsMonthProvider.notifier).next(),
              ),
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
            if (_selectedSubTab == 0)
              const Expanded(
                child: _StatsContent(palette: AppColors.chartPalette),
              )
            else if (_selectedSubTab == 1)
              const Expanded(child: BudgetView())
            else
              const Expanded(child: NoteView()),
          ],
        ),
      ),
    );
  }
}

class _SubTabBar extends ConsumerWidget {
  const _SubTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.periodMode,
    required this.onPeriodChanged,
  });

  final int selectedIndex;
  final void Function(int) onChanged;
  final StatsPeriodMode periodMode;
  final void Function(StatsPeriodMode) onPeriodChanged;

  String _periodLabel(StatsPeriodMode mode) {
    switch (mode) {
      case StatsPeriodMode.week:
        return 'W';
      case StatsPeriodMode.month:
        return 'M';
      case StatsPeriodMode.year:
        return 'Y';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      l10n.statsSubTabStats,
      l10n.statsSubTabBudget,
      l10n.statsSubTabNote,
    ];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          ...List.generate(tabs.length, (i) {
            final isActive = i == selectedIndex;
            return Expanded(
                child: InkWell(
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                                ? context.textPrimary
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(height: 2, color: AppColors.brandPrimary),
                  ],
                ),
              ),
            ));
          }),
          // Period selector — W / M / Y
          _PeriodSelector(
            current: periodMode,
            onChanged: onPeriodChanged,
            label: _periodLabel(periodMode),
          ),
        ],
      ),
    );
  }
}

/// W / M / Y period picker that shows a bottom sheet with three options.
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.current,
    required this.onChanged,
    required this.label,
  });

  final StatsPeriodMode current;
  final void Function(StatsPeriodMode) onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Semantics(
        label: 'Period selector, currently $label. Double-tap to change.',
        button: true,
        child: Container(
          margin: const EdgeInsets.only(right: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.bgTertiary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '$label ▼',
            style: AppTypography.subhead.copyWith(color: context.textPrimary),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PeriodOption(
              label: 'Week (W)',
              mode: StatsPeriodMode.week,
              current: current,
              onSelect: (m) {
                Navigator.of(context).pop();
                onChanged(m);
              },
            ),
            _PeriodOption(
              label: 'Month (M)',
              mode: StatsPeriodMode.month,
              current: current,
              onSelect: (m) {
                Navigator.of(context).pop();
                onChanged(m);
              },
            ),
            _PeriodOption(
              label: 'Year (Y)',
              mode: StatsPeriodMode.year,
              current: current,
              onSelect: (m) {
                Navigator.of(context).pop();
                onChanged(m);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.mode,
    required this.current,
    required this.onSelect,
  });

  final String label;
  final StatsPeriodMode mode;
  final StatsPeriodMode current;
  final void Function(StatsPeriodMode) onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == current;
    return ListTile(
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: isSelected ? AppColors.brandPrimary : context.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandPrimary)
          : null,
      onTap: () => onSelect(mode),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: l10n.income,
            isActive: statsType == 'income',
            onTap: () => onToggle('income'),
          ),
          _ToggleOption(
            label: l10n.expense,
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
                  color: isActive ? context.textPrimary : context.textSecondary,
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
    final l10n = AppLocalizations.of(context)!;
    final breakdownAsync = ref.watch(categoryBreakdownProvider);

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
              l10n.couldNotLoadStatistics,
              style: AppTypography.title3.copyWith(color: context.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.pleaseRetryStatistics,
              style:
                  AppTypography.subhead.copyWith(color: context.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => ref.invalidate(categoryBreakdownProvider),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (breakdown) {
        final segments = _buildSegments(breakdown, palette);

        final catsAsyncValue = ref.watch(statsCategoryListProvider);
        final cats = catsAsyncValue.asData?.value ?? [];

        final enrichedSegments = segments.map((s) {
          final cat = cats.where((c) => c.id == s.label).firstOrNull;
          return _EnrichedSegment(
            id: s.label,
            name: cat?.name ?? (s.label == 'Uncategorized' ? 'Other' : s.label),
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
                  l10n.noDataForPeriod,
                  style:
                      AppTypography.title3.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.addTransactionsForBreakdown,
                  style: AppTypography.subhead
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ClipRect(
              child: SizedBox(
                height: 280,
                child: PieChartWidget(segments: segments),
              ),
            ),
            Divider(height: 1, color: context.dividerColor),
            Expanded(
              child: ListView.builder(
                itemCount: enrichedSegments.length,
                itemBuilder: (_, i) {
                  final s = enrichedSegments[i];
                  return Column(
                    children: [
                      CategoryLegendRow(
                        categoryName: s.name,
                        amount: s.amount,
                        percentage: s.percentage,
                        badgeColor: s.color,
                        emoji: s.emoji,
                        onTap: () => _navigateToCategory(context, ref, s.id),
                      ),
                      Divider(height: 1, color: context.dividerColor),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sets the category filter and navigates to the Transactions tab (DailyView).
  void _navigateToCategory(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) {
    // Store the selected category so TransactionsScreen can apply the filter.
    ref.read(statsCategoryFilterProvider.notifier).set(
          categoryId == 'Uncategorized' ? null : categoryId,
        );
    context.go(Routes.transactions);
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
