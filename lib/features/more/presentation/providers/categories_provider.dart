// Riverpod providers exposing category streams to the UI — more feature.
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
