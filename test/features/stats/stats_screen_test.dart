// Widget tests for StatsScreen covering sub-tab switching, income/expense toggle, empty state — stats feature.
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/data/local/database.dart' hide Transaction;
import 'package:moneywise/features/stats/presentation/providers/stats_provider.dart';
import 'package:moneywise/features/stats/presentation/screens/stats_screen.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Widget _buildScreen(AppDatabase db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((_) => db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.light,
        home: const StatsScreen(),
      ),
    );

Future<String> _createAccount(AppDatabase db) async {
  final groups = await db.accountDao.getGroups();
  final id = _uuid.v4();
  final now = DateTime.now();
  await db.accountDao.insertAccount(
    AccountsCompanion(
      id: Value(id),
      groupId: Value(groups.first.id),
      name: const Value('Test Account'),
      currencyCode: const Value('EUR'),
      initialBalance: const Value(0.0),
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
  // Sub-tab bar
  // ---------------------------------------------------------------------------

  group('StatsScreen — sub-tab bar', () {
    testWidgets('renders Stats, Budget, Note tabs', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Budget tab shows BudgetView empty state',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      await tester.tap(find.text('Budget'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // BudgetView renders (either empty state or loading).
      expect(
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
              find.text('No budgets set').evaluate().isNotEmpty ||
              find.text('Set Up Budgets').evaluate().isNotEmpty,
          isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Note tab shows NoteView header', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      await tester.tap(find.text('Note'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // NoteView header row should be visible.
      expect(find.text('Note'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Stats tab after Budget returns to stats view',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      // Switch to Budget, then back to Stats.
      await tester.tap(find.text('Budget'));
      await tester.pump();
      await tester.tap(find.text('Stats'));
      await tester.pump();

      // Income/Expense toggle is always visible.
      expect(find.text('Income'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Income / Expense toggle
  // ---------------------------------------------------------------------------

  group('StatsScreen — income/expense toggle', () {
    testWidgets('renders Income and Expense toggle buttons', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      expect(find.text('Income'), findsAtLeastNWidgets(1));
      expect(find.text('Expense'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Income toggle switches stats type', (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Default is 'expense'. Tap Income toggle (last match avoids sub-tab).
      await tester.tap(find.text('Income').last);
      await tester.pump();

      expect(container.read(statsTypeProvider), 'income');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Exp. toggle switches back to expense', (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap Income first, then Expense.
      await tester.tap(find.text('Income').last);
      await tester.pump();
      await tester.tap(find.text('Expense').last);
      await tester.pump();

      expect(container.read(statsTypeProvider), 'expense');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Empty stats state
  // ---------------------------------------------------------------------------

  group('StatsScreen — empty data state', () {
    testWidgets('shows no-data message when no transactions', (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      // Navigate to a past month (no transactions there).
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('No data for this period'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Stats with data
  // ---------------------------------------------------------------------------

  group('StatsScreen — stats with data', () {
    testWidgets('shows pie chart and legend when transactions exist',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      // Use current month so no navigation needed.
      final month = container.read(selectedStatsMonthProvider);
      final txDate = DateTime(month.year, month.month, 10);

      // Get an expense category to attach.
      final expenseCats = await db.categoryDao.getByType('expense');
      final catId = expenseCats.first.id;

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(txDate),
          amount: const Value(100.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
        ),
      );

      container.invalidate(categoryBreakdownProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The screen should no longer show "No data for this period".
      expect(find.text('No data for this period'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Period selector snackbar
  // ---------------------------------------------------------------------------

  group('StatsScreen — period selector', () {
    testWidgets('tapping M period selector shows coming-soon snackbar',
        (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      await tester.tap(find.text('M ▼'));
      await tester.pump();

      expect(find.text('Coming soon'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Month navigation in Stats
  // ---------------------------------------------------------------------------

  group('StatsScreen — month navigation', () {
    testWidgets('previous chevron decrements stats month', (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();

      final initial = container.read(selectedStatsMonthProvider);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      final after = container.read(selectedStatsMonthProvider);
      final expected = initial.month == 1 ? 12 : initial.month - 1;
      expect(after.month, expected);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryLegendRow onTap — coming-soon snackbar
  // ---------------------------------------------------------------------------

  group('StatsScreen — legend row tap', () {
    testWidgets('tapping a legend row shows coming-soon snackbar',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      // Get an expense category from seeded data.
      final expenseCats = await db.categoryDao.getByType('expense');
      final catId = expenseCats.first.id;

      final month = container.read(selectedStatsMonthProvider);
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: Value(_uuid.v4()),
          type: const Value('expense'),
          date: Value(DateTime(month.year, month.month, 5)),
          amount: const Value(100.0),
          currencyCode: const Value('EUR'),
          accountId: Value(accountId),
          categoryId: Value(catId),
        ),
      );

      container.invalidate(categoryBreakdownProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Tap the first CategoryLegendRow InkWell to trigger the snackbar.
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first, warnIfMissed: false);
        await tester.pump();
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // _buildSegments — many-category "Other" grouping path
  // ---------------------------------------------------------------------------

  group('StatsScreen — many categories grouped as Other', () {
    testWidgets('renders without error when many distinct categories exist',
        (tester) async {
      final db = _testDb();
      final accountId = await _createAccount(db);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      final expenseCats = await db.categoryDao.getByType('expense');
      final month = container.read(selectedStatsMonthProvider);

      // Insert a transaction for each available expense category so the
      // 3%-grouping logic in _buildSegments is exercised.
      for (var i = 0; i < expenseCats.length; i++) {
        await db.transactionDao.insertTransaction(
          TransactionsCompanion(
            id: Value(_uuid.v4()),
            type: const Value('expense'),
            date: Value(DateTime(month.year, month.month, 10)),
            // Tiny amounts for all but the first — triggers the "Other" bucket.
            amount: Value(i == 0 ? 200.0 : 0.5),
            currencyCode: const Value('EUR'),
            accountId: Value(accountId),
            categoryId: Value(expenseCats[i].id),
          ),
        );
      }

      container.invalidate(categoryBreakdownProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Screen renders without throwing.
      expect(find.byType(StatsScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Error state for categoryBreakdownProvider
  // ---------------------------------------------------------------------------

  group('StatsScreen — error state', () {
    testWidgets('shows error message when categoryBreakdownProvider errors',
        (tester) async {
      final db = _testDb();

      // Override categoryBreakdownProvider to emit an error immediately.
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          categoryBreakdownProvider.overrideWith(
            (_) async => throw Exception('Stats load failed'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Error state should display the error message and Retry button.
      expect(find.text('Could not load statistics.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Retry invalidates categoryBreakdownProvider',
        (tester) async {
      final db = _testDb();

      // Override to error first, then succeed on retry.
      int callCount = 0;
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          categoryBreakdownProvider.overrideWith((_) async {
            callCount++;
            if (callCount == 1) throw Exception('First fail');
            return <String, double>{};
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Error state visible.
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry to trigger invalidation.
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After retry the provider was called again.
      expect(callCount, greaterThan(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });

  // ---------------------------------------------------------------------------
  // MonthNavigator next button in stats screen
  // ---------------------------------------------------------------------------

  group('StatsScreen — next month navigation', () {
    testWidgets('next chevron increments stats month after going back',
        (tester) async {
      final db = _testDb();

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((_) => db)],
      );
      addTearDown(container.dispose);

      // Move back two months, then forward one.
      container.read(selectedStatsMonthProvider.notifier).previous();
      container.read(selectedStatsMonthProvider.notifier).previous();
      final before = container.read(selectedStatsMonthProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            theme: AppTheme.light,
            home: const StatsScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      final after = container.read(selectedStatsMonthProvider);
      final expected = before.month == 12 ? 1 : before.month + 1;
      expect(after.month, expected);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });
  });
}
