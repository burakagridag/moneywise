// Filter bottom sheet for the transactions list — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/category.dart';
import '../providers/search_filter_provider.dart';
import '../providers/transactions_provider.dart';

/// Modal bottom sheet for filtering transactions by type, category, and date
/// range. Applies on "Apply", discards on "Reset".
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late Set<String> _types;
  late String? _categoryId;
  late DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterNotifierProvider);
    _types = Set.from(filter.types);
    _categoryId = filter.categoryId;
    _dateRange = filter.dateRange;
  }

  void _toggleType(String type) {
    setState(() {
      if (_types.contains(type)) {
        _types = {..._types}..remove(type);
      } else {
        _types = {..._types, type};
      }
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.brandPrimary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _apply() {
    ref.read(transactionFilterNotifierProvider.notifier).apply(
          TransactionFilter(
            types: _types,
            categoryId: _categoryId,
            dateRange: _dateRange,
          ),
        );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _types = {};
      _categoryId = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catsAsync = ref.watch(transactionCategoryListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.filterTitle, style: AppTypography.title3),
                    TextButton(
                      onPressed: _reset,
                      child: Text(l10n.filterReset),
                    ),
                  ],
                ),
              ),
              Divider(color: context.dividerColor, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Transaction type chips
                    Text(l10n.filterTypes, style: AppTypography.subhead),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _TypeChip(
                          label: l10n.income,
                          value: 'income',
                          selected: _types.contains('income'),
                          color: AppColors.income,
                          onTap: () => _toggleType('income'),
                        ),
                        _TypeChip(
                          label: l10n.expense,
                          value: 'expense',
                          selected: _types.contains('expense'),
                          color: AppColors.expense,
                          onTap: () => _toggleType('expense'),
                        ),
                        _TypeChip(
                          label: l10n.transfer,
                          value: 'transfer',
                          selected: _types.contains('transfer'),
                          color: AppColors.warning,
                          onTap: () => _toggleType('transfer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Category picker
                    Text(l10n.filterCategory, style: AppTypography.subhead),
                    const SizedBox(height: AppSpacing.sm),
                    catsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (cats) => _CategoryDropdown(
                        categories: cats,
                        selectedId: _categoryId,
                        noSelectionLabel: l10n.filterNoCategory,
                        onChanged: (id) => setState(() => _categoryId = id),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date range
                    Text(l10n.filterDateRange, style: AppTypography.subhead),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _pickDateRange,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.bgTertiary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              color: context.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _dateRange == null
                                  ? l10n.filterDateRange
                                  : '${_formatDate(_dateRange!.start)} – ${_formatDate(_dateRange!.end)}',
                              style: AppTypography.body.copyWith(
                                color: _dateRange == null
                                    ? context.textTertiary
                                    : context.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (_dateRange != null)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: context.textSecondary,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _dateRange = null),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Apply button
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                ),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnBrand,
                    minimumSize: const Size.fromHeight(AppHeights.button),
                  ),
                  child: Text(l10n.filterApply),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(51) : context.bgTertiary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? color : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: selected ? color : context.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.noSelectionLabel,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? selectedId;
  final String noSelectionLabel;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: selectedId,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      hint: Text(noSelectionLabel, style: AppTypography.body),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(noSelectionLabel, style: AppTypography.body),
        ),
        ...categories.map(
          (cat) => DropdownMenuItem<String>(
            value: cat.id,
            child: Text(
              '${cat.iconEmoji ?? ''} ${cat.name}',
              style: AppTypography.body,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
