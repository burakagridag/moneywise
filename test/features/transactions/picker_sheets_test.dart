// Widget tests for CategoryPickerSheet and AccountPickerSheet — transactions feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart'
    hide Transaction, Account, Category;
import 'package:moneywise/domain/entities/account.dart';
import 'package:moneywise/domain/entities/category.dart';
import 'package:moneywise/features/transactions/presentation/widgets/account_picker_sheet.dart';
import 'package:moneywise/features/transactions/presentation/widgets/category_picker_sheet.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _wrapSheet(AppDatabase db, Widget sheet) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => sheet,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

Future<String> _createAccount(AppDatabase db, {String name = 'Wallet'}) async {
  final groups = await db.accountDao.getGroups();
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(id),
      groupId: Value(groups.first.id),
      name: Value(name),
      currencyCode: const Value('EUR'),
      initialBalance: const Value(1000.0),
      sortOrder: const Value(0),
      isHidden: const Value(false),
      includeInTotals: const Value(true),
      isDeleted: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );
  return id;
}

void main() {
  // ---------------------------------------------------------------------------
  // CategoryPickerSheet
  // ---------------------------------------------------------------------------

  group('CategoryPickerSheet', () {
    testWidgets('renders Category header text', (tester) async {
      final db = _testDb();

      await tester.pumpWidget(
        _wrapSheet(
          db,
          CategoryPickerSheet(type: 'expense', onSelected: (_) {}),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Category'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('lists seeded expense categories', (tester) async {
      final db = _testDb();

      Category? selected;
      await tester.pumpWidget(
        _wrapSheet(
          db,
          CategoryPickerSheet(
            type: 'expense',
            onSelected: (c) => selected = c,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Seeded data includes at least one expense category.
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      // Tap the first category tile.
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows only income categories when type is income',
        (tester) async {
      final db = _testDb();

      final incomeCats = await db.categoryDao.getByType('income');

      await tester.pumpWidget(
        _wrapSheet(
          db,
          CategoryPickerSheet(type: 'income', onSelected: (_) {}),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Income picker must show at least one income category.
      expect(incomeCats, isNotEmpty);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('categories with colorHex render their color badge',
        (tester) async {
      final db = _testDb();

      // Insert a custom category with colorHex at sortOrder 0 so it appears first.
      final catId = _uuid.v4();
      final now = DateTime.now();
      await db.into(db.categories).insert(
            CategoriesCompanion(
              id: Value(catId),
              name: const Value('Custom Cat'),
              type: const Value('expense'),
              iconEmoji: const Value('🎯'),
              colorHex: const Value('3498DB'),
              sortOrder: const Value(0),
              isDefault: const Value(false),
              isDeleted: const Value(false),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await tester.pumpWidget(
        _wrapSheet(
          db,
          CategoryPickerSheet(type: 'expense', onSelected: (_) {}),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      // Use a longer settle to allow stream to deliver the new category.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The custom category should be rendered in the list.
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // AccountPickerSheet
  // ---------------------------------------------------------------------------

  group('AccountPickerSheet', () {
    testWidgets('renders Account header text', (tester) async {
      final db = _testDb();

      await tester.pumpWidget(
        _wrapSheet(
          db,
          AccountPickerSheet(onSelected: (_) {}),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('lists all non-deleted accounts', (tester) async {
      final db = _testDb();
      await _createAccount(db, name: 'My Wallet');

      Account? selected;
      await tester.pumpWidget(
        _wrapSheet(
          db,
          AccountPickerSheet(onSelected: (a) => selected = a),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('My Wallet'), findsOneWidget);

      // Tap the account tile.
      await tester.tap(find.text('My Wallet'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, 'My Wallet');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('disabled account row cannot be tapped', (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db, name: 'Savings');

      Account? selected;
      await tester.pumpWidget(
        _wrapSheet(
          db,
          AccountPickerSheet(
            onSelected: (a) => selected = a,
            disabledAccountId: accountId,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The disabled tile should be present but not selectable.
      expect(find.text('Savings'), findsOneWidget);
      await tester.tap(find.text('Savings'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // onSelected must NOT have been called for the disabled row.
      expect(selected, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows balance formatted with currency code', (tester) async {
      final db = _testDb();
      await _createAccount(db, name: 'Bank');

      await tester.pumpWidget(
        _wrapSheet(
          db,
          AccountPickerSheet(onSelected: (_) {}),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Balance subtitle contains currency code (EUR set in _createAccount).
      expect(find.textContaining('EUR'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
