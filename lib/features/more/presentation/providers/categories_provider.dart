// Riverpod providers exposing category streams and write operations to the UI — more feature.
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/entities/category.dart';

part 'categories_provider.g.dart';

/// Emits a reactive list of non-deleted income categories.
@riverpod
Stream<List<Category>> incomeCategories(IncomeCategoriesRef ref) =>
    ref.watch(categoryRepositoryProvider).watchByType('income');

/// Emits a reactive list of non-deleted expense categories.
@riverpod
Stream<List<Category>> expenseCategories(ExpenseCategoriesRef ref) =>
    ref.watch(categoryRepositoryProvider).watchByType('expense');

/// Notifier that exposes write operations for categories.
/// Screens must use this notifier instead of importing the repository directly.
@riverpod
class CategoryWriteNotifier extends _$CategoryWriteNotifier {
  @override
  void build() {}

  /// Persists a new [category] via the repository.
  Future<void> addCategory(Category category) =>
      ref.read(categoryRepositoryProvider).addCategory(category);

  /// Updates an existing [category] via the repository.
  Future<void> updateCategory(Category category) =>
      ref.read(categoryRepositoryProvider).updateCategory(category);

  /// Soft-deletes the category with the given [id] via the repository.
  Future<void> deleteCategory(String id) =>
      ref.read(categoryRepositoryProvider).deleteCategory(id);
}
