// BudgetEditModal — bottom sheet for editing a per-category budget — more feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/category.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../budget/presentation/providers/budget_providers.dart';

/// Shows a bottom-sheet that lets the user set or clear a budget amount for
/// [category] (or the total budget when [category] is null).
///
/// [existingBudgetId] is the DB row id of the existing budget, if any.
/// [existingAmount] is the pre-fill value for the amount field.
/// [selectedMonth] determines which month context the budget applies to.
Future<void> showBudgetEditModal({
  required BuildContext context,
  required Category? category,
  required DateTime selectedMonth,
  int? existingBudgetId,
  double? existingAmount,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BudgetEditModal(
      category: category,
      selectedMonth: selectedMonth,
      existingBudgetId: existingBudgetId,
      existingAmount: existingAmount,
    ),
  );
}

/// The bottom-sheet widget for editing budget amounts.
class BudgetEditModal extends ConsumerStatefulWidget {
  const BudgetEditModal({
    super.key,
    required this.category,
    required this.selectedMonth,
    this.existingBudgetId,
    this.existingAmount,
  });

  final Category? category;
  final DateTime selectedMonth;
  final int? existingBudgetId;
  final double? existingAmount;

  @override
  ConsumerState<BudgetEditModal> createState() => _BudgetEditModalState();
}

class _BudgetEditModalState extends ConsumerState<BudgetEditModal> {
  late final TextEditingController _amountController;
  bool _onlyThisMonth = false;
  bool _isSaving = false;
  String? _amountError;

  static const double _maxAmount = 999999999.0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existingAmount != null && widget.existingAmount! > 0
          ? widget.existingAmount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final current = double.tryParse(_amountController.text) ?? -1;
    return current != (widget.existingAmount ?? 0.0);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _amountController.text.trim();
    final value = double.tryParse(text);

    if (value == null || value <= 0) {
      setState(() => _amountError = l10n.budgetSettingAmountGreaterThanZero);
      return;
    }
    if (value > _maxAmount) {
      setState(() => _amountError = l10n.budgetSettingAmountTooLarge);
      return;
    }

    setState(() {
      _amountError = null;
      _isSaving = true;
    });

    try {
      final repo = ref.read(budgetRepositoryProvider);
      final effectiveFrom = DateTime(
        widget.selectedMonth.year,
        widget.selectedMonth.month,
      );
      final effectiveTo = _onlyThisMonth
          ? DateTime(
              widget.selectedMonth.year,
              widget.selectedMonth.month + 1,
              0,
            )
          : null;

      await repo.upsertBudget(
        id: widget.existingBudgetId,
        categoryId: widget.category?.id ?? '__total__',
        amount: value,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.budgetErrorSaving),
        ),
      );
    }
  }

  Future<void> _clearBudget() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          l10n.budgetSettingRemoveConfirmTitle,
          style: AppTypography.headline.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.budgetSettingRemoveConfirmMessage,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.budgetSettingRemoveAction,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      final repo = ref.read(budgetRepositoryProvider);
      if (widget.existingBudgetId != null) {
        await repo.deleteBudget(widget.existingBudgetId!);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.budgetErrorDeleting)),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(l10n.budgetSettingDiscardTitle,
            style:
                AppTypography.headline.copyWith(color: AppColors.textPrimary)),
        content: Text(l10n.budgetSettingDiscardMessage,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.budgetSettingKeepEditing,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.budgetSettingDiscardAction,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final insets = MediaQuery.of(context).viewInsets;
    final monthLabel = DateFormat('MMM yyyy').format(widget.selectedMonth);
    final categoryName = widget.category?.name ?? l10n.budgetSettingTotal;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: EdgeInsets.only(bottom: insets.bottom + AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
            // Header
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    if (widget.category?.iconEmoji != null)
                      Text(
                        widget.category!.iconEmoji!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: AppTypography.headline
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      l10n.budgetOf,
                      style: AppTypography.subhead
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            // Amount input
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: _amountError != null
                          ? Border.all(color: AppColors.error, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '€',
                          style: AppTypography.moneyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            style: AppTypography.moneyMedium
                                .copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: l10n.budgetSettingAmountHint,
                              hintStyle: AppTypography.moneyMedium
                                  .copyWith(color: AppColors.textTertiary),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) {
                              if (_amountError != null) {
                                setState(() => _amountError = null);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_amountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _amountError!,
                        style: AppTypography.caption1
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
            // "Only this month" checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: CheckboxListTile(
                value: _onlyThisMonth,
                onChanged: (v) => setState(() => _onlyThisMonth = v ?? false),
                activeColor: AppColors.brandPrimary,
                title: Row(
                  children: [
                    Text(
                      l10n.budgetSettingOnlyThisMonth,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '($monthLabel)',
                      style: AppTypography.footnote
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    disabledBackgroundColor:
                        AppColors.brandPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l10n.save),
                ),
              ),
            ),
            // Clear budget button (only if editing an existing budget)
            if (widget.existingBudgetId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _clearBudget,
                    child: Text(
                      l10n.budgetSettingClearBudget,
                      style:
                          AppTypography.body.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
