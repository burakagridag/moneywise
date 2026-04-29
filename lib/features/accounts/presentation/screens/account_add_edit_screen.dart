// Screen for adding or editing an account — accounts feature.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/i18n/arb/app_localizations.dart';
import '../../../../../domain/entities/account.dart';
import '../providers/accounts_provider.dart';

const _uuid = Uuid();

/// ISO 4217 currency codes shown in the currency dropdown.
const _commonCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'TRY',
  'JPY',
  'CNY',
  'CHF',
  'CAD',
  'AUD',
  'INR',
  'BRL',
  'MXN',
  'KRW',
  'SGD',
  'HKD',
  'NOK',
  'SEK',
  'DKK',
  'PLN',
  'AED',
];

/// Form screen that allows creating or editing a single [Account].
/// When [account] is null a new account is created; otherwise the existing
/// one is updated.
class AccountAddEditScreen extends ConsumerStatefulWidget {
  const AccountAddEditScreen({super.key, this.account});

  /// Existing account to edit, or null when adding a new one.
  final Account? account;

  @override
  ConsumerState<AccountAddEditScreen> createState() =>
      _AccountAddEditScreenState();
}

class _AccountAddEditScreenState extends ConsumerState<AccountAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late bool _includeInTotals;
  String? _selectedGroupId;
  late String _selectedCurrency;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameController = TextEditingController(text: a?.name ?? '');
    _balanceController = TextEditingController(
      text: a != null ? a.initialBalance.toStringAsFixed(2) : '0.00',
    );
    // Default to TRY (primary user locale). Fall back to TRY if saved value
    // is not in the dropdown list.
    final savedCurrency = a?.currencyCode ?? 'TRY';
    _selectedCurrency =
        _commonCurrencies.contains(savedCurrency) ? savedCurrency : 'TRY';
    _includeInTotals = a?.includeInTotals ?? true;
    _selectedGroupId = a?.groupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountGroup)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final account = Account(
      id: widget.account?.id ?? _uuid.v4(),
      groupId: _selectedGroupId!,
      name: _nameController.text.trim(),
      currencyCode: _selectedCurrency,
      initialBalance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
      sortOrder: widget.account?.sortOrder ?? 0,
      isHidden: widget.account?.isHidden ?? false,
      includeInTotals: _includeInTotals,
      createdAt: widget.account?.createdAt ?? now,
      updatedAt: now,
      isDeleted: false,
    );

    try {
      final notifier = ref.read(accountWriteNotifierProvider.notifier);
      if (widget.account == null) {
        await notifier.addAccount(account);
      } else {
        await notifier.updateAccount(account);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSavingAccount)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(accountGroupsProvider);
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editAccount : l10n.addAccount,
          style: AppTypography.title2,
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              l10n.save,
              style: AppTypography.headline.copyWith(
                color: _isSaving
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Account name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.accountName),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.accountNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Account group picker
            groupsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text(e.toString()),
              data: (groups) => DropdownButtonFormField<String>(
                initialValue: _selectedGroupId,
                decoration: InputDecoration(labelText: l10n.accountGroup),
                items: groups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(g.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedGroupId = v),
                validator: (v) => v == null ? l10n.accountGroup : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Currency dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              decoration: InputDecoration(labelText: l10n.currency),
              items: _commonCurrencies
                  .map(
                    (code) => DropdownMenuItem(
                      value: code,
                      child: Text(code),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCurrency = v);
              },
              validator: (v) => v == null ? l10n.currency : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // Initial balance
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(labelText: l10n.initialBalance),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) {
                  return l10n.invalidBalance;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Include in totals
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.includeInTotals, style: AppTypography.body),
              subtitle: Text(
                l10n.includeInTotalDescription,
                style: AppTypography.footnote.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              value: _includeInTotals,
              activeThumbColor: AppColors.brandPrimary,
              onChanged: (v) => setState(() => _includeInTotals = v),
            ),
          ],
        ),
      ),
    );
  }
}
