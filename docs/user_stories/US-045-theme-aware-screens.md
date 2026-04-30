# US-045: Theme-Aware Screens (Full Light/Dark Support)

## Source
Product Sponsor request — all screens must honour the ThemeMode selection introduced in US-044 (Sprint 6).

## Persona
A MoneyWise user who prefers a light theme and has selected it in Settings,
but finds that every screen except Settings remains dark.

## Story
**As** a MoneyWise user
**I want** every screen and widget in the app to adapt its colours to the active
theme (light or dark)
**So that** my chosen theme preference is respected consistently across the entire app

---

## Background / Root Cause

The app was built dark-mode-first. `AppTheme.light` and `AppTheme.dark` are already
defined in `lib/core/theme/app_theme.dart`, and `MaterialApp.router` already reads
`themeMode` from `AppPreferencesNotifier`. The problem is that individual screens
and widgets bypass the theme by hardcoding `AppColors` dark-mode constants directly
(e.g., `AppColors.bgPrimary`, `AppColors.textPrimary`, `AppColors.bgSecondary`)
instead of reading from `Theme.of(context)`.

Known hardcoded sites include (non-exhaustive — flutter-engineer must audit the full
widget tree):

- `TransactionsScreen` — `Scaffold.backgroundColor`, `AppBar.backgroundColor`,
  icon colours all set to `AppColors.bgPrimary` / `AppColors.textSecondary`
- `IncomeSummaryBar` — `Container.color: AppColors.bgPrimary`
- `MonthNavigator` and sub-navigators — colour constants on background containers
- `DailyView`, `CalendarView`, `MonthlyView`, `SummaryView` — date-header rows,
  empty-state text, list tiles
- All bottom sheets and modal surfaces
- Stats, Budget, and Accounts feature screens (to be verified by engineer)
- `MoreScreen` relies on the AppBar theme (already correct) but any child widgets
  with explicit colours must be audited

The Settings screen works correctly today because it does not override background
colour — this is the reference implementation pattern for this story.

---

## Acceptance Criteria

```gherkin
Feature: Theme-aware screens

  Background:
    Given the user has completed onboarding
    And at least one account and one transaction exist

  Scenario: Transactions screen respects light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user navigates to the Trans. tab
    Then the Scaffold background is white (AppColors.bgPrimaryLight)
    And the AppBar background is white
    And all text colours use the light-mode palette (dark text on light background)
    And the IncomeSummaryBar background is white
    And the MonthNavigator background is white
    And the period tab bar indicators and labels use theme colours
    And the transaction list rows use light-mode surface and text colours

  Scenario: Stats screen respects light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user navigates to the Stats tab
    Then the Scaffold background and all card surfaces use light-mode colours
    And chart labels and legend text use the light-mode text palette

  Scenario: Budget screen respects light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user navigates to the Budget tab
    Then the Scaffold background and all budget card surfaces use light-mode colours
    And progress bar backgrounds and text use theme-appropriate colours

  Scenario: Accounts screen respects light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user navigates to the Accounts tab
    Then the Scaffold background and account card surfaces use light-mode colours

  Scenario: More screen respects light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user navigates to the More tab
    Then all list tiles, dividers, and icon colours adapt to the light theme

  Scenario: Bottom sheets and modals respect light theme
    Given the user has selected "Light" in Settings > Appearance
    When the user opens any bottom sheet (Add Transaction, Filter, Bookmark Picker,
    Category Picker, Account Picker, Budget edit)
    Then the sheet surface uses the light-mode surface colour
    And all text, icons, and input fields inside use light-mode colours

  Scenario: Dark theme continues to render correctly
    Given the user has selected "Dark" in Settings > Appearance
    When the user navigates through all tabs and opens modals
    Then every screen renders identically to the current dark-mode baseline

  Scenario: System theme — Light OS setting
    Given the user has selected "System" in Settings > Appearance
    And the device OS is set to Light mode
    When the user navigates through all tabs
    Then all screens use light-mode colours

  Scenario: System theme — Dark OS setting
    Given the user has selected "System" in Settings > Appearance
    And the device OS is set to Dark mode
    When the user navigates through all tabs
    Then all screens use dark-mode colours

  Scenario: Live theme switch — no restart required
    Given the user is on the Trans. tab in dark mode
    When the user navigates to Settings > Appearance and switches to "Light"
    And the user navigates back to the Trans. tab
    Then the Trans. tab immediately renders in light mode without an app restart

  Scenario: Theme persists across app restarts
    Given the user has selected "Light" in Settings > Appearance
    When the user force-quits and relaunches the app
    Then all screens open in light mode
```

---

## Edge Cases

- [ ] Screens that are loaded lazily (not yet in widget tree when theme switches) must
      re-render in the correct theme on first build — no stale dark colours
- [ ] `IndexedStack` children (DailyView, CalendarView, MonthlyView, SummaryView) that are
      off-screen must pick up the active theme when they become visible
- [ ] Empty states (no transactions, no budgets, no accounts) must use theme colours for
      their illustration text and iconography
- [ ] Error states (network / DB read failure widgets) must also honour the theme
- [ ] `CircularProgressIndicator` colour — currently hardcoded to `AppColors.brandPrimary`
      in `DailyView`; confirm brand primary is theme-invariant (it is, per `AppColors`) —
      no change needed, but must be verified
- [ ] Modal bottom sheets use `backgroundColor: Colors.transparent` and define their own
      container colour — each must be updated to read from `Theme.of(context).colorScheme.surface`
- [ ] `AppTypography` styles that hardcode text colours via `.copyWith(color: AppColors.xxx)`
      must be updated to use `Theme.of(context).colorScheme.onSurface` or equivalent token
      wherever the colour is theme-sensitive
- [ ] iOS `CupertinoDatePicker` / `CupertinoPicker` surfaces inside `MonthNavigator` must
      match the active theme (Cupertino requires explicit brightness setting)
- [ ] Chart palette colours (`AppColors.chartPalette`) are theme-invariant by design — no
      change needed, but must be confirmed not to clash on a white background (especially
      the white `neutral` entry `0xFFFFFFFF`)
- [ ] Divider colours hardcoded to `AppColors.divider` (dark) must switch to
      `Theme.of(context).dividerColor`
- [ ] `showModalBottomSheet` calls that pass hardcoded `backgroundColor` must be updated

---

## Out of Scope

- Changing the MoneyWise colour palette or brand colours
- Adding a new theme option beyond Light / Dark / System
- Per-screen theme overrides
- Chart data colours (the 8-colour `chartPalette` is theme-invariant by design)
- Any new screen or feature not yet built

---

## Affected Screens / Surface Areas (to be confirmed by flutter-engineer audit)

| Area | Likely hardcoded sites |
|------|----------------------|
| `TransactionsScreen` | Scaffold, AppBar, icon colours |
| `IncomeSummaryBar` | Container background, border colour |
| `MonthNavigator` | Container background, text colours |
| `_PeriodTabBar` | Tab indicator, label colours |
| `DailyView` date headers | Row background, text colours |
| `CalendarView` cells | Cell background, day text |
| `MonthlyView` rows | Row surfaces |
| `SummaryView` cards | Card surface, label text |
| `TransactionRow` | Row background, amount text |
| `FilterBottomSheet` | Sheet container, chip colours |
| `BookmarkPickerModal` | Sheet container |
| `Add/Edit Transaction modal` | All surfaces and inputs |
| Stats tab screens | Scaffold, card, chart container backgrounds |
| Budget tab screens | Scaffold, progress bar backgrounds, card surfaces |
| Accounts tab screens | Scaffold, account card surfaces |
| More tab sub-screens (Bookmarks, Settings sub-screens) | Any explicit colour overrides |

---

## Test Scenarios for QA

1. **Happy path — Light, iOS:** Switch to Light, visit every tab and open one modal per
   tab — confirm no dark remnants visible
2. **Happy path — Light, Android:** Same walkthrough on Android
3. **Happy path — Dark, iOS:** Confirm dark baseline is unchanged from pre-story behaviour
4. **Happy path — Dark, Android:** Same as above
5. **System auto — iOS:** Set OS to Light, set app to System — verify light rendering
6. **System auto — Android:** Set OS to Dark, set app to System — verify dark rendering
7. **Live switch:** Switch theme while on Trans. tab — verify instant update with no
   partial repaints or leftover dark/light fragments
8. **Persistence:** Kill and relaunch after each theme selection — verify selection survives
9. **Empty states:** Confirm empty-state screens (no transactions, no budgets, no accounts)
   render theme-correct colours in both modes
10. **Error states:** Trigger a DB error (or mock one) — confirm error widget colours honour
    the active theme
11. **Modals and bottom sheets:** Open every bottom sheet in light mode — confirm sheet
    surface, text, input fields, and buttons all use light-mode colours
12. **Cupertino picker:** Open the month/year picker inside MonthNavigator in light mode —
    confirm the picker background is not dark

---

## UX Spec
N/A — colour mapping is fully governed by the existing `AppTheme.light` and `AppTheme.dark`
definitions in `lib/core/theme/app_theme.dart`. No new design decisions are required; the
engineer must replace hardcoded `AppColors` constants with `Theme.of(context)` lookups.
The UX designer does not need to produce a new spec for this story.

---

## Estimate
M (3-5 days)

The bulk of the work is a mechanical audit-and-replace pass across the widget tree.
The risk is completeness — missing one hardcoded widget causes a visible regression in
light mode. A targeted widget-test suite per affected screen mitigates this.

---

## Dependencies

- **US-044** (Settings > Appearance — ThemeMode selector) — **Done (Sprint 6)**.
  `AppPreferencesNotifier` already persists and exposes the selected `ThemeMode`.
  `MaterialApp.router` already reads it. This story only touches the screens.
- No other unresolved dependencies.
