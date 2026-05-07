// Unit tests for insight_classifier.dart — EPIC8C-01.
// Verifies that each rule ID routes to the correct surface per ADR-013 addendum.
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/insights/domain/insight_classifier.dart';

void main() {
  // ---------------------------------------------------------------------------
  // InsightSurface.budget — only concentration
  // ---------------------------------------------------------------------------

  group('InsightSurface.budget', () {
    test('concentration is visible on budget surface', () {
      expect(insightVisibleOn('concentration', InsightSurface.budget), isTrue);
    });

    test('big_transaction is NOT visible on budget surface', () {
      expect(
        insightVisibleOn('big_transaction', InsightSurface.budget),
        isFalse,
      );
    });

    test('savings_goal is NOT visible on budget surface', () {
      expect(
        insightVisibleOn('savings_goal', InsightSurface.budget),
        isFalse,
      );
    });

    test('daily_overpacing is NOT visible on budget surface', () {
      expect(
        insightVisibleOn('daily_overpacing', InsightSurface.budget),
        isFalse,
      );
    });

    test('weekend_spending is NOT visible on budget surface', () {
      expect(
        insightVisibleOn('weekend_spending', InsightSurface.budget),
        isFalse,
      );
    });

    test('unknown future rule id is NOT visible on budget surface', () {
      expect(
        insightVisibleOn('some_future_rule', InsightSurface.budget),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // InsightSurface.home — all except concentration
  // ---------------------------------------------------------------------------

  group('InsightSurface.home', () {
    test('concentration is NOT visible on home surface', () {
      expect(
        insightVisibleOn('concentration', InsightSurface.home),
        isFalse,
      );
    });

    test('big_transaction is visible on home surface', () {
      expect(
        insightVisibleOn('big_transaction', InsightSurface.home),
        isTrue,
      );
    });

    test('savings_goal is visible on home surface', () {
      expect(
        insightVisibleOn('savings_goal', InsightSurface.home),
        isTrue,
      );
    });

    test('daily_overpacing is visible on home surface', () {
      expect(
        insightVisibleOn('daily_overpacing', InsightSurface.home),
        isTrue,
      );
    });

    test('weekend_spending is visible on home surface', () {
      expect(
        insightVisibleOn('weekend_spending', InsightSurface.home),
        isTrue,
      );
    });

    test('unknown future rule id is visible on home surface', () {
      // Future rules default to home unless explicitly added to budget surface.
      expect(
        insightVisibleOn('some_future_rule', InsightSurface.home),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Exhaustiveness: surfaces are mutually exclusive for all known V1 rule IDs
  // ---------------------------------------------------------------------------

  group('surface exclusivity', () {
    const knownIds = [
      'concentration',
      'big_transaction',
      'savings_goal',
      'daily_overpacing',
      'weekend_spending',
    ];

    for (final id in knownIds) {
      test('$id is visible on exactly one surface', () {
        final onHome = insightVisibleOn(id, InsightSurface.home);
        final onBudget = insightVisibleOn(id, InsightSurface.budget);
        // Exactly one must be true, not both, not neither.
        expect(onHome ^ onBudget, isTrue,
            reason: '$id should appear on exactly one surface');
      });
    }
  });
}
