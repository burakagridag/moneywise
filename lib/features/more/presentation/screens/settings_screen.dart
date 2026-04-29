// Settings screen exposing app-level configuration options — more feature.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../core/router/routes.dart';

/// Settings screen. Currently exposes the Categories sub-screen;
/// additional settings (theme, currency, security) will be added in
/// later sprints.
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
