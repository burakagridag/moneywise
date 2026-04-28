# US-002: Theme system implemented (AppColors, AppTypography, AppSpacing, AppRadius, AppHeights)

## Source
SPEC.md §2 (Design System), §16.1 Sprint 1 checklist — "Theme + Color + Typography system"

## Persona
A flutter engineer who needs a centrally defined design token system so that every widget uses consistent colors and typography without hardcoding values.

## Story
**As** a MoneyWise developer
**I want** all design tokens (colors, typography, spacing, radii, heights) defined in a single theme system
**So that** every widget references tokens instead of magic values, enabling consistent UI and painless theme updates

## Acceptance Criteria

```gherkin
Scenario: AppColors exposes all dark mode tokens
  Given the app_colors.dart file is present under lib/core/constants/
  When a developer references AppColors in any Dart file
  Then the following constants are accessible:
    | brandPrimary      | 0xFFFF6B5C |
    | brandPrimaryDim   | 0xFFE85A4D |
    | brandPrimaryGlow  | 0x33FF6B5C |
    | bgPrimary         | 0xFF1A1B1E |
    | bgSecondary       | 0xFF24252A |
    | bgTertiary        | 0xFF2E2F35 |
    | textPrimary       | 0xFFFFFFFF |
    | textSecondary     | 0xFFB0B3B8 |
    | textTertiary      | 0xFF6B6E76 |
    | income            | 0xFF4A90E2 |
    | expense           | 0xFFFF6B5C |
    | divider           | 0xFF2E2F35 |
    | border            | 0xFF3A3B42 |
    | success           | 0xFF4CAF50 |
    | warning           | 0xFFFFA726 |
    | error             | 0xFFE53935 |

Scenario: AppColors exposes all light mode tokens
  Given the app_colors.dart file is present
  When a developer references light-mode color tokens
  Then the following constants are accessible:
    | bgPrimaryLight    | 0xFFFFFFFF |
    | bgSecondaryLight  | 0xFFF5F5F7 |
    | bgTertiaryLight   | 0xFFEAEAEC |
    | textPrimaryLight  | 0xFF1A1B1E |
    | textSecondaryLight| 0xFF6B6E76 |

Scenario: AppTypography exposes all text styles
  Given app_typography.dart is present under lib/core/constants/
  When a developer references AppTypography
  Then all named text styles are accessible: largeTitle (34/w700), title1 (28/w700), title2 (22/w600), title3 (20/w600), headline (17/w600), body (17/w400), bodyMedium (16/w500), callout (16/w400), subhead (15/w400), footnote (13/w400), caption1 (12/w400), caption2 (11/w400), moneyLarge (28/w700), moneyMedium (17/w600), moneySmall (15/w500)
  And moneyLarge, moneyMedium, moneySmall include FontFeature.tabularFigures()

Scenario: AppSpacing, AppRadius, AppHeights expose all sizing tokens
  Given the constant files are present
  When a developer references AppSpacing
  Then xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32 are accessible
  When a developer references AppRadius
  Then sm=6, md=10, lg=16, xl=24, pill=999 are accessible
  When a developer references AppHeights
  Then inputField=48, button=52, tabBar=49, appBar=44, listItem=56, bannerAd=50 are accessible

Scenario: ThemeData is created for dark and light modes
  Given app_theme.dart is present under lib/core/theme/
  When AppTheme.dark is applied to the app
  Then the scaffold background colour matches bgPrimary (0xFF1A1B1E)
  When AppTheme.light is applied to the app
  Then the scaffold background colour matches bgPrimaryLight (0xFFFFFFFF)

Scenario: No inline color or TextStyle literals in any widget
  Given the theme system is in place
  When flutter analyze runs on the codebase
  Then no hardcoded Color(0x...) literals appear outside of the constants files
  And no inline TextStyle(fontSize: ...) literals appear outside of AppTypography
```

## Edge Cases
- [ ] Font fallback chain must be: SF Pro Display (iOS) → Roboto (Android) → Inter (web/fallback); missing font must not crash
- [ ] All text styles must specify letterSpacing only where explicitly required in spec (largeTitle: -0.5)
- [ ] tabularFigures feature may not be available on all platforms — must degrade gracefully
- [ ] Theme extension (theme_extensions.dart) must expose AppColors via BuildContext so widgets do not import the constants file directly
- [ ] Changing theme at runtime must not require a cold restart

## Test Scenarios for QA
1. Launch app in dark mode — verify scaffold background is `#1A1B1E`
2. Launch app in light mode — verify scaffold background is `#FFFFFF`
3. Inspect a money display widget — confirm tabular figures are applied (digits align vertically in a list)
4. Run `flutter analyze` on entire project — zero lint warnings relating to inline colors or styles
5. Review constants file — confirm all tokens from SPEC.md §2 are present with correct hex values

## UX Spec
TBD — ux-designer Sprint 1 (design token reference sheet)

## Estimate
S (1–2 days)

## Dependencies
- US-001 (project must exist before adding core constants)
