# Shared Components Inventory

This file is the canonical registry of reusable widgets that live in `lib/core/widgets/`. Every time a new shared widget is identified — either during spec authoring or implementation — it must be added here.

**Owner:** UX Designer (spec columns) + Flutter Engineer (file / implementation notes columns)
**Updated:** 2026-04-28

---

## Sprint 1 Components

| Component | File | Used In | Variants / Props | Notes |
|-----------|------|---------|-----------------|-------|
| `BottomTabScaffold` | `core/widgets/bottom_tab_scaffold.dart` | All screens (root shell) | — | Wraps 4 nested navigators. Owns the `BottomNavigationBar` / `NavigationBar`. Tab 1 label is dynamic (day.month). See SPEC-001. |
| `AppButton` | `core/widgets/app_button.dart` | All screens with CTAs | `primary` (filled `brandPrimary`, white text), `secondary` (outline `brandPrimary`, brand text), `ghost` (no border, brand text) | Height: 52dp (`AppHeights.button`). Radius: 10dp (`AppRadius.md`). Disabled: opacity 0.5. Shows `LoadingIndicator` (16dp, white) inline when in loading state. |
| `LoadingIndicator` | `core/widgets/loading_indicator.dart` | All async states, splash screen, `AppButton` loading state | `size` (default 24dp), `color` (default `AppColors.brandPrimary`) | Circular progress. Used both as a standalone overlay and inline within buttons. |

---

## Sprint 2 Components

| Component | File | Used In | Variants / Props | Notes |
|-----------|------|---------|-----------------|-------|
| `AccountGroupPickerSheet` | `features/accounts/presentation/widgets/account_group_picker_sheet.dart` | SPEC-005 (AccountAddEditScreen) | `selectedGroupId`, `onGroupSelected` callback | Slide-up `AppBottomSheet` listing all 11 account group types. Each row 56dp. Active row has `bgTertiary` bg + `brandPrimary` dot. Cancel button at bottom. See SPEC-005. |
| `ColorSwatchRow` | `core/widgets/color_swatch_row.dart` | SPEC-005, SPEC-006 (category add/edit) | `selectedColor`, `onColorChanged`, `swatchSize` (default 28dp) | Horizontal row of 10 preset color circles. Selected swatch has 2dp `textPrimary` ring. No custom hex in V1. |
| `EmojiPickerGrid` | `core/widgets/emoji_picker_grid.dart` | SPEC-006 (category add/edit sheet) | `selectedEmoji`, `onEmojiSelected`, `columns` (default 6) | Scrollable grid of curated emoji. Each cell 44dp. Selected cell has `brandPrimary` border 2dp + `bgTertiary` bg. |
| `CurrencySearchList` | `features/more/presentation/widgets/currency_search_list.dart` | SPEC-007 (Main + Sub currency screens) | `mode` (single/multi), `selectedCodes`, `onToggle`, `mainCurrencyCode` | Search bar + section-grouped list. Reused for both main and sub currency screens via `mode` param. |
| `SettingsRow` | `core/widgets/settings_row.dart` | SPEC-004 (edit mode), SPEC-005 (form rows), SPEC-006, SPEC-007 | `label`, `value`, `onTap`, `trailing` (chevron / toggle / check / lock) | Standard 56dp form/settings row. Label left (`textSecondary`), value right (`textPrimary`), optional trailing widget. Divider at bottom. Min tap target 44x44dp. |
| `AccountListItem` | `features/accounts/presentation/widgets/account_list_item.dart` | SPEC-004 (AccountsScreen list) | `account`, `onTap`, `onHide`, `onDelete`, `showSwipeActions` | 56dp row. Leading icon circle (36dp, account color), name, trailing balance. Swipe actions: Hide (leading, iOS) and Delete (trailing, iOS). Android: long-press context menu. Balance color: `textPrimary` for positive, `expense` for negative. |
| `AccountsSummaryBar` | `features/accounts/presentation/widgets/accounts_summary_bar.dart` | SPEC-004 (AccountsScreen header) | `assets`, `liabilities`, `total`, `currency` | 60dp bar with three labeled columns: Assets (`income` blue), Liabilities (`expense` coral), Total (`textPrimary` white). `bgSecondary` background. |
| `EmptyStateView` | `core/widgets/empty_state_view.dart` | SPEC-004, SPEC-006, SPEC-007 | `illustration` (asset path or icon), `title`, `subtitle`, `ctaLabel`, `onCtaTap` | Centered column: illustration 120dp + title (`title3`) + subtitle (`subhead`) + optional `AppButton` primary CTA. Used for all empty states across the app. |

---

## Sprint 4 Components

| Component | File | Used In | Variants / Props | Notes |
|-----------|------|---------|-----------------|-------|
| `MonthNavigator` | `features/transactions/presentation/widgets/month_navigator.dart` | SPEC-008, SPEC-009, SPEC-010, SPEC-011, SPEC-012, Stats screen | `currentMonth`, `onPrevious`, `onNext`, `onMonthTap`, `showYearOnly` | 48dp height. `showYearOnly: true` when Monthly sub-tab is active — shows "2026" instead of "Nisan 2026". Arrow tap targets 44x44dp. Tapping label opens `MonthYearPicker` bottom sheet. |
| `PeriodTabBar` | `features/transactions/presentation/widgets/period_tabs.dart` | SPEC-008 | `tabs` (List<String>), `activeIndex`, `onTabChanged` | 49dp height. Animated 2dp `brandPrimary` underline (200ms easeInOut slide). Inaktif: `textSecondary`; aktif: `textPrimary`. |
| `IncomeSummaryBar` | `features/transactions/presentation/widgets/income_summary_bar.dart` | SPEC-008, SPEC-011 | `income`, `expense`, `total`, `currency`, `onIncomeTap`, `onExpenseTap`, `onTotalTap`, `isLoading` | 60dp height. 3 equal-flex columns. Income: `AppColors.income`; Expense: `AppColors.expense`; Total: `AppColors.textPrimary` (positive) or `AppColors.expense` (negative). `isLoading` shows dash placeholders. |
| `DayHeaderRow` | `features/transactions/presentation/widgets/day_header_row.dart` | SPEC-009 | `date`, `income`, `expense`, `isToday` | 56dp height. Day number `title1`. Day label badge 20x18dp with weekday-aware color (Mon–Fri: `bgTertiary`; Sat: `income` tint; Sun: `expense` tint). Today: 32dp `brandPrimary` circle behind number. |
| `TransactionListItem` | `features/transactions/presentation/widgets/transaction_list_item.dart` | SPEC-009, SPEC-010 (DayDetailPanel) | `transaction`, `onTap`, `onEdit`, `onDelete`, `showSwipeActions` | 56dp height. Left: `CategoryIcon` 40dp. Center: category name (`bodyMedium`) + account/note (`caption1` `textTertiary`). Right: amount `moneySmall` colored by type. Swipe-to-delete (iOS) / long-press menu (Android). `isExcluded` shows strikethrough. |
| `CalendarGrid` | `features/transactions/presentation/widgets/calendar_grid.dart` | SPEC-010 | `month`, `transactionSummaryByDay` (Map<DateTime, DaySummary>), `selectedDay`, `onDaySelected`, `weekStartDay` | 7-column grid. Each cell `screen_width / 7` wide × ~72dp tall. Handles partial months (prev/next month days shown as `textTertiary`, not tappable). |
| `CalendarDayCell` | `features/transactions/presentation/widgets/calendar_day_cell.dart` | SPEC-010 (via CalendarGrid) | `day`, `isCurrentMonth`, `isToday`, `isSelected`, `income`, `expense`, `onTap` | Cell height ~72dp. Day number top-left. Amounts bottom-center (income blue, expense coral), abbreviated for large values (≥1K → "€1,2K"). Today: 22dp `brandPrimary` circle. Selected: `bgTertiary` bg + `brandPrimary` 2dp border. |
| `DayDetailPanel` | `features/transactions/presentation/widgets/day_detail_panel.dart` | SPEC-010 | `selectedDay`, `transactions`, `isLoading`, `onClose`, `onTransactionTap`, `onTransactionDelete` | Slide-up panel above `AdBannerBar`. Max height `screen_height * 0.5`. Header 48dp with date label + close button. Content: `ListView` of `TransactionListItem`. Animated height (250ms easeOutCubic open, 200ms easeInCubic close). Swipe-down dismisses. |
| `MonthCard` | `features/transactions/presentation/widgets/month_card.dart` | SPEC-011 | `monthData`, `isExpanded`, `isCurrentMonth`, `onToggle`, `onWeekTap` | `AnimatedSize` wrapper. Expanded shows `WeekRow` list. Current month: 3dp `brandPrimary` left border. |
| `MonthRow` | `features/transactions/presentation/widgets/month_row.dart` | SPEC-011 (via MonthCard) | `month`, `dateRange`, `income`, `expense`, `total`, `isExpanded`, `isCurrentMonth`, `onTap` | 52dp height. Chevron icon rotates 0°→90° on expand (150ms). `bgTertiary` bg when expanded. |
| `WeekRow` | `features/transactions/presentation/widgets/week_row.dart` | SPEC-011 (via MonthCard) | `weekRange`, `income`, `expense`, `total`, `isCurrentWeek`, `onTap` | 44dp height. `bgTertiary` bg + `brandPrimaryGlow` tint for current week. Tap navigates to Daily tab at week start date. |
| `StatSummaryCard` | `features/transactions/presentation/widgets/stat_summary_card.dart` | SPEC-012 | `income`, `expense`, `savingsRate`, `currency`, `isLoading` | 2-column layout: left column has 2 mini cards (Income + Expense), right column has Savings Rate large card. |
| `AccountsSummaryCardWidget` | `features/transactions/presentation/widgets/accounts_summary_card_widget.dart` | SPEC-012 | `totalExpense`, `accountGroupNames`, `currency`, `onTap`, `isEmpty` | Not to be confused with `AccountsSummaryBar` (SPEC-004). This card is specific to the Summary View. |
| `BudgetSummaryCard` | `features/transactions/presentation/widgets/budget_summary_card.dart` | SPEC-012 | `totalBudget`, `spent`, `expectedSpend`, `progressRatio`, `isSetUp`, `onTap`, `onSetBudgetTap` | Progress bar color: `income` (normal) → `warning` (>80%) → `error` (>100%). "Bugün" indicator line on bar. |
| `CategoryBreakdownCard` | `features/transactions/presentation/widgets/category_breakdown_card.dart` | SPEC-012 | `categories` (List<CategorySummary> max 5), `onCategoryTap`, `onSeeAllTap`, `isLoading` | Contains up to 5 `CategoryBreakdownRow` items + "Tümünü Gör" ghost button. |
| `CategoryBreakdownRow` | `features/transactions/presentation/widgets/category_breakdown_row.dart` | SPEC-012 (via CategoryBreakdownCard) | `rank`, `emoji`, `name`, `amount`, `percentage`, `color`, `onTap` | 48dp height. Background progress bar overlay (full-width `bgTertiary` + `color` fill to percentage width). Emoji + name + amount + percentage on top layer. |
| `ExportActionCard` | `features/transactions/presentation/widgets/export_action_card.dart` | SPEC-012 | `onTap` | 52dp simple tappable card. Phosphor `FileXls` icon + label + caret. |

---

## Planned Components (Upcoming Sprints — not yet implemented)

The entries below are identified from the screen specs and SPEC.md but are deferred to future sprints. They are listed here so that the component inventory does not diverge from what will be needed.

| Component | File | Planned For | Notes |
|-----------|------|-------------|-------|
| `AppTextField` | `core/widgets/app_text_field.dart` | Add Transaction (Sprint 2+) | Label left, value right. Validation inline. See SPEC.md Section 2.5. |
| `CurrencyText` | `core/widgets/currency_text.dart` | Transaction lists, account headers | Tabular figures. Colors income blue (#4A90E2), expense coral (#FF6B5C), neutral white. |
| `MonthYearPicker` | `core/widgets/month_year_picker.dart` | Transactions, Stats, Budget | Cupertino drum-roll style, bottom sheet. |
| `AppBottomSheet` | `core/widgets/app_bottom_sheet.dart` | Pickers, Add Transaction modal | Rounded top corners (`AppRadius.xl` = 24dp), drag handle, `bgSecondary` background. |
| `TransactionListItem` | `features/transactions/presentation/widgets/transaction_list_item.dart` | Transactions screen (Daily view) | 56dp height, left icon, center description+category, right amount. |
| `CategoryIcon` | `core/widgets/category_icon.dart` | Category picker, transaction rows | Emoji or Phosphor icon in a colored circle. Size 40dp. |
| `ThemeToggleRow` | `core/widgets/theme_toggle_row.dart` | More screen (Sprint 1 placeholder), future Style screen | Extracted from SPEC-002. Label + Switch, 56dp row height. |
| `RateEntrySheet` | `features/more/presentation/widgets/rate_entry_sheet.dart` | SPEC-007 (Sub Currency) | `mainCurrencyCode`, `subCurrencyCode`, `initialRate`, `onRateSaved` | Compact bottom sheet with single numeric input. "1 [Main] = ? [Sub]" label. Done button (`AppButton` primary). |
| `DayNumberPicker` | `core/widgets/day_number_picker.dart` | SPEC-005 (Statement Day, Payment Due Day) | `initialValue` (1–31), `onChanged` | Drum-roll style bottom sheet picker for integers 1–31. "Done" button at top right. |

---

## Component Design Rules

All components in `core/widgets/` must follow these rules:

1. **No business logic.** Widgets are purely presentational. State and data come from the caller or from Riverpod providers passed down.
2. **Token-only styling.** Never hard-code color hex values or pixel sizes inside a widget. Reference `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppHeights` constants exclusively.
3. **Both themes supported.** Every widget must render correctly in both dark and light mode. Use `Theme.of(context)` or context extensions (`context.colors`) to resolve the correct token.
4. **Minimum tap target.** Any interactive element inside a widget must have a minimum 44x44dp tap target.
5. **Accessibility first.** Provide `Semantics` wrappers or `semanticLabel` arguments for screen reader support. Document the expected label in the corresponding spec.
6. **Documented states.** Every widget must handle: default, disabled, loading (where async applies), and error (where validation applies).
