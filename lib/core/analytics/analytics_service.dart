// AnalyticsService abstract interface + stub — core analytics layer (EPIC8A-12).
// Logs events to debugPrint in debug mode only; swappable for Firebase Analytics via Riverpod.
// See ADR-012 for design rationale.
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analytics_service.g.dart';

/// Abstract analytics contract.
///
/// All call sites depend on this interface. Swap the [analyticsServiceProvider]
/// override with a Firebase-backed implementation in a future sprint without
/// changing any call site.
///
/// V1 event registry (ADR-012):
/// - `home_tab_viewed`   — HomeScreen first mount (fire-once via `_didLogTabView`)
/// - `insight_card_tapped` — InsightCard tap; parameter: `insight_type: String`
///
/// Usage:
/// ```dart
/// ref.read(analyticsServiceProvider).logEvent('home_tab_viewed');
/// ```
abstract interface class AnalyticsService {
  /// Logs [name] and optional [parameters] to the analytics backend.
  void logEvent(String name, {Map<String, dynamic>? parameters});
}

/// V1 stub implementation — logs to [debugPrint] in debug mode only.
///
/// In release and profile builds this is a true no-op with zero overhead.
class StubAnalyticsService implements AnalyticsService {
  @override
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint(
        '[Analytics] $name${parameters != null ? ' $parameters' : ''}',
      );
    }
  }
}

@riverpod
AnalyticsService analyticsService(AnalyticsServiceRef ref) =>
    StubAnalyticsService();
