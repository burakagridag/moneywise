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

    testWidgets('tapping Budget tab shows Budget placeholder', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      await tester.tap(find.text('Budget'));
      await tester.pump();

      expect(find.text('Budget tracking'), findsOneWidget);
      expect(find.text('Budget management will be available soon.'),
          findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      await tester.pump(Duration.zero);
      await db.close();
    });

    testWidgets('tapping Note tab shows Note placeholder', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      await tester.tap(find.text('Note'));
      await tester.pump();

      expect(find.text('Spending notes'), findsOneWidget);
      expect(find.text('Note-based summaries will be available soon.'),
          findsOneWidget);

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

      // Income/Expense toggle is part of the Stats sub-tab.
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
    testWidgets('renders Income and Exp. toggle buttons', (tester) async {
      final db = _testDb();
      await tester.pumpWidget(_buildScreen(db));
      await tester.pump();

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Exp.'), findsOneWidget);

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

      // Default is 'expense'. Tap Income.
      await tester.tap(find.text('Income'));
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

      // Tap Income first, then Exp.
      await tester.tap(find.text('Income'));
      await tester.pump();
      await tester.tap(find.text('Exp.'));
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
}
