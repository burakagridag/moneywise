// Insight domain entity and InsightSeverity enum — insights feature.
// Pure Dart — zero Flutter SDK dependencies.
import 'insight_localization_data.dart';

/// Categorises the urgency of an [Insight] observation.
///
/// Severity controls the accent color of the [InsightCard] in the UI layer.
/// The mapping is:
/// - [info] → brand-blue palette
/// - [warning] → amber palette
/// - [critical] → reserved for future use (treated as warning in V1)
enum InsightSeverity {
  info,
  warning,
  critical;

  /// Sort key: lower value = shown first.
  int get sortOrder => switch (this) {
        InsightSeverity.critical => 0,
        InsightSeverity.warning => 1,
        InsightSeverity.info => 2,
      };
}

/// A single actionable observation produced by the InsightEngine.
///
/// [id] must be a stable constant string per rule (e.g. `'concentration'`) so
/// the UI can apply keyed animations and deduplicate across refreshes.
///
/// Icon and color data live in the presentation layer ([InsightViewModel])
/// so that this entity remains pure Dart with zero Flutter SDK dependencies.
class Insight {
  const Insight({
    required this.id,
    required this.severity,
    required this.headline,
    required this.body,
    this.actionRoute,
    this.bodyParams = const {},
    this.localizationData,
  });

  /// Stable constant string per rule — e.g. `'concentration'`.
  final String id;

  /// Severity that drives sort order in the [InsightProvider].
  final InsightSeverity severity;

  /// Short headline shown in [InsightCard] title (1 line, ellipsis).
  final String headline;

  /// Supporting detail shown in [InsightCard] subtitle (1 line, ellipsis).
  ///
  /// English fallback string. Use [bodyParams] to supply computed values to the
  /// presentation mapper so it can build a fully-localized body via ARB.
  final String body;

  /// Optional go_router path; null means the card is not tappable.
  final String? actionRoute;

  /// Named parameters used by the presentation mapper to build a localized
  /// [body] string via ARB placeholders.
  ///
  /// Keys and value types are rule-specific:
  /// - `'concentration'` rule: `{'pct': int}`
  /// - `'big_transaction'` rule: `{'amount': String, 'pct': int}` (pct<=100 branch)
  ///   or `const {}` (pct>100 / "Exceeds" branch)
  ///
  /// Rules with static body strings (savings_goal, daily_overpacing) leave this
  /// as the default empty map — the mapper uses the ARB key directly.
  final Map<String, dynamic> bodyParams;

  /// Typed localization payload consumed by the presentation mapper.
  ///
  /// When non-null, the mapper uses sealed dispatch on the subtype to call the
  /// appropriate [AppLocalizations] method. When null, the mapper falls back to
  /// [headline] and [body] strings directly.
  final InsightLocalizationData? localizationData;
}
