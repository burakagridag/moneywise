// Mutation signal provider for the transactions feature.
// Incremented on any add / edit / delete so the Home tab can invalidate
// insightsProvider without depending on the routing layer.
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_mutation_signal_provider.g.dart';

/// A monotonically increasing counter that is incremented whenever a
/// transaction is successfully added, edited, or deleted.
///
/// The Home tab listens to this provider via [ref.listen] and invalidates
/// [insightsProvider] on each increment — implementing the Tab Focus
/// Invalidation mechanism required by ADR-011 §Reactive Behaviour.
///
/// Consumers must never reset this counter; only [increment] is public.
@riverpod
class TransactionMutationSignal extends _$TransactionMutationSignal {
  @override
  int build() => 0;

  /// Call after any successful transaction mutation (add / edit / delete).
  void increment() => state++;
}
