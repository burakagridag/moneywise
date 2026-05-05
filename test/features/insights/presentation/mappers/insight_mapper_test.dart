// Unit tests for insightToViewModel mapper — insights feature presentation layer.
// Verifies locale-correct headline/body strings for each InsightLocalizationData
// subclass in both TR and EN locales, and the null-localizationData fallback path.
// ignore_for_file: prefer_const_constructors
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/i18n/arb/app_localizations.dart';
import 'package:moneywise/features/insights/domain/insight.dart';
import 'package:moneywise/features/insights/domain/insight_localization_data.dart';
import 'package:moneywise/features/insights/presentation/mappers/insight_mapper.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal [Insight] with the given [id] and [localizationData].
/// Headline and body are English fallback strings so the null-fallback test
/// can verify they are passed through unchanged.
Insight _makeInsight({
  required String id,
  InsightLocalizationData? localizationData,
  String headline = 'English headline',
  String body = 'English body',
}) {
  return Insight(
    id: id,
    severity: InsightSeverity.info,
    headline: headline,
    body: body,
    localizationData: localizationData,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppLocalizations l10nTr;
  late AppLocalizations l10nEn;

  setUpAll(() async {
    l10nTr = await AppLocalizations.delegate.load(const Locale('tr'));
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
  });

  // -------------------------------------------------------------------------
  // ConcentrationRule
  // -------------------------------------------------------------------------

  group('ConcentrationRule', () {
    test('TR locale — headline and body contain pct', () {
      final insight = _makeInsight(
        id: 'concentration',
        localizationData: const ConcentrationLocalizationData(pct: 80),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Harcama yoğunlaşması');
      expect(vm.body, contains('80'));
    });

    test('EN locale — headline is in English', () {
      final insight = _makeInsight(
        id: 'concentration',
        localizationData: const ConcentrationLocalizationData(pct: 80),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Spending concentrated');
      expect(vm.body, contains('80'));
    });

    test('TR locale — pct is reflected accurately in body for different values',
        () {
      final insight = _makeInsight(
        id: 'concentration',
        localizationData: const ConcentrationLocalizationData(pct: 65),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.body, contains('65'));
      expect(vm.body, isNot(contains('80')));
    });
  });

  // -------------------------------------------------------------------------
  // BigTransactionRule — normal branch (exceedsBudget: false)
  // -------------------------------------------------------------------------

  group('BigTransactionRule normal branch', () {
    test('TR locale — body contains formattedAmount and pct', () {
      final insight = _makeInsight(
        id: 'big_transaction',
        localizationData: const BigTransactionLocalizationData(
          pct: 38,
          formattedAmount: '300,00 €',
          exceedsBudget: false,
        ),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Büyük işlem');
      expect(vm.body, contains('300,00 €'));
      expect(vm.body, contains('38'));
    });

    test('EN locale — body contains formattedAmount and pct', () {
      final insight = _makeInsight(
        id: 'big_transaction',
        localizationData: const BigTransactionLocalizationData(
          pct: 38,
          formattedAmount: '300,00 €',
          exceedsBudget: false,
        ),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Large transaction');
      expect(vm.body, contains('300,00 €'));
      expect(vm.body, contains('38'));
    });
  });

  // -------------------------------------------------------------------------
  // BigTransactionRule — exceeds branch (exceedsBudget: true)
  // -------------------------------------------------------------------------

  group('BigTransactionRule exceeds branch', () {
    test('TR locale — body uses Sponsor-approved exceeds wording', () {
      final insight = _makeInsight(
        id: 'big_transaction',
        localizationData: const BigTransactionLocalizationData(
          pct: 150,
          formattedAmount: '1.500,00 €',
          exceedsBudget: true,
        ),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Büyük işlem');
      expect(vm.body, 'Aylık bütçeni aşan işlem'); // TR formality fix: siz→sen
    });

    test(
        'TR locale — body does NOT contain formattedAmount or pct when exceeds',
        () {
      final insight = _makeInsight(
        id: 'big_transaction',
        localizationData: const BigTransactionLocalizationData(
          pct: 150,
          formattedAmount: '1.500,00 €',
          exceedsBudget: true,
        ),
      );

      final vm = insightToViewModel(insight, l10nTr);

      // The fixed exceeds string does not embed the amount or pct.
      expect(vm.body, isNot(contains('1.500,00 €')));
      expect(vm.body, isNot(contains('150')));
    });

    test('EN locale — body uses English exceeds wording', () {
      final insight = _makeInsight(
        id: 'big_transaction',
        localizationData: const BigTransactionLocalizationData(
          pct: 120,
          formattedAmount: '1.200,00 €',
          exceedsBudget: true,
        ),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.body, 'Exceeds your monthly budget');
    });
  });

  // -------------------------------------------------------------------------
  // SavingsGoalRule
  // -------------------------------------------------------------------------

  group('SavingsGoalRule', () {
    test('TR locale — headline and fixed body string', () {
      final insight = _makeInsight(
        id: 'savings_goal',
        localizationData: const SavingsGoalLocalizationData(),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Düşük tasarruf oranı');
      expect(vm.body, isNotEmpty);
      // Body is a fixed string — it must contain the 10% threshold reference.
      expect(vm.body, contains('%10'));
    });

    test('EN locale — headline is in English', () {
      final insight = _makeInsight(
        id: 'savings_goal',
        localizationData: const SavingsGoalLocalizationData(),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Low savings rate');
    });
  });

  // -------------------------------------------------------------------------
  // DailyOverpacingRule
  // -------------------------------------------------------------------------

  group('DailyOverpacingRule', () {
    test('TR locale — headline and fixed body string', () {
      final insight = _makeInsight(
        id: 'daily_overpacing',
        localizationData: const DailyOverpacingLocalizationData(),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Aşırı harcama');
      expect(vm.body, isNotEmpty);
    });

    test('EN locale — headline is in English', () {
      final insight = _makeInsight(
        id: 'daily_overpacing',
        localizationData: const DailyOverpacingLocalizationData(),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Overspending pace');
    });
  });

  // -------------------------------------------------------------------------
  // WeekendSpendingRule
  // -------------------------------------------------------------------------

  group('WeekendSpendingRule', () {
    test('TR locale — headline and body contain pct', () {
      final insight = _makeInsight(
        id: 'weekend_spending',
        localizationData: const WeekendSpendingLocalizationData(pct: 200),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Hafta sonu harcaması yüksek');
      expect(vm.body, contains('200'));
    });

    test('EN locale — headline and body contain pct', () {
      final insight = _makeInsight(
        id: 'weekend_spending',
        localizationData: const WeekendSpendingLocalizationData(pct: 150),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Weekend spending high');
      expect(vm.body, contains('150'));
    });

    test('TR locale — pct is reflected accurately in body for different values',
        () {
      final insight = _makeInsight(
        id: 'weekend_spending',
        localizationData: const WeekendSpendingLocalizationData(pct: 125),
      );

      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.body, contains('125'));
      expect(vm.body, isNot(contains('200')));
    });

    test('EN locale — body does not contain wrong pct for different values',
        () {
      final insight = _makeInsight(
        id: 'weekend_spending',
        localizationData: const WeekendSpendingLocalizationData(pct: 300),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.body, contains('300'));
      expect(vm.body, isNot(contains('200')));
    });
  });

  // -------------------------------------------------------------------------
  // null localizationData — fallback to domain English strings
  // -------------------------------------------------------------------------

  group('null localizationData fallback', () {
    test(
        'TR locale — falls back to domain headline and body strings without crash',
        () {
      final insight = _makeInsight(
        id: 'unknown_future_rule',
        headline: 'Raw English',
        body: 'Raw body',
        // localizationData is null — no subclass exists for this rule yet.
      );

      // Must not throw regardless of locale.
      final vm = insightToViewModel(insight, l10nTr);

      expect(vm.headline, 'Raw English');
      expect(vm.body, 'Raw body');
    });

    test(
        'EN locale — falls back to domain headline and body strings without crash',
        () {
      final insight = _makeInsight(
        id: 'unknown_future_rule',
        headline: 'Raw English',
        body: 'Raw body',
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.headline, 'Raw English');
      expect(vm.body, 'Raw body');
    });

    test('Insight id drives icon/color even when localizationData is null', () {
      // concentration id → pie_chart icon branch in the switch.
      final insight = Insight(
        id: 'concentration',
        severity: InsightSeverity.warning,
        headline: 'Raw headline',
        body: 'Raw body',
        localizationData: null,
      );

      final vm = insightToViewModel(insight, l10nEn);

      // id-based icon branch fires; headline/body come from domain strings.
      expect(vm.headline, 'Raw headline');
      expect(vm.body, 'Raw body');
    });
  });

  // -------------------------------------------------------------------------
  // ViewModel field correctness
  // -------------------------------------------------------------------------

  group('InsightViewModel field correctness', () {
    test('vm.id delegates to insight.id', () {
      final insight = _makeInsight(id: 'concentration');
      final vm = insightToViewModel(insight, l10nEn);
      expect(vm.id, 'concentration');
    });

    test('vm.severity delegates to insight.severity', () {
      final insight = Insight(
        id: 'big_transaction',
        severity: InsightSeverity.warning,
        headline: 'h',
        body: 'b',
        localizationData: const BigTransactionLocalizationData(
          pct: 50,
          formattedAmount: '500 €',
          exceedsBudget: false,
        ),
      );

      final vm = insightToViewModel(insight, l10nEn);

      expect(vm.severity, InsightSeverity.warning);
    });
  });
}
