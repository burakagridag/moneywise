# SPEC-016: Note View (Stats Screen — Note Sub-tab)

**Sprint:** 5
**Related:** US-NoteView (Sprint 5)
**Reference:** SPEC.md Section 9.3.6, Reference screenshot 14
**Parent scaffold:** StatsScreen (SPEC-014)
**Route:** `/stats` (Note sub-tab active)
**Component:** `lib/features/stats/presentation/screens/note_view.dart`

---

## Purpose

NoteView, StatsScreen'in "Note" sub-tab'inda gorunur. Secili ayin islemlerini `note` alanina gore gruplar. Her grup bir baslik satiri (note metni, islem sayisi, toplam tutar) ve altinda amount descending sirali islem satirlari icerir. `note` alani bos olan islemler her zaman "(no note)" grubu altinda toplanir. Kullanici siralamayı (amount / count) ve gelir/gider filtresi ile ay navigasyonunu degistirebilir.

---

## Layout

```
┌─────────────────────────────────────────────┐
│            Stats                     56dp   │  <- AppBar (StatsScreen'den)
├─────────────────────────────────────────────┤
│  [Stats][Budget][Note]         [M ▼]  48dp  │  <- SubTabAndPeriodBar (Note aktif)
├─────────────────────────────────────────────┤
│  [<]      Apr 2026              [>]   48dp  │  <- MonthNavigator
├─────────────────────────────────────────────┤
│  Income  €0,00  │  Exp.  €651,13      44dp  │  <- IncomeExpenseToggle
├─────────────────────────────────────────────┤
│  Note             ↓ Count ▼      Amount     │  <- NoteListHeader (44dp)
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │ O2 (note text here)          1  € 14,11 │  <- NoteGroupHeader (48dp)
│  │   [emoji] Restaurant     € 14,11    │   │  <- NoteTransactionRow (52dp)
│  ├──────────────────────────────────────┤   │
│  │ Groceries trip               2  € 45,00 │  <- NoteGroupHeader
│  │   [emoji] Groceries      € 30,00    │   │  <- NoteTransactionRow
│  │   [emoji] Transport      € 15,00    │   │  <- NoteTransactionRow
│  ├──────────────────────────────────────┤   │
│  │ (no note)                   5  €192,44 │  <- NoteGroupHeader (always shown)
│  │   [emoji] Parking        € 80,00    │   │
│  │   [emoji] Bills          € 60,00    │   │
│  │   [emoji] Food           € 28,44    │   │
│  │   [emoji] Gym            € 14,00    │   │
│  │   [emoji] Medicine       € 10,00    │   │
│  └──────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│  [Banner Ad — 50dp, free tier]              │
└─────────────────────────────────────────────┘
```

---

## Component Hierarchy

```
NoteView (ConsumerWidget)
└── Column
    ├── NoteListHeader (44dp)
    │   ├── "Note" column label (left)
    │   ├── Sort toggle button (center) — "↓ Count ▼" or "↓ Amount ▼"
    │   └── "Amount" column label (right)
    └── Expanded
        └── ListView.builder (NoteGroup list)
            └── NoteGroup (for each distinct note value)
                ├── NoteGroupHeader (48dp)
                │   ├── Note text (or "(no note)" label)
                │   ├── Transaction count badge
                │   └── Group total amount
                └── List<NoteTransactionRow> (sorted amount desc within group)
```

---

## Token Specs

### NoteListHeader
| Element | Token |
|---------|-------|
| Height | 44dp |
| Background | `AppColors.bgPrimary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| "Note" label | `AppTypography.footnote`, `AppColors.textSecondary`, left-aligned |
| Sort toggle button | Center-aligned; Phosphor `ArrowDown` icon 14dp + sort mode text + Phosphor `CaretDown` 12dp; color `AppColors.textSecondary`; tap cycles between Count and Amount sort |
| "Amount" label | `AppTypography.footnote`, `AppColors.textSecondary`, right-aligned |
| Bottom divider | 1dp `AppColors.divider` |

### NoteGroupHeader
| Element | Token |
|---------|-------|
| Height | 48dp |
| Background | `AppColors.bgTertiary` |
| Horizontal padding | `AppSpacing.lg` (16dp) |
| Note text | `AppTypography.bodyMedium`, `AppColors.textPrimary`; truncated at 1 line with ellipsis; max ~60% of row width |
| "(no note)" label | Same style as note text but `AppColors.textTertiary` italicized (if font supports) |
| Transaction count badge | Rounded-rect, `AppColors.bgSecondary` fill, `AppColors.textSecondary` text, `AppTypography.caption2`, padding 4dp h / 2dp v, `AppRadius.sm` radius; placed to right of note text |
| Group total amount | `AppTypography.moneySmall`, `AppColors.expense` (for expense mode) or `AppColors.income` (for income mode); right-aligned |
| Tap behaviour | NoteGroupHeader tap collapses/expands the transaction rows for that group; chevron icon not shown per reference but collapse is supported |

### NoteTransactionRow
| Element | Token |
|---------|-------|
| Height | 52dp |
| Background | `AppColors.bgSecondary` |
| Left indent | `AppSpacing.xl` (20dp) to create visual nesting under group header |
| Leading icon | `CategoryIcon` 36dp (emoji in `AppColors.bgTertiary` circle, `AppRadius.sm`) |
| Gap: icon to text | `AppSpacing.sm` (8dp) |
| Category name | `AppTypography.bodyMedium`, `AppColors.textPrimary` |
| Sub-label | Account name + date (e.g. "Debit Card · Apr 27") — `AppTypography.caption1`, `AppColors.textTertiary` |
| Amount | Right-aligned `AppTypography.moneySmall`; expense: `AppColors.expense`; income: `AppColors.income` |
| Divider | 1dp `AppColors.divider` between rows, inset 56dp from left |
| Tap action | Navigate to transaction detail / opens edit modal |
| Swipe-to-delete | iOS: trailing swipe reveals red Delete action; Android: long-press context menu with Delete option |

---

## Sorting Behaviour

### Sort Toggle Options
The center button in NoteListHeader cycles through two modes:

| Mode | Label | Sort Key |
|------|-------|----------|
| Amount | "↓ Amount ▼" | Group sorted by group total amount, descending |
| Count | "↓ Count ▼" | Group sorted by transaction count, descending |

- Within each group, individual NoteTransactionRows are always sorted by amount descending regardless of the group sort mode.
- The "(no note)" group is always pinned to the **end** of the list, regardless of sort mode, even if it would otherwise rank first by amount or count.
- Sort state persists within the session; resets to Amount sort on next app launch.

---

## States

### Loading
- NoteListHeader visible (static, not loading)
- ListView replaced by 4 skeleton NoteGroupHeader blocks (48dp grey) each with 1–2 skeleton NoteTransactionRow blocks (52dp grey, indented)
- Shimmer animation on skeleton blocks

### Empty (no transactions with any note value in selected period + type)
- NoteListHeader still visible
- `EmptyStateView` below header:
  - Icon: Phosphor `Note` (64dp, `AppColors.textTertiary`)
  - Title: "No notes"
  - Subtitle: "Transactions with notes will appear here."
  - No CTA button

### "(no note)" group always visible when populated
- If there are transactions without a note, "(no note)" group always appears at the bottom of the list
- If every transaction in the period has a note, "(no note)" group is hidden

### Error (data load failure)
- `EmptyStateView` with Phosphor `Warning` icon, title "Could not load data", Retry action
- Snackbar with "Retry" option

### Populated (default)
- Groups sorted per active sort mode
- "(no note)" group pinned last
- Each group expanded by default (all rows visible)

---

## Interactions & Animations

### Sort Toggle Tap
- Cycles between Amount and Count modes
- List re-sorts with a 200ms crossfade animation (opacity fade out old order, fade in new order)
- Button label updates immediately

### Note Group Collapse / Expand
- Tapping NoteGroupHeader collapses or expands the NoteTransactionRow list for that group
- Animation: `AnimatedSize` on the row container, 200ms `easeInOutCubic`
- No chevron shown per reference; the tap is the only interaction surface

### NoteTransactionRow Tap
- Opens transaction detail / edit modal
- Same edit flow as DailyView transaction tap (see SPEC-009)

### NoteTransactionRow Swipe-to-delete
- iOS: trailing red "Delete" action (Phosphor `Trash` icon, `AppColors.error` background)
  - Confirm dialog: "Delete this transaction?" with "Delete" (red) and "Cancel"
- Android: long-press context menu with "Delete" option

### Month Navigation
- `<` / `>` reloads note groups for new month; IncomeExpenseToggle state preserved

### Income/Expense Toggle
- Switching reloads note groups for the selected type
- Sort mode and collapse state reset on type switch

### Pull-to-refresh
- Standard `RefreshIndicator`, `AppColors.brandPrimary`, invalidates note view provider

---

## Accessibility

- **Screen reader label for NoteListHeader:** "Note list. Sort by [Count/Amount]. Sorted descending."
- **Sort toggle button:** "Sort by Amount, currently sorted by Count. Double-tap to change." Minimum 44x44dp tap target.
- **NoteGroupHeader:** "Group: [note text or 'no note']. [N] transactions, total [amount]."
- **NoteTransactionRow:** "[Category name]. [Account]. [Date]. [Amount]. Double-tap to view details."
- **Swipe-to-delete:** "Delete [category] transaction, [amount]" on swipe action button.
- **"(no note)" distinction:** The label is textual ("no note"), so screen readers will announce it clearly.
- **Color independence:** Amount colors (income blue / expense coral) are supplemented by the sign (+/-) or context (Income/Expense toggle).
- **Focus order:** SubTabAndPeriodBar -> MonthNavigator -> IncomeExpenseToggle -> NoteListHeader sort button -> NoteGroupHeaders and rows in visual top-to-bottom order.
- **Dynamic Type:** Note text truncates to 1 line with ellipsis at all scale factors. Row heights fixed at spec values; do not expand with text scaling.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Single transaction with a note | One group with 1 NoteGroupHeader + 1 NoteTransactionRow. |
| Many groups (>20) | ListView scrolls; no pagination needed (data is month-scoped). |
| Very long note text | Truncated to 1 line in NoteGroupHeader; full text visible in transaction detail. |
| Note contains only whitespace | Treated as "(no note)" — trimmed before grouping. |
| Same note on both income and expense | With IncomeExpenseToggle set to Expense, only expense transactions in the group are shown. |
| Transaction deleted from NoteTransactionRow | Group count badge decrements; if group reaches 0 items, group header is removed. If it was the last group, empty state shown. |
| Sort by Amount, two groups with equal total | Secondary sort: alphabetical by note text (or "(no note)" last). |
| Period = Weekly | Note groups scoped to selected week instead of month; MonthNavigator shows week label. |

---

## New Components Required (Sprint 5)

| Component | File | Notes |
|-----------|------|-------|
| `NoteListHeader` | `features/stats/presentation/widgets/note_list_header.dart` | Static header with 3 columns and sort toggle. |
| `NoteGroupHeader` | `features/stats/presentation/widgets/note_group_header.dart` | 48dp collapsible group header. Accepts `noteText` (nullable, renders "(no note)" label), `count`, `total`, `isExpanded`, `onTap`. |
| `NoteTransactionRow` | `features/stats/presentation/widgets/note_transaction_row.dart` | 52dp indented row. Accepts `transaction`, `onTap`, `onDelete`. Wraps `CategoryIcon` and `CurrencyText`. |
