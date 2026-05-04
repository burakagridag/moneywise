# Test Plan — EPIC8B-08a: Accessibility + Performance Audit (InsightCard & Home Tab)

**Story:** EPIC8B-08a
**Status:** DRAFT — pre-implementation. Activate after Sponsor go-signal and simulator testing.
**Created:** 2026-05-02
**Tester:** qa-agent
**Coverage scope:** InsightCard widget (to-be-built), Home tab with insights visible, RuleBasedInsightProvider.generate()

---

## Context

Sprint 8b delivered four insight rules (ConcentrationRule, SavingsGoalRule, DailyOverpacingRule, BigTransactionRule) plus a FifthRulePlaceholder. The `insightsProvider` assembles an `InsightContext` from live Drift data and maps results to `InsightViewModel` objects for the presentation layer. EPIC8B-08a is the mid-sprint quality gate verifying that the forthcoming `InsightCard` widgets and the populated Home tab meet WCAG 2.1 AA accessibility requirements and the 16ms/300ms/60fps performance thresholds defined by the team.

**Implementation artefacts under test (once built):**
- `lib/features/insights/presentation/widgets/insight_card.dart` — InsightCard widget
- `lib/features/home/presentation/screens/home_screen.dart` — Home tab with ThisWeekSection
- `lib/features/insights/presentation/providers/insights_providers.dart` — insightsProvider
- `lib/features/insights/data/rule_based_insight_provider.dart` — RuleBasedInsightProvider.generate()

---

## Test Environments

| Platform | Device | OS | Theme |
|----------|--------|----|-------|
| iOS primary | iPhone 15 Pro simulator (Xcode 16+) | iOS 17 | Light + Dark |
| iOS N-1 | iPhone 13 simulator | iOS 16 | Light |
| Android primary | Pixel 7 Pro emulator | Android 14 | Light + Dark |
| Android N-1 | Pixel 6 emulator | Android 13 | Light |

Locale tested: EN and TR on each primary device.

---

## Test Data Seeds

All performance scenarios require a pre-seeded dataset. Apply before running Section B tests.

### Seed DS-1: Typical user (rule evaluation benchmark)
- 200 expense transactions spread across current month
- 10 categories (each with at least 1 transaction)
- 5 active category budgets (2 categories unbudgeted intentionally)
- Global monthly budget: EUR 2 000
- 1 transaction >= 31% of global budget (triggers BigTransactionRule)
- Top category >= 71% of total spend (triggers ConcentrationRule)
- Income: EUR 0 (SavingsGoalRule suppressed — avoids noise in perf benchmark)
- referenceDate.day: 15 (DailyOverpacingRule can trigger)

### Seed DS-2: Empty state (cold-start baseline)
- 0 transactions, 0 accounts, 0 budgets
- Used for cold-start delta measurement only

### Seed DS-3: Large dataset (scroll stress)
- 1 000 expense transactions across current month
- 4 insight cards visible (all four V1 rules firing)
- Used for scroll frame rate test

---

## Section A — Accessibility Tests

### A-01: Semantics labels — VoiceOver (iOS)

**Precondition:** DS-1 seeded. Insights section on Home tab shows at least 2 insight cards.
Enable VoiceOver: Settings > Accessibility > VoiceOver > On.

**Steps:**
1. Navigate to Home tab.
2. Swipe right with one finger to move focus through the insight cards in the "This week" section.
3. For each InsightCard, listen to what VoiceOver announces.

**Expected per card:**
- VoiceOver announces a label that includes: severity (e.g., "Warning" or "Critical"), headline text, and body text — without requiring the user to read the color of the card.
- Example for DailyOverpacingRule: "Critical — Overspending pace — At this rate, you'll exceed your budget by end of month."
- The icon container must NOT be announced as a separate focusable element (it is decorative; `ExcludeSemantics` or `Semantics(excludeSemantics: true)` must wrap the icon).
- If the card has an `actionRoute`, the card element is announced as "button" in the traits.
- If the card has no `actionRoute`, it is announced without "button" trait.

**Pass criteria:**
- [ ] Severity is communicated in the announced label (not only by icon color)
- [ ] Headline is included in the announced label
- [ ] Body is included in the announced label
- [ ] Icon container is excluded from the focus order (VoiceOver skips it silently)
- [ ] Tappable cards carry "button" trait; non-tappable cards do not
- [ ] VoiceOver does not announce raw widget type names (e.g., "text" or "image" in isolation)

---

### A-02: Semantics labels — TalkBack (Android)

**Precondition:** DS-1 seeded. Same 2+ cards visible.
Enable TalkBack: Settings > Accessibility > TalkBack > On.

**Steps:**
1. Navigate to Home tab.
2. Swipe right to advance focus through insight cards.
3. For each InsightCard, listen to TalkBack announcement.

**Expected:** Identical to A-01 for content. TalkBack uses "double-tap to activate" on tappable cards (instead of VoiceOver's "button" trait) — this is platform-expected and not a bug.

**Pass criteria:**
- [ ] Severity, headline, and body all announced for each card
- [ ] Icon excluded from focus traversal
- [ ] Tappable cards: TalkBack says "double-tap to activate"
- [ ] Non-tappable cards: no "double-tap to activate" announcement
- [ ] No announcement of raw Color values or internal widget state

---

### A-03: Color contrast — light theme

**Precondition:** Light theme active. All 4 insight rules firing (DS-1).

Test each of the following InsightCard visual configurations using a contrast analyzer (e.g., Colour Contrast Analyser desktop tool on a screenshot, or Flutter's `SemanticsDebugger`):

| Card | Background | Text color | Icon color | Min required ratio |
|------|-----------|------------|------------|-------------------|
| ConcentrationRule (warning) | amber-100 `#FEF3C7` | Body text (theme textPrimary) | amber-500 `#F59E0B` | 4.5:1 (text); 3:1 (icon, UI component) |
| SavingsGoalRule (warning) | amber 12% alpha on white | Body text | amber-700 | 4.5:1 (text); 3:1 (icon) |
| DailyOverpacingRule (critical) | red-100 `#FEE2E2` | Body text | red-500 `#EF4444` | 4.5:1 (text); 3:1 (icon) |
| BigTransactionRule (warning) | amber-100 `#FEF3C7` | Body text | amber-500 `#F59E0B` | 4.5:1 (text); 3:1 (icon) |
| Fallback info card | gray-100 `#F3F4F6` | Body text | gray-500 `#6B7280` | 4.5:1 (text); 3:1 (icon) |

**Note on amber-100 + body text:** The tinted icon container background does NOT contain the headline or body text. The headline and body text render on the card's overall background (e.g., theme surface or card color). Measure text contrast against the actual card background, not the icon container.

**Pass criteria (light theme):**
- [ ] All headline text: >= 4.5:1 against card background
- [ ] All body text: >= 4.5:1 against card background
- [ ] All icon colors: >= 3:1 against their icon container background
- [ ] No combination fails the 4.5:1 threshold for text

---

### A-04: Color contrast — dark theme

**Precondition:** Dark theme active. Same 4 cards visible.

The icon background colors defined in `insight_mapper.dart` are light-palette values (amber-100, red-100, gray-100). These will likely fail contrast in dark theme if used unchanged.

**Steps:**
1. Switch app to dark theme.
2. Inspect each InsightCard's icon container: does the icon remain legible?
3. Inspect headline and body text contrast against the dark card surface.
4. Screenshot each card variant and measure contrast ratios.

**Expected:** Flutter Engineer must apply theme-aware icon background colors in dark mode (e.g., amber-900 with amber-300 icon, red-900 with red-300 icon) rather than using the hardcoded light-palette values from `insight_mapper.dart`.

**Pass criteria (dark theme):**
- [ ] All headline text: >= 4.5:1 against dark card background
- [ ] All body text: >= 4.5:1 against dark card background
- [ ] All icon colors: >= 3:1 against their dark-mode icon container background
- [ ] amber-100 / red-100 / gray-100 hardcoded backgrounds do NOT appear in dark theme (they will fail contrast; engineer must use `Theme.of(context)` or `MediaQuery.platformBrightness` to select appropriate tints)

---

### A-05: Touch target size

**Precondition:** DS-1 seeded, at least 2 tappable cards visible (DailyOverpacingRule has `actionRoute`, others TBD per implementation).

**Steps:**
1. In Flutter DevTools > Widget Inspector, select each InsightCard.
2. Read the rendered height and width of the tappable `GestureDetector` or `InkWell` wrapping the card.
3. On a physical or simulator device with Flutter's `debugPaintSizeEnabled = true`, verify no card row is shorter than 44dp.

**Expected:**
- Each InsightCard's minimum height: >= 44dp (logical pixels).
- Each InsightCard's minimum width: full card width (extends to screen edges minus horizontal padding), which will be > 44dp on any supported device.
- Cards that have no `actionRoute` should still be >= 44dp tall for visual consistency, but a tap target that is non-interactive is acceptable below 44dp only if it is fully excluded from semantics (i.e., it is decorative-only — but insight cards are informational, so they should still be readable at full size).

**Pass criteria:**
- [ ] Every InsightCard rendered height >= 44dp in Widget Inspector
- [ ] Every tappable InsightCard (actionRoute != null) wrapped in at least a 44x44dp tap area
- [ ] No InsightCard clips its content at 44dp height (icon, headline, and at least first line of body must be visible)

---

### A-06: Color-blind safety — severity must not be communicated by color alone

**Precondition:** DS-1 seeded, all 4 insight rule cards visible.

**Test method:** Take a screenshot of the Home tab showing all 4 insight cards. Apply a grayscale filter (macOS: Preview > Adjust Color > Saturation to 0, or a browser extension). Alternatively, enable iOS Accessibility > Display & Text Size > Color Filters > Grayscale.

**Steps:**
1. Enable grayscale rendering on the simulator or use a post-processed screenshot.
2. For each InsightCard in grayscale, verify:
   a. The severity icon is still recognizable (different icons per severity).
   b. The headline text clearly communicates the nature of the issue without color cues.

**Expected:**
- ConcentrationRule (warning): `Icons.pie_chart_outline` + "Spending concentrated" — readable in grayscale.
- SavingsGoalRule (warning): `Icons.savings_outlined` + "Low savings rate" — readable.
- DailyOverpacingRule (critical): `Icons.trending_up` + "Overspending pace" — the critical severity must be distinguished from warning not by color alone. Verify that the icon differs from warning-severity cards OR that a text severity badge/label (e.g., "Critical") is present.
- BigTransactionRule (warning): `Icons.warning_amber_outlined` + "Large transaction" — readable.

**Known risk:** In V1, `critical` and `warning` both share amber-palette icon colors. In the current `insight_mapper.dart`, DailyOverpacingRule uses red (`#EF4444`) and BigTransactionRule uses amber (`#F59E0B`) — these are color-differentiated, but in grayscale they may be indistinguishable. The engineer must ensure that icon shape alone (or a severity text label) distinguishes critical from warning.

**Pass criteria:**
- [ ] In grayscale rendering, each card's meaning is conveyed without needing color
- [ ] Critical and warning cards are distinguishable in grayscale (different icon OR explicit severity text label)
- [ ] No card relies solely on icon background color tint to communicate severity

---

### A-07: Dynamic Type at 200% font scale (iOS only)

**Precondition:** DS-1 seeded, all 4 cards visible.
Enable Accessibility font size: Settings > Accessibility > Display & Text Size > Larger Text > drag to maximum (approximately 200% of default).

**Steps:**
1. Relaunch app with maximum accessibility font size active.
2. Navigate to Home tab.
3. Observe each InsightCard.

**Expected:**
- Headline text: single line with ellipsis (`overflow: TextOverflow.ellipsis`) when the text exceeds card width — no overflow rendering exception.
- Body text: single line with ellipsis OR wraps gracefully to 2 lines maximum — no overflow.
- Icon container: fixed 36x36dp; does not scale with text and does not get clipped.
- Card overall: expands vertically to accommodate larger text rather than clipping.
- No `RenderFlex overflow` yellow-stripe errors visible on screen.

**Pass criteria:**
- [ ] No `RenderFlex overflow` errors at 200% font scale
- [ ] Headline visible (may be truncated) — not clipped behind the icon or card edge
- [ ] Body visible (may be truncated) — not zero-height
- [ ] Icon container renders at intended fixed size, not distorted
- [ ] Card is still tappable (touch target not collapsed by overflow)

---

### A-08: Focus order in screen reader — severity-sorted traversal

**Precondition:** DS-1 seeded. Multiple severity levels firing: at least one `critical` (DailyOverpacingRule) and at least one `warning` (ConcentrationRule or BigTransactionRule).
Enable VoiceOver (iOS) or TalkBack (Android).

**Steps:**
1. Navigate to Home tab.
2. Advance focus through the insight cards by swiping right.
3. Note the order in which cards receive focus.

**Expected:**
- Focus order matches the display order in the widget tree.
- Display order is severity-sorted: `critical` cards appear before `warning` cards, which appear before `info` cards (per `RuleBasedInsightProvider.generate()` sort logic).
- Therefore, VoiceOver/TalkBack encounters the DailyOverpacingRule card (critical) before any warning-severity cards.
- Focus does not jump out of order or skip cards.

**Pass criteria:**
- [ ] Focus traversal order matches visual render order (top-to-bottom)
- [ ] Critical card(s) focused before warning card(s)
- [ ] Warning card(s) focused before info card(s) (if info cards present)
- [ ] No cards skipped during traversal
- [ ] Focus does not trap inside a card (user can always advance to next card)

---

## Section B — Performance Tests

### B-01: Rule evaluation time — generate() must complete within one frame budget

**Measurement method:** Unit test with `Stopwatch` (not a widget test — pure Dart).

**Test setup:**
Create a unit test in `test/features/insights/rule_based_insight_provider_perf_test.dart`:
1. Construct an `InsightContext` using DS-1 data (200 transactions, 10 categories, 5 budgets, effectiveBudget: 2000.0, referenceDate: day 15 of current month).
2. Instantiate `RuleBasedInsightProvider` with all 5 rules (ConcentrationRule, SavingsGoalRule, DailyOverpacingRule, BigTransactionRule, FifthRulePlaceholder).
3. Call `generate(context)` 100 times in a loop; record total elapsed time.
4. Calculate mean per-call duration = totalElapsed / 100.

**Expected:** Mean duration per `generate()` call < 16ms.

**Rationale:** `generate()` runs synchronously on the UI isolate inside `insightsProvider`. A single call must not consume more than one 16ms frame budget. With 5 rules each doing simple arithmetic over a 200-transaction list, the expected actual time is < 1ms — the 16ms budget is a hard ceiling, not an aspirational target.

**Pass criteria:**
- [ ] Mean `generate()` time over 100 iterations < 16ms with DS-1 dataset
- [ ] No single call exceeds 32ms (2-frame budget) in any of the 100 iterations
- [ ] Test is reproducible on CI (emulator or pure Dart VM); no flakiness

**Failure action:** If > 16ms, file P1 bug. Root cause will likely be an O(n²) operation in a rule (e.g., nested loops over transactions and budgets). DailyOverpacingRule and BigTransactionRule both iterate `currentMonthTransactions` — verify `O(n)` behaviour.

---

### B-02: insightsProvider rebuild frequency

**Measurement method:** Flutter DevTools > Performance > Rebuild Stats, or add a `debugPrint` counter inside `insightsProvider`.

**Test setup:**
1. Launch app with DS-1 seeded.
2. Open Flutter DevTools > Performance > Enable "Track Widget Builds".
3. Navigate to Home tab. Wait for insights to load.
4. Perform one user action: navigate to Transactions tab and return to Home tab (triggers tab switch, not a data change).
5. Observe insightsProvider rebuild count.

**Expected:**
- Initial load: insightsProvider rebuilds exactly once (one `AsyncData` emission after the `await` chain resolves).
- Tab switch with no data change: insightsProvider does NOT rebuild (Riverpod caches the `Future` result; a tab switch navigates the router but does not invalidate the provider unless data changes).
- No spurious rebuilds caused by unrelated providers (e.g., theme provider, locale provider) triggering insightsProvider unnecessarily.

**Verification for spurious rebuild check:**
- Toggle app theme (light → dark) while on Home tab.
- Verify insightsProvider does NOT rebuild (theme change is unrelated to financial data).

**Pass criteria:**
- [ ] insightsProvider rebuilds exactly once during initial Home tab load
- [ ] Tab navigation (Home → Transactions → Home) does not trigger a second rebuild
- [ ] Theme toggle does not trigger insightsProvider rebuild
- [ ] Locale switch (EN → TR) does not trigger insightsProvider rebuild (i18n strings are in the widget layer, not in the provider)

---

### B-03: Home tab first visible InsightCard — render time < 300ms

**Measurement method:** Flutter DevTools > Performance timeline, or `dart:developer` Timeline events wrapping the navigation call.

**Test setup:**
1. App is running (warm start — not cold). DS-1 is seeded.
2. Navigate away from Home tab to Transactions tab.
3. Tap Home tab icon. Start timer at tap.
4. Stop timer when the first InsightCard renders its content visibly (not a loading skeleton — actual headline text visible).

**Platforms:**
- iOS: iPhone 15 Pro simulator (Xcode 16). Profile build (`flutter run --profile`).
- Android: Pixel 7 Pro emulator. Profile build.

**Expected:** Time from Home tab tap to first InsightCard content visible < 300ms.

**Rationale:** insightsProvider is a `FutureProvider` that awaits 4 async data sources (two `repo.getByMonth()` calls, one `budgetsForMonthProvider`, one `effectiveBudgetProvider`). The UI should show a loading skeleton or shimmer immediately (< 32ms) and resolve to real content within the 300ms budget. If no skeleton is implemented, the 300ms budget covers the full latency to first content.

**Pass criteria:**
- [ ] iOS (iPhone 15 Pro simulator, profile mode): < 300ms to first InsightCard content
- [ ] Android (Pixel 7 Pro emulator, profile mode): < 300ms to first InsightCard content
- [ ] If a loading skeleton is shown: skeleton appears within 32ms; final content within 300ms
- [ ] No frame drop (jank) during the content transition from loading to loaded state

---

### B-04: Scroll frame rate — 60fps during Home tab scroll with 4 insight cards

**Measurement method:** Flutter DevTools > Performance > Frame timeline.

**Test setup:**
1. DS-3 seeded (all 4 rules firing). Home tab shows 4 insight cards in the "This week" section plus other Home tab content below (total balance, onboarding cards if applicable, recent transactions).
2. Profile build on primary simulators.
3. Scroll the Home tab up and down 5 times continuously while DevTools records frames.

**Expected:**
- All frames render within 16.6ms (60fps target).
- No dropped frames ("red" frames in DevTools frame chart) during smooth, continuous scroll.
- Jank threshold: zero dropped frames in a 5-second scroll sequence is ideal; the acceptable threshold is < 2% dropped frames (< 6 dropped frames in 300 frames).

**Pass criteria:**
- [ ] iOS: < 2% dropped frames during 5-second continuous scroll
- [ ] Android: < 2% dropped frames during 5-second continuous scroll
- [ ] No single frame exceeds 33ms (2x budget) during scroll
- [ ] InsightCard widgets use `const` constructors where possible (verify via Widget Inspector — non-const widgets rebuild unnecessarily on parent rebuild)

---

### B-05: Cold start time delta — insight rules must not regress startup by > 50ms

**Measurement method:** `flutter run --profile` with `dart:developer` `Timeline.startSync('AppStartup') / endSync()`, or Android `adb logcat` startup timing / iOS Instruments "App Launch" template.

**Baseline:** EPIC8B-05 stub baseline (insightsProvider wired with empty rules that return `[]` immediately — no database calls). Record cold start time: T_baseline.

**Test:** Full EPIC8B implementation (4 concrete rules + FifthRulePlaceholder). Record cold start time: T_actual.

**Expected:** T_actual - T_baseline < 50ms.

**Rationale:** `insightsProvider` is a `FutureProvider` — it does not block the widget tree from rendering. Cold start time should not increase because insightsProvider does not block `main()` or the first frame. The 50ms budget catches regressions from accidental synchronous work introduced in the insight layer at startup.

**Steps:**
1. Cold-start the app with the EPIC8B-05 stub (empty rules). Measure 5 cold starts, discard highest and lowest, average the remaining 3. Record as T_baseline.
2. Cold-start the app with EPIC8B full rules (DS-1 seeded). Measure 5 cold starts, same averaging. Record as T_actual.
3. Compute delta.

**Pass criteria:**
- [ ] iOS delta (T_actual - T_baseline) < 50ms
- [ ] Android delta (T_actual - T_baseline) < 50ms
- [ ] If no EPIC8B-05 stub baseline is available, record T_actual and flag for comparison in Sprint 8c

---

## Section C — Regression Checks

Run these checks after A and B pass to confirm that adding insights did not break existing Home tab behavior.

- [ ] Total Balance card (EPIC8A-05) still renders correctly with DS-1 data
- [ ] Empty-state onboarding cards (EPIC8A-10) hide/show correctly — adding DS-1 data satisfies all three completion criteria; verify "Get started" section is fully hidden
- [ ] Insight section is hidden when insightsProvider returns `[]` (empty rules state)
- [ ] Pull-to-refresh on Home tab invalidates insightsProvider and reloads cards
- [ ] Navigating Home → Stats → Home: insights are still visible (not cleared by navigation)
- [ ] Theme toggle (light → dark): InsightCard icon backgrounds update; no stale light-theme colors remain
- [ ] Locale switch (EN → TR): InsightCard headline and body text update to Turkish strings (verify with Flutter Engineer that TR ARB keys are defined for each insight message)

---

## Section D — Cross-Platform Parity

For each of the following, verify behavior is identical on iOS and Android. Document any difference as a potential bug.

| Check | iOS | Android |
|-------|-----|---------|
| InsightCard renders at same height | | |
| Severity sort order (critical before warning) | | |
| VoiceOver / TalkBack announcement content matches | | |
| Dark theme icon backgrounds correct | | |
| 200% font scale — no overflow | | |
| Pull-to-refresh gesture triggers provider invalidation | | |
| Tappable card navigates to correct route | | |

---

## Pass / Fail Summary Checklist

Copy this section into the QA sign-off comment once testing is complete.

### Accessibility
- [ ] A-01 VoiceOver semantics labels — iOS
- [ ] A-02 TalkBack semantics labels — Android
- [ ] A-03 Color contrast light theme — all 5 card variants
- [ ] A-04 Color contrast dark theme — all 5 card variants
- [ ] A-05 Touch target >= 44x44dp
- [ ] A-06 Color-blind safety — grayscale rendering
- [ ] A-07 Dynamic Type 200% — no overflow (iOS)
- [ ] A-08 Focus order matches severity sort

### Performance
- [ ] B-01 generate() < 16ms (unit test, 100 iterations)
- [ ] B-02 insightsProvider no spurious rebuilds
- [ ] B-03 First InsightCard visible < 300ms (profile mode)
- [ ] B-04 Scroll at 60fps — < 2% dropped frames
- [ ] B-05 Cold start delta < 50ms

### Regression
- [ ] C — All regression checks pass (see Section C checklist)

### Cross-platform parity
- [ ] D — No iOS/Android behavioral differences (see Section D table)

---

## Bug Severity Reference

| Severity | Definition for this story |
|----------|--------------------------|
| P0 | Any accessibility test blocks VoiceOver/TalkBack users from reading insight content; or generate() > 32ms (2-frame jank) |
| P1 | Contrast ratio failure in any theme; touch target < 44dp on tappable card; color-blind users cannot distinguish critical from warning; first render > 500ms |
| P2 | Dynamic Type overflow (cosmetic, non-crashing); spurious provider rebuild adding latency; cold start delta 50–100ms |
| P3 | Minor focus order deviation (e.g., tied severity cards in wrong sub-order); cosmetic dark-theme tint shade mismatch |

---

## Open Questions — RESOLVED (2026-05-03, Sponsor)

1. **InsightCard actionRoute mapping:** ✅ RESOLVED — Sprint 8b: **no rules are tappable** (actionRoute = null on all 4). Sprint 8c will wire actionRoutes as follows:
   - ConcentrationRule → category breakdown drill-down (EPIC8B-06, Sprint 8c)
   - DailyOverpacingRule → Budget tab (Sprint 8c)
   - BigTransactionRule → transaction detail sheet (Sprint 8c)
   - SavingsGoalRule → V1.x only (requires user-configurable savings goal entity, not yet scoped)
   For Sprint 8b QA: test A-01/A-02 with non-interactive card semantics (no "button" trait expected). B-04 navigation test deferred to Sprint 8c.

2. **TR ARB keys for insight messages:** ✅ RESOLVED — All 4 rules have EN + TR translations in `app_en.arb` / `app_tr.arb`. Section C regression check will pass.

3. **Loading skeleton:** ✅ RESOLVED — No shimmer/skeleton in Sprint 8b. `insightsProvider` transitions directly to content. B-03 measures time-to-content directly.

4. **EPIC8B-05 stub baseline binary:** ✅ RESOLVED — No tagged baseline artifact exists. Record T_actual in Sprint 8b; defer delta comparison to Sprint 8c when a tagged baseline can be created at sprint start.

5. **FifthRulePlaceholder:** ✅ RESOLVED — Confirmed always returns null. Include in B-01 timing; overhead expected to be < 0.01ms (single null return).
