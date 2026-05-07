// BookmarkAddEditSheet — create or edit a saved transaction template — more/bookmarks feature.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../domain/entities/bookmark.dart';
import '../providers/bookmarks_provider.dart';

/// Bottom sheet for adding a new bookmark or editing an existing one.
/// Pass [bookmark] = null for add mode; non-null for edit mode.
class BookmarkAddEditSheet extends ConsumerStatefulWidget {
  const BookmarkAddEditSheet({super.key, this.bookmark});

  final Bookmark? bookmark;

  @override
  ConsumerState<BookmarkAddEditSheet> createState() =>
      _BookmarkAddEditSheetState();
}

class _BookmarkAddEditSheetState extends ConsumerState<BookmarkAddEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type;
  bool _isSaving = false;

  bool get _isEditMode => widget.bookmark != null;

  @override
  void initState() {
    super.initState();
    final b = widget.bookmark;
    if (b != null) {
      _nameController.text = b.name;
      _type = b.type;
      if (b.amount != null) {
        _amountController.text = b.amount!.toStringAsFixed(2);
      }
      if (b.note != null) {
        _noteController.text = b.note!;
      }
    } else {
      _type = 'expense';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final amountText = _amountController.text.replaceAll(',', '.');
      final amount = amountText.isEmpty ? null : double.tryParse(amountText);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (_isEditMode) {
        final updated = widget.bookmark!.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          amount: amount,
          note: note,
          updatedAt: DateTime.now(),
        );
        await ref.read(bookmarksNotifierProvider.notifier).save(updated);
      } else {
        await ref.read(bookmarksNotifierProvider.notifier).add(
              name: _nameController.text.trim(),
              type: _type,
              amount: amount,
              note: note,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save bookmark.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  _isEditMode ? 'Edit Bookmark' : 'Add Bookmark',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Name
                TextFormField(
                  controller: _nameController,
                  style:
                      AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Type
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                    ButtonSegment(value: 'transfer', label: Text('Transfer')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.brandPrimary,
                    selectedForegroundColor: AppColors.textOnBrand,
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Amount — optional (MINOR-3: uses 'optional' label key)
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style:
                      AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Amount (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Note — optional
                TextFormField(
                  controller: _noteController,
                  style:
                      AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    minimumSize: const Size.fromHeight(AppHeights.button),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
