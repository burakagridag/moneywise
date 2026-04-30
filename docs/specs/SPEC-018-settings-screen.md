# SPEC-018: Settings Screen

**Sprint:** 6
**Related:** US-018
**Reference:** SPEC.md Section 9, existing `SettingsScreen` at `lib/features/more/presentation/screens/settings_screen.dart`
**Route:** `/more/settings`
**Component:** `lib/features/more/presentation/screens/settings_screen.dart` (expand existing)

---

## Purpose

The Settings screen is the central configuration hub reached from More > Settings. It currently exposes only the Categories sub-screen. Sprint 6 expands it with four new sections: Appearance (theme), Default Currency, Language, and About. Each section follows the `SettingsRow` component pattern already established in SPEC-004/SPEC-005.

---

## Screen / Component Hierarchy

```
SettingsScreen (Scaffold)
├── AppBar (44dp)
│   ├── Back arrow (leading, 44x44dp tap target)
│   └── Title: "Settings"
└── ListView (body)
    ├── SectionHeader — "General"
    ├── SettingsRow — Categories  → push /more/settings/categories
    ├── SettingsRow — Default Currency → push /more/settings/currencies
    ├── SectionDivider
    ├── SectionHeader — "Appearance"
    ├── SettingsRow — Theme         → ThemePickerSheet (bottom sheet)
    ├── SettingsRow — Language      → LanguagePickerSheet (bottom sheet)
    ├── SectionDivider
    ├── SectionHeader — "About"
    ├── SettingsRow — App Version   → no action (value-only)
    ├── SettingsRow — Privacy Policy → open in-app WebView
    └── SettingsRow — Licenses      → push /more/settings/licenses
```

---

## Layout

```
┌─────────────────────────────────────────────┐
│ ←   Settings                          44dp  │  ← AppBar
├─────────────────────────────────────────────┤
│  GENERAL                              12dp  │  ← SectionHeader
├─────────────────────────────────────────────┤
│  [category icon] Categories       [>] 56dp  │
├─────────────────────────────────────────────┤
│  [currency icon] Default Currency [>] 56dp  │
├─────────────────────────────────────────────┤
│                                       8dp   │  ← SectionDivider (visual gap)
│  APPEARANCE                           12dp  │  ← SectionHeader
├─────────────────────────────────────────────┤
│  [palette icon] Theme          Dark  [>] 56dp│
├─────────────────────────────────────────────┤
│  [globe icon]   Language    English  [>] 56dp│
├─────────────────────────────────────────────┤
│                                       8dp   │
│  ABOUT                                12dp  │
├─────────────────────────────────────────────┤
│  [info icon]   App Version       1.0.0  56dp│  ← no chevron, no tap
├─────────────────────────────────────────────┤
│  [shield icon] Privacy Policy         [>] 56dp│
├─────────────────────────────────────────────┤
│  [doc icon]    Licenses               [>] 56dp│
└─────────────────────────────────────────────┘
```

---

## Token Specs

### AppBar
| Element | Token |
|---------|-------|
| Height | 44dp (`AppHeights.appBar`) |
| Background | `AppColors.bgPrimary` |
| Title | `AppTypography.title2`, `AppColors.textPrimary` |
| Leading icon | Back arrow (chevron on iOS, arrow on Android), `AppColors.textPrimary`, tap target 44x44dp |

### SectionHeader
| Element | Token |
|---------|-------|
| Height | 36dp total (12dp top padding, text, 8dp bottom padding) |
| Background | `AppColors.bgPrimary` |
| Text | `AppTypography.footnote`, `AppColors.textTertiary`, uppercase, `letterSpacing: 0.8` |
| Horizontal padding | `AppSpacing.lg` (16dp) |

### SettingsRow (reuse `core/widgets/settings_row.dart`)
| Element | Token |
|---------|-------|
| Height | 56dp (`AppHeights.listItem`) |
| Background | `AppColors.bgPrimary` |
| Leading icon | 24dp, `AppColors.textSecondary` |
| Label | `AppTypography.body`, `AppColors.textPrimary` |
| Value (current selection) | `AppTypography.body`, `AppColors.textSecondary`, right-aligned |
| Trailing chevron | `AppColors.textTertiary`, 20dp; absent on version-only row |
| Bottom divider | 1dp `AppColors.divider`; suppressed on last row in a section |
| Horizontal content padding | `AppSpacing.lg` (16dp) |

### SectionDivider
| Element | Token |
|---------|-------|
| Height | 8dp transparent gap |
| Effect | Visual breathing room between sections; no visible rule line |

---

## Sub-Screens and Bottom Sheets

### ThemePickerSheet
A compact `AppBottomSheet` presented modally. Does not push a new route.

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                              drag  │
│   Theme                              title  │
├─────────────────────────────────────────────┤
│  [sun icon]    Light          [○] 56dp      │
├─────────────────────────────────────────────┤
│  [moon icon]   Dark           [●] 56dp      │  ← active
├─────────────────────────────────────────────┤
│  [device icon] System Default [○] 56dp      │
└─────────────────────────────────────────────┘
```

- Sheet background: `AppColors.bgSecondary`, radius `AppRadius.xl` (24dp) top corners
- Drag handle: 36x4dp rounded pill, `AppColors.textTertiary`, centered, 12dp top margin
- Title: `AppTypography.headline`, `AppColors.textPrimary`, left-aligned, `AppSpacing.lg` horizontal padding, 16dp bottom margin
- Each option row: 56dp height, icon 24dp `AppColors.textSecondary` (leading), label `AppTypography.body` `AppColors.textPrimary`, trailing radio indicator
- Radio indicator: active = filled 20dp circle `AppColors.brandPrimary` with white center dot; inactive = 20dp circle outline `AppColors.border`
- Active row background: `AppColors.bgTertiary`
- Selecting an option: applies theme immediately (live preview), sheet auto-dismisses after 200ms
- Preference persisted to local storage (SharedPreferences key `app_theme`)

### LanguagePickerSheet
Same structure as `ThemePickerSheet`.

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                                    │
│   Language                                  │
├─────────────────────────────────────────────┤
│  English (EN)                     [○] 56dp  │
├─────────────────────────────────────────────┤
│  Türkçe (TR)                      [●] 56dp  │  ← active if system is TR
└─────────────────────────────────────────────┘
```

- Same token rules as `ThemePickerSheet`
- No leading icon (language rows)
- V1 supports only English and Turkish
- Selecting applies locale immediately; app content re-renders in place (no app restart required)
- Preference persisted to local storage (SharedPreferences key `app_locale`)

### Licenses Screen
- Route: `/more/settings/licenses`
- Uses Flutter's built-in `LicensePage` wrapped in a `Scaffold` with custom AppBar matching Settings tokens
- No custom spec needed; behavior is platform-standard

---

## States

### Default
- All rows display current values fetched from local settings provider
- Theme row value reflects current active theme: "Light", "Dark", or "System Default"
- Language row value reflects current locale display name
- App Version row value is injected at build time from `package_info_plus`

### Loading (settings provider initializing)
- Theme and Language value cells show a `AppColors.bgTertiary` skeleton pill (60x16dp) while provider loads
- Duration: typically <50ms; skeleton is a precaution for slow devices

### Error (settings provider failure — rare)
- Rows still render; value shows dash "—"
- Tapping an affected row shows a Snackbar: "Could not load settings. Tap to retry."

---

## Interactions

| Trigger | Action |
|---------|--------|
| Tap "Categories" row | `context.push(Routes.categoryManagement)` |
| Tap "Default Currency" row | `context.push(Routes.currencies)` — existing currency screen |
| Tap "Theme" row | Open `ThemePickerSheet` as bottom sheet |
| Tap "Language" row | Open `LanguagePickerSheet` as bottom sheet |
| Tap "App Version" row | No action (non-interactive, no chevron) |
| Tap "Privacy Policy" row | Push `/more/settings/privacy` — in-app WebView |
| Tap "Licenses" row | Push `/more/settings/licenses` — Flutter `LicensePage` |
| Back arrow | `context.pop()` — return to MoreScreen |

### Theme Change Animation
- Theme transition: fade-through, 250ms, `Curves.easeInOut`
- The `MaterialApp` `themeMode` updates immediately upon selection; no additional confirmation needed

---

## Accessibility

- **Screen reader label for AppBar:** "Settings screen"
- **SectionHeader:** `excludeFromSemantics: true` (decorative grouping; rows are self-describing)
- **SettingsRow — Theme:** "Theme. Current value: Dark. Tap to change."
- **SettingsRow — Language:** "Language. Current value: English. Tap to change."
- **SettingsRow — App Version:** "App version 1.0.0." (no hint; non-interactive)
- **ThemePickerSheet radio rows:** "Light theme option. Unselected. Double-tap to activate." / "Dark theme option. Selected."
- **Color contrast:** All text tokens pass WCAG AA 4.5:1 against respective backgrounds
- **Focus order (keyboard / screen reader):** AppBar back button → Categories row → Default Currency row → Theme row → Language row → App Version → Privacy Policy → Licenses
- **Dynamic Type / text scaling:** All `AppTypography` styles scale with system font size. Section headers maintain `AppSpacing.lg` minimum horizontal padding to prevent clipping at 200% scale.
- **Minimum tap targets:** All rows 56dp height × full screen width. Trailing chevrons are not separate tap targets.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Theme = System, system switches to dark at sunset | App follows system immediately; Settings row value updates to "System Default" (unchanged label) |
| Language changed mid-session | All visible text re-renders via locale rebuild; no app restart; navigation stack remains intact |
| App version not retrievable (build config issue) | Version row shows "—" instead of crashing |
| Long currency name truncated | Value cell clips with ellipsis; full name accessible via screen reader `semanticLabel` |
| Licenses page contains hundreds of entries | Flutter `LicensePage` handles scroll internally; AppBar back arrow still visible |

---

## New Components Required (Sprint 6)

| Component | File | Notes |
|-----------|------|-------|
| `SectionHeader` | `core/widgets/section_header.dart` | Uppercase label with vertical padding. Reused by Settings and any future grouped-list screens. |
| `ThemePickerSheet` | `features/more/presentation/widgets/theme_picker_sheet.dart` | `currentTheme` (light/dark/system), `onThemeSelected` callback. |
| `LanguagePickerSheet` | `features/more/presentation/widgets/language_picker_sheet.dart` | `currentLocale` (en/tr), `onLocaleSelected` callback. |
