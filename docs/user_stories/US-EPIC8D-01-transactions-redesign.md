# US-EPIC8D-01: Transactions Screen Redesign — 3-Tab Focused Layout

**Epic:** EPIC8D — Transactions Screen Redesign  
**Sprint:** 8d  
**Story Points:** 5pt  
**Source:** Sponsor spec `docs/specs/SPEC-021-transactions-redesign.md` (2026-05-08) + ADR-015 Design Token Unification  
**Status:** Ready for Engineering

---

## Persona

A MoneyWise user who checks their spending daily and wants to review transactions, navigate by calendar, and get a monthly summary — all within a single coherent screen that matches the visual design of the Home and Budget screens.

---

## Story

**As** a MoneyWise user  
**I want** the Transactions screen redesigned from 5 tabs to a focused 3-tab layout (Liste / Takvim / Özet) with the same warm-beige card design language used on the Home and Budget screens  
**So that** I can find what I need with less cognitive overhead and the app feels visually unified across all major screens

---

## Resolved Open Questions (Pre-Engineering Decisions)

The following questions from Section 7 of `SPEC-021` are now formally resolved:

| # | Question | V1 Decision | V1.x Deferral |
|---|----------|-------------|---------------|
| Q1 | Quick category chips source | Most-used categories from the last 30 days of transactions (top 4 by frequency) | V1.x: manual pin option |
| Q2 | Recurring transaction indicator | Out of scope for this story | Add in V1.x as separate story |
| Q3 | Calendar day tap behavior | Switch active tab to Liste (no scroll-to-position, no bottom sheet) | V1.x: bottom sheet day detail |
| Q4 | Bookmark feature semantics | Bookmark = saved transaction **template** (not a favorite flag). Tapping the bookmark icon opens `BookmarkPickerModal`, which lists named templates (`Bookmark` entity: name, type, optional amount/account/category/note). User selects a template to pre-fill the Add Transaction form. No change to bookmark semantics in this story — only layout cleanup of the icon in the header. | — |
| Q5 | Search scope | Full-text search across: category name + note/description text + account name (already implemented in `applySearchFilter`). Amount filter remains a separate filter chip, not part of text search. | V1.x: fuzzy/ML search |

---

## Current Description Tab — Content Analysis for Migration

Based on codebase inspection (`lib/features/transactions/`), the existing Description tab content could not be located as a standalone widget file. The `TransactionAddEditScreen` has a `_noteController` (the per-transaction "Note/description" free-text field stored as `transaction.description`). The old "Description" tab in the 5-tab layout most likely surfaced this per-transaction note field in a list context.

**Migration instruction for Flutter Engineer:** Run `git log --all --full-history -- "*description*tab*"` to confirm whether a Description tab widget was ever committed. If the tab only showed the `transaction.description` string field from existing transaction rows, that content is already visible in the Liste tab's transaction rows (via note/description text). No separate migration of Description tab content into Özet is required for V1. If a richer "Description" tab widget is found in git history, flag to PM before proceeding.

---

## Definition of Ready

- [x] Acceptance criteria written in Gherkin format
- [x] UX spec exists: `docs/specs/SPEC-021-transactions-redesign.md` + HTML mockups at `docs/specs/references/EPIC8D-01-v1-*.html`
- [x] Estimate provided: 5pt
- [x] Dependencies identified (see below)
- [x] Edge cases enumerated
- [x] Test scenarios outlined

### Dependencies

- ADR-015 (Design Token Unification) — tokens must be defined before this story can use them. If ADR-015 is not yet written, Flutter Engineer must write it as the first sub-task of this story.
- `Bookmark` entity and `BookmarkPickerModal` already implemented — no changes needed to bookmark data layer.
- `SearchFilterNotifier` and `applySearchFilter` already implemented — search scope (Q5) is satisfied by existing code.
- `TransactionAddEditScreen` already has dual CTA (Save / Save & Continue) — modal UI update is incremental.

---

## Acceptance Criteria

```gherkin
# ─────────────────────────────────────────────
# Feature: Transactions Screen — Common Header
# ─────────────────────────────────────────────

Feature: Transactions screen common header

  Scenario: Header renders correctly on all tabs
    Given I am on the Transactions screen on any tab
    Then I see a search icon left-aligned in the AppBar
    And I see the title "İşlemler" / "Transactions" center or brand-bold
    And I see a bookmark icon right-aligned
    And I see a filter icon right-aligned next to bookmark
    And I see a month navigator row below the AppBar with back and forward arrows
    And I see a 3-tab bar: "Liste" | "Takvim" | "Özet"
    And the active tab has a slate-blue underline indicator (#3D5A99 light / #4F46E5 dark)

  Scenario: Month navigator changes the period
    Given I am on the Transactions screen
    When I tap the back arrow in the month navigator
    Then the displayed month decrements by one
    And all three tabs reflect the new period's data
    When I tap the forward arrow
    Then the displayed month increments by one

  Scenario: Background and card surface use ADR-015 tokens
    Given I am on the Transactions screen in light mode
    Then the page background is #F7F6F3 (warm beige)
    And transaction cards have a #FFFFFF surface with 16px border radius and 0 2px 8px rgba(0,0,0,0.04) shadow
    Given I am on the Transactions screen in dark mode
    Then the page background is #0F1117
    And transaction cards have a #181C27 surface

# ─────────────────────────────────────────────
# Feature: Liste Tab (default)
# ─────────────────────────────────────────────

Feature: Liste tab — day-grouped transaction list

  Scenario: Liste tab is selected by default on screen open
    Given I navigate to the Transactions screen
    Then the "Liste" tab is selected
    And I see transactions grouped by day for the current month

  Scenario: Summary strip shows monthly income, expense, and net
    Given I am on the Liste tab
    And the selected month has income of €1,000.00 and expenses of €10.00
    Then I see a summary strip with three columns: "Gelir +1.000 €" | "Gider −10 €" | "Net +990 €"
    And income amounts are displayed in success green (#047857 light / #34D399 dark)
    And expense amounts are displayed in danger red (#C0392B light / #E55A4E dark)
    And net positive amounts are displayed in text-primary (#1A1C24 light / #F0F2F8 dark)
    And net negative amounts are displayed in danger red

  Scenario: Day header shows date and net day total
    Given I am on the Liste tab
    And May 8 has income €1,000.00 and expense €10.00
    Then I see a day header labeled "8 Cuma" with day number in slate-blue
    And the right side of the header shows "+990 €"

  Scenario: Transaction row displays category emoji, name, account, and colored amount
    Given I am on the Liste tab
    And a transaction exists: type=income, category="Maaş" (emoji 💰), account="DKB", amount=€1,000.00
    Then I see a row with a 32px circle emoji icon for "💰"
    And the category name "Maaş" displayed as body text
    And the account name "DKB" displayed as caption/secondary
    And the amount "+1.000,00 €" in success green

  Scenario: Expense transaction row amount is red
    Given a transaction exists: type=expense, category="Yemek" (emoji 🍜), amount=€10.00
    Then the amount "−10,00 €" is displayed in danger red

  Scenario: Multiple transactions on same day are grouped in one white card separated by dividers
    Given May 8 has 2 transactions (income + expense)
    Then both appear inside a single white card container
    And the two rows are separated by a 1px divider

  Scenario: FAB is visible on Liste tab
    Given I am on the Liste tab
    Then a FAB with "+" icon is visible in the bottom-right corner
    And the FAB has 16px border radius

# ─────────────────────────────────────────────
# Feature: Takvim Tab
# ─────────────────────────────────────────────

Feature: Takvim tab — monthly calendar grid

  Scenario: Calendar grid renders with weekday header (Monday-first, no weekend color)
    Given I am on the Takvim tab
    Then I see a weekday header row: P | S | Ç | P | C | C | P (TR) / M | T | W | T | F | S | S (EN)
    And Saturday and Sunday cells have no special color distinction from weekday cells

  Scenario: Calendar cell shows income and expense indicators for days with transactions
    Given May 8 has income €1,000.00 and expense €10.00
    When I view the Takvim tab for May 2026
    Then the cell for day 8 shows a green income indicator "+1K€" and a red expense indicator "−10€"

  Scenario: Today's date has a subtle ring marker
    Given today is May 8, 2026
    When I view the Takvim tab for May 2026
    Then day 8's cell has a brand-color ring (transparent fill)

  Scenario: Selected/active day has a filled slate-blue circle with white text
    Given I am on the Takvim tab
    When I tap day 12
    Then day 12 shows a slate-blue filled circle (#3D5A99 light / #4F46E5 dark) with white day number

  Scenario: Tapping a day with transactions switches to Liste tab
    Given I am on the Takvim tab
    And May 8 has transactions
    When I tap day 8
    Then the active tab switches to "Liste"
    And the Liste tab is displayed for the same month

  Scenario: Tapping a day with no transactions stays on Takvim (no action)
    Given I am on the Takvim tab
    And May 15 has no transactions
    When I tap day 15
    Then I remain on the Takvim tab
    And no navigation occurs

  Scenario: Summary strip is also visible on Takvim tab
    Given I am on the Takvim tab
    Then I see the same 3-column summary strip (Gelir / Gider / Net) as on the Liste tab

# ─────────────────────────────────────────────
# Feature: Özet Tab
# ─────────────────────────────────────────────

Feature: Özet tab — aggregated monthly summary

  Scenario: Hero metric card shows net total with income and expense sub-text
    Given I am on the Özet tab
    And the selected month has income €1,000.00 and expense €10.00
    Then I see a hero card with brand gradient (slate-blue #3D5A99 to #2E4A87)
    And the label "NET BU AY" / "NET THIS MONTH" in 12px uppercase caption
    And the net amount "+990,00 €" in 32px weight-700 white text
    And sub-text "+1.000 € gelir  −10 € gider" below the hero amount
    And a days-remaining label (e.g. "23 gün kaldı") in the top-right of the card

  Scenario: Top categories section shows up to 5 expense categories with progress bars
    Given the selected month has expenses in 3 categories: Yemek €10 (100%), others €0
    When I view the Özet tab
    Then I see a section titled "ÜST KATEGORİLER" / "TOP CATEGORIES"
    And I see at most 5 category rows
    And each row shows: emoji icon, category name, progress bar, percentage, and amount
    And the category with 100% spend shows a full progress bar
    And a contextual hint "Sadece 1 kategoride harcama var" / "Only 1 category has spending" appears when only 1 category exists

  Scenario: Week trend section shows bar chart with busiest week highlighted
    Given the selected month has spending distributed across 4 weeks
    When I view the Özet tab
    Then I see a section titled "HAFTA TRENDİ" / "WEEK TREND"
    And I see 4–5 vertical bars representing week-by-week net totals
    And the busiest week bar is highlighted
    And a label "En yoğun hafta: {date range}" / "Busiest week: {date range}" appears below the chart
    And the net for that week is shown as "{amount} net"

# ─────────────────────────────────────────────
# Feature: Empty State
# ─────────────────────────────────────────────

Feature: Empty state when no transactions exist for the selected month

  Scenario: Empty state renders with illustration, headline, subtitle, and CTA
    Given the selected month has zero transactions
    When I view the Transactions screen
    Then I see a brand-tinted circle illustration with a clipboard/list icon
    And a headline "Henüz işlem yok" / "No transactions yet" in 20px weight-600
    And a subtitle "Gelir, gider veya transferi ekleyerek başla" / "Start by adding income, expense, or transfer" in 15px text-secondary
    And a full-width brand CTA button "+ İlk işlemi ekle" / "Add first transaction" in slate-blue with white text
    And no tab bar is shown (tabs are hidden in empty state per spec Section 5.5)

  Scenario: Tapping the CTA in empty state opens the Add Transaction modal
    Given I am on the empty state
    When I tap "+ İlk işlemi ekle" / "Add first transaction"
    Then the Add Transaction modal opens
    And the type defaults to "Gider" / "Expense"

# ─────────────────────────────────────────────
# Feature: Add Transaction Modal
# ─────────────────────────────────────────────

Feature: Add Transaction modal — redesigned layout

  Scenario: Modal opens with big amount input, segmented type control, and quick chips
    Given I am on the Liste tab
    When I tap the FAB "+"
    Then a modal titled "Yeni İşlem" / "New Transaction" opens
    And I see a segmented control with 3 segments: "Gider" (selected by default) | "Gelir" | "Transfer"
    And I see a large amount input (36px weight-700) centered, showing "0,00 €" with currency suffix
    And I see up to 4 quick category chip pills below the amount input
    And I see form rows for: Kategori, Hesap, Tarih, Not (opsiyonel)
    And I see a primary "Kaydet" / "Save" button
    And I see a secondary "Kaydet & Devam" / "Save & Continue" button

  Scenario: Quick category chips show most-used categories from last 30 days
    Given I have used "Yemek" 10 times, "Ulaşım" 6 times, "Market" 4 times, "Sağlık" 2 times in the last 30 days
    When I open the Add Transaction modal with type "Gider"
    Then I see 4 quick chips in order: "🍜 Yemek" | "🚌 Ulaşım" | "🛒 Market" | "💊 Sağlık"

  Scenario: Quick chips are type-aware (income vs expense)
    Given I switch the type to "Gelir"
    Then the quick chips update to show the most-used income categories from the last 30 days

  Scenario: No quick chips shown when no transaction history exists
    Given the user has no transaction history in the last 30 days
    When I open the Add Transaction modal
    Then no quick chips row is rendered (section is hidden, not empty)

  Scenario: Tapping a quick chip pre-selects the category
    Given the Add Transaction modal is open
    When I tap the "🍜 Yemek" chip
    Then the Kategori row shows "🍜 Yemek" as the selected category
    And the chip appears visually selected (brand-blue tint)

  Scenario: Save button disabled when amount is 0 or empty
    Given the Add Transaction modal is open
    And the amount field shows "0,00 €"
    Then the "Kaydet" button is disabled

  Scenario: Save & Continue resets form and keeps modal open
    Given I fill in a valid expense (amount, category, account)
    When I tap "Kaydet & Devam" / "Save & Continue"
    Then the transaction is saved
    And the form resets to empty (amount "0,00 €", no category selected, date = today)
    And the modal remains open

# ─────────────────────────────────────────────
# Feature: Light / Dark Theme Parity
# ─────────────────────────────────────────────

Feature: Light and dark mode visual parity with Home and Budget screens

  Scenario: Light mode token parity with Home and Budget screens
    Given I switch to light mode
    When I open the Transactions screen
    Then the page background, card surface, border, shadow, and brand color
         match the tokens used on the Home screen and Budget screen (ADR-015)

  Scenario: Dark mode token parity with Home and Budget screens
    Given I switch to dark mode
    When I open the Transactions screen
    Then the page background (#0F1117), card surface (#181C27), and brand color (#4F46E5)
         match the dark-mode tokens used on the Home screen and Budget screen

  Scenario: Income / Expense colors update correctly in dark mode
    Given I am in dark mode on the Liste tab
    Then income amounts display in #34D399 (dark success green)
    And expense amounts display in #E55A4E (dark danger red)
```

---

## Edge Cases

### Empty / Zero States
- [ ] Month with zero transactions → empty state renders (no tab bar), CTA visible
- [ ] Month with only income transactions → Gider column in summary strip shows "−0 €" or "−"; Özet top-categories section shows "No expense categories" hint; week trend shows income-only bars
- [ ] Month with only expense transactions → Gelir column shows "+0 €"; hero net is negative (displayed in danger red per token spec)
- [ ] Day with zero transactions → day row is skipped in Liste tab (not rendered as empty card unless explicitly toggled on — spec Section 5.2 says "default skip")
- [ ] No transaction history in last 30 days → quick chips section hidden entirely in Add modal

### Boundary / Numeric
- [ ] Large amounts: €99,999.99 — must not overflow row, amount text truncates or scales, no float rounding artifacts
- [ ] Negative net month (expenses > income) — hero card net shown in danger red, same card gradient retained
- [ ] Zero net month (income == expense) — net shown in text-primary (neutral black), not red
- [ ] Amount exactly €0.00 entered in Add modal → Save button disabled, validation error shown

### Category / Text
- [ ] Very long category name (e.g. 40 chars) — category name truncates with ellipsis in transaction row; chip label truncates with ellipsis
- [ ] Category with no emoji set — emoji circle shows a default placeholder icon, not a broken container
- [ ] Note/description text longer than 100 chars — note field scrolls, row in Liste tab clips to 1–2 lines

### Calendar
- [ ] Month starting on Sunday — first row of Takvim grid shows correct offset (Monday-first grid means Sunday is column 7)
- [ ] February in a leap year — 29 days render correctly
- [ ] Current month shown → today marker ring is visible on today's cell; no marker shown for non-current months

### Search and Filter
- [ ] Search query matches only by account name (not category or note) → those transactions appear in results
- [ ] Search query with mixed case — search is case-insensitive
- [ ] Active filter + active search query — both predicates apply simultaneously
- [ ] Filter or search active when switching tabs — filter state persists across tab switches

### Offline / Persistence
- [ ] App is offline → all transaction data (local Drift/SQLite) loads normally; no network error shown
- [ ] Transaction added while filter is active → new transaction appears in filtered list if it matches criteria
- [ ] App restart after adding transactions → all transactions persist correctly

### Cross-Platform
- [ ] iOS: bottom safe area padding does not clip FAB or "Kaydet & Devam" button
- [ ] Android: system back gesture on Add modal with dirty form shows discard dialog (existing behavior must be preserved)
- [ ] Both platforms: segmented control (type selector) renders correctly without overflow

### Bookmark / Template
- [ ] Bookmark picker opened from header icon with no saved bookmarks → empty picker state renders with "Go to Bookmarks" button
- [ ] Selecting a bookmark with amount=null → Add modal opens with empty amount field (user must enter amount)
- [ ] Selecting a bookmark with a deleted account → account picker row shows empty/placeholder, user must re-select

---

## Test Scenarios for QA

### Happy Path (iOS + Android)
1. Open Transactions screen → Liste tab shown by default with current month data
2. Navigate to previous month → all 3 tabs update to reflect selected month
3. View income transaction row → green amount, correct category emoji
4. View expense transaction row → red amount, correct category emoji
5. Switch to Takvim tab → calendar grid renders, today marker visible, income/expense indicators on cells with transactions
6. Tap a day with transactions → switches to Liste tab
7. Switch to Özet tab → hero card, top categories, week trend all render with correct data
8. Tap FAB → Add Transaction modal opens
9. Select quick chip → category pre-selected in form
10. Fill form and tap Kaydet → transaction saved, modal closes, Liste tab updates
11. Fill form and tap Kaydet & Devam → transaction saved, form resets, modal stays open
12. Tap bookmark icon → BookmarkPickerModal opens; select a bookmark → form pre-filled

### Validation
13. Open Add modal → leave amount at 0 → Kaydet disabled
14. Clear amount field → Kaydet disabled
15. Enter negative number → validation error shown
16. Enter amount with comma (e.g. "10,50") → parsed correctly as 10.50

### Empty State
17. Select a month with no transactions → empty state renders (no tabs), CTA visible
18. Tap CTA → Add modal opens with Expense type selected

### Edge Case Verification
19. Enter amount €99,999.99 → displays without overflow in row and summary strip
20. Category with 40-char name → truncates in row and chip with ellipsis
21. Search for a term matching only account name → matching transactions appear
22. Apply type filter + text search simultaneously → both predicates applied

### Light / Dark Mode Parity
23. Switch to dark mode → page background #0F1117, card #181C27, income #34D399, expense #E55A4E
24. Switch to light mode → page background #F7F6F3, card #FFFFFF, income #047857, expense #C0392B
25. Visual comparison: Transactions screen card style matches Home screen and Budget screen cards

### Persistence
26. Add a transaction → close app → reopen → transaction still present
27. App offline → Transactions screen loads all local data normally

---

## ARB Key Requirements

All keys listed in Section 6 of `SPEC-021` (approximately 30+ keys) must be implemented in both `app_en.arb` and `app_tr.arb`. TR translations are sponsor-approved per the spec. See spec Section 6 for the complete key list.

Key families: `transactionsTitle`, `transactionsTab*`, `transactionsStrip*`, `transactionsList*`, `transactionsCalendar*`, `transactionsSummary*`, `transactionsEmpty*`, `transactionsAdd*`, `transactionsRowSemantic*`, `transactionsCalendarCellSemantic*`.

---

## Migration Notes for Flutter Engineer

| Old Tab | Maps To | Action |
|---------|---------|--------|
| Daily | Liste | Direct replacement — same day-grouped list, new visual tokens |
| Calendar | Takvim | Direct replacement — strip header added, weekend color removed |
| Monthly | Özet (partial) | Monthly totals → feed hero card and week trend chart |
| Summary | Özet (partial) | Aggregate data → feed top categories section |
| Description | Investigate | Run `git log` to confirm content; likely no separate migration needed (see analysis above) |

---

## Out of Scope (V1.x — Do Not Implement)

- Recurring transaction indicator in transaction rows
- Quick chip manual pinning (chip order is always computed from last-30-day frequency)
- Calendar day tap → bottom sheet with day detail list
- Description tab content (if found in git history, defer to separate story)
- Bulk edit / multi-select
- Export to CSV or PDF
- Transaction templates / recurring scheduling
- Scroll-to-position on Liste tab when navigating from Takvim
- "Bugün / Dün" quick date toggle in Add modal

---

## ADR Impact

- **ADR-015 (Design Token Unification):** Must be written and merged before engineering begins. Transactions screen is the first major consumer of unified tokens alongside Home and Budget. Flutter Engineer to author ADR-015 as sub-task #0 of this story.
- **ADR-016 (Information Architecture — 5-tab to 3-tab):** Proposed for Sprint 8e. This story sets the precedent but does not require ADR-016 to be in place before implementation.

---

## UX Spec

`docs/specs/SPEC-021-transactions-redesign.md` (full spec with ASCII wireframes)  
HTML mockups: `docs/specs/references/EPIC8D-01-v1-*.html` (6 files)

## Estimate

**5pt** (confirmed by Sponsor, preliminary — subject to Flutter Engineer sub-task breakdown)
