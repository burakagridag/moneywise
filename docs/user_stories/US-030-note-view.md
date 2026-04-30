# US-030: NoteView — note-grouped transaction summary list

## Persona
A MoneyWise user who uses the Note field when recording transactions and wants to see a
consolidated view of all transactions grouped by their note text, so they can track recurring
spending patterns that share the same description (e.g., "O2 monthly plan", "Gym membership").

## Story
**As** a MoneyWise user
**I want** the Note sub-tab in the Stats screen to list my transactions aggregated by their
Note field value, sorted by total amount descending
**So that** I can identify recurring note-based spending patterns and understand how much
I spend on any given recurring item across the selected period

## Source
SPEC.md §9.3.6 (Note Sub-tab, Ekran 14); SPEC.md §16.1 Sprint 5 goal.

## Acceptance Criteria

```gherkin
Scenario: NoteView shows transactions grouped by note text
  Given April 2026 transactions with notes:
    | Note           | Type    | Amount |
    | "O2"           | expense | 14.11  |
    | "Gym"          | expense | 29.99  |
    | "Gym"          | expense | 29.99  |
    | (empty note)   | expense | 53.95  |
    | (empty note)   | expense | 12.00  |
  When I tap the "Note" sub-tab in the Stats screen
  Then the list shows a header row:
    | "Note" | sort icon (↓ amount) | "Amount" |
  And the list contains:
    | (no note)  | 2 (count) | € 65,95 |
    | Gym        | 2 (count) | € 59,98 |
    | O2         | 1 (count) | € 14,11 |
  And rows are ordered by amount descending
  And transactions with empty notes are grouped in a single "(no note)" row at the top

Scenario: Count badge shows the number of transactions with that note
  Given "Gym" appears in 2 transactions in April 2026
  When I am on the NoteView
  Then the "Gym" row shows the count "2" in the middle column

Scenario: Tapping a note row opens a filtered transaction list
  Given the NoteView shows "O2" with count 1 and amount € 14,11
  When I tap the "O2" row
  Then a detail view or bottom sheet opens showing the individual "O2" transaction(s)
  And the detail shows date, category, account, and amount for each transaction

Scenario: Income / Exp. toggle filters the note list
  Given April 2026 has both income and expense transactions with notes
  And the "Exp." toggle is active (default)
  When I tap "Income"
  Then the NoteView re-renders with only income transactions grouped by note
  And the total amounts are recalculated for income only

Scenario: Month navigation updates the note list
  Given the NoteView is showing April 2026 data
  When I tap "<" in the Month/Year navigator
  Then the navigator shows "Mar 2026"
  And the note list re-renders with March transactions

Scenario: Sort toggle reverses the order
  Given the NoteView list is ordered amount descending (default)
  When I tap the sort icon in the header
  Then the list reorders to amount ascending
  And the sort icon reflects the new direction

Scenario: Empty state when no transactions have a note in the selected period
  Given April 2026 has transactions but none have a Note value
  When I am on the NoteView with "Exp." active
  Then only a "(no note)" row appears grouping all expense transactions
  And the user is not shown an empty-state illustration (data exists, just no notes)

Scenario: Empty state when no transactions exist at all in the selected period
  Given January 2026 has no transactions
  When the NoteView shows January 2026
  Then a centred empty-state illustration is shown
  And the text "No data for this period" is displayed
  And no list rows appear
```

## Edge Cases
- [ ] Note text is whitespace-only — treat as empty note; group under "(no note)"
- [ ] Note text is very long (> 50 chars) — truncated with ellipsis in the row; full text visible in detail view
- [ ] Two notes differ only in case ("gym" vs "Gym") — treat as distinct groups (case-sensitive grouping matches how user entered them)
- [ ] More than 50 note groups — list is scrollable; no pagination needed for MVP
- [ ] Transfer transactions with notes — included in the grouped list; displayed under the active Income / Exp. toggle correctly (transfers excluded from both income and expense totals per existing SPEC.md double-entry rules — show only if user explicitly filters for transfers; for MVP show expense-side only)
- [ ] Amount is 0.00 — row appears in list with "€ 0,00"; not excluded
- [ ] Offline — all data is local; NoteView renders normally
- [ ] Note field contains special characters or emoji — rendered correctly; no encoding errors
- [ ] Dark / Light theme — "(no note)" italic label remains readable in both themes

## Test Scenarios for QA
1. Happy path iOS: add transactions with and without notes, open NoteView, verify correct grouping and amounts
2. Happy path Android: same as above
3. "(no note)" group: verify empty-note transactions are grouped together at the top
4. Sort toggle: tap sort icon, verify list reverses order
5. Tap note row: verify filtered transaction detail opens with correct transaction(s)
6. Income toggle: verify only income notes appear with correct totals
7. Month navigation: navigate back one month, verify list refreshes
8. Empty period (no transactions): verify empty-state illustration and message appear
9. Long note text: verify truncation with ellipsis in the row
10. Case-sensitive grouping: "Gym" and "gym" appear as separate rows

## UX Spec
See `docs/specs/SPEC-017-note-view.md` (to be authored by ux-designer in Sprint 5, due Day 3)

## Estimate
S (2–3 days)

## Dependencies
- US-026 (StatsScreen scaffold — NoteView is a sub-tab within StatsScreen)
- US-010 (Transaction CRUD — data source with note field)
- Riverpod StreamProvider with Drift grouped query (GROUP BY note, SUM amount)
