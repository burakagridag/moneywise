// Widget tests covering the _AddCategorySheet save path — more feature.
// Uses a stub CategoryWriteNotifier override to avoid real DB I/O inside
// FakeAsync, which would otherwise deadlock the test scheduler.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/domain/entities/category.dart';
import 'package:moneywise/features/more/presentation/providers/categories_provider.dart';
import 'package:moneywise/features/more/presentation/screens/category_management_screen.dart';

// ---------------------------------------------------------------------------
// Stub write notifier — records the last saved category; no DB I/O.
// ---------------------------------------------------------------------------

class _StubCategoryWriteNotifier extends CategoryWriteNotifier {
  Category? lastSaved;

  @override
  Future<void> addCategory(Category category) async {
    lastSaved = category;
  }
}

// ---------------------------------------------------------------------------
// Test setup helpers
// ---------------------------------------------------------------------------

Widget _wrap({_StubCategoryWriteNotifier? notifier}) {
  notifier ??= _StubCategoryWriteNotifier();
  return ProviderScope(
    overrides: [
      // Stub write notifier — no real DB I/O.
      categoryWriteNotifierProvider.overrideWith(() => notifier!),
      // Return empty streams so the category-list tabs don't hang waiting for DB.
      incomeCategoriesProvider.overrideWith((ref) => Stream.value(const [])),
      expenseCategoriesProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light,
      home: const CategoryManagementScreen(),
    ),
  );
}

/// Pumps multiple frames to let the seeded providers (backed by an in-memory
/// db override) settle. With the stub override for writes, the category-list
/// providers still read from a fresh container (no DB) and show empty lists.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the add-category bottom sheet by tapping the FAB.
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // ---------------------------------------------------------------------------
  // _AddCategorySheet — form validation (no DB I/O)
  // ---------------------------------------------------------------------------

  group('AddCategorySheet — form validation', () {
    testWidgets('shows validation error when name is empty and Save tapped',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);
      await _openSheet(tester);

      // Tap Save without entering a name — form validation fires.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Category name is required'), findsOneWidget);
    });

    testWidgets('sheet renders Category Name field', (tester) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);
      await _openSheet(tester);

      expect(
          find.widgetWithText(TextFormField, 'Category Name'), findsOneWidget);
    });

    testWidgets('sheet renders Icon (emoji) field', (tester) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);
      await _openSheet(tester);

      expect(
          find.widgetWithText(TextFormField, 'Icon (emoji)'), findsOneWidget);
    });

    testWidgets('sheet renders Income/Expense segmented button',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);
      await _openSheet(tester);

      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('tapping Save with valid name calls notifier.addCategory',
        (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Groceries',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.lastSaved, isNotNull);
      expect(notifier.lastSaved!.name, 'Groceries');
    });

    testWidgets('saved category defaults to expense type', (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Fast Food',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.lastSaved!.type, 'expense');
    });

    testWidgets('switching type to income is reflected in saved category',
        (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      // Switch to income.
      await tester.tap(find.text('Income').last);
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Salary Bonus',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.lastSaved!.type, 'income');
      expect(notifier.lastSaved!.name, 'Salary Bonus');
    });

    testWidgets('emoji is passed to saved category', (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Sports',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Icon (emoji)'),
        '⚽',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.lastSaved!.iconEmoji, '⚽');
    });

    testWidgets('sheet is dismissed after successful save', (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Travel',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      // Allow navigator pop animation to complete.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    });

    testWidgets('category has isDefault = false when created from sheet',
        (tester) async {
      final notifier = _StubCategoryWriteNotifier();
      await tester.pumpWidget(_wrap(notifier: notifier));
      await _settle(tester);
      await _openSheet(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Category Name'),
        'Custom Cat',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.lastSaved!.isDefault, isFalse);
    });
  });
}
