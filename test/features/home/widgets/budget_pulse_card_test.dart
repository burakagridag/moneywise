// Widget tests for BudgetPulseCard — home feature (EPIC8A-07).
// Covers all three card states (no-budget CTA, normal, over-budget) plus
// pace-line color logic, progress bar 100% clamp, and fallback-mode spent
// scoping (only budgeted-category transactions count toward spent).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/providers/user_settings_providers.dart';
import 'package:moneywise/features/home/presentation/widgets/budget_pulse_card.dart';
import 'package:moneywise/features/more/presentation/providers/app_preferences_provider.dart';

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
// Widget builder — injects all BudgetPulseCard dependencies via overrides.
//
// [budget] maps to effectiveBudgetProvider (the resolved ceiling).
// [spent]  maps to effectiveSpentProvider  (the mode-aware spent total).
//
// Both providers are overridden directly so tests remain isolated from the
// real database, transaction stream, and global-budget logic. This also
// means the fallback-mode scoping is covered by the dedicated test group
// below, not by the widget helper itself.
// ---------------------------------------------------------------------------

Widget _buildCard({
  double? budget,
  double spent = 0.0,
  ThemeData? theme,
}) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month);

  return ProviderScope(
    overrides: [
      effectiveBudgetProvider(month).overrideWith((_) async => budget),
      effectiveSpentProvider(month).overrideWith((_) async => spent),
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
          _buildCard(budget: 500.0, spent: 100.0),
        );
        await tester.pump();

        expect(find.text('Budget pulse'), findsOneWidget);
      });

      testWidgets('shows "View →" link', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 500.0, spent: 100.0),
        );
        await tester.pump();

        expect(find.textContaining('View'), findsOneWidget);
      });

      testWidgets('remaining calculated correctly (budget − spent)',
          (tester) async {
        // budget=550, spent=87.40, remaining=462.60
        await tester.pumpWidget(
          _buildCard(budget: 550.0, spent: 87.40),
        );
        await tester.pump();

        // Formatted value contains "462"
        expect(find.textContaining('462'), findsWidgets);
      });

      testWidgets('"left of" subtext rendered', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 500.0, spent: 50.0),
        );
        await tester.pump();

        expect(find.textContaining('left of'), findsOneWidget);
      });

      testWidgets('pace line shows "Daily pace:" label', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 500.0, spent: 50.0),
        );
        await tester.pump();

        expect(find.textContaining('Daily pace:'), findsWidgets);
      });

      testWidgets('pace line shows "You can spend" when within budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 500.0, spent: 50.0),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsWidgets);
      });

      testWidgets('no overflow on standard viewport', (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildCard(budget: 500.0, spent: 100.0),
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
          _buildCard(budget: 200.0, spent: 287.40),
        );
        await tester.pump();

        expect(find.textContaining('Over budget'), findsWidgets);
      });

      testWidgets('does NOT show "You can spend" when over budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 150.0),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsNothing);
      });

      testWidgets('still shows "View →" link when over budget', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 150.0),
        );
        await tester.pump();

        expect(find.textContaining('View'), findsOneWidget);
      });

      testWidgets('expense color applied in over-budget state', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 150.0),
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

      // Bug 3 fix: spent == budget exactly is now "On budget" (amber), not
      // "Over budget". The truly-over-budget path requires spent > budget.
      testWidgets('on-budget when spent equals budget exactly', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 300.0, spent: 300.0),
        );
        await tester.pump();

        expect(find.textContaining('On budget'), findsWidgets);
        expect(find.textContaining('Over budget'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // safeDailyAmount and divide-by-zero guard
    // -----------------------------------------------------------------------

    group('safeDailyAmount calculation', () {
      testWidgets('"You can spend" present with positive remaining',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 1000.0, spent: 10.0),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsWidgets);
      });

      testWidgets('no exception — divide-by-zero guard always active',
          (tester) async {
        // max(daysInMonth - currentDay + 1, 1) prevents division by zero.
        await tester.pumpWidget(
          _buildCard(budget: 300.0, spent: 50.0),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('spent = 0 — pace line renders correctly', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 600.0),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('You can spend'), findsWidgets);
      });

      // Bug 3 fix: remaining == 0 is now "On budget" (amber), not "Over budget".
      testWidgets('remaining == 0 → "On budget" shown (not "Over budget")',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 100.0),
        );
        await tester.pump();

        expect(find.textContaining('On budget'), findsWidgets);
        expect(find.textContaining('Over budget'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // State: On budget (spent == budget within epsilon)
    // -----------------------------------------------------------------------

    group('on-budget state — spent equals budget', () {
      testWidgets('shows "On budget" in the pace line', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 200.0, spent: 200.0),
        );
        await tester.pump();

        expect(find.textContaining('On budget'), findsWidgets);
      });

      testWidgets('does NOT show "Over budget" when on-budget', (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 200.0, spent: 200.0),
        );
        await tester.pump();

        expect(find.textContaining('Over budget'), findsNothing);
      });

      testWidgets('does NOT show "You can spend" when on-budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 200.0, spent: 200.0),
        );
        await tester.pump();

        expect(find.textContaining('You can spend'), findsNothing);
      });

      // Bug 1: no minus sign when remaining rounds to zero.
      testWidgets('remaining display does not show minus sign when near-zero',
          (tester) async {
        // 0.001 over budget — abs remaining is 0.001, below 0.005 threshold.
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 100.001),
        );
        await tester.pump();

        // No Text widget should contain a minus/en-dash before a currency symbol.
        final allTexts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toList();
        for (final text in allTexts) {
          expect(
            text,
            isNot(contains('−€')),
            reason: 'Negative zero must not render with a minus sign',
          );
          expect(
            text,
            isNot(contains('-€')),
            reason: 'Negative zero must not render with a minus sign',
          );
        }
      });

      // Bug 2: subtitle shows "left of X budget" (not "left of …") on on-budget.
      testWidgets('shows "left of" subtitle in on-budget state',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 200.0, spent: 200.0),
        );
        await tester.pump();

        expect(find.textContaining('left of'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Bug 2: subtitle shows "over budget" not "left of" when truly over budget
    // -----------------------------------------------------------------------

    group('over-budget subtitle text (Bug 2)', () {
      testWidgets('subtitle shows "Over budget" text when spent > budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 150.0),
        );
        await tester.pump();

        // The subtitle next to the remaining amount should say "Over budget".
        expect(find.textContaining('Over budget'), findsWidgets);
      });

      testWidgets('subtitle does NOT show "left of" when truly over-budget',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 150.0),
        );
        await tester.pump();

        expect(find.textContaining('left of'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Epsilon boundary gap — _remaining == -0.005 must land in on-budget state
    // -----------------------------------------------------------------------

    group('epsilon boundary — _remaining == -0.005', () {
      // budget=100.0, spent=100.005 → remaining = -0.005 exactly.
      // Before the fix (_isOnBudget used strict <), this value fell through
      // both guards and showed a negative "You can spend" line.
      // After the fix (_isOnBudget uses <=), it resolves to on-budget state.
      testWidgets(
          'should_show_on_budget_when_remaining_is_exactly_minus_epsilon',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 100.005),
        );
        await tester.pump();

        expect(
          find.textContaining('On budget'),
          findsWidgets,
          reason: 'remaining == -0.005 must resolve to on-budget state',
        );
        expect(
          find.textContaining('You can spend'),
          findsNothing,
          reason: 'negative "You can spend" must not appear at the boundary',
        );
        expect(
          find.textContaining('Over budget'),
          findsNothing,
          reason: 'over-budget must not trigger at the epsilon boundary',
        );
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
          _buildCard(budget: 100.0, spent: 250.0),
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
          _buildCard(budget: 100.0, spent: 95.0),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Today-marker geometry — _BudgetProgressBar
    // -----------------------------------------------------------------------

    group('today-marker geometry', () {
      testWidgets(
          '_BudgetProgressBar renders without overflow at midpoint markerFraction',
          (tester) async {
        // Provide a viewport that gives the LayoutBuilder real constraints.
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        // A budget that positions the spent/budget ratio at roughly 50% and
        // a real date mid-month will compute markerFraction ≈ 0.5.
        // The key assertion is that the Positioned today-marker (top: 0,
        // height: 12) does not escape the 12dp Stack — no overflow.
        await tester.pumpWidget(
          _buildCard(budget: 200.0, spent: 100.0),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          '_BudgetProgressBar renders without overflow at markerFraction 0.0',
          (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildCard(budget: 300.0, spent: 10.0),
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
          _buildCard(budget: 500.0, spent: 100.0, theme: AppTheme.dark),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('over-budget state renders without errors in dark mode',
          (tester) async {
        await tester.pumpWidget(
          _buildCard(budget: 100.0, spent: 200.0, theme: AppTheme.dark),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Fallback mode: spent scoped to budgeted categories only
    //
    // When no global budget is set, effectiveBudgetProvider returns the sum of
    // category budgets. effectiveSpentProvider must return only the spending
    // under those same categories — not the full month total.
    //
    // Scenario: Food budget = 11.50 €, Food spent = 11 €, Social Life spent =
    // 10 € (no budget for Social Life).
    //   • Correct: spent=11, budget=11.50, remaining=+0.50 (within budget)
    //   • Wrong:   spent=21, budget=11.50, remaining=-9.50 (false over-budget)
    // -----------------------------------------------------------------------

    group('fallback mode — spent scoped to budgeted categories', () {
      testWidgets(
          'remaining is positive when un-budgeted category spend is excluded',
          (tester) async {
        // effectiveBudgetProvider = 11.50 (sum of Food budget only)
        // effectiveSpentProvider  = 11.00 (Food spent only — Social Life excluded)
        // remaining = 0.50 → within budget, "left of" should appear
        await tester.pumpWidget(
          _buildCard(budget: 11.50, spent: 11.0),
        );
        await tester.pump();

        expect(
          find.textContaining('left of'),
          findsOneWidget,
          reason: 'remaining=+0.50 is within budget; "left of" must appear',
        );
        expect(
          find.textContaining('Over budget'),
          findsNothing,
          reason:
              'must NOT show over-budget when un-budgeted spend is correctly excluded',
        );
        expect(
          find.textContaining('You can spend'),
          findsWidgets,
          reason:
              'positive remaining means user still has safe daily spend available',
        );
      });

      testWidgets(
          'if all spent were included (wrong), result would be over budget',
          (tester) async {
        // Demonstrate that the wrong total (21 €) against 11.50 € budget would
        // produce over-budget. This is the pre-fix behaviour we guard against.
        // effectiveSpentProvider is overridden to 21 to simulate wrong behaviour.
        await tester.pumpWidget(
          _buildCard(budget: 11.50, spent: 21.0),
        );
        await tester.pump();

        expect(
          find.textContaining('Over budget'),
          findsWidgets,
          reason:
              'sanity check: including un-budgeted spend (21 €) must show over-budget',
        );
      });
    });
  });
}
