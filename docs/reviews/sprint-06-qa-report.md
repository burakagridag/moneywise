# Sprint 6 QA Report
Date: 2026-04-30
Tester: qa-agent
Branch: sprint/06-more-search-bookmarks

---

## Verdict: FAIL

Sprint 6 delivery is INCOMPLETE. Three of nine user stories (US-031, US-032, US-033) have
acceptance criteria that cannot pass because the required screens and provider wiring are
either missing or are stub implementations from earlier sprints. Additionally, US-034,
US-035, US-036, and US-038 are partially implemented — providers and widgets exist, but
they are NOT wired into the UI, making the features unreachable by a user.

---

## Acceptance Criteria Results

| US | Scenario | Status | Note |
|----|----------|--------|------|
| US-031 | More tab opens settings menu with all sections | FAIL | MoreScreen has only one tile ("Settings"). No Section 1/2/3/4 grouping. No app version in corner. |
| US-031 | Each row navigates to its target screen | FAIL | Routes for /more/style, /more/language, /more/currency-main do not exist in routes.dart. |
| US-031 | Section separators visually group settings | FAIL | No sections exist; single flat ListTile. |
| US-032 | StyleScreen displays three theme options | FAIL | No StyleScreen exists. Theme selection is a SimpleDialog inside ThemePickerTile, accessible only via the Settings sub-screen, not via a dedicated route at /more/style. |
| US-032 | Selecting Dark Mode applies theme immediately | PARTIAL | ThemePickerTile + AppPreferencesNotifier correctly call setThemeMode() which updates SharedPreferences and sets AsyncData on the notifier. ThemeMode is read by MaterialApp via ref.watch. Immediate apply works IF the tile is reached. The StyleScreen route requirement fails. |
| US-032 | Theme persists across app restarts | PASS | SharedPreferences write is synchronous before state update. ThemeMode is read in build() on cold start. |
| US-032 | System Mode follows device appearance reactively | PASS | MaterialApp.themeMode = ThemeMode.system; Flutter handles reactive OS-level changes natively. |
| US-033 | CurrencyScreen opens with current currency highlighted | FAIL | No CurrencyScreen exists at route /more/currency-main. A simplified CurrencyPickerTile bottom sheet exists in settings_tiles.dart but is not exposed from MoreScreen. |
| US-033 | Searching filters the currency list | FAIL | The bottom sheet lists only 4 hardcoded currencies (EUR/USD/TRY/GBP) with no search bar. |
| US-033 | Selecting currency updates immediately and persists | PASS | setCurrencyCode() writes to SharedPreferences and updates provider state. |
| US-033 | Currency change does not alter stored transaction amounts | PASS | Only the preference key is changed; no migration is triggered on the transactions table. |
| US-034 | Tapping search icon opens search bar | FAIL | AppBar search IconButton onPressed is an empty comment: `// Sprint 6: Search modal`. TransactionSearchBar widget exists and is correct, but it is never shown. |
| US-034 | Typing returns matching transactions in real time | PARTIAL | applySearchFilter() logic is correct (description, categoryName, accountName). 300ms debounce is implemented in TransactionSearchBar. However, the bar is unreachable. |
| US-034 | Search returns no results state | UNKNOWN | Cannot reach the search bar; unverifiable. |
| US-034 | Tapping result navigates to transaction | FAIL | TransactionSearchBar has no result list; it only updates SearchQueryNotifier. No result list widget or navigation from search results is implemented. |
| US-034 | Clearing search resets results | PARTIAL | _clearSearch() in TransactionSearchBar correctly clears the controller and calls notifier.clear(). Correct when visible; unreachable otherwise. |
| US-035 | Tapping filter icon opens FilterModal | FAIL | AppBar filter IconButton onPressed is an empty comment: `// Sprint 6: Filter modal`. FilterBottomSheet widget exists and is correct but is never shown. |
| US-035 | Applying Type filter shows only matching transactions | PARTIAL | Logic in applySearchFilter() is correct. FilterBottomSheet _apply() correctly calls notifier methods. Unreachable from UI. |
| US-035 | Applying Category filter | PARTIAL | Single categoryId (not multi-select) supported in TransactionFilter — US-035 spec requires multi-select. FAIL on spec, PARTIAL on logic. |
| US-035 | Applying Date Range filter overrides month navigator | PARTIAL | Date range predicate is correct. Month navigator is NOT locked/hidden when date range is active — US-035 spec requires it to be. |
| US-035 | Clearing all filters restores full list | PASS | reset() on TransactionFilterNotifier sets const TransactionFilter() (all null/empty). Correct. |
| US-035 | Filter-active indicator on filter icon | FAIL | No badge or indicator is rendered on the filter icon in TransactionsScreen AppBar. activeCount getter exists in TransactionFilter but is never consumed by the AppBar widget. |
| US-036 | Search and active filters applied simultaneously | PARTIAL | filteredTransactions provider watches both searchQueryNotifierProvider and transactionFilterNotifierProvider; combined AND logic is correct in applySearchFilter(). Unreachable from UI. |
| US-036 | Clearing search while filters active preserves filters | PASS | _clearSearch() only calls searchQueryNotifier.clear(); filter state is independent. |
| US-036 | Clearing filters while search text entered preserves search | PASS | reset() on FilterNotifier does not touch SearchQueryNotifier. |
| US-037 | Bookmark icon visible on Add Transaction screen | FAIL | TransactionAddEditScreen AppBar has no bookmark icon. There is no "Save as Bookmark" flow from the transaction form. |
| US-037 | Saving bookmark creates record in bookmarks table | PARTIAL | BookmarkAddEditSheet (accessible from BookmarksScreen FAB) correctly creates a Bookmark and calls save(). The entry point from the transaction form is missing. |
| US-037 | Bookmark with optional amount (blank amount field) | PASS | Amount field is optional in BookmarkAddEditSheet; null stored correctly. |
| US-037 | Duplicate bookmark name warning | FAIL | No duplicate name check exists anywhere in BookmarkAddEditSheet or BookmarkRepository. A duplicate name silently creates a second record with a different UUID. |
| US-038 | BookmarkPickerModal opens from AppBar icon | FAIL | AppBar bookmark IconButton onPressed: `// Sprint 6: Bookmark modal`. Not wired. |
| US-038 | BookmarkPickerModal opens from secondary FAB | FAIL | Secondary FAB onPressed: `// Sprint 6: BookmarkPickerModal`. Not wired. |
| US-038 | Selecting bookmark opens Add Transaction pre-filled | PARTIAL | _useBookmark() calls context.push(Routes.transactionAddEdit, extra: bookmark). TransactionAddEditScreen does NOT accept a Bookmark as `extra` — it only accepts `Transaction?`. Pre-fill from bookmark is not implemented in the screen. |
| US-038 | Selecting bookmark with null amount leaves Amount empty | FAIL | The pre-fill path does not exist (see above). |
| US-038 | Using a bookmark increments useCount | FAIL | Bookmark entity has no useCount field. BookmarkDao has no increment method. BookmarkRepository has no useCount method. This feature is entirely missing from the data layer. |
| US-039 | BookmarksScreen accessible from More tab | FAIL | MoreScreen has no row navigating to BookmarksScreen. The route /more/bookmarks is defined in routes.dart but is not linked from MoreScreen or any navigation tile. |
| US-039 | Editing a bookmark updates fields | PASS | BookmarkAddEditSheet in edit mode (existing != null) pre-fills all fields and calls save() on upsert. Drift stream updates the list reactively. |
| US-039 | Deleting a bookmark removes it from list | PASS | Dismissible + confirmDelete + softDelete (isDeleted=true) implemented correctly. Row disappears from Drift reactive stream. |
| US-039 | Reordering via drag-and-drop updates sortOrder | FAIL | No ReorderableListView or drag-and-drop gesture is implemented in BookmarksScreen. ListView is non-reorderable. |

---

## Bugs Found

### P1 (Blocker)

**BUG-S6-001: Search, Filter, and BookmarkPickerModal are unreachable from the UI**
- File: `lib/features/transactions/presentation/screens/transactions_screen.dart` lines 91, 109, 124, 251, 262
- All three AppBar IconButtons and both FAB onPressed handlers are empty comments.
- TransactionSearchBar, FilterBottomSheet, and BookmarkPickerModal widgets all exist and are correct, but none are wired to their trigger points.
- Affects: US-034, US-035, US-036, US-038.

**BUG-S6-002: TransactionAddEditScreen does not accept Bookmark as pre-fill data**
- File: `lib/features/transactions/presentation/screens/transaction_add_edit_screen.dart`
- The screen constructor accepts only `Transaction? transaction`. BookmarkPickerModal calls `context.push(Routes.transactionAddEdit, extra: bookmark)` passing a `Bookmark` object, but the screen does not extract or use it.
- When a user selects a bookmark (once the picker is wired), the form will open completely blank.
- Affects: US-038 (Scenario: Selecting a bookmark opens Add Transaction pre-filled).

**BUG-S6-003: useCount feature entirely missing from data layer**
- US-038 requires that using a bookmark increments its useCount, and that the BookmarkPickerModal sorts by useCount descending.
- The `Bookmark` entity, `BookmarksTable`, `BookmarkDao`, and `BookmarkRepository` have no `useCount` column or increment logic.
- The DAO currently orders by `sortOrder ASC, createdAt DESC` — not by useCount.
- Affects: US-038 (Scenario: Using a bookmark increments its useCount; BookmarkPickerModal sort order).

**BUG-S6-004: Bookmark icon missing from TransactionAddEditScreen AppBar (US-037 entry point)**
- File: `lib/features/transactions/presentation/screens/transaction_add_edit_screen.dart`
- The AppBar actions list only contains a delete icon (edit mode). No bookmark icon exists.
- US-037 requires a bookmark icon in the AppBar of the Add Transaction screen to trigger "Save as Bookmark".
- Affects: US-037 (all scenarios).

**BUG-S6-005: MoreScreen missing required Settings structure and navigation entries**
- File: `lib/features/more/presentation/screens/more_screen.dart`
- MoreScreen renders a single "Settings" tile that goes to a flat SettingsScreen (categories only).
- US-031 requires 4 labelled sections with many rows. StyleScreen, CurrencyScreen, LanguageScreen, BookmarkManagement, and BudgetSetting rows are absent.
- Routes /more/style, /more/language, /more/currency-main are not defined in routes.dart.
- Affects: US-031 (all scenarios), US-032 (route requirement), US-033 (route requirement), US-039 (entry point).

### P2 (Major)

**BUG-S6-006: Category filter is single-select, not multi-select as required by US-035**
- File: `lib/features/transactions/presentation/providers/search_filter_provider.dart` line 35
- `TransactionFilter.categoryId` is a single `String?`, not a `Set<String>`.
- US-035 Scenario "Applying a Category filter" requires multi-select ("select categories 'Food' and 'Transport'").
- Affects: US-035, US-036.

**BUG-S6-007: Month navigator not locked/hidden when date range filter is active**
- File: `lib/features/transactions/presentation/screens/transactions_screen.dart`
- TransactionsScreen does not watch `transactionFilterNotifierProvider`. MonthNavigator is always visible regardless of filter state.
- US-035 requires: "the month navigator is visually locked or hidden while a date range filter is active".
- Affects: US-035 (Date Range scenario).

**BUG-S6-008: No filter-active badge on the filter icon in TransactionsScreen**
- File: `lib/features/transactions/presentation/screens/transactions_screen.dart` lines 119-128
- The filter IconButton does not show a badge or color change when filters are active.
- `TransactionFilter.activeCount` and `hasActiveFilter` getters exist but are never consumed in the AppBar.
- US-035 requires: "a filter-active indicator (e.g., badge or highlighted icon) appears on the filter icon".
- Affects: US-035.

**BUG-S6-009: Duplicate bookmark name produces silent duplicate record**
- File: `lib/features/transactions/presentation/widgets/bookmark_add_edit_sheet.dart`
- No duplicate-name check exists in BookmarkAddEditSheet._save() or BookmarkRepository.save().
- US-037 requires: "A bookmark named 'X' already exists. Save anyway?" warning dialog.
- Affects: US-037.

**BUG-S6-010: No drag-and-drop reorder in BookmarksScreen**
- File: `lib/features/transactions/presentation/screens/bookmarks_screen.dart`
- `ListView.separated` is used, not `ReorderableListView`. No long-press gesture or drag handle is implemented.
- US-039 scenario "Reordering bookmarks via drag-and-drop updates sortOrder" cannot be satisfied.
- Affects: US-039.

**BUG-S6-011: Language preference saved but not applied to MaterialApp locale**
- File: `lib/app.dart`
- `AppPreferencesNotifier.setLanguageCode()` correctly writes to SharedPreferences and updates provider state.
- However, `MoneyWiseApp.build()` does NOT read `languageCode` from `appPreferencesNotifierProvider` and does NOT set `locale:` on `MaterialApp.router`.
- The supported locales are hardcoded. Changing language in the picker has no visible effect.
- Affects: US-033 analog for language (no specific story, but impacts the Settings feature's correctness claim).

### P3 (Minor / Cosmetic)

**BUG-S6-012: Search text field does not match US-034 spec on result tapping**
- TransactionSearchBar is a bare TextField with debounce; it renders no result list.
- US-034 requires result rows with category emoji, account name, date, amount, and a highlighted matching substring.
- There is no result list widget at all; the search bar only pipes the query to the provider.
- This is covered by BUG-S6-001 (UI not wired) but also represents a widget-level gap.

**BUG-S6-013: BookmarkListItem does not show category emoji or account name**
- File: `lib/features/transactions/presentation/widgets/bookmark_list_item.dart`
- The subtitle shows only type chip + amount. US-038 picker spec requires "category emoji + account name" per row.
- categoryId and accountId are available on Bookmark entity but not displayed.
- Affects: US-038 (picker row content).

**BUG-S6-014: Bookmark name max-length (50 chars) not enforced**
- File: `lib/features/transactions/presentation/widgets/bookmark_add_edit_sheet.dart`
- The TextFormField for bookmark name has no `maxLength` property and no `LengthLimitingTextInputFormatter`.
- US-037 edge case requires: "Bookmark name max length: 50 characters — enforce with validation".
- Affects: US-037 edge case.

---

## Edge Case Analysis

| Edge Case | Status | Finding |
|-----------|--------|---------|
| Bookmark saved — form clears | N/A | Bookmark creation from transaction form (US-037 path) is not implemented. BookmarksScreen FAB opens a modal that closes on save; the Add Transaction form is unaffected. Correct for the standalone modal path. |
| Filter active — month change — filter resets | PASS | filteredTransactions provider re-subscribes to the new month's DB stream but filter state in TransactionFilterNotifier is independent; it is NOT reset on period change. This is the correct behavior per US-035 ("Filter state must survive the app going to background"). Month change does not clear filter. |
| Search + filter active simultaneously | PASS (logic) | applySearchFilter() applies all predicates in one pass with AND semantics. Not reachable from UI (BUG-S6-001). |
| Theme persists on restart | PASS | SharedPreferences write before provider state update; read on cold build(). |
| Bookmark deleted — picker modal updates reactively | PASS | BookmarkPickerModal watches bookmarksStreamProvider (a Drift reactive stream). Soft-delete triggers a new emission; the modal list updates without a restart. |
| Filter badge count correct | FAIL | activeCount getter logic is correct (1 point for types, 1 for categoryId, 1 for dateRange). Badge is never rendered in the UI (BUG-S6-008). |

---

## Regression Check (Sprint 5 Features)

No Sprint 5 code was modified in this sprint based on the files reviewed. The following
areas were checked by code analysis:

| Area | Status | Finding |
|------|--------|---------|
| Transactions CRUD (US-010 to US-019) | PASS | TransactionAddEditScreen, TransactionWriteNotifier, TransactionDao unchanged. |
| Budget Setting screen (US-029) | PASS | BudgetSettingScreen untouched; Routes.budgetSetting still defined. |
| Category management (US-007/008) | PASS | CategoryManagementScreen untouched. |
| Stats tab | PASS | StatsScreen, statsProvider untouched. |
| Accounts tab | PASS | AccountRepository, AccountDao untouched. |
| filteredTransactions provider — new dependency | RISK | filteredTransactions now watches selectedPeriodNotifierProvider (a Sprint 4 provider). If TransactionsScreen sub-views switch to filteredTransactions instead of the raw monthly stream, a latent regression is possible. Currently DailyView, CalendarView etc. were not checked for this change. Recommend flutter-engineer confirm no sub-view was silently switched to use filteredTransactions without the search/filter UI being active. |

---

## Summary for Flutter Engineer

The following work must be completed before Sprint 6 can be verified as Done:

1. Wire AppBar search icon to show/hide TransactionSearchBar (set `_searchVisible` state).
2. Implement a search result list below the search bar (category emoji, account name, date, amount, highlight matched substring).
3. Wire AppBar filter icon to `showModalBottomSheet(FilterBottomSheet)`.
4. Wire AppBar bookmark icon and secondary FAB to `showModalBottomSheet(BookmarkPickerModal)`.
5. Add `useCount` column to bookmarks table (migration), domain entity, DAO increment method, and repository. Call increment on successful transaction save from a bookmark.
6. Update BookmarkPickerModal sort to order by useCount DESC.
7. Update TransactionAddEditScreen to accept `Bookmark` as `extra` and pre-fill form fields.
8. Add bookmark icon to TransactionAddEditScreen AppBar with Save-as-Bookmark flow.
9. Implement duplicate bookmark name warning in BookmarkAddEditSheet.
10. Expand MoreScreen to render the full 4-section list per US-031 spec and add routes for /more/style, /more/language, /more/currency-main.
11. Build standalone StyleScreen (radio-style theme picker at the route level) per US-032.
12. Build standalone CurrencyScreen with search bar and full ISO 4217 list per US-033.
13. Wire `locale:` on MaterialApp.router to read `languageCode` from appPreferencesNotifierProvider.
14. Change `TransactionFilter.categoryId` to `Set<String> categoryIds` and update the predicate and FilterBottomSheet UI for multi-select.
15. Lock/hide MonthNavigator when a date range filter is active.
16. Render a badge on the filter icon when `filter.hasActiveFilter`.
17. Implement `ReorderableListView` in BookmarksScreen for drag-and-drop sortOrder updates.
18. Add `LengthLimitingTextInputFormatter(50)` to the bookmark name field.
19. Show category emoji and account name in BookmarkListItem rows.
20. Add a BookmarksScreen navigation row to MoreScreen.
