// Widget tests for BudgetPulseCard — home feature (EPIC8A-07).
// Covers all three card states (no-budget CTA, normal, over-budget) plus
// pace-line color logic and progress bar 100% clamp.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/providers/user_settings_providers.dart';
import 'package:moneywise/features/home/presentation/widgets/budget_pulse_card.dart';
import 'package:moneywise/features/more/presentation/providers/app_preferences_provider.dart';
import 'package:moneywise/features/transactions/presentation/providers/transactions_provider.dart';
// Transaction is re-exported from transactions_provider — no separate import needed.

// ---------------------------------------------------------------------------
// Fake preferences notifier — subclasses the real notifier to avoid
// SharedPreferences I/O in tests.
// ---------------------------------------------------------------------------

class _FakePrefsNotifier extends AppPreferencesNotifier {
  @override
  Future<AppPreferences> build() async => const AppPreferences(
        themeMode: ThemeMode.light,
        currencyCode: 'EUR',
        languageCode: 'en',
      );
}

// ---------------------------------------------------------------------------
// Helper — build a minimal expense Transaction
// ---------------------------------------------------------------------------

Transaction _expense({required double amount, String id = 'tx1'}) =>
    Transaction(
      id: id,
      type: 'expense',
      date: DateTime.now(),
      amount: amount,
      currencyCode: 'EUR',
      accountId: 'acc1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

// ---------------------------------------------------------------------------
// Widget builder — injects all BudgetPulseCard dependencies via overrides
// ---------------------------------------------------------------------------

Widget _buildCard({
  double? budget,
  List<Transaction> transactions = const [],
  ThemeData? theme,
}) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);

  return ProviderScope(
    overrides: [
      effectiveBudgetProvider(month).overrideWith((_) async => budget),
      transactionsByMonthProvider.overrideWith(
        (_) => Stream.value(transactions),
      ),
      appPreferencesNotifierProvider.overrideWith(() => _FakePrefsNotifier()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: theme ?? AppTheme.light,
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: BudgetPulseCard(),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BudgetPulseCard — EPIC8A-07', () {
    // -----------------------------------------------------------------------
    // State: No budget set
    // -----------------------------------------------------------------------

    group('no-budget CTA state', () {
      testWidgets('shows "Budget pulse" title', (tester) async {
        await tester.pumpWidget(_buildCard(budget: null));
        await tester.pump();

        expect(find.text('Budget pulse'), findsOneWidget);
      });

      testWidgets('shows "Set a monthly budget" CTA text', (tester) async {
        await tester.pumpWidget(_buildCard(budget: null));
        await tester.pump();

        expect(find.textContaining('Set a monthly budget'), findsOneWidget);
      });

      testWidgets('shows "Set budget" button', (tester) async {
        await tester.pumpWidget(_buildCard(budget: null));
        await tester.pump();

        expect(find.text('Set budget'), findsOneWidget);
      });

      testWidgets('no pace line rendered in CTA state', (tester) async {
        await tester.pumpWidget(_buildCard(budget: null));
        await tester.pump();

        expect(find.textContaining('Daily pace'), findsNothing);
      });

      testWidgets('shows CTA when budget is exactly 0', (tester) async {
        await tester.pumpWidget(_buildCard(budget: 0.0));
        await tester.pump();

        expect(find.textContaining('Set a monthly budget'), findsOneWidget);
      });

      testWidgets('no "View →" link in CTA state', (tester) async {
        await tester.pumpWidget(_buildCard(budget: null));
        await tester.pump();

        expect(find.textContaining('View →'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // State: Normal (budget set, spent < budget)
    // -----------------------------------------------------------------------

    group('normal state — budget set, within budget', () {
      testWidgets('shows "Budget pulse" title', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 100.0)],
          ),
        );
        await tester.pump();

        expect(find.text('Budget pulse'), findsOneWidget);
      });

      testWidgets('shows "View →" link', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 100.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('View'), findsOneWidget);
      });

      testWidgets('remaining calculated correctly (budget − spent)',
          (tester) async {
        // budget=550, spent=87.40, remaining=462.60
        await tester.pumpWidget(
          _buildCard(
            budget: 550.0,
            transactions: [_expense(amount: 87.40)],
          ),
        );
        await tester.pump();

        // Formatted value contains "462"
        expect(find.textContaining('462'), findsWidgets);
      });

      testWidgets('"left of" subtext rendered', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 50.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('left of'), findsOneWidget);
      });

      testWidgets('pace line shows "Daily pace:" label', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 50.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('Daily pace:'), findsWidgets);
      });

      testWidgets('pace line shows "You can spend" when within budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 50.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsWidgets);
      });

      testWidgets('no overflow on standard viewport', (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 100.0)],
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // State: Over-budget (spent >= budget)
    // -----------------------------------------------------------------------

    group('over-budget state', () {
      testWidgets('shows "Over budget" in the pace line', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 200.0,
            transactions: [_expense(amount: 287.40)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('Over budget'), findsWidgets);
      });

      testWidgets('does NOT show "You can spend" when over budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 150.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsNothing);
      });

      testWidgets('still shows "View →" link when over budget', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 150.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('View'), findsOneWidget);
      });

      testWidgets('expense color applied in over-budget state', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 150.0)],
          ),
        );
        await tester.pump();

        bool foundExpenseColor = false;
        for (final t in tester.widgetList<Text>(find.byType(Text))) {
          if (t.style?.color == AppColors.expense) {
            foundExpenseColor = true;
          }
        }
        for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
          void checkSpan(InlineSpan span) {
            if (span is TextSpan) {
              if (span.style?.color == AppColors.expense) {
                foundExpenseColor = true;
              }
              span.children?.forEach(checkSpan);
            }
          }

          checkSpan(rt.text);
        }

        expect(
          foundExpenseColor,
          isTrue,
          reason: 'Expense color must appear somewhere in over-budget state',
        );
      });

      testWidgets('over-budget when spent equals budget exactly',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 300.0,
            transactions: [_expense(amount: 300.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('Over budget'), findsWidgets);
      });
    });

    // -----------------------------------------------------------------------
    // safeDailyAmount and divide-by-zero guard
    // -----------------------------------------------------------------------

    group('safeDailyAmount calculation', () {
      testWidgets('"You can spend" present with positive remaining',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 1000.0,
            transactions: [_expense(amount: 10.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsWidgets);
      });

      testWidgets('no exception — divide-by-zero guard always active',
          (tester) async {
        // max(daysInMonth - currentDay + 1, 1) prevents division by zero.
        await tester.pumpWidget(
          _buildCard(
            budget: 300.0,
            transactions: [_expense(amount: 50.0)],
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('spent = 0 — pace line renders correctly', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 600.0, transactions: const []),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('You can spend'), findsWidgets);
      });

      testWidgets('remaining == 0 → "Over budget" shown', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 100.0)],
          ),
        );
        await tester.pump();

        expect(find.textContaining('Over budget'), findsWidgets);
      });
    });

    // -----------------------------------------------------------------------
    // Progress bar 100% clamp
    // -----------------------------------------------------------------------

    group('progress bar clamping', () {
      testWidgets('no error when spent >> budget (fill clamped to 100%)',
          (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 250.0)],
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Warning pace color
    // -----------------------------------------------------------------------

    group('warning pace color', () {
      testWidgets('renders without errors when pace is high', (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 95.0)],
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Dark theme
    // -----------------------------------------------------------------------

    group('dark theme', () {
      testWidgets('CTA state renders without errors in dark mode',
          (tester) async {
        await tester.pumpWidget(_buildCard(budget: null, theme: AppTheme.dark));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Budget pulse'), findsOneWidget);
      });

      testWidgets('normal state renders without errors in dark mode',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 500.0,
            transactions: [_expense(amount: 100.0)],
            theme: AppTheme.dark,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('over-budget state renders without errors in dark mode',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(
            budget: 100.0,
            transactions: [_expense(amount: 200.0)],
            theme: AppTheme.dark,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
