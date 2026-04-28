// More screen with settings and navigation to sub-screens — more feature.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../core/router/routes.dart';

/// Entry point for app settings and management screens (categories, etc.).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMore, style: AppTypography.title2),
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
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settings, style: AppTypography.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Settings screen — Sprint 3+
            },
          ),
        ],
      ),
    );
  }
}
