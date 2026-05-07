// InsightViewModel — insights feature presentation layer.
// Wraps a pure-domain [Insight] with Flutter SDK icon/color and localized
// headline/body for rendering in [InsightCard].
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/insight.dart';

/// Presentation-layer wrapper that enriches an [Insight] domain entity with
/// Flutter SDK types (icon, colors) and locale-resolved strings for [InsightCard].
///
/// [headline] and [body] override the domain entity strings when provided,
/// allowing the mapper to supply ARB-localized copies without touching the domain.
class InsightViewModel {
  const InsightViewModel({
    required this.insight,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    String? headline,
    String? body,
  })  : _headlineOverride = headline,
        _bodyOverride = body;

  /// The underlying pure-domain entity.
  final Insight insight;

  /// Icon to render in the 36×36dp container.
  final IconData icon;

  /// Icon stroke/fill color.
  final Color iconColor;

  /// Tinted background of the icon container.
  final Color iconBackgroundColor;

  // Nullable overrides — set by the mapper when ARB strings are available.
  final String? _headlineOverride;
  final String? _bodyOverride;

  // ---------------------------------------------------------------------------
  // Convenience getters — prefer localized overrides over domain strings.
  // ---------------------------------------------------------------------------

  String get id => insight.id;
  InsightSeverity get severity => insight.severity;

  /// Localized headline when available; falls back to domain insight headline.
  String get headline => _headlineOverride ?? insight.headline;

  /// Localized body when available; falls back to domain insight body.
  String get body => _bodyOverride ?? insight.body;

  String? get actionRoute => insight.actionRoute;

  // ---------------------------------------------------------------------------
  // Dark-mode correction — called from the widget layer where BuildContext is
  // available, allowing ThemeMode.system to resolve to actual device brightness.
  // ---------------------------------------------------------------------------

  /// Returns a new [InsightViewModel] with [iconBackgroundColor] re-computed
  /// for [isDark].
  ///
  /// The provider resolves [isDark] from the persisted ThemeMode preference,
  /// which cannot distinguish [ThemeMode.system] from light mode. Widgets call
  /// this method with `Theme.of(context).brightness == Brightness.dark` to
  /// ensure system dark-mode users always see the correct icon background.
  InsightViewModel copyWithDark(bool isDark) {
    final bg = switch (insight.severity) {
      InsightSeverity.critical => isDark
          ? AppColors.insightCriticalIconBgDark
          : AppColors.insightCriticalIconBg,
      InsightSeverity.warning => isDark
          ? AppColors.insightWarningIconBgDark
          : AppColors.insightWarningIconBg,
      InsightSeverity.info => isDark
          ? AppColors.insightNeutralIconBgDark
          : AppColors.insightNeutralIconBg,
    };
    return InsightViewModel(
      insight: insight,
      icon: icon,
      iconColor: iconColor,
      iconBackgroundColor: bg,
      headline: _headlineOverride,
      body: _bodyOverride,
    );
  }
}
