// Bottom sheet for adding or editing a bookmark (transaction template) — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/account.dart';
import '../../../../domain/entities/bookmark.dart';
import '../../../../domain/entities/category.dart';
import '../providers/bookmark_provider.dart';
import 'account_picker_sheet.dart';
import 'category_picker_sheet.dart';

const _uuid = Uuid();

/// Modal bottom sheet for creating or editing a [Bookmark].
/// Pass [existing] to enter edit mode (pre-populates all fields).
class BookmarkAddEditSheet extends ConsumerStatefulWidget {
  const BookmarkAddEditSheet({super.key, this.existing});

  final Bookmark? existing;

  @override
  ConsumerState<BookmarkAddEditSheet> createState() =>
      _BookmarkAddEditSheetState();
}

class _BookmarkAddEditSheetState extends ConsumerState<BookmarkAddEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String _type;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController = TextEditingController(
      text: b?.amount != null ? b!.amount!.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: b?.note ?? '');
    _type = b?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final b = widget.existing;

    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = amountText.isNotEmpty ? double.tryParse(amountText) : null;

    final bookmark = Bookmark(
      id: b?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      type: _type,
      amount: amount,
      currencyCode: _selectedAccount?.currencyCode ?? b?.currencyCode ?? 'EUR',
      accountId: _selectedAccount?.id ?? b?.accountId,
      toAccountId: _type == 'transfer'
          ? (_selectedToAccount?.id ?? b?.toAccountId)
          : null,
      categoryId: _selectedCategory?.id ?? b?.categoryId,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      sortOrder: b?.sortOrder ?? 0,
      createdAt: b?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(bookmarkWriteNotifierProvider.notifier).save(bookmark);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSavingBookmark)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l10n.editBookmark : l10n.addBookmark,
                style: AppTypography.title3,
              ),
              const SizedBox(height: AppSpacing.md),

              // Type selector
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'expense', label: Text(l10n.expense)),
                  ButtonSegment(value: 'income', label: Text(l10n.income)),
                  ButtonSegment(value: 'transfer', label: Text(l10n.transfer)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _selectedCategory = null;
                }),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.brandPrimary,
                  selectedForegroundColor: AppColors.textOnBrand,
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name field (required)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.bookmarkName,
                  hintText: l10n.bookmarkNameHint,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.bookmarkNameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Amount field (optional)
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                decoration: InputDecoration(
                  labelText:
                      '${l10n.amount} (${l10n.filterNoCategory.toLowerCase()})',
                  hintText: '0.00',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return l10n.invalidBalance;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category picker (hidden for transfer)
              if (_type != 'transfer') ...[
                _PickerRow(
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
                const Divider(color: AppColors.divider, height: 1),
              ],

              // Account picker
              _PickerRow(
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
              const Divider(color: AppColors.divider, height: 1),

              // To account (transfer only)
              if (_type == 'transfer') ...[
                _PickerRow(
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
                const Divider(color: AppColors.divider, height: 1),
              ],

              // Note field (optional)
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.notes,
                    color: AppColors.textSecondary,
                  ),
                  hintText: l10n.note,
                  border: InputBorder.none,
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),

              const SizedBox(height: AppSpacing.lg),

              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnBrand,
                  minimumSize: const Size.fromHeight(AppHeights.button),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker row
// ---------------------------------------------------------------------------

class _PickerRow extends StatelessWidget {
  const _PickerRow({
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
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        value ?? label,
        style: AppTypography.body.copyWith(
          color: value != null ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
