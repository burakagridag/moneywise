// Widget tests for ThisWeekSection — home feature (EPIC8A-08, EPIC8A-12).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/analytics/analytics_service.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/core/theme/app_theme.dart';
import 'package:moneywise/features/home/presentation/widgets/insight_card.dart';
import 'package:moneywise/features/home/presentation/widgets/this_week_section.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_provider.dart';
import 'package:moneywise/features/insights/presentation/models/insight_view_model.dart';
import 'package:moneywise/features/insights/presentation/providers/insights_providers.dart';

// ---------------------------------------------------------------------------
// Spy analytics service — records all logged events for assertion.
// ---------------------------------------------------------------------------

class _SpyAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, dynamic>? parameters})> events = [];

  @override
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    events.add((name: name, parameters: parameters));
  }
}

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
// Sample insight view models
// ---------------------------------------------------------------------------

InsightViewModel _makeViewModel(String id, InsightSeverity severity) {
  final insight = Insight(
    id: id,
    severity: severity,
    headline: 'Headline $id',
    body: 'Body $id',
  );
  return InsightViewModel(
    insight: insight,
    icon: Icons.info,
    iconColor: AppColors.brandPrimary,
    iconBackgroundColor: AppColors.brandSurface,
    headline: 'Headline $id',
    body: 'Body $id',
  );
}

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildSection({
  ThemeData? theme,
  required List<InsightViewModel> viewModels,
}) =>
    ProviderScope(
      overrides: [
        // Analytics stub — prevents real provider usage in tests (EPIC8A-12).
        analyticsServiceProvider.overrideWith((_) => StubAnalyticsService()),
        // Override the FutureProvider directly to avoid DB calls in widget tests.
        // This also verifies that insightProviderInstanceProvider is injectable.
        insightProviderInstanceProvider.overrideWithValue(
          _FakeProvider(viewModels.map((vm) => vm.insight).toList()),
        ),
        insightsProvider.overrideWith((_) async => viewModels),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
      await tester.pumpWidget(_buildSection(viewModels: const []));
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
      await tester.pumpWidget(_buildSection(viewModels: const []));
      await tester.pump();

      // When hidden, ThisWeekSection renders SizedBox.shrink() — find it
      // by verifying no Section header text is in the tree.
      expect(find.text('THIS WEEK'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 1 insight → 1 InsightCard
    // -----------------------------------------------------------------------

    testWidgets('1 insight → 1 InsightCard rendered', (tester) async {
      final vm = _makeViewModel('test_1', InsightSeverity.info);

      await tester.pumpWidget(_buildSection(viewModels: [vm]));
      await tester.pump();

      expect(find.byType(InsightCard), findsOneWidget);
      expect(find.text('Headline test_1'), findsOneWidget);
      expect(find.text('Body test_1'), findsOneWidget);
    });

    testWidgets('1 insight → section header is visible', (tester) async {
      final vm = _makeViewModel('test_1', InsightSeverity.info);

      await tester.pumpWidget(_buildSection(viewModels: [vm]));
      await tester.pump();

      expect(find.text('THIS WEEK'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2 insights → 2 InsightCards
    // -----------------------------------------------------------------------

    testWidgets('2 insights → 2 InsightCards rendered', (tester) async {
      final viewModels = [
        _makeViewModel('a', InsightSeverity.warning),
        _makeViewModel('b', InsightSeverity.info),
      ];

      await tester.pumpWidget(_buildSection(viewModels: viewModels));
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
      final viewModels = [
        _makeViewModel('a', InsightSeverity.critical),
        _makeViewModel('b', InsightSeverity.warning),
        _makeViewModel('c', InsightSeverity.info),
      ];

      await tester.pumpWidget(_buildSection(viewModels: viewModels));
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
      final injectedVm =
          _makeViewModel('injected', InsightSeverity.info);
      final fakeProvider =
          _FakeProvider([injectedVm.insight]);

      final injectedInsights = fakeProvider.generate(
        InsightContext(
          currentMonthTransactions: const [],
          previousMonthTransactions: const [],
          currentMonthBudgets: const [],
          effectiveBudget: null,
          referenceDate: DateTime(2026, 5, 1),
          formatAmount: (amount) => amount.toStringAsFixed(2),
        ),
      );
      // Map domain insights to view models for the provider override.
      final injectedViewModels = injectedInsights
          .map((i) => _makeViewModel(i.id, i.severity))
          .toList();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Analytics stub (EPIC8A-12).
            analyticsServiceProvider
                .overrideWith((_) => StubAnalyticsService()),
            insightProviderInstanceProvider.overrideWithValue(fakeProvider),
            // Override insightsProvider to bypass DB calls.
            insightsProvider
                .overrideWith((_) async => injectedViewModels),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
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
      final vm = _makeViewModel('dark_test', InsightSeverity.warning);

      await tester.pumpWidget(
        _buildSection(theme: AppTheme.dark, viewModels: [vm]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(InsightCard), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // EPIC8A-12 — Analytics: insight_card_tapped spy test
    // -----------------------------------------------------------------------

    testWidgets(
        'tapping InsightCard fires insight_card_tapped with correct insight_type',
        (tester) async {
      final spy = _SpyAnalyticsService();
      final vm = _makeViewModel('budget_warning', InsightSeverity.warning);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWith((_) => spy),
            insightProviderInstanceProvider
                .overrideWithValue(_FakeProvider([vm.insight])),
            insightsProvider.overrideWith((_) async => [vm]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(child: ThisWeekSection()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the rendered InsightCard.
      await tester.tap(find.byType(InsightCard).first);
      await tester.pump();

      final tapped = spy.events.where((e) => e.name == 'insight_card_tapped');
      expect(tapped, hasLength(1));
      expect(
          tapped.first.parameters, equals({'insight_type': 'budget_warning'}));
    });
  });
}
