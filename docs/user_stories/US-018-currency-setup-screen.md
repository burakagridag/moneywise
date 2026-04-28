# US-018: Multi-currency setup — main currency and sub-currency selector

## Persona
A MoneyWise user who holds accounts in multiple currencies (e.g. EUR as main, USD and TRY as
sub-currencies) and wants to configure which currency is the primary display currency and which
additional currencies are enabled, so that all balances and reports are shown in their preferred
unit.

## Story
**As** a MoneyWise user
**I want** to set my main display currency and optionally enable additional sub-currencies
**So that** all account balances, summaries, and reports use my preferred currency and I can
record transactions in other currencies with my own exchange rate

## Source
SPEC.md §9.16 (CurrencyScreen, /more/currency-main and /more/currency-sub);
SPEC.md §6.9 (settings KV store — mainCurrency, subCurrencies keys);
SPEC.md §6.10 (currencies table — ISO 4217 code, name, symbol, decimalDigits, rateToBase).
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Main Currency screen lists all ISO 4217 currencies
  Given the user navigates to More > Main Currency Setting
  When the CurrencyScreen opens in main-currency mode
  Then a searchable list of currencies is shown
  And each row displays: flag (or placeholder), currency code, full name, symbol
  And the currently active main currency is highlighted with a brand-colour check mark

Scenario: Default main currency is EUR on first launch
  Given the app is launched for the first time
  When the user opens More > Main Currency Setting
  Then EUR is selected (checked) in the list

Scenario: Select a new main currency
  Given EUR is the current main currency
  When the user taps "TRY — Turkish Lira — ₺" in the list
  Then TRY receives the check mark
  And EUR loses the check mark
  And the settings KV entry mainCurrency is updated to "TRY"
  And the user is navigated back to MoreScreen

Scenario: Main currency search filters the list
  Given the currency list is open
  When the user types "USD" in the search bar
  Then only USD (and any matching) currencies are shown
  When the user clears the search
  Then the full list is shown again

Scenario: Sub Currency screen allows multiple selections
  Given the user navigates to More > Sub Currency Setting
  When SubCurrencyScreen opens
  Then a list of all ISO 4217 currencies is shown with toggles
  And currencies already selected are toggled ON
  And the main currency is excluded from the list (cannot be added as sub)

Scenario: Enable a sub-currency
  Given no sub-currencies are selected
  When the user toggles ON "USD"
  Then USD is added to the subCurrencies setting (JSON array)
  And USD row shows a manual exchange rate field defaulting to 1.0

Scenario: Set manual exchange rate for a sub-currency
  Given USD is toggled ON with default rate 1.0
  When the user enters rate 1.08 in the exchange rate field for USD
  Then the currencies table row for USD has rateToBase = 1.08
  And rateUpdatedAt is set to the current timestamp

Scenario: Disable a sub-currency
  Given USD is toggled ON
  When the user toggles OFF USD
  Then USD is removed from subCurrencies setting
  And the USD exchange rate field disappears

Scenario: Main currency cannot be toggled OFF via sub-currency screen
  Given main currency is EUR
  Then EUR does not appear in the sub-currency list at all

Scenario: Currency settings persist across app restart
  Given the user sets main currency to TRY and enables USD as sub-currency
  When the app is killed and relaunched
  Then mainCurrency is still "TRY"
  And subCurrencies still contains "USD"
```

## Edge Cases
- [ ] First launch with no mainCurrency in settings — app must default to EUR without crash
- [ ] Search with no results — show "No currencies found" empty state; not a blank list
- [ ] Exchange rate = 0 — must be rejected with a validation error; rate must be > 0
- [ ] Exchange rate field: very small values (0.000001 for weak currencies) — display with sufficient decimal precision; use money2 for storage
- [ ] Changing the main currency when accounts already exist in the old currency — in Sprint 2 the app stores the currencyCode per account; changing main currency does NOT retroactively change account currencies; it only changes the display preference. A warning dialog must explain this: "This changes the display currency. Existing account currencies are not modified."
- [ ] Long currency name or symbol (some codes have long official names) — list row must truncate gracefully with ellipsis
- [ ] Offline — all changes are local; exchange rate API fetch is deferred to Sprint 5 (Phase 2); the "Fetch rates automatically" button is shown but disabled with a "Coming soon" label
- [ ] Dark mode and Light mode rendering

## Test Scenarios for QA
1. Main currency screen: verify EUR selected on fresh install, on both iOS and Android
2. Select TRY as main: verify settings KV updated and UI check mark moved
3. Search "GBP": verify only GBP (and matches) appear; clear: full list restored
4. Sub-currency screen: verify main currency absent from list
5. Toggle USD ON: verify subCurrencies setting updated in DB
6. Set exchange rate 1.08 for USD: verify currencies table rateToBase = 1.08
7. Toggle USD OFF: verify removed from subCurrencies, rate field disappears
8. Set exchange rate = 0: verify validation error shown
9. Restart app: verify mainCurrency and subCurrencies persist
10. Change main currency when accounts exist: verify warning dialog shown

## UX Spec
TBD — ux-designer to deliver `docs/specs/SPEC-007-currency-screen.md` during Sprint 2.
Reference: SPEC.md §9.16.

## Estimate
M (3–4 days)

## Dependencies
- US-004 (Drift DB — settings table and currencies table)
- US-013 is not a dependency (categories are independent)
- US-014 is not a dependency
- US-016 references this screen for the per-account currency picker; currency picker can be
  delivered as a shared widget in this story
