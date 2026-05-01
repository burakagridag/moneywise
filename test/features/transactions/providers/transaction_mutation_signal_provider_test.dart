// Unit tests for TransactionMutationSignal provider — transactions feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/transactions/presentation/providers/transaction_mutation_signal_provider.dart';

void main() {
  group('TransactionMutationSignal provider', () {
    test('starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(transactionMutationSignalProvider), 0);
    });

    test('increments to 1 after the first call', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(transactionMutationSignalProvider.notifier).increment();

      expect(container.read(transactionMutationSignalProvider), 1);
    });

    test('increments monotonically over multiple calls', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(transactionMutationSignalProvider.notifier).increment();
      container.read(transactionMutationSignalProvider.notifier).increment();
      container.read(transactionMutationSignalProvider.notifier).increment();

      expect(container.read(transactionMutationSignalProvider), 3);
    });

    test('each independent ProviderContainer starts at 0', () {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      containerA.read(transactionMutationSignalProvider.notifier).increment();

      expect(containerA.read(transactionMutationSignalProvider), 1);
      expect(containerB.read(transactionMutationSignalProvider), 0);
    });

    test('listener fires on each increment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final observed = <int>[];
      container.listen(
        transactionMutationSignalProvider,
        (_, next) => observed.add(next),
        fireImmediately: false,
      );

      container.read(transactionMutationSignalProvider.notifier).increment();
      container.read(transactionMutationSignalProvider.notifier).increment();

      expect(observed, [1, 2]);
    });
  });
}
