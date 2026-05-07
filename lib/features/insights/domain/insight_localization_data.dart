// insight_localization_data.dart — insights feature domain layer.
// Sealed class hierarchy that carries the rule-specific parameters needed for
// the presentation layer to call AppLocalizations methods. Keeping this in the
// domain layer avoids any Flutter imports while enabling type-safe l10n dispatch.
//
// Rules populate [Insight.localizationData]; the presentation mapper reads it
// to produce the locale-correct headline and body strings.

/// Typed payload attached to an [Insight] so the presentation layer can call
/// the appropriate [AppLocalizations] method with the correct arguments.
///
/// Each subclass corresponds to one rule in the V1 Rule Registry (ADR-013).
/// A null [Insight.localizationData] means the domain rule does not provide
/// structured parameters; the mapper falls back to [Insight.headline] and
/// [Insight.body].
sealed class InsightLocalizationData {
  const InsightLocalizationData();
}

/// Payload for [ConcentrationRule]: top-category concentration percentage.
///
/// [pct] is the integer percentage (e.g. 75 for 75%).
class ConcentrationLocalizationData extends InsightLocalizationData {
  const ConcentrationLocalizationData({required this.pct});

  final int pct;
}

/// Payload for [SavingsGoalRule]: no numeric parameters required; the body is
/// a fixed string with the 10% threshold embedded directly in the ARB key.
class SavingsGoalLocalizationData extends InsightLocalizationData {
  const SavingsGoalLocalizationData();
}

/// Payload for [DailyOverpacingRule]: no numeric parameters required; the body
/// is a fixed string in the ARB file.
class DailyOverpacingLocalizationData extends InsightLocalizationData {
  const DailyOverpacingLocalizationData();
}

/// Payload for [WeekendSpendingRule]: percentage above weekday average.
///
/// [pct] is the integer percentage above weekday daily average.
/// e.g. ratio=3.0 → pct=200, ratio=2.5 → pct=150.
class WeekendSpendingLocalizationData extends InsightLocalizationData {
  const WeekendSpendingLocalizationData({required this.pct});

  final int pct;
}

/// Payload for [BigTransactionRule]: percentage of effective budget consumed
/// and the locale-aware formatted amount string.
///
/// [pct] is the integer percentage (e.g. 50 for 50%).
/// [formattedAmount] is the currency-formatted transaction amount produced by
/// [InsightContext.formatAmount] (e.g. '€ 500.00').
/// [exceedsBudget] is true when pct > 100 (transaction exceeds full budget);
/// the mapper uses [insightBigTransactionBodyExceeds] in this case instead.
class BigTransactionLocalizationData extends InsightLocalizationData {
  const BigTransactionLocalizationData({
    required this.pct,
    required this.formattedAmount,
    required this.exceedsBudget,
  });

  final int pct;
  final String formattedAmount;
  final bool exceedsBudget;
}
