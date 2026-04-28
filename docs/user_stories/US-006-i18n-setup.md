# US-006: i18n setup — flutter_localizations + TR and EN ARB files, locale switching works

## Source
SPEC.md §5 (core/i18n/), §9.15 (LanguageScreen), §16.1 Sprint 1 checklist — "i18n setup (TR + EN)"

## Persona
A MoneyWise user who prefers Turkish or English and wants the app to display in their chosen language from first launch.

## Story
**As** a MoneyWise user
**I want** to use the app in my preferred language (Turkish or English)
**So that** all labels, messages, and navigation text are shown in the language I understand

## Acceptance Criteria

```gherkin
Scenario: App uses device locale on first launch
  Given the device system language is set to Turkish (tr)
  When the app is launched for the first time
  Then all visible text in the app is displayed in Turkish
  And the locale in use is "tr"

Scenario: App uses English when device locale is English
  Given the device system language is set to English (en)
  When the app is launched for the first time
  Then all visible text in the app is displayed in English
  And the locale in use is "en"

Scenario: App falls back to English for unsupported device locales
  Given the device system language is set to Japanese (ja), which is not yet supported
  When the app is launched
  Then the app displays in English (the fallback locale)
  And no missing-translation warning crashes the app

Scenario: Locale can be changed in-app to Turkish
  Given the app is running in English
  When the user navigates to More > Language and selects "Turkce"
  Then the app immediately re-renders all screens in Turkish
  And the new locale preference is persisted
  And after a cold restart the app opens in Turkish

Scenario: Locale can be changed in-app to English
  Given the app is running in Turkish
  When the user navigates to More > Language and selects "English"
  Then the app immediately re-renders all screens in English
  And the new locale preference is persisted

Scenario: ARB files contain at minimum the Sprint 1 string keys
  Given app_en.arb and app_tr.arb exist in lib/core/i18n/arb/
  When the ARB files are inspected
  Then both files define the same set of keys
  And the Turkish file provides Turkish values for all keys
  And at a minimum the following keys are present:
    | tabTransactions |
    | tabStats        |
    | tabAccounts     |
    | tabMore         |
    | appName         |

Scenario: Missing translation key produces a visible fallback, not a crash
  Given a translation key is present in app_en.arb but accidentally omitted from app_tr.arb
  When the app is running in Turkish and that key is rendered
  Then the English fallback string is displayed
  And no exception is thrown
```

## Edge Cases
- [ ] Right-to-left (RTL) locales are not in scope for Sprint 1 but the MaterialApp must include `Directionality` support so it does not break when added later
- [ ] Numbers and dates formatted via `intl` must respect the active locale (e.g., date separator differs between TR and EN)
- [ ] The locale_provider.dart must persist the user's choice using SharedPreferences or the settings Drift table (decision to be made by flutter-engineer in Sprint 1; document chosen approach)
- [ ] Generating the l10n files requires running `flutter gen-l10n`; the CI pipeline must include this step before `flutter analyze`
- [ ] Zero-width characters or special Turkish characters (ğ, ü, ş, ı, ö, ç) must render correctly on both iOS and Android
- [ ] App name in launcher is not localised via ARB — each flavor's native config handles this; document this limitation

## Test Scenarios for QA
1. Set device language to Turkish, launch app — verify all tab labels and visible strings are in Turkish
2. Set device language to English, launch app — verify all strings are in English
3. Set device language to an unsupported locale (e.g., Japanese) — verify app launches in English without crash
4. Change language from English to Turkish in-app — verify immediate re-render, no restart required
5. Close and relaunch app after language change — verify persisted locale is respected
6. Run `flutter gen-l10n` and then `flutter analyze` — zero errors

## UX Spec
TBD — ux-designer Sprint 1 (Language Selection bottom-sheet, per SPEC.md §9.15)

## Estimate
S (1–2 days)

## Dependencies
- US-001 (project skeleton)
- US-005 (folder structure — i18n directory)
- US-007 (pubspec.yaml with intl and flutter_localizations)
