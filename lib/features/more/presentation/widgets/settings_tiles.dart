// Reusable settings tile widgets for the Settings screen — more feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_colors_ext.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../providers/app_preferences_provider.dart';

// ---------------------------------------------------------------------------
// Theme picker tile
// ---------------------------------------------------------------------------

/// ListTile that opens a SimpleDialog to pick System / Light / Dark theme.
class ThemePickerTile extends ConsumerWidget {
  const ThemePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(appPreferencesNotifierProvider);
    final currentMode =
        prefsAsync.whenData((p) => p.themeMode).value ?? ThemeMode.system;

    String themeModeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return l10n.themeLight;
        case ThemeMode.dark:
          return l10n.themeDark;
        case ThemeMode.system:
          return l10n.themeSystem;
      }
    }

    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: Text(l10n.appearance, style: AppTypography.body),
      trailing: Text(
        themeModeLabel(currentMode),
        style: AppTypography.body.copyWith(color: context.textSecondary),
      ),
      onTap: () async {
        final picked = await showDialog<ThemeMode>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.appearance),
            children: ThemeMode.values.map((mode) {
              return SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(mode),
                child: Row(
                  children: [
                    if (mode == currentMode)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.brandPrimary,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(themeModeLabel(mode), style: AppTypography.body),
                  ],
                ),
              );
            }).toList(),
          ),
        );
        if (picked != null && context.mounted) {
          await ref
              .read(appPreferencesNotifierProvider.notifier)
              .setThemeMode(picked);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Currency picker tile
// ---------------------------------------------------------------------------

const _kSupportedCurrencies = ['EUR', 'USD', 'TRY', 'GBP'];

/// ListTile that opens a bottom sheet to pick the app currency.
class CurrencyPickerTile extends ConsumerWidget {
  const CurrencyPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(appPreferencesNotifierProvider);
    final currentCode =
        prefsAsync.whenData((p) => p.currencyCode).value ?? 'EUR';

    return ListTile(
      leading: const Icon(Icons.attach_money_outlined),
      title: Text(l10n.currency, style: AppTypography.body),
      trailing: Text(
        currentCode,
        style: AppTypography.body.copyWith(color: context.textSecondary),
      ),
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _CurrencyPickerSheet(
            current: currentCode,
          ),
        );
        if (picked != null && context.mounted) {
          await ref
              .read(appPreferencesNotifierProvider.notifier)
              .setCurrencyCode(picked);
        }
      },
    );
  }
}

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: context.isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(l10n.currency, style: AppTypography.title3),
            ),
            Divider(color: context.dividerColor, height: 1),
            ..._kSupportedCurrencies.map(
              (code) => ListTile(
                title: Text(code, style: AppTypography.body),
                trailing: code == current
                    ? const Icon(Icons.check, color: AppColors.brandPrimary)
                    : null,
                onTap: () => Navigator.of(context).pop(code),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language picker tile
// ---------------------------------------------------------------------------

const _kSupportedLanguages = {
  'en': 'English',
  'tr': 'Türkçe',
};

/// ListTile that opens a dialog to pick the app language.
class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefsAsync = ref.watch(appPreferencesNotifierProvider);
    final currentCode =
        prefsAsync.whenData((p) => p.languageCode).value ?? 'en';
    final currentLabel = _kSupportedLanguages[currentCode] ?? currentCode;

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(l10n.language, style: AppTypography.body),
      trailing: Text(
        currentLabel,
        style: AppTypography.body.copyWith(color: context.textSecondary),
      ),
      onTap: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.language),
            children: _kSupportedLanguages.entries.map((entry) {
              return SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(entry.key),
                child: Row(
                  children: [
                    if (entry.key == currentCode)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.brandPrimary,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(entry.value, style: AppTypography.body),
                  ],
                ),
              );
            }).toList(),
          ),
        );
        if (picked != null && context.mounted) {
          await ref
              .read(appPreferencesNotifierProvider.notifier)
              .setLanguageCode(picked);
        }
      },
    );
  }
}
