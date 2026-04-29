// Bottom sheet for picking a source or destination account — transactions feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/arb/app_localizations.dart';
import '../../../../domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';

/// Modal bottom sheet that lists all non-deleted accounts.
/// [disabledAccountId] disables the row already chosen as the counterpart
/// account (e.g. source when picking destination for a transfer).
/// Calls [onSelected] with the chosen [Account] and pops itself.
class AccountPickerSheet extends ConsumerWidget {
  const AccountPickerSheet({
    super.key,
    required this.onSelected,
    this.disabledAccountId,
  });

  final void Function(Account) onSelected;
  final String? disabledAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(transactionAccountListProvider);
    final fmt = NumberFormat('#,##0.00', 'de_DE');

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(
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
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l10n.account,
                  style: AppTypography.headline
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: accountsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      l10n.errorSavingAccount,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (accounts) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        return _AccountPickerRow(
                          account: acc,
                          isDisabled: acc.id == disabledAccountId,
                          fmt: fmt,
                          onTap: () {
                            onSelected(acc);
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
}

/// A single row in the account picker that watches [accountBalanceProvider]
/// so the displayed balance is always up-to-date with all recorded transactions.
class _AccountPickerRow extends ConsumerWidget {
  const _AccountPickerRow({
    required this.account,
    required this.isDisabled,
    required this.fmt,
    required this.onTap,
  });

  final Account account;
  final bool isDisabled;
  final NumberFormat fmt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));
    final balance = balanceAsync.valueOrNull ?? account.initialBalance;

    return ListTile(
      enabled: !isDisabled,
      leading: CircleAvatar(
        backgroundColor: AppColors.bgTertiary,
        child: Icon(
          Icons.account_balance_wallet_outlined,
          color: isDisabled ? AppColors.textTertiary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        account.name,
        style: AppTypography.bodyMedium.copyWith(
          color: isDisabled ? AppColors.textTertiary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${account.currencyCode} ${fmt.format(balance)}',
        style: AppTypography.caption1.copyWith(
          color: isDisabled ? AppColors.textTertiary : AppColors.textSecondary,
        ),
      ),
      onTap: isDisabled ? null : onTap,
    );
  }
}
