// Settings screen exposing app-level configuration options — more feature.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../core/router/routes.dart';
import '../widgets/settings_tiles.dart';

/// Settings screen. Exposes theme, currency, language pickers and the
/// Categories sub-screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings, style: AppTypography.title2),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          const ThemePickerTile(),
          const Divider(height: 1),
          const CurrencyPickerTile(),
          const Divider(height: 1),
          const LanguagePickerTile(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.categories, style: AppTypography.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.categoryManagement),
          ),
        ],
      ),
    );
  }
}
