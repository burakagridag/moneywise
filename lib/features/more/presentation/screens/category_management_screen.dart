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

/// Two-tab screen showing Income and Expense categories with add support.
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
          onPressed: () => _showAddCategorySheet(context),
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

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCategorySheet(),
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
// Individual category row
// ---------------------------------------------------------------------------

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
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
      trailing: category.isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.brandPrimaryGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.defaultBadge,
                style: AppTypography.caption2.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Add category bottom sheet
// ---------------------------------------------------------------------------

/// Bottom sheet for creating a new category.
/// Declared as [ConsumerStatefulWidget] so it owns its own [WidgetRef] and
/// never captures a ref across an async gap.
class _AddCategorySheet extends ConsumerStatefulWidget {
  const _AddCategorySheet();

  @override
  ConsumerState<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<_AddCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  String _selectedType = 'expense';
  bool _isSaving = false;

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
    final category = Category(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      iconEmoji: _emojiController.text.trim().isNotEmpty
          ? _emojiController.text.trim()
          : null,
      sortOrder: 999,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    try {
      await ref
          .read(categoryWriteNotifierProvider.notifier)
          .addCategory(category);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSavingCategory)),
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
            Text(l10n.addCategory, style: AppTypography.title3),
            const SizedBox(height: AppSpacing.md),

            // Type selector
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'income', label: Text(l10n.income)),
                ButtonSegment(value: 'expense', label: Text(l10n.expense)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) =>
                  setState(() => _selectedType = v.first),
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
