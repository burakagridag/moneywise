# Story EPIC8A-09 — RecentTransactionsList Component

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-03, EPIC8A-UX
**Phase:** 2

## Description

Implement the `RecentTransactionsList` widget for the Home tab. The component shows at most 2 of the user's most recent transactions, with a section header containing a "All →" link to the Transactions tab. The widget accepts up to 5 transactions but renders only the first 2 (most recent first). When the transaction list is empty, the entire section is hidden — the Empty State (EPIC8A-10) handles that scenario.

Each transaction row reuses the existing `TransactionRow` widget (already present in `lib/features/transactions/presentation/widgets/transaction_row.dart`) with a `compact: true` prop. If that prop does not exist yet, the engineer must add it to `TransactionRow` in a backwards-compatible way (default `compact: false`).

Row tap navigates to the existing transaction detail bottom sheet. The "All →" link calls `onSeeAllTap` which the `HomeScreen` wires to `context.go(AppRoutes.transactions)`.

Data is sourced from a new `recentTransactionsProvider` that returns the latest 5 non-deleted transactions across all accounts.

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — RecentTransactionsList section
- `docs/designs/home-tab/redlines.md` — row layout: 32×32 icon container, inset divider at 54dp from left
- `lib/features/transactions/presentation/widgets/transaction_row.dart` — existing widget to reuse or extend
- `lib/features/transactions/` — transaction providers and entity
- `lib/features/home/presentation/screens/home_screen.dart` — scaffold slot to fill
- `EPIC_home_tab_redesign_v2.md` Section "RecentTransactionsList"

## Outputs (agent must produce)

- `lib/features/home/presentation/widgets/recent_transactions_list.dart` — `RecentTransactionsList` widget (accepts `transactions: List<TransactionEntity>`, `onSeeAllTap: VoidCallback`)
- `lib/features/home/presentation/providers/recent_transactions_provider.dart` — `recentTransactionsProvider` (`StreamProvider<List<TransactionEntity>>`) returning latest 5 non-deleted transactions
- `lib/features/transactions/presentation/widgets/transaction_row.dart` — `compact` prop added if not already present
- `lib/features/home/presentation/screens/home_screen.dart` — RecentSection slot filled; hides section when list is empty
- `lib/l10n/app_en.arb` — `homeRecentAll` ("All"), `homeRecentTitle` ("Recent")
- `lib/l10n/app_tr.arb` — TR placeholders
- `test/features/home/widgets/recent_transactions_list_test.dart` — widget tests
- `docs/prs/epic8a-09.md`

## Acceptance Criteria

- [ ] Section is hidden when `transactions` list is empty
- [ ] When 1 transaction provided: 1 row rendered, no divider
- [ ] When 2+ transactions provided: exactly 2 rows rendered, inset divider between them
- [ ] Transactions rendered in most-recent-first order
- [ ] Row tap opens the transaction detail bottom sheet
- [ ] "All →" link tap fires `onSeeAllTap`; `HomeScreen` wires it to Transactions tab navigation
- [ ] `compact: true` on `TransactionRow` does not break existing Transactions tab list (`compact: false` default preserves current behavior)
- [ ] Section header shows "Recent" label
- [ ] No hardcoded colors; theme-aware
- [ ] All widget tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- Pagination or loading more than 2 items on the Home tab
- Swipe-to-delete from the Home tab
- Filtering by account or category
- Analytics events

## Quality Bar

The `compact` prop change to `TransactionRow` must be tested to confirm the existing Transactions tab widget tests still pass. The engineer must run all pre-existing `TransactionRow` tests and report results in the PR.
