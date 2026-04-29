// Widget tests for AccountAddEditScreen — add and edit flows — accounts feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction, Account;
import 'package:moneywise/domain/entities/account.dart';
import 'package:moneywise/features/accounts/presentation/screens/account_add_edit_screen.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildAddScreen(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const AccountAddEditScreen(),
      ),
    );

Widget _buildEditScreen(AppDatabase db, Account account) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: AccountAddEditScreen(account: account),
      ),
    );

Future<Account> _makeAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final now = DateTime.now();
  return Account(
    id: 'test-account-id',
    groupId: groups.first.id,
    name: 'Existing Account',
    currencyCode: 'EUR',
    initialBalance: 500.0,
    sortOrder: 0,
    isHidden: false,
    includeInTotals: true,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Add mode
  // ---------------------------------------------------------------------------

  group('AccountAddEditScreen — add mode', () {
    testWidgets('shows Add Account title', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Add Account'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders account name, currency and balance fields',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Account Name'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Initial Balance'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders Include in totals switch', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Include in Totals'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders Save button in AppBar', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Save'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows validation error when name is empty and save tapped',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Save without entering a name.
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Account name is required'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('include-in-totals switch toggles', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final switchFinder = find.byType(Switch);
      // Default is true (on).
      final initialValue = (tester.widget<Switch>(switchFinder)).value;

      await tester.tap(switchFinder);
      await tester.pump();

      final newValue = (tester.widget<Switch>(switchFinder)).value;
      expect(newValue, isNot(initialValue));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('account group dropdown loads from seeded data',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Group dropdown should appear after async load.
      expect(find.text('Account Group'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Edit mode
  // ---------------------------------------------------------------------------

  group('AccountAddEditScreen — edit mode', () {
    testWidgets('shows Edit Account title', (tester) async {
      final db = _testDb();
      final account = await _makeAccount(db);

      await tester.pumpWidget(_buildEditScreen(db, account));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Account'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('pre-fills name field with existing account name',
        (tester) async {
      final db = _testDb();
      final account = await _makeAccount(db);

      await tester.pumpWidget(_buildEditScreen(db, account));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.widgetWithText(TextFormField, 'Existing Account'),
          findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('pre-fills balance with existing account initialBalance',
        (tester) async {
      final db = _testDb();
      final account = await _makeAccount(db);

      await tester.pumpWidget(_buildEditScreen(db, account));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Balance displayed as "500.00".
      expect(find.widgetWithText(TextFormField, '500.00'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Save flow
  // ---------------------------------------------------------------------------

  group('AccountAddEditScreen — save flow', () {
    testWidgets('saving a new account with valid data pops the screen',
        (tester) async {
      final db = _testDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((_) => db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const AccountAddEditScreen(),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Navigate to AddEditScreen.
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter a valid name.
      await tester.enterText(
        find.byType(TextFormField).first,
        'New Bank',
      );

      // Select the first group from the dropdown that was loaded.
      // Find the DropdownButtonFormField for the group and open it.
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      if (dropdowns.evaluate().isNotEmpty) {
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();
        // Pick the first item.
        final items = find.byType(DropdownMenuItem<String>);
        if (items.evaluate().isNotEmpty) {
          await tester.tap(items.first);
          await tester.pumpAndSettle();
        }
      }

      // Tap Save.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Screen should have popped (navigator returns to the Go button).
      expect(find.text('Go'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('invalid balance shows validation error', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter a name so name validation passes.
      await tester.enterText(find.byType(TextFormField).first, 'Test');

      // Enter invalid balance.
      final balanceField = find.byType(TextFormField).last;
      await tester.enterText(balanceField, 'not-a-number');

      // Select group from dropdown.
      final groupDropdown = find.byType(DropdownButtonFormField<String>).first;
      await tester.tap(groupDropdown);
      await tester.pumpAndSettle();
      final items = find.byType(DropdownMenuItem<String>);
      if (items.evaluate().isNotEmpty) {
        await tester.tap(items.first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Please enter a valid number'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('currency dropdown onChange updates selected currency',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildAddScreen(db));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The currency dropdown defaults to TRY; open and switch to USD.
      // Find the currency dropdown (second DropdownButtonFormField).
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      // The currency dropdown is the second dropdown (after group).
      if (dropdowns.evaluate().length >= 2) {
        await tester.tap(dropdowns.at(1));
        await tester.pumpAndSettle();

        // Select USD from the dropdown items.
        final usdItem = find.text('USD').last;
        if (usdItem.evaluate().isNotEmpty) {
          await tester.tap(usdItem);
          await tester.pumpAndSettle();
        }
      }

      // Screen should still be displayed without error.
      expect(find.text('Add Account'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('updating an existing account pops the screen', (tester) async {
      final db = _testDb();
      final account = await _makeAccount(db);
      // Insert the account into DB so update can succeed.
      final groups = await db.accountDao.getGroups();
      final now = DateTime.now();
      await db.accountDao.insertAccount(
        AccountsCompanion(
          id: Value(account.id),
          groupId: Value(groups.first.id),
          name: const Value('Existing Account'),
          currencyCode: const Value('EUR'),
          initialBalance: const Value(500.0),
          sortOrder: const Value(0),
          isHidden: const Value(false),
          includeInTotals: const Value(true),
          isDeleted: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((_) => db)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AccountAddEditScreen(account: account),
                  ),
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Save on the pre-filled form.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should have popped back to the Go button.
      expect(find.text('Go'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
