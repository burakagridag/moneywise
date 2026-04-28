// Main accounts screen — lists accounts grouped by account group — accounts feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../core/router/routes.dart';
import '../../../../../domain/entities/account.dart';
import '../../../../../domain/entities/account_group.dart';
import '../providers/accounts_provider.dart';

/// Displays all accounts grouped by their account group with a FAB to add new ones.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(accountGroupsProvider);
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accounts, style: AppTypography.title2),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.accountAddEdit),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textOnBrand,
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
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
        data: (groups) => accountsAsync.when(
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
          data: (accounts) {
            if (accounts.isEmpty) {
              return _EmptyAccountsView(message: l10n.emptyAccountsMessage);
            }
            return _AccountGroupedList(groups: groups, accounts: accounts);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyAccountsView extends StatelessWidget {
  const _EmptyAccountsView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grouped list
// ---------------------------------------------------------------------------

class _AccountGroupedList extends StatelessWidget {
  const _AccountGroupedList({
    required this.groups,
    required this.accounts,
  });

  final List<AccountGroup> groups;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    // Build a map of groupId → accounts for efficient lookup.
    final byGroup = <String, List<Account>>{};
    for (final account in accounts) {
      byGroup.putIfAbsent(account.groupId, () => []).add(account);
    }

    // Only show groups that have at least one account.
    final populatedGroups =
        groups.where((g) => byGroup.containsKey(g.id)).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: populatedGroups.length,
      itemBuilder: (context, index) {
        final group = populatedGroups[index];
        final groupAccounts = byGroup[group.id] ?? [];
        return _AccountGroupSection(group: group, accounts: groupAccounts);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Group section header + rows
// ---------------------------------------------------------------------------

class _AccountGroupSection extends StatelessWidget {
  const _AccountGroupSection({
    required this.group,
    required this.accounts,
  });

  final AccountGroup group;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            group.name.toUpperCase(),
            style: AppTypography.caption1.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...accounts.map((a) => _AccountRow(account: a)),
        const Divider(height: 1, indent: AppSpacing.md),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual account row
// ---------------------------------------------------------------------------

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Text(
          account.iconKey ?? account.name.characters.first.toUpperCase(),
          style: AppTypography.headline,
        ),
      ),
      title: Text(
        account.name,
        style: AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      subtitle: Text(
        account.currencyCode,
        style: AppTypography.footnote.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        account.initialBalance.toStringAsFixed(2),
        style: AppTypography.moneySmall.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}
