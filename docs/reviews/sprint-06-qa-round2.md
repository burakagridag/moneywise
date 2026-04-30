# Sprint 6 QA — Round 2 Verification Report

**Date:** 2026-04-30
**Tester:** qa-agent
**Branch:** claude/sharp-booth-8088e8
**Overall result:** CONDITIONAL PASS — 2 minor issues remain (P2/P3), no blockers

---

## Summary

| Feature | Criteria | Pass | Fail |
|---------|----------|------|------|
| Search (US-040) | 4 | 4 | 0 |
| Filter (US-041) | 4 | 3 | 1 |
| Bookmarks (US-042/043) | 5 | 4 | 1 |
| Settings (US-044) | 4 | 4 | 0 |
| DailyView filter integration | 1 | 1 | 0 |

---

## Feature 1: Search (US-040)

### AC-1: TransactionSearchBar shows when search icon is tapped
**Result: PASS**

`TransactionsScreen` holds `_showSearchBar` as local state (line 41). The search icon in the AppBar `leading` slot calls `_toggleSearchBar()` (line 67–69), which flips `_showSearchBar`. `TransactionSearchBar` receives `isVisible: _showSearchBar` (line 153). `didUpdateWidget` triggers `_animController.forward()` when `isVisible` becomes true. Correct.

### AC-2: Search bar updates searchQueryNotifierProvider on text change
**Result: PASS**

`_onChanged` in `_TransactionSearchBarState` (line 71–76) fires a 300ms debounced call to `ref.read(searchQueryNotifierProvider.notifier).setQuery(value)`. The debounce is correctly cancelled before re-arming on each keystroke. Correct.

### AC-3: Search bar clears query when hidden
**Result: PASS**

`didUpdateWidget` calls `_animController.reverse().whenComplete(_clearSearch)` when `isVisible` goes false (line 53). `_clearSearch` (line 66–69) calls `_controller.clear()` and `ref.read(searchQueryNotifierProvider.notifier).clear()`. Provider is reset to empty string before the animation completes. Correct.

### AC-4: filteredTransactionsProvider correctly filters by query
**Result: PASS**

`filteredTransactionsProvider` (line 120–135 of `search_filter_provider.dart`) watches `searchQueryNotifierProvider`, `transactionFilterNotifierProvider`, and `selectedPeriodNotifierProvider`. The `applySearchFilter` function (line 142–182) matches the query case-insensitively against description, category name, and account name. Logic is sound and correct.

---

## Feature 2: Filter (US-041)

### AC-1: Filter modal opens from filter icon in AppBar
**Result: PASS**

`TransactionsScreen` has an `Icons.tune` `IconButton` in AppBar `actions` (lines 137–146) that calls `_showFilterSheet(context)` (line 80–87), which opens `FilterBottomSheet` as a modal bottom sheet. Correct.

### AC-2: _apply() preserves existing search query (search and filter are separate providers)
**Result: PASS**

`_apply()` in `FilterBottomSheet` (lines 67–78) only reads/writes `transactionFilterNotifierProvider`. It never touches `searchQueryNotifierProvider`. The two providers are independent. `filteredTransactionsProvider` watches both and applies both predicates. No interference. Correct.

### AC-3: Reset works
**Result: PASS**

`_reset()` (lines 80–86) resets local widget state (`_types`, `_categoryId`, `_dateRange`) to empty/null. This only resets the sheet's local draft state — the user must still tap Apply to commit. This is the correct UX pattern. Pressing Reset then Apply will call `notifier.reset()` followed by no-ops for empty types/null values, resulting in a clean `TransactionFilter()`. Correct.

### AC-4: apply(TransactionFilter) bulk method exists in TransactionFilterNotifier
**Result: FAIL (P2 — minor)**

`TransactionFilterNotifier.apply(TransactionFilter)` is defined in `search_filter_provider.dart` (line 104). However, `FilterBottomSheet._apply()` does NOT use it. Instead it calls `notifier.reset()` then `notifier.toggleType(t)` for each type, then `setCategoryId`, then `setDateRange` — which is 2-to-5 sequential state mutations triggering up to 5 rebuilds of `filteredTransactionsProvider` on a single tap. While this produces the correct final state, it is inefficient and causes unnecessary intermediate UI flickers (the list may briefly show "no results" between reset and the first toggleType call).

The `apply()` method was introduced precisely to fix this in a single atomic state update. It should be used here.

**Reproduction:** Open filter sheet, select all three types, a category, and a date range, then tap Apply. The transaction list will flicker through 4-5 intermediate states before settling.

**Expected:** `_apply()` should construct a `TransactionFilter(types: _types, categoryId: _categoryId, dateRange: _dateRange)` and call `notifier.apply(filter)` once, then pop.

---

## Feature 3: Bookmarks (US-042, US-043)

### AC-1: /more/bookmarks route is registered in app_router.dart
**Result: PASS**

`app_router.dart` lines 96–99 define a `GoRoute(path: 'bookmarks', builder: ... BookmarksScreen())` nested under the `/more` branch. `Routes.bookmarks` is defined as `'/more/bookmarks'` in `routes.dart` (line 26). Used correctly in `MoreScreen` and `BookmarkPickerModal`. Correct.

### AC-2: Bookmarks ListTile is present in more_screen.dart
**Result: PASS**

`MoreScreen` (lines 25–30) has a `ListTile` with `Icons.bookmark_outline`, title `l10n.bookmarks`, and `onTap: () => context.push(Routes.bookmarks)`. Correct.

### AC-3: BookmarksScreen has a proper error state (not raw e.toString())
**Result: PASS**

`BookmarksScreen` error branch (lines 40–60) renders `l10n.errorLoadTitle` with a retry button calling `ref.invalidate(bookmarksStreamProvider)`. No raw `e.toString()`. Correct.

### AC-4: BookmarkPickerModal navigates to TransactionAddEditScreen with prefillBookmark correctly (not passing Bookmark as Transaction)
**Result: PASS**

`_useBookmark()` in `BookmarkPickerModal` (lines 120–123) calls `context.push(Routes.transactionAddEdit, extra: bookmark)`. In `app_router.dart` (lines 38–44), the router checks `if (extra is Bookmark)` first and routes to `TransactionAddEditScreen(prefillBookmark: extra)`. The `Transaction` cast only runs for the else branch. This is the correct type-safe pattern. Correct.

### AC-5: BookmarkPickerModal error state uses raw e.toString()
**Result: FAIL (P3 — cosmetic/minor)**

`BookmarkPickerModal` error branch (lines 77–81) still renders `e.toString()` directly to the user. This exposes internal exception messages (e.g., Drift database errors, stack trace prefixes) to the end user and is a UX concern. The fix applied to `BookmarksScreen` was not applied here.

**Affected code:** `bookmark_picker_modal.dart`, lines 77–81.

**Expected:** Replace `e.toString()` with `l10n.errorLoadTitle` and add a retry mechanism consistent with `BookmarksScreen`.

---

## Feature 4: Settings (US-044)

### AC-1: ThemePickerTile, CurrencyPickerTile, LanguagePickerTile rendered in SettingsScreen
**Result: PASS**

`SettingsScreen.build()` (lines 26–29) renders all three tiles: `const ThemePickerTile()`, `const CurrencyPickerTile()`, `const LanguagePickerTile()`. Each is implemented in `settings_tiles.dart`. Correct.

### AC-2: AppPreferencesNotifier safely initializes SharedPreferences (no raw _prefs! before build)
**Result: PASS**

`_prefs` is assigned at the start of `build()` (line 94), before `_safePrefs` is called (line 96). All three mutator methods (`setThemeMode`, `setCurrencyCode`, `setLanguageCode`) access `_safePrefs` only, which asserts `_prefs != null`. Since Riverpod's `AsyncNotifier` guarantees `build()` completes before any method can be called from outside, the guard is sound. No raw `_prefs!` access anywhere. Correct.

### AC-3: locale is wired from languageCode in app.dart
**Result: PASS**

`app.dart` (lines 18–21) derives `locale` from `prefs.whenOrNull(data: (p) => p.languageCode.isNotEmpty ? Locale(p.languageCode) : null)` and passes it to `MaterialApp.router(locale: locale, ...)`. Changing language in `LanguagePickerTile` calls `setLanguageCode`, which updates `appPreferencesNotifierProvider`, which triggers a rebuild of `MoneyWiseApp`, which propagates the new `Locale`. Correct.

### AC-4: themeMode correctly drives MaterialApp.router(themeMode: ...)
**Result: PASS**

`app.dart` (lines 16–17) reads `themeMode` from `prefs.whenOrNull(data: (p) => p.themeMode) ?? ThemeMode.system` and passes it to `MaterialApp.router(themeMode: themeMode, ...)`. `AppTheme.light` and `AppTheme.dark` are both provided via `theme:` and `darkTheme:`. The fallback to `ThemeMode.system` while prefs are loading is correct. Correct.

---

## DailyView Filter Integration

### AC: DailyView watches filteredTransactionsProvider (not the monthly raw provider)
**Result: PASS**

`DailyView.build()` (line 27) calls `ref.watch(filteredTransactionsProvider)`. It imports `search_filter_provider.dart` (line 16). The raw monthly provider is not referenced. Correct.

---

## Blocking Bugs

None. Both remaining issues are non-blocking.

---

## Non-Blocking Issues Found

### ISSUE-1 (P2): FilterBottomSheet._apply() causes multiple sequential state mutations instead of a single atomic apply
**File:** `lib/features/transactions/presentation/widgets/filter_bottom_sheet.dart`, lines 67–78
**Impact:** The transaction list flickers through intermediate filter states on Apply when multiple filter criteria are active. Functionally correct, visually noisy.
**Fix:** Construct a `TransactionFilter` from local state and call `notifier.apply(filter)` once, then pop.

```dart
void _apply() {
  ref.read(transactionFilterNotifierProvider.notifier).apply(
    TransactionFilter(
      types: _types,
      categoryId: _categoryId,
      dateRange: _dateRange,
    ),
  );
  Navigator.of(context).pop();
}
```

### ISSUE-2 (P3): BookmarkPickerModal error state exposes raw exception message
**File:** `lib/features/transactions/presentation/widgets/bookmark_picker_modal.dart`, lines 77–81
**Impact:** On a database error, the user sees a raw Dart/Drift exception string instead of a localized message. No retry option.
**Fix:** Replace `e.toString()` with `l10n.errorLoadTitle` and add a retry button matching the pattern in `BookmarksScreen`.

---

## Edge Case Observations

1. **Filter + Search interaction with empty results:** When both a search query and a filter are active, and the result set is empty, `DailyView` shows the empty state widget. This is correct behavior, but there is no visual indication to the user that active filters/search are the cause. This is an acceptable UX gap for V1.

2. **BookmarkAddEditSheet — category not pre-populated in edit mode:** `_selectedCategory` is `null` on `initState` even when `widget.existing?.categoryId` is set. The category is not rehydrated from the database. This means editing a bookmark shows no category selected even if one was saved. This is a pre-existing limitation, not introduced in Round 2 fixes, and should be filed as a separate story.

3. **_apply() reset + toggleType atomicity:** Between `notifier.reset()` and the first `notifier.toggleType(t)`, the filter is transiently empty. If `filteredTransactionsProvider` rebuilds mid-sequence (Dart microtask boundary), the list could flash with all transactions. This directly relates to ISSUE-1 above.

4. **AppPreferencesNotifier.setThemeMode/setCurrencyCode/setLanguageCode do not await before updating state:** Each method calls `await _safePrefs.setString(...)` then synchronously updates state. If SharedPreferences write fails (unlikely but possible), the in-memory state diverges from persisted state. For V1 this is acceptable.

---

## Regression Check

- Search and filter providers are independent: confirmed
- DailyView watches filtered provider: confirmed
- Router handles Bookmark vs Transaction extra correctly: confirmed
- Settings changes propagate to MaterialApp: confirmed
- Bookmarks CRUD screen has safe error handling: confirmed (BookmarksScreen only; BookmarkPickerModal still has raw error string)

---

## Overall Recommendation

**Ready to merge with the following conditions:**

1. ISSUE-1 (P2 — FilterBottomSheet._apply uses bulk apply): Should be fixed before merge. The fix is a 5-line change and eliminates intermediate list flickers.
2. ISSUE-2 (P3 — BookmarkPickerModal raw error string): Can be fixed in a follow-up patch or immediately — trivial change.

All Round 1 bugs are confirmed fixed. No regressions detected. No blockers.
