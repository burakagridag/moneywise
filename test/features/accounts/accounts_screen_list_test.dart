// Widget tests covering the grouped-list and empty-state data paths of
// AccountsScreen — accounts feature.
//
// Both allAccountsProvider and accountGroupsProvider are overridden with
// synchronous StreamProviders so there is no FakeAsync deadlock.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/domain/entities/account.dart' as domain;
import 'package:moneywise/domain/entities/account_group.dart';
import 'package:moneywise/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:moneywise/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Helpers — synchronous stream overrides
// ---------------------------------------------------------------------------

AccountGroup _group(String name, {int sortOrder = 0}) {
  final now = DateTime.now();
  return AccountGroup(
    id: _uuid.v4(),
    name: name,
    type: 'cash',
    sortOrder: sortOrder,
    includeInTotals: true,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

domain.Account _account({
  required String groupId,
  String name = 'Test Account',
  String currency = 'EUR',
  double balance = 100.0,
}) {
  final now = DateTime.now();
  return domain.Account(
    id: _uuid.v4(),
    groupId: groupId,
    name: name,
    currencyCode: currency,
    initialBalance: balance,
    sortOrder: 0,
    isHidden: false,
    includeInTotals: true,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

/// Wraps [AccountsScreen] with overridden stream providers so no real DB
/// is needed and FakeAsync never gets stuck waiting for I/O callbacks.
Widget _buildScreen({
  List<AccountGroup> groups = const [],
  List<domain.Account> accounts = const [],
}) {
  return ProviderScope(
    overrides: [
      accountGroupsProvider.overrideWith(
        (ref) => Stream.value(groups),
      ),
      allAccountsProvider.overrideWith(
        (ref) => Stream.value(accounts),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light,
      home: const AccountsScreen(),
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  group('AccountsScreen — empty state', () {
    testWidgets('shows empty-state message when no accounts exist',
        (tester) async {
      final groups = [_group('Cash'), _group('Bank')];
      await tester.pumpWidget(_buildScreen(groups: groups, accounts: const []));
      // One pump lets the Stream.value emit and providers settle.
      await tester.pump();

      expect(find.text('No accounts yet.\nTap + to add your first account.'),
          findsOneWidget);
    });

    testWidgets('shows FAB on empty state', (tester) async {
      await tester.pumpWidget(_buildScreen(groups: [_group('Cash')]));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Grouped list — _AccountGroupedList, _AccountGroupSection, _AccountRow
  // ---------------------------------------------------------------------------

  group('AccountsScreen — grouped list with accounts', () {
    testWidgets('shows account name in list tile', (tester) async {
      final group = _group('My Wallets');
      final acc = _account(groupId: group.id, name: 'Piggy Bank');

      await tester.pumpWidget(_buildScreen(groups: [group], accounts: [acc]));
      await tester.pump();

      expect(find.text('Piggy Bank'), findsOneWidget);
    });

    testWidgets('shows account currency as subtitle', (tester) async {
      final group = _group('Bank Accounts');
      final acc =
          _account(groupId: group.id, name: 'Checking', currency: 'USD');

      await tester.pumpWidget(_buildScreen(groups: [group], accounts: [acc]));
      await tester.pump();

      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('shows balance formatted to 2 decimal places as trailing',
        (tester) async {
      final group = _group('Savings');
      final acc =
          _account(groupId: group.id, name: 'Emergency Fund', balance: 1234.5);

      await tester.pumpWidget(_buildScreen(groups: [group], accounts: [acc]));
      await tester.pump();

      expect(find.text('1234.50'), findsOneWidget);
    });

    testWidgets('shows group section header in uppercase', (tester) async {
      final group = _group('cash savings');
      final acc = _account(groupId: group.id, name: 'Jar');

      await tester.pumpWidget(_buildScreen(groups: [group], accounts: [acc]));
      await tester.pump();

      expect(find.text('CASH SAVINGS'), findsOneWidget);
    });

    testWidgets('shows multiple accounts in the same group', (tester) async {
      final group = _group('Wallets');
      final acc1 = _account(groupId: group.id, name: 'Wallet A');
      final acc2 = _account(groupId: group.id, name: 'Wallet B');

      await tester
          .pumpWidget(_buildScreen(groups: [group], accounts: [acc1, acc2]));
      await tester.pump();

      expect(find.text('Wallet A'), findsOneWidget);
      expect(find.text('Wallet B'), findsOneWidget);
    });

    testWidgets('shows accounts from two different groups', (tester) async {
      final g1 = _group('Cash');
      final g2 = _group('Bank');
      final acc1 = _account(groupId: g1.id, name: 'Cash Wallet');
      final acc2 = _account(groupId: g2.id, name: 'Bank Account');

      await tester
          .pumpWidget(_buildScreen(groups: [g1, g2], accounts: [acc1, acc2]));
      await tester.pump();

      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('BANK'), findsOneWidget);
      expect(find.text('Cash Wallet'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);
    });

    testWidgets('groups without accounts are not rendered', (tester) async {
      final groupWithAccount = _group('Active');
      final groupEmpty = _group('Empty Group');
      final acc = _account(groupId: groupWithAccount.id, name: 'Only Account');

      await tester.pumpWidget(_buildScreen(
        groups: [groupWithAccount, groupEmpty],
        accounts: [acc],
      ));
      await tester.pump();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('EMPTY GROUP'), findsNothing);
    });

    testWidgets(
        'account leading circle shows first letter of name when no icon',
        (tester) async {
      final group = _group('Cash');
      // Account with no iconKey — CircleAvatar shows first char of name.
      final acc = _account(groupId: group.id, name: 'Xylophone Fund');

      await tester.pumpWidget(_buildScreen(groups: [group], accounts: [acc]));
      await tester.pump();

      // The CircleAvatar text shows account.name.characters.first.toUpperCase()
      expect(find.text('X'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  group('AccountsScreen — loading state', () {
    testWidgets('shows loading text while groupsProvider is pending',
        (tester) async {
      // Use a never-completing stream to simulate loading.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountGroupsProvider.overrideWith(
              (ref) => const Stream<List<AccountGroup>>.empty(),
            ),
            allAccountsProvider.overrideWith(
              (ref) => const Stream<List<domain.Account>>.empty(),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const AccountsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading...'), findsWidgets);
    });
  });
}
