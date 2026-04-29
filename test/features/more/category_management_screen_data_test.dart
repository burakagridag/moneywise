// Widget tests covering the data-path branches of CategoryManagementScreen — more feature.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/features/more/presentation/screens/category_management_screen.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _wrap(Widget screen, AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: screen,
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tearDown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
  await db.close();
}

void main() {
  // ---------------------------------------------------------------------------
  // CategoryManagementScreen — data-path (categories loaded)
  // ---------------------------------------------------------------------------

  group('CategoryManagementScreen data path', () {
    testWidgets('shows category rows in Income tab after data loads',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      // Income tab is selected by default; seeded income categories should show.
      // "Salary" is a default income category from seed data.
      expect(find.text('Salary'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('shows default badge on default categories', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      // Default badge appears for isDefault categories.
      expect(find.text('Default'), findsWidgets);

      await _tearDown(tester, db);
    });

    testWidgets('income tab shows Allowance from seeded categories',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      // 'Allowance' is the first seeded income category.
      expect(find.text('Allowance'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('switching to Expense tab shows Food expense category',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      // Tap the Expense tab.
      await tester.tap(find.text('Expense'));
      // Pump through tab animation and stream delivery.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 'Food' is the first seeded expense category.
      expect(find.text('Food'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('FAB is present and visible', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('tapping FAB opens add-category bottom sheet', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      await tester.tap(find.byType(FloatingActionButton));
      // Pump through bottom sheet animation without pumpAndSettle (avoids timer
      // hang from Drift streams keeping the event loop alive).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add Category'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('bottom sheet has Category Name field', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
          find.widgetWithText(TextFormField, 'Category Name'), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('bottom sheet has type segmented button', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SegmentedButton<String>), findsOneWidget);

      await _tearDown(tester, db);
    });

    testWidgets('bottom sheet has Save button', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_wrap(const CategoryManagementScreen(), db));
      await _settle(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      await _tearDown(tester, db);
    });
  });
}
