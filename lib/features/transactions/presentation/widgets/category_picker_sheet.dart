// Bottom sheet for picking a transaction category — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_colors_ext.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/category.dart';
import '../providers/transactions_provider.dart';

/// Modal bottom sheet that lists categories filtered by [type] ('income' or
/// 'expense'). Calls [onSelected] with the chosen [Category] and pops itself.
class CategoryPickerSheet extends ConsumerWidget {
  const CategoryPickerSheet({
    super.key,
    required this.type,
    required this.onSelected,
  });

  final String type;
  final void Function(Category) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catsAsync = ref.watch(transactionCategoryListProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
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
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l10n.category,
                  style: AppTypography.headline
                      .copyWith(color: context.textPrimary),
                ),
              ),
              Expanded(
                child: catsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      l10n.errorSavingCategory,
                      style: AppTypography.body
                          .copyWith(color: context.textSecondary),
                    ),
                  ),
                  data: (cats) {
                    final filtered = cats.where((c) => c.type == type).toList();
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _parseColor(cat.colorHex) ?? context.bgTertiary,
                            child: Text(
                              cat.iconEmoji ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: AppTypography.bodyMedium
                                .copyWith(color: context.textPrimary),
                          ),
                          onTap: () {
                            onSelected(cat);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }
}
