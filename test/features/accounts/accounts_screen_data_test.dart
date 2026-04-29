// Widget tests covering AccountAddEditScreen form-field branches — accounts feature.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide AccountGroup;
import 'package:moneywise/domain/entities/account.dart' as domain;
import 'package:moneywise/domain/entities/account_group.dart';
import 'package:moneywise/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:moneywise/features/accounts/presentation/screens/account_add_edit_screen.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Known group ID used in edit-path tests so the DropdownButtonFormField
// assertion (initialValue must appear in items list) is satisfied.
// ---------------------------------------------------------------------------
const _kFakeGroupId = '00000000-0000-0000-0000-000000000001';

AccountGroup _fakeGroup() {
  final now = DateTime.now();
  return AccountGroup(
    id: _kFakeGroupId,
    name: 'Test Group',
    type: 'cash',
    sortOrder: 0,
    includeInTotals: true,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Wraps [screen] backed by a real in-memory DB for normal add-mode tests.
Widget _wrapWithDb(Widget screen, AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: screen,
      ),
    );

/// Wraps [screen] with a synchronous override for accountGroupsProvider so the
/// DropdownButtonFormField sees the expected group immediately and no real DB
/// I/O races with FakeAsync.
Widget _wrapWithSyncGroups(Widget screen,
        {List<AccountGroup> groups = const []}) =>
    ProviderScope(
      overrides: [
        accountGroupsProvider.overrideWith((ref) => Stream.value(groups)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: screen,
      ),
    );

/// Pump enough frames for a single AutoDispose stream provider to settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tearDown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
  await db.close();
}

domain.Account _buildAccount({
  required String groupId,
  String name = 'Test Account',
  String currency = 'EUR',
  double balance = 0.0,
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

void main() {
  // ---------------------------------------------------------------------------
  // AccountAddEditScreen — add mode (real DB, groups stream from seeded data)
  // ---------------------------------------------------------------------------

  group('AccountAddEditScreen — form fields', () {
    testWidgets('renders account group dropdown after groups load',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrapWithDb(const AccountAddEditScreen(), db));
      await _settle(tester);

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('renders currency field with EUR default', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrapWithDb(const AccountAddEditScreen(), db));
      await _settle(tester);

      expect(find.widgetWithText(TextFormField, 'EUR'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('renders include-in-totals switch', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrapWithDb(const AccountAddEditScreen(), db));
      await _settle(tester);

      expect(find.byType(SwitchListTile), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('renders initial balance field with 0.00 default',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrapWithDb(const AccountAddEditScreen(), db));
      await _settle(tester);

      expect(find.widgetWithText(TextFormField, '0.00'), findsOneWidget);

      await _tearDown(tester, db);
    });

    // -------------------------------------------------------------------------
    // Edit mode — uses synchronous group override to avoid DropdownButtonFormField
    // assertion failure caused by a groupId that isn't yet in the streamed list.
    // -------------------------------------------------------------------------

    testWidgets('shows Edit Account title when account is passed',
        (tester) async {
      final existing = _buildAccount(
        groupId: _kFakeGroupId,
        name: 'Existing',
      );
      await tester.pumpWidget(_wrapWithSyncGroups(
        AccountAddEditScreen(account: existing),
        groups: [_fakeGroup()],
      ));
      await _settle(tester);

      expect(find.text('Edit Account'), findsOneWidget);
    });

    testWidgets('pre-populates name field when editing', (tester) async {
      final existing = _buildAccount(
        groupId: _kFakeGroupId,
        name: 'Prepopulated Name',
      );
      await tester.pumpWidget(_wrapWithSyncGroups(
        AccountAddEditScreen(account: existing),
        groups: [_fakeGroup()],
      ));
      await _settle(tester);

      expect(find.widgetWithText(TextFormField, 'Prepopulated Name'),
          findsOneWidget);
    });

    testWidgets('pre-populates currency field when editing', (tester) async {
      final existing = _buildAccount(
        groupId: _kFakeGroupId,
        name: 'USD Account',
        currency: 'USD',
      );
      await tester.pumpWidget(_wrapWithSyncGroups(
        AccountAddEditScreen(account: existing),
        groups: [_fakeGroup()],
      ));
      await _settle(tester);

      expect(find.widgetWithText(TextFormField, 'USD'), findsOneWidget);
    });

    testWidgets('pre-populates balance field when editing', (tester) async {
      final existing = _buildAccount(
        groupId: _kFakeGroupId,
        name: 'Funded',
        balance: 999.99,
      );
      await tester.pumpWidget(_wrapWithSyncGroups(
        AccountAddEditScreen(account: existing),
        groups: [_fakeGroup()],
      ));
      await _settle(tester);

      expect(find.widgetWithText(TextFormField, '999.99'), findsOneWidget);
    });
  });
}
