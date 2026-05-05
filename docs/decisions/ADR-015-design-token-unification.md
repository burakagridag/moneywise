# ADR-015: Design Token Unification for Card Decoration

## Status
Accepted — 2026-05-05

## Context

EPIC8C-01 (Budget Screen Redesign) established a consistent card decoration pattern
for the Budget and Home tabs:

- Surface color: `AppColors.bgElevatedLight` (light) / `AppColors.bgSecondary` (dark)
- Border: `AppColors.borderLight` (#C8C4BC, light) / `AppColors.border` (#2E3453, dark)
- Shadow: `BoxShadow(color: black.withValues(alpha: 0.04), blurRadius: 8, offset: Offset(0, 2))`
- Border radius: `AppRadius.lg` (14px)

The Transactions screen (pre-EPIC8D-01) uses a different pattern — `bgSecondary` for
card background in both modes, `0x0A000000` shadow, and no explicit border token. This
mismatch creates Bulgu #6 class defects (visual inconsistency across tabs).

EPIC8D-01 (Transactions Screen Redesign) provides the right moment to unify these
tokens across all feature screens, establishing a single card decoration language for
the entire app.

Options considered:
1. Unify now, during EPIC8D-01, adding a shared helper or documenting the token set.
2. Defer unification to a dedicated "Design Tokens Sprint" post-V1.
3. Use a `ThemeExtension` to encode card decoration.

## Decision

Unify card decoration tokens across all feature screens as part of EPIC8D-01. The
canonical card decoration pattern is:

```dart
final isDark = context.isDark;
BoxDecoration(
  color: isDark ? AppColors.bgSecondary : AppColors.bgElevatedLight,
  borderRadius: BorderRadius.circular(AppRadius.lg),   // 14px
  border: Border.all(
    color: isDark ? AppColors.border : AppColors.borderLight,
  ),
  boxShadow: isDark ? [] : [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
)
```

All **new** widgets created in EPIC8D-01 use this pattern. Existing screens that deviate
(DailyView `_DayGroup`, SummaryView `_StatSummaryCard`, etc.) are updated incrementally
— either in EPIC8D-01 when touched, or in a follow-up clean-up sprint.

A `ThemeExtension` is explicitly **not** chosen at this time because it would require
introducing a breaking change to the existing `AppTheme` setup and touches every screen.
Deferred to post-V1.

## Consequences

### Positive
- Visual coherence: Home, Budget, and Transactions tabs render identical card chrome.
- Prevents future Bulgu #6 class defects without a dedicated audit sprint.
- Token set is already implemented in `AppColors` (`bgElevatedLight`, `bgSecondary`,
  `borderLight`, `border`) — no new tokens required.
- New income color (`AppColors.income = Color(0xFF047857)`) brings success-green
  semantics aligned with industry standard (green = income, red = expense).

### Negative
- Minor: existing screens that were not touched in EPIC8D-01 still use the old pattern
  until a follow-up clean-up. Risk is low — it is purely visual.
- Requires engineers to remember to use the canonical pattern rather than reaching for
  `context.bgSecondary` directly as a card background.

## Token Inventory (EPIC8D-01 additions to `AppColors`)

| Token | Value | Usage |
|---|---|---|
| `AppColors.income` | `Color(0xFF047857)` | Income amounts, light mode (was teal blue) |
| `AppColors.incomeDark` | `Color(0xFF34D399)` | Income amounts, dark mode |
| `AppColors.calendarHighlightLight` | `Color(0xFFEAEEF7)` | Calendar selected-day bg, light |
| `AppColors.calendarHighlightDark` | `Color(0xFF1F2540)` | Calendar selected-day bg, dark |

## Alternatives Rejected

- **Dedicated Design Tokens Sprint (option 2)**: Deferral increases divergence. EPIC8D-01
  touches the only remaining major tab that deviates, making now the lowest-cost moment.
- **ThemeExtension (option 3)**: High refactoring cost; post-V1.

## References
- EPIC8C-01 budget_view.dart `_MetricCard` — canonical pattern source
- `lib/core/constants/app_colors.dart` — token definitions
- SPEC-021-transactions-redesign.md
