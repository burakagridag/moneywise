// Abstract InsightProvider interface — insights feature domain layer.
import 'insight.dart';
import 'insight_context.dart';

/// Generates a list of [Insight] observations from a pre-assembled
/// [InsightContext] snapshot.
///
/// V1 binding: [RuleBasedInsightProvider].
/// V2 binding: An AI-driven provider injected via
/// `insightProviderInstanceProvider.overrideWith(...)` at app startup —
/// zero UI or scaffold code changes required.
abstract class InsightProvider {
  /// Evaluates all registered rules (or queries an AI endpoint) and returns
  /// the resulting insights in display-ready order.
  ///
  /// Must be pure and synchronous — all async data is pre-loaded in [context].
  List<Insight> generate(InsightContext context);
}
