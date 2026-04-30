// Add / Edit transaction screen with type toggle, pickers, and validation — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/bookmark.dart';
import '../../../../domain/entities/category.dart';
import '../providers/transactions_provider.dart';
import '../widgets/account_picker_sheet.dart';
import '../widgets/category_picker_sheet.dart';

const _uuid = Uuid();

/// Fullscreen form for adding a new transaction or editing an existing one.
/// Pass [transaction] = null for add mode; non-null for edit mode.
/// Pass [prefillBookmark] to pre-populate the form from a saved bookmark template.
class TransactionAddEditScreen extends ConsumerStatefulWidget {
  const TransactionAddEditScreen({
    super.key,
    this.transaction,
    this.prefillBookmark,
  });

  final Transaction? transaction;

  /// When set, the form is pre-populated with this bookmark's fields (add mode).
  final Bookmark? prefillBookmark;

  @override
  ConsumerState<TransactionAddEditScreen> createState() =>
      _TransactionAddEditScreenState();
}

class _TransactionAddEditScreenState
    extends ConsumerState<TransactionAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _pickersInitialized = false;

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    final bm = widget.prefillBookmark;
    if (tx != null) {
      _type = tx.type;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _noteController.text = tx.description ?? '';
      _selectedDate = tx.date;
    } else if (bm != null) {
      // Pre-fill from bookmark template (add mode).
      _type = bm.type;
      if (bm.amount != null) {
        _amountController.text = bm.amount!.toStringAsFixed(2);
      }
      _noteController.text = bm.note ?? '';
      _selectedDate = DateTime.now();
      // accountId / categoryId / toAccountId resolved in _tryInitPickers.
    } else {
      _type = 'expense';
      _selectedDate = DateTime.now();
    }
    _amountController.addListener(_markDirty);
    _noteController.addListener(_markDirty);
  }

  /// Pre-populates [_selectedCategory] and [_selectedAccount] from the lists
  /// provided by the repository-backed providers. Called after the first frame
  /// so that [ref] is available and providers have had a chance to emit.
  /// Handles both edit mode (from [widget.transaction]) and bookmark pre-fill
  /// mode (from [widget.prefillBookmark]).
  void _tryInitPickers() {
    if (_pickersInitialized) return;

    final tx = widget.transaction;
    final bm = widget.prefillBookmark;

    // Only attempt picker init for edit mode or bookmark pre-fill.
    if (tx == null && bm == null) {
      _pickersInitialized = true;
      return;
    }

    final accounts =
        ref.read(transactionAccountListProvider).asData?.value ?? [];
    final categories =
        ref.read(transactionCategoryListProvider).asData?.value ?? [];

    if (accounts.isEmpty) return; // retry next rebuild

    _pickersInitialized = true;

    if (tx != null) {
      _selectedAccount =
          accounts.where((a) => a.id == tx.accountId).firstOrNull;
      _selectedToAccount = tx.toAccountId != null
          ? accounts.where((a) => a.id == tx.toAccountId).firstOrNull
          : null;
      _selectedCategory = tx.categoryId != null
          ? categories.where((c) => c.id == tx.categoryId).firstOrNull
          : null;
    } else if (bm != null) {
      _selectedAccount = bm.accountId != null
          ? accounts.where((a) => a.id == bm.accountId).firstOrNull
          : null;
      _selectedToAccount = bm.toAccountId != null
          ? accounts.where((a) => a.id == bm.toAccountId).firstOrNull
          : null;
      _selectedCategory = bm.categoryId != null
          ? categories.where((c) => c.id == bm.categoryId).firstOrNull
          : null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      _selectedCategory = null; // reset — type changed
      _isDirty = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      setState(() {
        _selectedDate = picked;
        _isDirty = true;
      });
    }
  }

  Future<void> _save({bool continueAdding = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedAccount == null) {
      _showError(AppLocalizations.of(context)!.account);
      return;
    }
    if (_type == 'transfer' && _selectedToAccount == null) {
      _showError(AppLocalizations.of(context)!.toAccount);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final transaction = Transaction(
        id: _isEditMode ? widget.transaction!.id : _uuid.v4(),
        type: _type,
        date: _selectedDate,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        currencyCode: _selectedAccount!.currencyCode,
        accountId: _selectedAccount!.id,
        toAccountId: _type == 'transfer' ? _selectedToAccount?.id : null,
        categoryId: _selectedCategory?.id,
        description: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: _isEditMode ? widget.transaction!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditMode) {
        await ref
            .read(transactionWriteNotifierProvider.notifier)
            .updateTransaction(transaction);
      } else {
        await ref
            .read(transactionWriteNotifierProvider.notifier)
            .addTransaction(transaction);
      }

      if (!mounted) return;

      if (continueAdding) {
        _resetForContinue();
      } else {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorSavingTransaction),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForContinue() {
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDate = DateTime.now();
      _isDirty = false;
    });
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.bgSecondary,
        title: Text(
          l10n.deleteTransaction,
          style: AppTypography.headline.copyWith(color: ctx.textPrimary),
        ),
        content: Text(
          l10n.deleteTransactionConfirm,
          style: AppTypography.body.copyWith(color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(transactionWriteNotifierProvider.notifier)
          .deleteTransaction(widget.transaction!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorDeletingTransaction),
        ),
      );
    }
  }

  void _showError(String fieldName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$fieldName is required')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // In edit mode or bookmark pre-fill mode, watch the account/category lists
    // so this widget rebuilds when they emit data. _tryInitPickers() then reads
    // them synchronously to set the picker state before the rest of the widget
    // tree is built.
    if ((_isEditMode || widget.prefillBookmark != null) &&
        !_pickersInitialized) {
      ref.watch(transactionAccountListProvider);
      ref.watch(transactionCategoryListProvider);
    }
    // Attempt to pre-populate category/account pickers on each rebuild until
    // the providers emit data (edit mode only).
    _tryInitPickers();

    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('d MMM yyyy');

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.bgSecondary,
            title: Text(
              'Discard changes?',
              style: AppTypography.headline.copyWith(color: ctx.textPrimary),
            ),
            content: Text(
              'Your changes will be lost.',
              style: AppTypography.body.copyWith(color: ctx.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Discard',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        if (leave == true && mounted) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: context.bgSecondary,
          title: Text(
            _isEditMode ? l10n.editTransaction : l10n.addTransaction,
            style: AppTypography.headline.copyWith(color: context.textPrimary),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            if (_isEditMode)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Type selector
              _TypeSegmentedButton(
                selected: _type,
                onChanged: _setType,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: AppTypography.title2.copyWith(
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: AppTypography.title2.copyWith(
                    color: context.textTertiary,
                  ),
                  border: InputBorder.none,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.amount;
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return l10n.invalidBalance;
                  return null;
                },
              ),
              Divider(color: context.dividerColor),
              const SizedBox(height: AppSpacing.sm),

              // Category (hidden for transfer)
              if (_type != 'transfer') ...[
                _PickerTile(
                  icon: Icons.category_outlined,
                  label: l10n.category,
                  value: _selectedCategory != null
                      ? '${_selectedCategory!.iconEmoji ?? ''} ${_selectedCategory!.name}'
                      : null,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CategoryPickerSheet(
                      type: _type,
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ),
                Divider(color: context.dividerColor),
              ],

              // Account
              _PickerTile(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.account,
                value: _selectedAccount?.name,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AccountPickerSheet(
                    disabledAccountId: _selectedToAccount?.id,
                    onSelected: (acc) => setState(() => _selectedAccount = acc),
                  ),
                ),
              ),
              Divider(color: context.dividerColor),

              // To Account (transfer only)
              if (_type == 'transfer') ...[
                _PickerTile(
                  icon: Icons.swap_horiz,
                  label: l10n.toAccount,
                  value: _selectedToAccount?.name,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AccountPickerSheet(
                      disabledAccountId: _selectedAccount?.id,
                      onSelected: (acc) =>
                          setState(() => _selectedToAccount = acc),
                    ),
                  ),
                ),
                Divider(color: context.dividerColor),
              ],

              // Date
              _PickerTile(
                icon: Icons.calendar_today_outlined,
                label: l10n.date,
                value: dateFmt.format(_selectedDate),
                onTap: _pickDate,
              ),
              Divider(color: context.dividerColor),

              // Note
              TextFormField(
                controller: _noteController,
                style: AppTypography.body.copyWith(
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.notes,
                    color: context.textSecondary,
                  ),
                  hintText: l10n.note,
                  hintStyle: AppTypography.body.copyWith(
                    color: context.textTertiary,
                  ),
                  border: InputBorder.none,
                ),
              ),
              Divider(color: context.dividerColor),

              const SizedBox(height: AppSpacing.xxl),

              // Save button
              FilledButton(
                onPressed: _isSaving ? null : () => _save(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  minimumSize: const Size.fromHeight(AppHeights.button),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(l10n.save),
              ),

              // Save & Continue (add mode only)
              if (!_isEditMode) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => _save(continueAdding: true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    minimumSize: const Size.fromHeight(AppHeights.button),
                  ),
                  child: Text(l10n.saveAndContinue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _TypeSegmentedButton extends StatelessWidget {
  const _TypeSegmentedButton({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'expense', label: Text(l10n.expense)),
        ButtonSegment(value: 'income', label: Text(l10n.income)),
        ButtonSegment(value: 'transfer', label: Text(l10n.transfer)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.brandPrimary,
        selectedForegroundColor: AppColors.textOnBrand,
        foregroundColor: context.textSecondary,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: context.textSecondary),
      title: Text(
        value ?? label,
        style: AppTypography.body.copyWith(
          color: value != null ? context.textPrimary : context.textTertiary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: context.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
