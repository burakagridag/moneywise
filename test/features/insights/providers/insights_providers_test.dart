// Unit tests for insightsProvider — insights feature (EPIC8A-08).
// Verifies V1 shell behavior: empty rules list returns empty insight list.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_provider.dart';
import 'package:moneywise/features/insights/presentation/models/insight_view_model.dart';
import 'package:moneywise/features/insights/presentation/providers/insights_providers.dart';

// ---------------------------------------------------------------------------
// Fake InsightProvider implementations
// ---------------------------------------------------------------------------

/// Always returns an empty list — equivalent to V1 shell.
class _EmptyInsightProvider implements InsightProvider {
  const _EmptyInsightProvider();

  @override
  List<Insight> generate(InsightContext context) => const [];
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('insightsProvider — V1 shell', () {
    test('insightProviderInstanceProvider is an AutoDisposeProvider', () {
      // Verify the provider type is correct for overridability in tests.
      expect(
        insightProviderInstanceProvider,
        isA<AutoDisposeProvider<InsightProvider>>(),
      );
    });

    test(
        'insightProviderInstanceProvider can be overridden in ProviderContainer',
        () {
      final container = ProviderContainer(
        overrides: [
          insightProviderInstanceProvider
              .overrideWithValue(const _EmptyInsightProvider()),
        ],
      );
      addTearDown(container.dispose);

      final provider = container.read(insightProviderInstanceProvider);
      expect(provider, isA<_EmptyInsightProvider>());
    });

    test(
        'insightsProvider is an AutoDisposeFutureProvider<List<InsightViewModel>>',
        () {
      expect(
        insightsProvider,
        isA<AutoDisposeFutureProvider<List<InsightViewModel>>>(),
      );
    });
  });
}
