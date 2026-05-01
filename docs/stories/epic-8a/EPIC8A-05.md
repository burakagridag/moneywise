# Story EPIC8A-05 — HomeHeader Component

**Assigned to:** Flutter Engineer
**Estimated effort:** 1 point
**Dependencies:** EPIC8A-03, EPIC8A-UX
**Phase:** 2

## Description

Implement the `HomeHeader` widget: a greeting row with time-of-day salutation, the current date, and a 36×36 avatar circle showing the user's initial. The greeting text changes by hour (Good morning 05:00–11:59, Good afternoon 12:00–17:59, Good evening 18:00–04:59). If a `userName` is available from `AppPreferencesNotifier`, the greeting appends `, {userName}`; otherwise it shows the greeting alone.

The avatar tap navigates to `AppRoutes.settings` (or the More tab root if settings is a sub-page). The date renders locale-aware: EN format `Thursday, 30 April`, TR format `30 Nisan Perşembe`.

The widget is a pure presentational widget. It receives `userName`, `currentDate`, and `onAvatarTap` as constructor parameters. The `HomeScreen` scaffold (EPIC8A-03) injects the values from providers.

## Inputs (agent must read)

- `docs/designs/home-tab/spec.md` — HomeHeader section (EPIC8A-UX output)
- `docs/designs/home-tab/redlines.md` — token mappings for greeting, date, avatar
- `docs/designs/home-tab/mockup-light.html` and `mockup-dark.html`
- `lib/features/home/presentation/screens/home_screen.dart` — the scaffold slot to fill
- `lib/features/more/presentation/providers/app_preferences_provider.dart` — source of `userName` and `languageCode`
- `lib/l10n/` — existing ARB files for greeting and date strings
- `EPIC_home_tab_redesign_v2.md` Section "HomeHeader" — component spec and tokens

## Outputs (agent must produce)

- `lib/features/home/presentation/widgets/home_header.dart` — `HomeHeader` stateless presentational widget
- `lib/features/home/presentation/screens/home_screen.dart` — updated to inject `HomeHeader` into the header slot; reads `appPreferencesProvider` for `userName` and `languageCode`
- `lib/l10n/app_en.arb` — greeting keys: `homeGreetingMorning`, `homeGreetingAfternoon`, `homeGreetingEvening`; date format key
- `lib/l10n/app_tr.arb` — TR translations for the same keys (PM owns TR content; engineer adds placeholder strings marked `// TODO: TR review`)
- `test/features/home/widgets/home_header_test.dart` — widget tests: morning/afternoon/evening greeting, empty userName, userName present, avatar tap callback fires
- `docs/prs/epic8a-05.md`

## Acceptance Criteria

- [ ] Greeting shows "Good morning" for 08:00, "Good afternoon" for 14:00, "Good evening" for 20:00 (verified by injecting a fixed `currentDate`)
- [ ] With `userName = "Burak"`, header shows "Good evening, Burak"
- [ ] With `userName = ""` or null, header shows "Good evening" with no comma or trailing space
- [ ] Date renders in EN locale as `Thursday, 30 April` and in TR locale as `30 Nisan Perşembe`
- [ ] Avatar shows the first letter of `userName` (uppercase); if `userName` is empty, shows a person icon or empty circle (as per `spec.md`)
- [ ] Avatar tap fires `onAvatarTap` callback; `HomeScreen` wires this to `context.go(AppRoutes.settings)`
- [ ] Widget respects Dynamic Type: text clamps between 0.85× and 1.3× of base size
- [ ] No hardcoded colors; all colors via theme tokens
- [ ] All widget tests pass; `flutter analyze` and `dart format` pass

## Out of Scope

- Editing the user's name (that is a Settings screen concern)
- Notification badge on avatar
- Profile picture / image avatar (V2)
- Analytics events (EPIC8A-12)

## Quality Bar

Widget tests must cover all greeting variants using a fixed `DateTime` input so tests are deterministic. The widget must not call `DateTime.now()` internally — the date is always passed in as a parameter.
