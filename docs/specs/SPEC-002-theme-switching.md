# SPEC-002: Theme Switching

**Related:** US-001 (Project Skeleton)
**Reference:** SPEC.md Section 2.1 (Color Palette), SPEC.md Section 3.1 (More Navigator → StyleScreen)
**Sprint:** 1 — Project Setup & Foundation
**Location in app:** More tab placeholder screen

---

## Purpose

Allow the user to switch between Dark Mode and Light Mode. The preference persists across app restarts. In Sprint 1 this control lives directly on the More tab placeholder screen. In a later sprint it will move to a dedicated Style screen (`/more/style`), but the component and behavior are identical.

---

## Scope

1. Theme toggle row widget (label + switch)
2. Immediate theme switch behavior (no page transition)
3. Persistence of the chosen theme
4. All visual states and token assignments

---

## 1. Layout

The toggle row is placed on the More tab placeholder screen, below the centered "More" heading.

```
┌─────────────────────────────────────────────────────┐
│  [Status bar]                                       │
│                                                     │
│                                                     │
│                     More                           │  ← AppTypography.title2, centered
│                                                     │
│                  ← 24dp gap →                       │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Dark Mode                          [ ◉——— ]  │  │  ← Toggle row, 56dp height
│  └───────────────────────────────────────────────┘  │
│                                                     │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│  [Bottom tab bar — 49dp]                            │
└─────────────────────────────────────────────────────┘
```

### 1.1 Toggle Row Dimensions

| Property | Value |
|----------|-------|
| Row height | 56dp (`AppHeights.listItem`) |
| Horizontal padding (left) | `AppSpacing.lg` (16dp) |
| Horizontal padding (right) | `AppSpacing.lg` (16dp) |
| Label-to-switch gap | Flexible (row fills width; label left-aligned, switch right-aligned) |
| Row background | `AppColors.bgSecondary` (dark: #24252A / light: #F5F5F7) |
| Row corner radius | `AppRadius.md` (10dp) — the row is a rounded card |
| Card horizontal margin | `AppSpacing.lg` (16dp) each side |
| Vertical gap between "More" heading and card | `AppSpacing.xxl` (24dp) |

### 1.2 Label

| Property | Value |
|----------|-------|
| Text | `"Dark Mode"` |
| Typography | `AppTypography.body` (17sp, w400) |
| Color (dark mode active) | `AppColors.textPrimary` (#FFFFFF) |
| Color (light mode active) | `AppColors.textPrimary` (#1A1B1E) |

### 1.3 Switch / Toggle

| Property | Value |
|----------|-------|
| Widget | Platform-native `Switch` (Material on Android, CupertinoSwitch on iOS — or a unified custom toggle that visually matches both) |
| Active track color | `AppColors.brandPrimary` (#FF6B5C) |
| Active thumb color | #FFFFFF |
| Inactive track color | `AppColors.border` (#3A3B42) in dark mode / `AppColors.bgTertiary` light (#EAEAEC) in light mode |
| Inactive thumb color | `AppColors.textSecondary` (#B0B3B8) |
| Switch width | Platform default (~51dp iOS / ~34dp Android) |
| Switch height | Platform default (~31dp iOS / ~20dp Android) |
| Minimum tap target | 44x44dp (expand hit area around switch if needed) |

---

## 2. States

### 2.1 Dark Mode ON (default on first launch)

```
Dark Mode                          [ ◉——— ]
```

- Toggle is in ON position (thumb right, track filled with `AppColors.brandPrimary`)
- Screen background: `AppColors.bgPrimary` dark (#1A1B1E)
- Row card background: `AppColors.bgSecondary` dark (#24252A)
- Label color: `AppColors.textPrimary` dark (#FFFFFF)
- Status bar: light icons

### 2.2 Light Mode ON (Dark Mode OFF)

```
Dark Mode                          [ ———◯ ]
```

- Toggle is in OFF position (thumb left, track filled with inactive color)
- Screen background: `AppColors.bgPrimary` light (#FFFFFF)
- Row card background: `AppColors.bgSecondary` light (#F5F5F7)
- Label color: `AppColors.textPrimary` light (#1A1B1E)
- Status bar: dark icons
- The "More" heading and all other UI elements on the screen update their colors simultaneously with the theme change (no lag)

### 2.3 System Theme (Future — not Sprint 1)

System-follow mode (auto) is out of scope for Sprint 1. The app launches in Dark Mode by default on first install. The user's explicit choice overrides all system preferences until they change it again.

---

## 3. Behavior

### 3.1 Toggle Tap

1. User taps the toggle switch.
2. The toggle animates to its new position (platform default animation, ~200ms).
3. Simultaneously, the entire app's `ThemeData` switches — all visible widgets repaint with new colors.
4. No page transition, no loading state, no confirmation dialog.
5. The new preference is written to local storage (key-value settings table in Drift, or `SharedPreferences` if settings DB is not yet available in Sprint 1).

### 3.2 Persistence

- The selected theme is stored as a boolean or enum value (`themeMode: dark | light`) in local settings.
- On app cold start: read the stored preference before the first frame renders. If no preference exists, default to `ThemeMode.dark`.
- The preference is read synchronously (or with a fallback default) so there is no flash of the wrong theme on startup.

### 3.3 Theme Change Scope

- The theme change affects the entire app immediately: all four tab screens, any open modals, the status bar overlay style, and the bottom tab bar.
- No partial or per-screen theming in Sprint 1.

---

## 4. Accessibility

### 4.1 Semantic Label

The toggle widget must expose a single merged semantic node:

| State | Semantic label |
|-------|----------------|
| Dark mode ON | `"Dark mode. Toggle switch. Currently on."` |
| Dark mode OFF | `"Dark mode. Toggle switch. Currently off."` |

The label updates dynamically when the value changes so that screen readers announce the new state after toggling.

### 4.2 Color Contrast

| Pair | Ratio | Passes WCAG AA |
|------|-------|----------------|
| Label (#FFFFFF) on row bg (#24252A) — dark mode | ≈ 14.5:1 | Exceeds AAA |
| Label (#1A1B1E) on row bg (#F5F5F7) — light mode | ≈ 15.8:1 | Exceeds AAA |
| Active track (#FF6B5C) on bg dark (#1A1B1E) | ≈ 4.6:1 | Passes AA (non-text component; 3:1 required — passes comfortably) |

### 4.3 Focus and Keyboard

- The entire row (label + switch) is a single focusable tap target, minimum 44x44dp.
- Focus ring must be visible in both dark and light themes. Use `AppColors.brandPrimary` as the focus indicator color.
- Keyboard/switch-access: pressing the action key (Enter / Space) on the focused row toggles the switch.

### 4.4 Dynamic Type

- The "Dark Mode" label text scales with the system text size up to 1.3x. Beyond 1.3x, cap to prevent the label from overflowing the row (use `maxLines: 1`, `overflow: TextOverflow.ellipsis`).
- The row height of 56dp accommodates up to 1.3x scale without layout breaks.

---

## 5. Animation

| Event | Animation |
|-------|-----------|
| Toggle switch thumb movement | Platform default (~200ms, ease) |
| App theme change (colors repaint) | Immediate (0ms transition); Flutter's widget rebuild handles the repaint in the same frame as the toggle animation starts |
| Status bar icon style change | Immediate on theme change via `SystemChrome.setSystemUIOverlayStyle` |

No page-level fade or slide is applied when switching themes. The change is perceived as an instant color shift, consistent with the reference app behavior.

---

## 6. Empty / Error States

| State | Behavior |
|-------|----------|
| Settings not yet loaded | Show toggle in default OFF state (light mode). Once settings load, update to stored preference. The delay should be imperceptible in normal operation. |
| Settings write failure | Silent failure in Sprint 1. Log to console. Do not show an error to the user — the in-session theme change still takes effect; it simply won't persist to next launch. |

---

## 7. Open Questions

- Should the first-launch default be Dark Mode (matching the reference app) or follow the system setting? Decision for Sprint 1: **Dark Mode default**, system-follow is deferred to a later sprint.
- In the future Style screen (`/more/style`), additional options (system-follow, font size, color accent) may be added alongside this toggle. This spec covers only the toggle.
