// Unit tests for InsightRule stubs and RuleBasedInsightProvider — insights feature.
// Placeholder tests for the four V1 rule classes; full tests in Epic 8b.
// ignore_for_file: prefer_const_constructors, prefer_const_declarations
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/insights/data/rule_based_insight_provider.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_context.dart';
import 'package:moneywise/features/insights/domain/insight_rule.dart';
import 'package:moneywise/features/insights/domain/rules/big_transaction_rule.dart';
import 'package:moneywise/features/insights/domain/rules/concentration_rule.dart';
import 'package:moneywise/features/insights/domain/rules/daily_overpacing_rule.dart';
import 'package:moneywise/features/insights/domain/rules/savings_goal_rule.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal [InsightContext] with empty/null values for stub rule tests.
InsightContext _emptyContext() => InsightContext(
      currentMonthTransactions: const [],
      previousMonthTransactions: const [],
      currentMonthBudgets: const [],
      effectiveBudget: null,
      referenceDate: DateTime(2026, 5, 1),
    );

/// A fake rule that always fires with a known insight.
class _AlwaysFiresRule implements InsightRule {
  const _AlwaysFiresRule(this.id, this.severity);

  final String id;
  final InsightSeverity severity;

  @override
  Insight? evaluate(InsightContext context) => Insight(
        id: id,
        severity: severity,
        headline: 'Test: $id',
        body: 'Body: $id',
        icon: Icons.info,
        iconColor: Colors.blue,
        iconBackgroundColor: Colors.blue.withValues(alpha: 0.1),
      );
}

/// A fake rule that never fires.
class _NeverFiresRule implements InsightRule {
  const _NeverFiresRule();

  @override
  Insight? evaluate(InsightContext context) => null;
}

// ---------------------------------------------------------------------------
// ConcentrationRule stub
// ---------------------------------------------------------------------------

void main() {
  group('ConcentrationRule stub — Epic 8b', () {
    test('has stable id constant', () {
      expect(ConcentrationRule.id, equals('concentration'));
    });

    test('evaluate() returns null for empty context (stub)', () {
      // TODO: Epic 8b — replace with full rule logic tests.
      const rule = ConcentrationRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // SavingsGoalRule stub
  // -------------------------------------------------------------------------

  group('SavingsGoalRule stub — Epic 8b', () {
    test('has stable id constant', () {
      expect(SavingsGoalRule.id, equals('savings_goal'));
    });

    test('evaluate() returns null for empty context (stub)', () {
      // TODO: Epic 8b — replace with full rule logic tests.
      const rule = SavingsGoalRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // DailyOverpacingRule stub
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule stub — Epic 8b', () {
    test('has stable id constant', () {
      expect(DailyOverpacingRule.id, equals('daily_overpacing'));
    });

    test('evaluate() returns null for empty context (stub)', () {
      // TODO: Epic 8b — replace with full rule logic tests.
      const rule = DailyOverpacingRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // BigTransactionRule stub
  // -------------------------------------------------------------------------

  group('BigTransactionRule stub — Epic 8b', () {
    test('has stable id constant', () {
      expect(BigTransactionRule.id, equals('big_transaction'));
    });

    test('evaluate() returns null for empty context (stub)', () {
      // TODO: Epic 8b — replace with full rule logic tests.
      const rule = BigTransactionRule();
      expect(rule.evaluate(_emptyContext()), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // RuleBasedInsightProvider
  // -------------------------------------------------------------------------

  group('RuleBasedInsightProvider', () {
    test('empty rules list returns empty insights', () {
      const provider = RuleBasedInsightProvider(rules: []);
      final results = provider.generate(_emptyContext());
      expect(results, isEmpty);
    });

    test('rules returning null are filtered out', () {
      const provider = RuleBasedInsightProvider(
        rules: [_NeverFiresRule(), _NeverFiresRule()],
      );
      final results = provider.generate(_emptyContext());
      expect(results, isEmpty);
    });

    test('firing rule produces an insight', () {
      final provider = const RuleBasedInsightProvider(
        rules: [_AlwaysFiresRule('test', InsightSeverity.info)],
      );
      final results = provider.generate(_emptyContext());
      expect(results.length, equals(1));
      expect(results.first.id, equals('test'));
    });

    test('insights are sorted by severity: critical before warning before info',
        () {
      final provider = RuleBasedInsightProvider(
        rules: [
          _AlwaysFiresRule('info_rule', InsightSeverity.info),
          _AlwaysFiresRule('critical_rule', InsightSeverity.critical),
          _AlwaysFiresRule('warning_rule', InsightSeverity.warning),
        ],
      );
      final results = provider.generate(_emptyContext());
      expect(results.length, equals(3));
      expect(results[0].severity, equals(InsightSeverity.critical));
      expect(results[1].severity, equals(InsightSeverity.warning));
      expect(results[2].severity, equals(InsightSeverity.info));
    });

    test('null rules are filtered, non-null rules are included', () {
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
  });

  // -------------------------------------------------------------------------
  // InsightSeverity sort order
  // -------------------------------------------------------------------------

  group('InsightSeverity.sortOrder', () {
    test('critical < warning < info', () {
      expect(
        InsightSeverity.critical.sortOrder,
        lessThan(InsightSeverity.warning.sortOrder),
      );
      expect(
        InsightSeverity.warning.sortOrder,
        lessThan(InsightSeverity.info.sortOrder),
      );
    });
  });
}
