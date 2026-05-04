// Unit tests for TransactionFilter pure logic and SearchFilterNotifier — features/transactions.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/features/transactions/presentation/providers/search_filter_provider.dart';

void main() {
  group('TransactionFilter', () {
    test('isEmpty returns true for default filter', () {
      const filter = TransactionFilter();
      expect(filter.isEmpty, isTrue);
    });

    test('isEmpty returns false when query is set', () {
      const filter = TransactionFilter(query: 'coffee');
      expect(filter.isEmpty, isFalse);
    });

    test('isEmpty returns false when type is set', () {
      const filter = TransactionFilter(type: 'expense');
      expect(filter.isEmpty, isFalse);
    });

    test('isEmpty returns false when categoryId is set', () {
      const filter = TransactionFilter(categoryId: 'cat-1');
      expect(filter.isEmpty, isFalse);
    });

    test('isEmpty returns false when amountMin is set', () {
      const filter = TransactionFilter(amountMin: 10.0);
      expect(filter.isEmpty, isFalse);
    });

    test('copyWith preserves unset nullable fields as null (sentinel pattern)',
        () {
      const original = TransactionFilter(type: 'expense', categoryId: null);
      final copy = original.copyWith(query: 'test');
      expect(copy.type, equals('expense'));
      expect(copy.categoryId, isNull);
      expect(copy.query, equals('test'));
    });

    test('copyWith can explicitly set nullable field to null', () {
      const original = TransactionFilter(type: 'income');
      final copy = original.copyWith(type: null);
      expect(copy.type, isNull);
    });

    test('equality works for identical filters', () {
      const a = TransactionFilter(query: 'food', type: 'expense');
      const b = TransactionFilter(query: 'food', type: 'expense');
      expect(a, equals(b));
    });

    test('equality distinguishes different filters', () {
      const a = TransactionFilter(type: 'income');
      const b = TransactionFilter(type: 'expense');
      expect(a, isNot(equals(b)));
    });
  });

  group('SearchFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('initial state is empty filter', () {
      final state = container.read(searchFilterNotifierProvider);
      expect(state.isEmpty, isTrue);
    });

    test('setQuery updates query', () {
      container.read(searchFilterNotifierProvider.notifier).setQuery('coffee');
      expect(
          container.read(searchFilterNotifierProvider).query, equals('coffee'));
    });

    test('clearQuery resets query to empty', () {
      container.read(searchFilterNotifierProvider.notifier).setQuery('food');
      container.read(searchFilterNotifierProvider.notifier).clearQuery();
      expect(container.read(searchFilterNotifierProvider).query, isEmpty);
    });

    test('apply replaces the entire filter atomically', () {
      const newFilter = TransactionFilter(
        type: 'expense',
        query: 'grocery',
        amountMin: 5.0,
      );
      container.read(searchFilterNotifierProvider.notifier).apply(newFilter);
      final state = container.read(searchFilterNotifierProvider);
      expect(state.type, equals('expense'));
      expect(state.query, equals('grocery'));
      expect(state.amountMin, equals(5.0));
    });

    test('reset clears all filters', () {
      container.read(searchFilterNotifierProvider.notifier).apply(
            const TransactionFilter(type: 'income', query: 'salary'),
          );
      container.read(searchFilterNotifierProvider.notifier).reset();
      expect(container.read(searchFilterNotifierProvider).isEmpty, isTrue);
    });
  });
}
