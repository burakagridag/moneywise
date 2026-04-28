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

---

## Component Design Rules

All components in `core/widgets/` must follow these rules:

1. **No business logic.** Widgets are purely presentational. State and data come from the caller or from Riverpod providers passed down.
2. **Token-only styling.** Never hard-code color hex values or pixel sizes inside a widget. Reference `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppHeights` constants exclusively.
3. **Both themes supported.** Every widget must render correctly in both dark and light mode. Use `Theme.of(context)` or context extensions (`context.colors`) to resolve the correct token.
4. **Minimum tap target.** Any interactive element inside a widget must have a minimum 44x44dp tap target.
5. **Accessibility first.** Provide `Semantics` wrappers or `semanticLabel` arguments for screen reader support. Document the expected label in the corresponding spec.
6. **Documented states.** Every widget must handle: default, disabled, loading (where async applies), and error (where validation applies).
