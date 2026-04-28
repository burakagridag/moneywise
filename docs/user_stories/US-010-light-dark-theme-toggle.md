# US-010: Light/Dark theme toggle — user can switch theme and preference is persisted

## Source
SPEC.md §2.1 (Color Palette — dark and light modes), §9.14 (StyleScreen), §16.1 Sprint 1 checklist — "Theme + Color + Typography system"; Core Feature #10 "Light/Dark theme — System-aware, manual override"

## Persona
A MoneyWise user who prefers light mode during the day and dark mode at night, and wants the app to remember their preference.

## Story
**As** a MoneyWise user
**I want** to switch between System, Dark, and Light themes from the Style screen
**So that** the app matches my visual preference and that choice is remembered across sessions

## Acceptance Criteria

```gherkin
Scenario: App respects system theme on first launch
  Given the user has not set a theme preference in MoneyWise
  And the device system appearance is set to Dark
  When the app launches
  Then the app displays in dark mode (bgPrimary #1A1B1E)

Scenario: App respects system light mode on first launch
  Given the user has not set a theme preference in MoneyWise
  And the device system appearance is set to Light
  When the app launches
  Then the app displays in light mode (bgPrimaryLight #FFFFFF)

Scenario: User switches to Dark mode manually
  Given I am on the Style screen (More > Style)
  When I select "Dark Mode"
  Then the app immediately switches to dark theme
  And all screens use AppColors dark tokens (bgPrimary, textPrimary, etc.)
  And the "Dark Mode" radio option shows a brandPrimary filled circle

Scenario: User switches to Light mode manually
  Given I am on the Style screen
  When I select "Light Mode"
  Then the app immediately switches to light theme
  And all screens use AppColors light tokens (bgPrimaryLight, textPrimaryLight, etc.)

Scenario: User selects System Mode
  Given I am on the Style screen and Dark Mode is manually selected
  When I select "System Mode"
  Then the app theme follows the device system appearance setting again
  And changing the device appearance immediately updates the app theme

Scenario: Theme preference is persisted across cold restarts
  Given the user has manually selected "Light Mode"
  When the app is fully closed and relaunched
  Then the app opens in light mode without requiring the user to re-select it

Scenario: Style screen shows three options with correct visual state
  Given I navigate to More > Style
  Then I see three rows: "System Mode", "Dark Mode", "Light Mode"
  And the currently active mode has a brandPrimary-filled circle on the right
  And inactive modes show a border-only circle
```

## Edge Cases
- [ ] Switching theme while a modal bottom-sheet is open must not cause a visual flash or broken color state in the sheet
- [ ] The `ThemeMode` state must be stored in the Drift settings table (or SharedPreferences) — the flutter-engineer decides; document the choice
- [ ] System mode: if the device does not report a platform brightness (unusual edge case), fall back to dark mode
- [ ] Transitioning between themes must not cause widget rebuild storms (use `AnimatedTheme` or ensure ProviderScope rebuilds are scoped correctly)
- [ ] All custom widgets using `AppColors` constants directly (not via `Theme.of(context)`) must be updated to use `context.colors` extension so theme switching works without hot restart
- [ ] The Style screen itself must correctly render in the current theme before the user changes it

## Test Scenarios for QA
1. Set device to dark system mode, launch app with no saved preference — verify dark theme
2. Set device to light system mode, launch app with no saved preference — verify light theme
3. Navigate to More > Style, select "Light Mode" — verify immediate app-wide switch to light theme
4. Navigate to More > Style, select "Dark Mode" — verify immediate app-wide switch to dark theme
5. Select "Light Mode", close app fully, relaunch — verify light mode is restored without re-selecting
6. Select "System Mode", change device appearance while app is open — verify app theme updates in real time
7. Switch theme while a bottom-sheet modal is open — verify no visual glitch or error

## UX Spec
TBD — ux-designer Sprint 1 (Style screen visual spec, per SPEC.md §9.14)

## Estimate
M (2–3 days)

## Dependencies
- US-002 (theme tokens — dark and light AppColors must be defined)
- US-003 (navigation — More tab must be navigable to reach Style screen)
- US-005 (folder structure — features/more/presentation/screens/style_screen.dart stub)
