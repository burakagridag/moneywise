// Category management screen with Income/Expense tabs — more feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../domain/entities/category.dart';
import '../providers/categories_provider.dart';

const _uuid = Uuid();

/// Two-tab screen showing Income and Expense categories with add, edit,
/// and delete support.
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.categories, style: AppTypography.title2),
          centerTitle: false,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.income),
              Tab(text: l10n.expense),
            ],
            indicatorColor: AppColors.brandPrimary,
            labelColor: AppColors.brandPrimary,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCategorySheet(context, null),
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: AppColors.textOnBrand,
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _CategoryList(
              streamProvider: incomeCategoriesProvider,
              type: 'income',
            ),
            _CategoryList(
              streamProvider: expenseCategoriesProvider,
              type: 'expense',
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the add/edit bottom sheet. Pass [category] to enter edit mode.
  static void _showCategorySheet(BuildContext context, Category? category) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategorySheet(existingCategory: category),
    );
  }
}

// ---------------------------------------------------------------------------
// Category list tab content
// ---------------------------------------------------------------------------

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    required this.streamProvider,
    required this.type,
  });

  final ProviderListenable<AsyncValue<List<Category>>> streamProvider;
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncCategories = ref.watch(streamProvider);

    return asyncCategories.when(
      loading: () => Center(
        child: Text(
          l10n.loading,
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          error.toString(),
          style: AppTypography.body.copyWith(color: AppColors.error),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Text(
              l10n.emptyCategoriesMessage,
              style: AppTypography.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: categories.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: AppSpacing.md + 48),
          itemBuilder: (context, index) =>
              _CategoryRow(category: categories[index]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual category row — tap to edit, long-press to delete
// ---------------------------------------------------------------------------

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Center(
          child: Text(
            category.iconEmoji ?? '•',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        category.name,
        style: AppTypography.body.copyWith(color: colorScheme.onSurface),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => CategoryManagementScreen._showCategorySheet(
        context,
        category,
      ),
      onLongPress: () => _confirmDelete(context, ref, l10n),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCategory, style: AppTypography.title3),
        content: Text(
          l10n.deleteCategoryConfirm,
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.deleteCategory,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // Guard: context may be gone after the await.
    if (!context.mounted) return;

    try {
      await ref
          .read(categoryWriteNotifierProvider.notifier)
          .deleteCategory(category.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorDeletingCategory)),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Add / Edit category bottom sheet
// ---------------------------------------------------------------------------

/// Bottom sheet for creating or editing a category.
/// Pass [existingCategory] to enter edit mode (pre-populates all fields).
class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.existingCategory});

  final Category? existingCategory;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  late String _selectedType;
  bool _isSaving = false;

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCategory;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _emojiController = TextEditingController(text: existing?.iconEmoji ?? '');
    _selectedType = existing?.type ?? 'expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final existing = widget.existingCategory;

    final category = Category(
      id: existing?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      iconEmoji: _emojiController.text.trim().isNotEmpty
          ? _emojiController.text.trim()
          : null,
      sortOrder: existing?.sortOrder ?? 999,
      isDefault: existing?.isDefault ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isDeleted: false,
    );

    try {
      final notifier = ref.read(categoryWriteNotifierProvider.notifier);
      if (_isEditing) {
        await notifier.updateCategory(category);
      } else {
        await notifier.addCategory(category);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? l10n.errorUpdatingCategory : l10n.errorSavingCategory,
          ),
        ),
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
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? l10n.editCategory : l10n.addCategory,
              style: AppTypography.title3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Type selector — locked when editing to avoid changing category type.
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'income', label: Text(l10n.income)),
                ButtonSegment(value: 'expense', label: Text(l10n.expense)),
              ],
              selected: {_selectedType},
              onSelectionChanged: _isEditing
                  ? null
                  : (v) => setState(() => _selectedType = v.first),
            ),
            const SizedBox(height: AppSpacing.md),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.categoryName),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.categoryNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Emoji field
            TextFormField(
              controller: _emojiController,
              decoration: InputDecoration(labelText: l10n.categoryIcon),
              maxLength: 2,
            ),
            const SizedBox(height: AppSpacing.md),

            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnBrand,
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
