# SPEC-004: Accounts Screen

**Related:** Sprint 2 — Accounts feature
**Reference:** SPEC.md Section 9.4 (Ekran 13), SPEC.md Section 7.3 (Asset/Liability)
**Route:** `/accounts`
**Component:** `lib/features/accounts/presentation/screens/accounts_screen.dart`

---

## Purpose

The Accounts tab main screen. Gives the user an at-a-glance overview of all their financial accounts grouped by account type. Shows the aggregated Assets, Liabilities, and Net Total. Allows navigating into account details and launching the add-account flow.

---

## Layout

Dark mode shown. Light mode mirrors with light tokens (`bgPrimaryLight`, `textPrimaryLight`, etc.).

```
┌─────────────────────────────────────────────────┐
│  [Edit ✎]          Accounts          [+]    44dp│  ← AppBar
├─────────────────────────────────────────────────┤
│                                                 │
│   Assets          Liabilities        Total      │  ← Summary bar
│   € 0,00 (blue)   € 0,00 (coral)   € 0,00      │  60dp
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  CASH                              € 0,00  ▾   │  ← Group header (collapsible)
│  ─────────────────────────────────────────────  │  divider
│    [icon] Cash Wallet              € 0,00       │  ← Account row 56dp
│                                                 │
│  ACCOUNTS                          € 0,00  ▾   │
│  ─────────────────────────────────────────────  │
│    [icon] Bank Account             € 0,00       │
│    [icon] Savings Account          € 0,00       │
│                                                 │
│  CARD                              € 0,00  ▾   │
│  ─────────────────────────────────────────────  │
│    [icon] Credit Card             -€ 0,00       │  ← negative = coral
│                                                 │
│  ... (remaining groups, only shown if non-empty)│
│                                                 │
├─────────────────────────────────────────────────┤
│  [Banner Ad — 50dp, free tier only]             │
├─────────────────────────────────────────────────┤
│  [Bottom Tab Bar — 49dp]                        │
└─────────────────────────────────────────────────┘

                              ┌──────┐
                              │  +   │  ← FAB (brand, 56dp circle)
                              └──────┘
```

---

## Tokens

| Element | Token | Value |
|---|---|---|
| AppBar background | `AppColors.bgPrimary` | #1A1B1E |
| AppBar height | `AppHeights.appBar` | 44dp |
| AppBar title | `AppTypography.headline` + `AppColors.textPrimary` | 17/600, white |
| AppBar icon color | `AppColors.textSecondary` | #B0B3B8 |
| Summary bar background | `AppColors.bgSecondary` | #24252A |
| Summary bar height | 60dp | — |
| Summary "Assets" label | `AppTypography.caption1` + `AppColors.textSecondary` | 12/400 |
| Summary "Assets" value | `AppTypography.moneyMedium` + `AppColors.income` | 17/600, blue |
| Summary "Liabilities" value | `AppTypography.moneyMedium` + `AppColors.expense` | 17/600, coral |
| Summary "Total" value | `AppTypography.moneyMedium` + `AppColors.textPrimary` | 17/600, white |
| Summary column padding (horizontal) | `AppSpacing.lg` | 16dp per side |
| Group header background | `AppColors.bgPrimary` | #1A1B1E |
| Group header height | 40dp | — |
| Group header text | `AppTypography.footnote` + `AppColors.textSecondary` | 13/400, uppercase |
| Group header padding (left) | `AppSpacing.lg` | 16dp |
| Group header balance | `AppTypography.footnote` + `AppColors.textSecondary` | 13/400 |
| Group collapse icon | `AppColors.textTertiary` | #6B6E76 |
| Account row height | `AppHeights.listItem` | 56dp |
| Account row background | `AppColors.bgSecondary` | #24252A |
| Account row selected background | `AppColors.bgTertiary` | #2E2F35 |
| Account row horizontal padding | `AppSpacing.lg` | 16dp |
| Account row divider | `AppColors.divider` | #2E2F35 |
| Account icon container size | 36dp circle | — |
| Account icon container background | account's `colorHex` or `AppColors.bgTertiary` | — |
| Account name | `AppTypography.body` + `AppColors.textPrimary` | 17/400 |
| Account balance (positive / neutral) | `AppTypography.moneySmall` + `AppColors.textPrimary` | 15/500 |
| Account balance (negative / liability) | `AppTypography.moneySmall` + `AppColors.expense` | 15/500, coral |
| FAB size | 56dp circle | — |
| FAB background | `AppColors.brandPrimary` | #FF6B5C |
| FAB icon | `+` white, Phosphor Icons | — |
| FAB margin (bottom-right) | `AppSpacing.lg` | 16dp from safe area + tab bar |

---

## States

### Default (accounts exist)

- Summary bar shows computed Assets, Liabilities, Total.
- Account groups rendered in canonical order: Cash, Accounts, Card, Debit Card, Savings, Top-Up/Prepaid, Investments, Overdrafts, Loan, Insurance, Others.
- Groups with zero accounts are hidden.
- All groups start expanded.
- Balances streamed reactively from the Drift `accountsList` provider.
- Hidden accounts (isHidden = true) are excluded from the list and totals.

### Loading

- Summary bar shows three `---` placeholders (`AppColors.textTertiary`) where values will appear.
- List area shows 3 skeleton rows: a 40dp shimmer block (group header) followed by two 56dp shimmer blocks (account rows). Shimmer color cycles between `AppColors.bgSecondary` and `AppColors.bgTertiary`.
- FAB is visible and tappable (navigates immediately; saves user from waiting for data).

### Empty (no accounts)

```
┌─────────────────────────────────────────────────┐
│  [Edit ✎]          Accounts          [+]        │
├─────────────────────────────────────────────────┤
│            Assets    Liabilities    Total        │
│            € 0,00      € 0,00      € 0,00       │
├─────────────────────────────────────────────────┤
│                                                 │
│                    [Illustration]               │
│              (wallet with a '+' icon)           │
│                                                 │
│              No accounts yet                    │
│         Start by adding your first account      │
│                                                 │
│         ┌───────────────────────────┐           │
│         │   + Add your first account│           │  ← AppButton primary
│         └───────────────────────────┘           │
│                                                 │
└─────────────────────────────────────────────────┘
```

- Illustration area: 120dp height, centered, uses a simple wallet SVG/asset (greyed out, `AppColors.textTertiary`).
- "No accounts yet": `AppTypography.title3` + `AppColors.textPrimary`, centered.
- Sub-copy: `AppTypography.subhead` + `AppColors.textSecondary`, centered, 8dp below title.
- CTA button: `AppButton` primary, 52dp height, `AppRadius.md`, width = 220dp, 24dp below sub-copy.
- Tapping CTA navigates to `AccountAddEditScreen` (add mode).
- FAB is still visible and also navigates to `AccountAddEditScreen`.

### Error

- Summary bar values show `--` (`AppColors.textTertiary`).
- List area replaced by centered error message:
  - Icon: Phosphor `WarningCircle`, 40dp, `AppColors.error`.
  - Text: "Could not load accounts" — `AppTypography.subhead` + `AppColors.textSecondary`.
  - Retry button: `AppButton` ghost, "Try again", taps retrigger the stream provider.
- FAB remains tappable.

### Edit Mode (multi-select)

Activated by tapping the Edit (pencil) icon in the AppBar.

- AppBar right action changes from `[✎] [+]` to `[Done]`.
- Each account row gains a leading circular checkbox (24dp, unchecked = `AppColors.border`, checked = `AppColors.brandPrimary` fill + white tick).
- A bottom action bar slides up (56dp, `AppColors.bgSecondary`): "Delete selected" button (`AppColors.error` text, disabled until at least one row selected).
- FAB is hidden in edit mode.
- Group headers are not selectable.
- Tapping a row in edit mode toggles its checkbox; it does NOT navigate to account detail.
- Tapping "Done" exits edit mode, deselects all, hides the bottom action bar.

---

## Interactions

### Tap account row
- Navigates to `AccountDetailScreen` (`/accounts/:id`).
- Row shows pressed state: background briefly transitions to `AppColors.bgTertiary` (150ms, easeInOut).

### Tap group header
- Toggles expand/collapse of the group's account rows.
- Collapse icon rotates 180° (200ms, easeOutCubic).
- Row area shrinks/expands with an animated size transition (250ms, easeOutCubic).

### Tap FAB (+)
- Navigates to `AccountAddEditScreen` in add mode.
- FAB scales down to 0.9 on press and back on release (100ms).

### Tap AppBar (+) icon
- Same as FAB: navigates to `AccountAddEditScreen` in add mode.
- Minimum tap target: 44x44dp.

### Tap AppBar Edit (pencil) icon
- Enters edit mode (see Edit Mode state above).

### Swipe-to-hide (iOS primary / Android secondary)

Each account row supports a leading swipe action:
- iOS: swipe right to reveal "Hide" action (Phosphor `EyeSlash` icon, `AppColors.bgTertiary` background, white icon+label).
- Android: long-press the row to reveal a context menu with "Hide" and "Edit" options (min 44dp touch targets).
- "Hide" sets `account.isHidden = true`. Account disappears from the list immediately (animated removal, 300ms slide + fade). A snackbar appears: "Account hidden. Undo" (4s, tap Undo restores).
- Hidden accounts can be revealed via Account Settings screen (outside this spec).

### Swipe-to-delete (iOS primary / Android secondary)

Each account row supports a trailing swipe action:
- iOS: swipe left to reveal "Delete" action (Phosphor `Trash` icon, `AppColors.error` background, white icon+label).
- Android: long-press → context menu → "Delete".
- Tapping "Delete" shows a confirmation alert (see Confirmation Alert below).
- If the account has transactions, the alert warns: "This account has transactions. Deleting it will also delete all associated transactions. This cannot be undone."
- Confirming performs a soft delete (`isDeleted = true`). Row animates out (slide + fade, 300ms).
- Default system accounts (if any) are not deletable (swipe reveals no delete action; trailing swipe is a no-op).

### Confirmation Alert (Delete)

```
Title: "Delete account?"
Body: "This will permanently delete [Account Name] and all its transactions."
Actions:
  - "Cancel" (default, `AppColors.textPrimary`)
  - "Delete" (destructive, `AppColors.error`)
```

Platform: iOS uses `CupertinoAlertDialog`; Android uses `AlertDialog` with matching color tokens.

---

## Navigation

| Action | Destination |
|---|---|
| Tap account row | `AccountDetailScreen` `/accounts/:id` |
| Tap FAB / AppBar + | `AccountAddEditScreen` `/accounts/add` |
| Tap AppBar Edit, then tap account row | Toggle select (stays on screen) |

---

## Accessibility

- AppBar title: semanticLabel "Accounts screen".
- Edit button: semanticLabel "Edit accounts".
- Add button (AppBar): semanticLabel "Add new account".
- FAB: semanticLabel "Add new account".
- Summary bar columns: each wrapped in a `Semantics` node with label "Assets [value]", "Liabilities [value]", "Total [value]".
- Group header: semanticLabel "[Group name], [balance], [expanded/collapsed]". Role = button.
- Account row: semanticLabel "[Account name], balance [value], [positive/negative]". Role = button.
- Swipe actions: For screen readers, each row has an `actions` list in `Semantics`: "Hide account" and "Delete account".
- Color is never the sole differentiator: positive/negative balances differ in both color and sign character (`+` / `-`).
- Minimum tap target on all interactive elements: 44x44dp.
- Focus order (keyboard/switch access): AppBar Edit → AppBar Add → Summary bar → Group headers (in order) → Account rows within each group → FAB.
- Dynamic Type: all text scales up with system font size. Group headers that overflow truncate with ellipsis.

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Screen enter | Full screen slide from right | 300ms | easeOutCubic |
| Group expand/collapse | Row area animated size | 250ms | easeOutCubic |
| Collapse chevron rotation | Icon | 200ms | easeOutCubic |
| Account row press | Background color | 150ms | easeInOut |
| Swipe action reveal | Slide | 200ms | easeOut |
| Row deletion | Slide + fade out | 300ms | easeInCubic |
| FAB press | Scale 1.0 → 0.9 → 1.0 | 100ms | easeInOut |
| Edit mode bottom bar | Slide up | 250ms | easeOutCubic |

---

## Empty and Error Copy

| Context | Copy |
|---|---|
| Empty state title | "No accounts yet" |
| Empty state subtitle | "Start by adding your first account" |
| Empty state CTA | "+ Add your first account" |
| Error title | "Could not load accounts" |
| Error action | "Try again" |
| Delete confirmation title | "Delete account?" |
| Delete confirmation body | "This will permanently delete [Name] and all its transactions." |
| Hide snackbar | "Account hidden. Undo" |
| Account with transactions delete warning | "This account has [N] transaction(s). Deleting it will also remove them. This cannot be undone." |

---

## Open Questions

- Q: Should the Assets/Liabilities/Total summary bar be tappable (e.g., to filter or drill in)? Decision needed from PM.
- Q: Should hidden accounts be visible in a separate collapsed section on this screen, or only accessible via Account Settings? Assumption for V1: only in Account Settings.
- Q: Are group headers reorderable (drag-and-drop)? Assumption for V1: fixed canonical order.
