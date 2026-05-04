// Unit tests for BookmarkRepository using in-memory Drift database — data feature.
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/database.dart';
import 'package:moneywise/data/repositories/bookmark_repository.dart';
import 'package:moneywise/domain/entities/bookmark.dart' as domain;

({ProviderContainer container, AppDatabase db, BookmarkRepository repo})
    _buildSetup() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWith((_) => db)],
  );
  addTearDown(db.close);
  addTearDown(container.dispose);
  final repo = container.read(bookmarkRepositoryProvider);
  return (container: container, db: db, repo: repo);
}

domain.Bookmark _bookmark({
  String id = 'bm-1',
  String name = 'Coffee',
  String type = 'expense',
  double? amount = 4.5,
  String? note = 'Daily coffee',
}) {
  final now = DateTime.now();
  return domain.Bookmark(
    id: id,
    name: name,
    type: type,
    amount: amount,
    note: note,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BookmarkRepository', () {
    test('add and getAll returns the inserted bookmark', () async {
      final (:container, db: _, :repo) = _buildSetup();
      addTearDown(container.dispose);
      final b = _bookmark();
      await repo.add(b);
      final all = await repo.getAll();
      expect(all.length, equals(1));
      expect(all.first.name, equals('Coffee'));
      expect(all.first.amount, equals(4.5));
    });

    test('update replaces the existing bookmark', () async {
      final (:container, db: _, :repo) = _buildSetup();
      addTearDown(container.dispose);
      final b = _bookmark();
      await repo.add(b);

      final updated = b.copyWith(name: 'Espresso', amount: 3.0);
      await repo.update(updated);

      final all = await repo.getAll();
      expect(all.length, equals(1));
      expect(all.first.name, equals('Espresso'));
      expect(all.first.amount, equals(3.0));
    });

    test('delete removes the bookmark', () async {
      final (:container, db: _, :repo) = _buildSetup();
      addTearDown(container.dispose);
      final b = _bookmark();
      await repo.add(b);
      await repo.delete(b.id);
      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    test('watchAll emits updates on add', () async {
      final (:container, db: _, :repo) = _buildSetup();
      addTearDown(container.dispose);
      final stream = repo.watchAll();

      final events = <List<domain.Bookmark>>[];
      final sub = stream.listen(events.add);

      await Future.delayed(Duration.zero);
      await repo.add(_bookmark(id: 'bm-1', name: 'Coffee'));
      await Future.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.last.length, equals(1));
    });

    test('copyWith sentinel preserves null amount', () {
      final b = _bookmark(amount: null);
      final copy = b.copyWith(name: 'Tea');
      expect(copy.amount, isNull);
      expect(copy.name, equals('Tea'));
    });

    test('copyWith can explicitly set amount to null', () {
      final b = _bookmark(amount: 5.0);
      final copy = b.copyWith(amount: null);
      expect(copy.amount, isNull);
    });
  });
}
