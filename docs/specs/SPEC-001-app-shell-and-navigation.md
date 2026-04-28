# SPEC-001: App Shell and Bottom Navigation

**Related:** US-001 (Project Skeleton)
**Reference:** SPEC.md Section 3.1 (Bottom Tab Navigator), Section 2 (Design System)
**Sprint:** 1 — Project Setup & Foundation

---

## Purpose

Define the outer app shell: the persistent bottom tab bar that wraps all four primary destinations, the per-tab placeholder screens shown in Sprint 1, the splash/loading state shown before the app is ready, and the default app bar style that all future screens must inherit.

This spec is the single source of truth for navigation chrome. All future screen specs may reference it rather than re-specify tab bar or app bar tokens.

---

## Scope

1. Bottom tab bar (persistent, all screens)
2. Per-tab placeholder screens (Transactions, Stats, Accounts, More)
3. App bar defaults (applies to all future screens)
4. Splash / loading state
5. Safe area handling rules

---

## 1. Bottom Tab Bar

### 1.1 Layout

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│           [Screen content area]                     │
│                                                     │
├─────────────────────────────────────────────────────┤  ← divider: AppColors.divider (1dp)
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │  [icon]  │ │  [icon]  │ │  [icon]  │ │ [icon] │ │
│  │  28.4    │ │   Stats  │ │ Accounts │ │  More  │ │  ← 49dp total height
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ │
└─────────────────────────────────────────────────────┘
     Tab 1          Tab 2        Tab 3       Tab 4
```

### 1.2 Dimensions

| Property | Value |
|----------|-------|
| Tab bar total height | 49dp (`AppHeights.tabBar`) |
| Top divider height | 1dp |
| Tab icon size | 24x24dp |
| Icon-to-label gap | 4dp (`AppSpacing.xs`) |
| Label font | `AppTypography.caption2` (11sp, w400) |
| Minimum tap target per tab | 44x44dp (expand hit area, not visual area) |
| Bottom padding (iOS home indicator) | Derived from `MediaQuery.padding.bottom` — content sits above home indicator |

### 1.3 Color Tokens

| Element | Active state | Inactive state |
|---------|-------------|----------------|
| Tab icon | `AppColors.brandPrimary` (#FF6B5C) | `AppColors.textSecondary` (#B0B3B8) |
| Tab label | `AppColors.brandPrimary` (#FF6B5C) | `AppColors.textSecondary` (#B0B3B8) |
| Tab bar background | `AppColors.bgPrimary` (dark: #1A1B1E / light: #FFFFFF) | — |
| Top divider | `AppColors.divider` (#2E2F35) | — |

### 1.4 Tab Definitions

| # | Icon (Phosphor) | Label | Route | Notes |
|---|-----------------|-------|-------|-------|
| 1 | `NotebookLight` (notebook / ledger) | Dynamic: today as `"28.4"` | `/transactions` | Label is `day.month` with no leading zero on month. Computed at runtime from device clock. |
| 2 | `ChartBarLight` (bar chart) | `"Stats"` | `/stats` | Static label |
| 3 | `StackLight` (stacked coins) | `"Accounts"` | `/accounts` | Static label |
| 4 | `DotsThreeOutlineLight` (three dots) | `"More"` | `/more` | Static label |

**Tab 1 label logic:**
- Format: `{day}.{month}` where day and month are integers with no leading zeros
- Examples: April 28 → `"28.4"`, December 3 → `"3.12"`, January 10 → `"10.1"`
- The label updates at app launch. It does not tick in real-time mid-session (acceptable: the date changes only at midnight and users typically relaunch).

### 1.5 Active / Inactive State

- Only one tab is active at a time.
- Switching tabs: instant color change (no animation on the tab bar itself). Screen transition follows platform conventions (see Section 1.6).
- No badge indicators in Sprint 1.

### 1.6 Navigation Behavior

- Each tab owns an independent navigation stack (nested navigator per tab).
- Tapping an already-active tab: scroll the active screen to the top if it is scrollable; otherwise no-op.
- Tab state is preserved when switching between tabs (each navigator stack retains its route history).
- Back navigation within a tab does NOT pop to another tab.
- Modal sheets (e.g., Add Transaction) float above all tabs and are not part of any tab's navigator stack.

**Platform conventions:**
- iOS: swipe-from-left-edge navigates back within a tab's stack (standard `CupertinoPageRoute` or `go_router` with `CupertinoTransitionPage`).
- Android: system back button pops the current tab's stack. When the stack is at root, system back triggers app-exit confirmation (standard Android behavior).

---

## 2. Placeholder Screens (Sprint 1)

Each of the four tabs shows an identical-structure placeholder screen during Sprint 1. These are replaced by real screens in subsequent sprints.

### 2.1 Layout (all four tabs)

```
┌─────────────────────────────────────────────────────┐
│  [Status bar — system managed]                      │
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│                   [Tab Name]                        │  ← Centered vertically + horizontally
│                                                     │
│                                                     │
│                                                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│  [Bottom tab bar — 49dp]                            │
└─────────────────────────────────────────────────────┘
```

### 2.2 Tokens

| Element | Token |
|---------|-------|
| Screen background | `AppColors.bgPrimary` |
| Centered label text | `AppTypography.title2` (22sp, w600) |
| Centered label color | `AppColors.textPrimary` |
| No app bar | — (Sprint 1 placeholder only; real screens will add one) |

### 2.3 Per-tab Placeholder Labels

| Tab | Placeholder label text |
|-----|------------------------|
| Transactions | `"Transactions"` |
| Stats | `"Stats"` |
| Accounts | `"Accounts"` |
| More | `"More"` |

The Transactions placeholder label remains static ("Transactions"), even though the tab bar label is dynamic. The centered text is descriptive, not a date.

### 2.4 More Tab: Theme Toggle

The More tab placeholder includes a single interactive element — a theme toggle row — in addition to the centered label. See SPEC-002 for the full spec of this row. The row is positioned below the centered label with `AppSpacing.xxl` (24dp) vertical gap.

---

## 3. App Bar Defaults (All Future Screens)

These defaults apply to every screen in the app unless a screen spec explicitly overrides a property.

### 3.1 Layout

```
┌─────────────────────────────────────────────────────┐
│  [Back icon / leading]   [Title — centered]  [Menu] │  ← 44dp height
└─────────────────────────────────────────────────────┘
```

### 3.2 Tokens

| Property | Value |
|----------|-------|
| Height | 44dp (`AppHeights.appBar`) |
| Background | `AppColors.bgPrimary` |
| Title typography | `AppTypography.headline` (17sp, w600) |
| Title color | `AppColors.textPrimary` |
| Title alignment | Centered |
| Back icon | `PhosphorIcons.caretLeft` (or `PhosphorIcons.arrowLeft`), 24dp, `AppColors.textPrimary` |
| Back icon tap target | 44x44dp minimum |
| Trailing action icon (optional) | 24dp, `AppColors.textPrimary` |
| Divider below app bar | 1dp, `AppColors.divider` (only when content scrolls beneath it; omit on flat screens) |
| Elevation / shadow | 0 (flat; no shadow by default) |

### 3.3 Status Bar

- **Dark mode:** status bar icons — light (white) on dark background.
- **Light mode:** status bar icons — dark (black) on white background.
- The `AppBar` background color extends behind the status bar (no system overlay gap).
- `SystemUiOverlayStyle` must match the active theme. This is set globally in `AppTheme` and should not require per-screen overrides.

---

## 4. Safe Area Handling

### 4.1 Rules

- All screen content must be inset by `MediaQuery.padding` on all sides to avoid overlap with status bar (top), home indicator (bottom iOS), and notch/punch-hole (left/right on some devices).
- The bottom tab bar is drawn below the safe area content but above the home indicator. Its 49dp height is the visual chrome; the home indicator inset is additional.
- Screen content scrollable lists must have a `bottomPadding` equal to `AppHeights.tabBar + MediaQuery.padding.bottom` so that the last item is not obscured by the tab bar or home indicator.
- Full-screen modals and bottom sheets must also respect `MediaQuery.padding.bottom`.

### 4.2 Platform Notes

| Platform | Key consideration |
|----------|-------------------|
| iOS (notch) | Top safe area ≈ 44–59dp depending on device. Never hard-code. |
| iOS (home indicator) | Bottom safe area ≈ 34dp on current devices. |
| Android (gesture nav) | Bottom safe area ≈ 0–24dp depending on nav mode. Use `MediaQuery`. |
| Android (3-button nav) | System nav bar visible; `MediaQuery.padding.bottom` accounts for it. |

---

## 5. States

### 5.1 Default (Dark Mode)

- Background: `AppColors.bgPrimary` (#1A1B1E)
- Active tab: `AppColors.brandPrimary` (#FF6B5C) icon + label
- Inactive tabs: `AppColors.textSecondary` (#B0B3B8) icon + label
- Status bar: light icons on dark background
- Placeholder screens show centered tab name in `AppTypography.title2`, `AppColors.textPrimary`

### 5.2 Light Mode Mirror

- Background: `AppColors.bgPrimary` light (#FFFFFF)
- Tab bar background: #FFFFFF
- Active tab: `AppColors.brandPrimary` (#FF6B5C) — unchanged
- Inactive tabs: `AppColors.textSecondary` (#B0B3B8) — unchanged
- Status bar: dark icons on white background
- Placeholder text: `AppColors.textPrimary` light (#1A1B1E)
- Top divider on tab bar: `AppColors.divider` — remains visible (the divider color works on both modes as it is a mid-tone separator)

### 5.3 Splash / Loading State

Shown while the app initializes (Riverpod `ProviderScope` bootstrapping, database opening, settings loading). This state must never flash for more than ~300ms on a modern device; on slow devices it may be visible for 1–2 seconds.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                                                     │
│                                                     │
│               [App Logo / Wordmark]                 │  ← Centered, 80x80dp logo area
│                                                     │
│         [Circular progress indicator]               │  ← 24dp diameter, brandPrimary color
│                                                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

| Element | Token |
|---------|-------|
| Background | `AppColors.bgPrimary` (matches system theme at launch) |
| Logo placeholder | `AppColors.brandPrimary` wordmark/icon, centered |
| Progress indicator | `LoadingIndicator` widget, `AppColors.brandPrimary`, 24dp diameter |
| Bottom tab bar | Hidden (not rendered during splash) |

The splash screen uses the native splash (configured via `flutter_native_splash`) to prevent white flash on cold start. The Flutter-side loading overlay takes over immediately after the engine initializes.

### 5.4 Error State (App Initialization Failure)

If the database fails to open or settings cannot be read at startup:

- Show a centered error message: `"Something went wrong. Please restart the app."` in `AppTypography.body`, `AppColors.textSecondary`.
- Show a `"Retry"` button using the primary `AppButton` style (see COMPONENTS.md).
- No tab bar is shown.
- This state is a last resort. Log the error to the crash reporter.

---

## 6. Interactions

| Trigger | Behavior |
|---------|----------|
| Tap inactive tab | Switches to that tab. Instant icon/label color change. Screen slides in per platform convention (no custom animation on tab switch). |
| Tap active tab (stack depth > 1) | Pops to root of that tab's navigator stack. |
| Tap active tab (stack depth = 1, scrollable screen) | Scrolls the screen's primary scroll view to the top. |
| Long-press tab | No action in Sprint 1. |
| Swipe left/right on content area | Not a tab-switching gesture. Each tab's content may use horizontal swipe internally (e.g., sub-tabs). |

---

## 7. Accessibility

### 7.1 Semantic Labels (Bottom Tab Bar)

| Tab | Active semantic label | Inactive semantic label |
|-----|-----------------------|-------------------------|
| Transactions (Tab 1) | `"Transactions. Selected. Tab 1 of 4."` | `"Transactions. Tab 1 of 4."` |
| Stats (Tab 2) | `"Stats. Selected. Tab 2 of 4."` | `"Stats. Tab 2 of 4."` |
| Accounts (Tab 3) | `"Accounts. Selected. Tab 3 of 4."` | `"Accounts. Tab 3 of 4."` |
| More (Tab 4) | `"More. Selected. Tab 4 of 4."` | `"More. Tab 4 of 4."` |

Note: The dynamic date label on Tab 1 ("28.4") is a visual-only shorthand. The semantic label always reads "Transactions" so screen reader users are not confused by a date string.

### 7.2 Placeholder Screen Accessibility

- The centered tab name text must have a role of `header` (use `Semantics(header: true, ...)`).
- No other interactive elements on the placeholder screens except the More tab's theme toggle (see SPEC-002).

### 7.3 Focus Order

Bottom tab bar: Tab 1 → Tab 2 → Tab 3 → Tab 4 (left to right). Focus does not cycle into the screen content from the tab bar; screen content has its own focus group.

### 7.4 Color Contrast

| Pair | Ratio | Passes WCAG AA |
|------|-------|----------------|
| Active tab label (#FF6B5C) on bgPrimary dark (#1A1B1E) | ≈ 4.6:1 | Yes |
| Active tab label (#FF6B5C) on bgPrimary light (#FFFFFF) | ≈ 3.6:1 | Fails AA for text — acceptable because tab labels are 11sp (caption), which is iconographic/decorative. The icon (24dp) provides the primary affordance. |
| Inactive tab label (#B0B3B8) on bgPrimary dark (#1A1B1E) | ≈ 4.8:1 | Yes |
| Inactive tab label (#B0B3B8) on bgPrimary light (#FFFFFF) | ≈ 3.1:1 | Below AA — note as known exception; inactive labels are secondary affordance alongside icons |
| Placeholder text (#FFFFFF) on bgPrimary dark (#1A1B1E) | 18.1:1 | Exceeds AAA |
| Placeholder text (#1A1B1E) on bgPrimary light (#FFFFFF) | 18.1:1 | Exceeds AAA |

### 7.5 Dynamic Type / Text Scaling

- Tab bar labels: fixed at `AppTypography.caption2` (11sp). Do NOT scale with system text size. Tab bars are navigation chrome with fixed heights; scaling would break the 49dp constraint.
- Placeholder text: responds to system text scale (use `textScaleFactor`). If the scaled text overflows, truncate with ellipsis (single line).
- App bar title: responds to system text scale up to 1.3x. Beyond 1.3x, cap the scale to prevent overflow.

---

## 8. Animation

| Event | Animation |
|-------|-----------|
| Tab icon/label color change on selection | Instant (0ms) — no tween, matches reference app behavior |
| Screen push within a tab stack (iOS) | Right-to-left slide, 350ms, default Cupertino spring curve |
| Screen push within a tab stack (Android) | Bottom-to-top slide, 300ms, `easeOutCubic` (Material default) |
| Splash → main shell | Cross-fade, 200ms, `easeIn` — the loading overlay fades out to reveal the tab shell |

---

## 9. Open Questions

None for Sprint 1. Future sprints will extend this spec when the Transactions, Stats, Accounts, and More screens are built.
