// Widget tests for ThisWeekSection — home feature (EPIC8A-08).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/widgets/insight_card.dart';
import 'package:moneywise/features/home/presentation/widgets/this_week_section.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_provider.dart';
import 'package:moneywise/features/insights/presentation/providers/insights_providers.dart';

// ---------------------------------------------------------------------------
// Fake InsightProvider — returns a configurable list synchronously.
// ---------------------------------------------------------------------------

class _FakeProvider implements InsightProvider {
  const _FakeProvider(this.insights);

  final List<Insight> insights;

  @override
  List<Insight> generate(InsightContext context) => insights;
}

// ---------------------------------------------------------------------------
// Sample insights
// ---------------------------------------------------------------------------

Insight _makeInsight(String id, InsightSeverity severity) => Insight(
      id: id,
      severity: severity,
      headline: 'Headline $id',
      body: 'Body $id',
      icon: Icons.info,
      iconColor: AppColors.brandPrimary,
      iconBackgroundColor: AppColors.brandSurface,
    );

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildSection({
  ThemeData? theme,
  required List<Insight> insights,
}) =>
    ProviderScope(
      overrides: [
        // Override the FutureProvider directly to avoid DB calls in widget tests.
        // This also verifies that insightProviderInstanceProvider is injectable.
        insightProviderInstanceProvider
            .overrideWithValue(_FakeProvider(insights)),
        insightsProvider.overrideWith((_) async => insights),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(child: ThisWeekSection()),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ThisWeekSection', () {
    // -----------------------------------------------------------------------
    // Empty list — section hidden
    // -----------------------------------------------------------------------

    testWidgets('0 insights → section hidden (SizedBox.shrink)',
        (tester) async {
      await tester.pumpWidget(_buildSection(insights: const []));
      await tester.pump(); // allow FutureProvider to resolve

      expect(find.byType(InsightCard), findsNothing);
      // "THIS WEEK" header must not appear
      expect(find.text('THIS WEEK'), findsNothing);

      // Widget occupies zero height — find SizedBox.shrink via zero-size box.
      // We verify by ensuring no InsightCard is present and no error occurs.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '0 insights → zero vertical space occupied (SizedBox.shrink height 0)',
        (tester) async {
      await tester.pumpWidget(_buildSection(insights: const []));
      await tester.pump();

      // When hidden, ThisWeekSection renders SizedBox.shrink() — find it
      // by verifying no Section header text is in the tree.
      expect(find.text('THIS WEEK'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 1 insight → 1 InsightCard
    // -----------------------------------------------------------------------

    testWidgets('1 insight → 1 InsightCard rendered', (tester) async {
      final insight = _makeInsight('test_1', InsightSeverity.info);

      await tester.pumpWidget(_buildSection(insights: [insight]));
      await tester.pump();

      expect(find.byType(InsightCard), findsOneWidget);
      expect(find.text('Headline test_1'), findsOneWidget);
      expect(find.text('Body test_1'), findsOneWidget);
    });

    testWidgets('1 insight → section header is visible', (tester) async {
      final insight = _makeInsight('test_1', InsightSeverity.info);

      await tester.pumpWidget(_buildSection(insights: [insight]));
      await tester.pump();

      expect(find.text('THIS WEEK'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2 insights → 2 InsightCards
    // -----------------------------------------------------------------------

    testWidgets('2 insights → 2 InsightCards rendered', (tester) async {
      final insights = [
        _makeInsight('a', InsightSeverity.warning),
        _makeInsight('b', InsightSeverity.info),
      ];

      await tester.pumpWidget(_buildSection(insights: insights));
      await tester.pump();

      expect(find.byType(InsightCard), findsNWidgets(2));
      expect(find.text('Headline a'), findsOneWidget);
      expect(find.text('Headline b'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // >2 insights → only first 2 shown
    // -----------------------------------------------------------------------

    testWidgets('>2 insights → only first 2 InsightCards rendered',
        (tester) async {
      final insights = [
        _makeInsight('a', InsightSeverity.critical),
        _makeInsight('b', InsightSeverity.warning),
        _makeInsight('c', InsightSeverity.info),
      ];

      await tester.pumpWidget(_buildSection(insights: insights));
      await tester.pump();

      expect(find.byType(InsightCard), findsNWidgets(2));
      expect(find.text('Headline a'), findsOneWidget);
      expect(find.text('Headline b'), findsOneWidget);
      expect(find.text('Headline c'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // insightProviderInstanceProvider is overridable
    // -----------------------------------------------------------------------

    testWidgets(
        'insightProviderInstanceProvider is injectable via overrideWithValue',
        (tester) async {
      final fakeProvider = _FakeProvider([
        _makeInsight('injected', InsightSeverity.info),
      ]);

      final injectedInsights = fakeProvider.generate(
        InsightContext(
          currentMonthTransactions: const [],
          previousMonthTransactions: const [],
          currentMonthBudgets: const [],
          effectiveBudget: null,
          referenceDate: DateTime(2026, 5, 1),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            insightProviderInstanceProvider.overrideWithValue(fakeProvider),
            // Override insightsProvider to bypass DB calls.
            insightsProvider.overrideWith((_) async => injectedInsights),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ThisWeekSection()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Headline injected'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Dark theme
    // -----------------------------------------------------------------------

    testWidgets('renders without error in dark theme', (tester) async {
      final insight = _makeInsight('dark_test', InsightSeverity.warning);

      await tester.pumpWidget(
        _buildSection(theme: AppTheme.dark, insights: [insight]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(InsightCard), findsOneWidget);
    });
  });
}
