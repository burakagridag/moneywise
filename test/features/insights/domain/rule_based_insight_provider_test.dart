// Unit tests for RuleBasedInsightProvider and V1 stub rules — insights feature (EPIC8B-05).
// Verifies: null filtering, severity sorting, top-3 cap (ADR-013 note),
// empty rules list, and FifthRulePlaceholder stub behaviour.
// ignore_for_file: prefer_const_constructors, prefer_const_declarations
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/insights/data/rule_based_insight_provider.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_rule.dart';
import 'package:moneywise/features/insights/domain/rules/big_transaction_rule.dart';
import 'package:moneywise/features/insights/domain/rules/concentration_rule.dart';
import 'package:moneywise/features/insights/domain/rules/daily_overpacing_rule.dart';
import 'package:moneywise/features/insights/domain/rules/fifth_rule_placeholder.dart';
import 'package:moneywise/features/insights/domain/rules/savings_goal_rule.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Minimal [InsightContext] with no transactions and no budget configured.
InsightContext _emptyContext() => InsightContext(
      currentMonthTransactions: const [],
      previousMonthTransactions: const [],
      currentMonthBudgets: const [],
      effectiveBudget: null,
      referenceDate: DateTime(2026, 5, 15),
      formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
    );

/// A rule that always fires with a known [id] and [severity].
class _AlwaysFiresRule implements InsightRule {
  const _AlwaysFiresRule(this.id, this.severity);

  final String id;
  final InsightSeverity severity;

  @override
  Insight? evaluate(InsightContext context) => Insight(
        id: id,
        severity: severity,
        headline: 'Headline: $id',
        body: 'Body: $id',
      );
}

/// A rule that never fires (always returns null).
class _NeverFiresRule implements InsightRule {
  const _NeverFiresRule();

  @override
  Insight? evaluate(InsightContext context) => null;
}

// ---------------------------------------------------------------------------
// RuleBasedInsightProvider tests
// ---------------------------------------------------------------------------

void main() {
  group('RuleBasedInsightProvider', () {
    test('empty rules list returns empty insights list', () {
      const provider = RuleBasedInsightProvider(rules: []);
      final results = provider.generate(_emptyContext());
      expect(results, isEmpty);
    });

    test('null results from all rules produce empty insights list', () {
      const provider = RuleBasedInsightProvider(
        rules: [_NeverFiresRule(), _NeverFiresRule(), _NeverFiresRule()],
      );
      final results = provider.generate(_emptyContext());
      expect(results, isEmpty);
    });

    test('null results are filtered out; firing rule produces an insight', () {
      final provider = RuleBasedInsightProvider(
        rules: [
          _NeverFiresRule(),
          _AlwaysFiresRule('fires', InsightSeverity.warning),
          _NeverFiresRule(),
        ],
      );
      final results = provider.generate(_emptyContext());
      expect(results.length, equals(1));
      expect(results.first.id, equals('fires'));
    });

    test('insights are sorted by severity: critical → warning → info', () {
      final provider = RuleBasedInsightProvider(
        rules: [
          _AlwaysFiresRule('info_rule', InsightSeverity.info),
          _AlwaysFiresRule('critical_rule', InsightSeverity.critical),
          _AlwaysFiresRule('warning_rule', InsightSeverity.warning),
        ],
      );
      final results = provider.generate(_emptyContext());
      expect(results.length, equals(3));
      expect(results[0].id, equals('critical_rule'));
      expect(results[0].severity, equals(InsightSeverity.critical));
      expect(results[1].id, equals('warning_rule'));
      expect(results[1].severity, equals(InsightSeverity.warning));
      expect(results[2].id, equals('info_rule'));
      expect(results[2].severity, equals(InsightSeverity.info));
    });

    test(
        'mixed null/non-null rules — only firing rules are included, sorted correctly',
        () {
      final provider = RuleBasedInsightProvider(
        rules: [
          _NeverFiresRule(),
          _AlwaysFiresRule('warning', InsightSeverity.warning),
          _NeverFiresRule(),
          _AlwaysFiresRule('critical', InsightSeverity.critical),
        ],
      );
      final results = provider.generate(_emptyContext());
      expect(results.length, equals(2));
      expect(results[0].severity, equals(InsightSeverity.critical));
      expect(results[1].severity, equals(InsightSeverity.warning));
    });

    test('all five V1 rules can be registered without error', () {
      // V1 rule registry as defined in ADR-013.
      const provider = RuleBasedInsightProvider(
        rules: [
          ConcentrationRule(),
          SavingsGoalRule(),
          DailyOverpacingRule(),
          BigTransactionRule(),
          FifthRulePlaceholder(),
        ],
      );
      // All stubs return null — result must be empty (no crash).
      final results = provider.generate(_emptyContext());
      expect(results, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // InsightSeverity sort order
  // -------------------------------------------------------------------------

  group('InsightSeverity.sortOrder', () {
    test('critical.sortOrder < warning.sortOrder', () {
      expect(
        InsightSeverity.critical.sortOrder,
        lessThan(InsightSeverity.warning.sortOrder),
      );
    });

    test('warning.sortOrder < info.sortOrder', () {
      expect(
        InsightSeverity.warning.sortOrder,
        lessThan(InsightSeverity.info.sortOrder),
      );
    });
  });

  // -------------------------------------------------------------------------
  // V1 stub rule constants and behaviour
  // -------------------------------------------------------------------------

  group('ConcentrationRule stub', () {
    test('has stable id constant', () {
      expect(ConcentrationRule.id, equals('concentration'));
    });

    test('threshold is 0.70 (70%) per ADR-013', () {
      expect(ConcentrationRule.threshold, equals(0.70));
    });

    test('evaluate() returns null for empty context (stub)', () {
      const rule = ConcentrationRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  group('SavingsGoalRule stub', () {
    test('has stable id constant', () {
      expect(SavingsGoalRule.id, equals('savings_goal'));
    });

    test('threshold is 0.10 (10%) per ADR-013', () {
      expect(SavingsGoalRule.threshold, equals(0.10));
    });

    test('evaluate() returns null for empty context (stub)', () {
      const rule = SavingsGoalRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  group('DailyOverpacingRule stub', () {
    test('has stable id constant', () {
      expect(DailyOverpacingRule.id, equals('daily_overpacing'));
    });

    test('minimumDayOfMonth is 5 per ADR-013', () {
      expect(DailyOverpacingRule.minimumDayOfMonth, equals(5));
    });

    test('evaluate() returns null for empty context (stub)', () {
      const rule = DailyOverpacingRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  group('BigTransactionRule stub', () {
    test('has stable id constant', () {
      expect(BigTransactionRule.id, equals('big_transaction'));
    });

    test('threshold is 0.30 (30%) per ADR-013', () {
      expect(BigTransactionRule.threshold, equals(0.30));
    });

    test('evaluate() returns null for empty context (stub)', () {
      const rule = BigTransactionRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  group('FifthRulePlaceholder', () {
    test('has stable id constant', () {
      expect(FifthRulePlaceholder.id, equals('fifth_rule_placeholder'));
    });

    test('evaluate() always returns null (permanent stub until Sprint 8c)', () {
      const rule = FifthRulePlaceholder();
      expect(rule.evaluate(_emptyContext()), isNull);
    });

    test('evaluate() returns null regardless of context data', () {
      // Even with a context that has data, the placeholder must return null.
      const rule = FifthRulePlaceholder();
      final ctxWithBudget = InsightContext(
        currentMonthTransactions: const [],
        previousMonthTransactions: const [],
        currentMonthBudgets: const [],
        effectiveBudget: 1000.0,
        referenceDate: DateTime(2026, 5, 15),
        formatAmount: (amount) => '€${amount.toStringAsFixed(2)}',
      );
      expect(rule.evaluate(ctxWithBudget), isNull);
    });
  });
}
