// Insight domain entity and InsightSeverity enum — insights feature.
import 'package:flutter/material.dart';

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
/// [iconData], [iconColor], and [iconBackgroundColor] are set by the provider
/// layer; the [InsightCard] widget is purely presentational and must not switch
/// on [severity] to derive colors.
class Insight {
  const Insight({
    required this.id,
    required this.severity,
    required this.headline,
    required this.body,
    this.actionRoute,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });

  /// Stable constant string per rule — e.g. `'concentration'`.
  final String id;

  /// Severity that drives sort order in the [InsightProvider].
  final InsightSeverity severity;

  /// Short headline shown in [InsightCard] title (1 line, ellipsis).
  final String headline;

  /// Supporting detail shown in [InsightCard] subtitle (1 line, ellipsis).
  final String body;

  /// Optional go_router path; null means the card is not tappable.
  final String? actionRoute;

  /// Icon to render in the 36×36dp container.
  final IconData icon;

  /// Icon stroke/fill color — set by the rule/provider layer.
  final Color iconColor;

  /// Tinted background of the icon container — set by the rule/provider layer.
  final Color iconBackgroundColor;
}
