// Riverpod providers driving per-card visibility in EmptyStateCards — home feature (EPIC8A-10).
// Each provider independently tracks a single completion condition so cards
// auto-dismiss as soon as the user completes the corresponding onboarding action.
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../data/local/database.dart';
import '../../../../data/repositories/account_repository.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../budget/domain/budget_entity.dart';
import 'user_settings_providers.dart';

part 'empty_state_provider.g.dart';

/// Emits the total count of non-deleted transactions across all accounts.
///
/// The "Add your first transaction" card is shown when this emits 0 and hidden
/// as soon as it emits > 0.
///
/// Uses [TransactionDao.watchTransactionCount] — a single SQL COUNT aggregate
/// over the transactions table — to avoid the 3-table JOIN and 1 000-row
/// fetch that [watchAllWithDetails] would incur just to derive a head count.
@riverpod
Stream<int> totalTransactionCount(TotalTransactionCountRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.transactionDao.watchTransactionCount();
}

/// Emits the total count of non-deleted accounts.
///
/// The "Manage your accounts" card is shown when this emits 0 and hidden as
/// soon as at least one account exists (user has set up their financial profile).
@riverpod
Stream<int> userAccountCount(UserAccountCountRef ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAccounts().map((list) => list.length);
}

/// Emits `true` when the user has configured any budget — either a global
/// monthly budget ceiling OR at least one active category budget with amount > 0.
///
/// The "Set a monthly budget" onboarding card is hidden whenever this emits
/// `true` and shown only when both sources are absent.
///
/// Combines two reactive sources:
///   1. [UserSettingsRepository.watchGlobalBudget] — non-null means global budget set
///   2. [BudgetRepository.watchBudgetsForMonth] for the current month — any row with
///      amount > 0 means a category budget exists
///
/// Both streams are merged into a single [StreamController] so the result
/// updates whenever either source fires. The current month is computed once at
/// subscription time; the provider is auto-disposed and recreated on next watch.
@riverpod
Stream<bool> hasBudgetConfigured(HasBudgetConfiguredRef ref) {
  final settingsRepo = ref.watch(userSettingsRepositoryProvider);
  final budgetRepo = ref.watch(budgetRepositoryProvider);

  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);

  // Track last-known values from each source so any update to either
  // recalculates and emits the combined bool.
  double? lastGlobal;
  List<BudgetEntity> lastCategory = const [];
  bool globalReady = false;
  bool categoryReady = false;

  final controller = StreamController<bool>();

  void emit() {
    if (!globalReady || !categoryReady) return;
    final hasGlobal = lastGlobal != null;
    final hasCategory = lastCategory.any((b) => b.amount > 0);
    controller.add(hasGlobal || hasCategory);
  }

  final globalSub = settingsRepo.watchGlobalBudget().listen(
    (value) {
      lastGlobal = value;
      globalReady = true;
      emit();
    },
    onError: controller.addError,
  );

  final categorySub = budgetRepo.watchBudgetsForMonth(currentMonth).listen(
    (value) {
      lastCategory = value;
      categoryReady = true;
      emit();
    },
    onError: controller.addError,
  );

  controller.onCancel = () async {
    await globalSub.cancel();
    await categorySub.cancel();
    await controller.close();
  };

  return controller.stream;
}
