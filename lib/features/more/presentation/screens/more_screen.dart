// More screen with settings and navigation to sub-screens — more feature.
// Accounts entry added here after IA refactor (EPIC8A-01).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../core/router/routes.dart';

/// Entry point for app settings and management screens.
/// Accounts, Categories, and other config options live under sub-screens.
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
          // Accounts — relocated from top-level tab (EPIC8A-01)
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l10n.accounts, style: AppTypography.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.accounts),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: Text(l10n.bookmarks, style: AppTypography.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.bookmarks),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settings, style: AppTypography.body),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }
}
