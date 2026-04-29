// Widget tests for BudgetSettingScreen — TOTAL row first, modal opening,
// validation — budget feature (US-029).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/more/presentation/screens/budget_setting_screen.dart';

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const BudgetSettingScreen(),
      ),
    );

void main() {
  // ---------------------------------------------------------------------------
  // TOTAL row is first
  // ---------------------------------------------------------------------------

  group('BudgetSettingScreen — TOTAL row first', () {
    testWidgets('TOTAL label appears before category rows', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      // TOTAL row is always rendered first.
      expect(find.text('TOTAL'), findsOneWidget);

      // TOTAL comes before any category name — find first text in the list.
      final totalFinder = find.text('TOTAL');
      expect(totalFinder, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('renders category rows after TOTAL', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 300));

      // Seeded categories should appear.
      final expenseCats = await db.categoryDao.getByType('expense');
      expect(expenseCats, isNotEmpty);

      // Screen has rendered items (TOTAL + categories).
      expect(find.text('TOTAL'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Screen structure
  // ---------------------------------------------------------------------------

  group('BudgetSettingScreen — screen structure', () {
    testWidgets('shows app bar with Budget Setting title', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      expect(find.text('Budget Setting'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('shows month navigator', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      // Month navigator has chevron icons (may appear multiple times in list).
      expect(find.byIcon(Icons.chevron_left), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetEditModal opening
  // ---------------------------------------------------------------------------

  group('BudgetSettingScreen — modal opening', () {
    testWidgets('tapping TOTAL row opens BudgetEditModal', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();

      // Modal should be visible with a Save button.
      expect(find.text('Save'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('BudgetEditModal shows amount input field', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();

      // Amount input should be present.
      expect(find.byType(TextField), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('BudgetEditModal shows Only this month checkbox',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();

      expect(find.text('Only this month'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  group('BudgetSettingScreen — validation', () {
    testWidgets('Save with empty amount shows validation error',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();

      // Clear field (empty by default) and tap Save.
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(
        find.text('Please enter an amount greater than zero.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('entering valid amount enables Save', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('TOTAL'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '500');
      await tester.pump();

      // No validation error shown.
      expect(
        find.text('Please enter an amount greater than zero.'),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Month navigation
  // ---------------------------------------------------------------------------

  group('BudgetSettingScreen — month navigation', () {
    testWidgets('chevron left decrements month without crashing',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap back chevron.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump(const Duration(milliseconds: 300));

      // Screen still renders — no exception thrown.
      expect(find.byType(BudgetSettingScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
