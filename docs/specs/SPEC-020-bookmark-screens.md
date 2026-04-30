# SPEC-020: Bookmark Screens

**Sprint:** 6
**Related:** US-020
**Reference:** SPEC.md Section 9, `TransactionAddEditScreen` (existing), SPEC-009 (`TransactionListItem`)
**Routes:**
  - Bookmark picker modal: presented in-place over `TransactionAddEditScreen` (no route)
  - Bookmark management screen: `/more/bookmarks`
  - Bookmark-to-transaction: reuses `/transactions/add` with pre-filled data
**Components:**
  - `lib/features/bookmarks/presentation/widgets/bookmark_picker_sheet.dart`
  - `lib/features/bookmarks/presentation/screens/bookmarks_screen.dart`

---

## Purpose

Bookmarks are saved transaction templates. A user creates a bookmark from any transaction (or from scratch inside the add/edit screen) and later taps it to pre-fill the add transaction form — reducing repetitive entry for regular transactions such as rent, commute, or coffee.

There are three distinct interaction surfaces:

1. **Bookmark Picker Sheet** — accessed while adding a transaction; lets the user select an existing bookmark to pre-fill the form.
2. **Bookmark Management Screen** — accessed from More; shows all saved bookmarks with edit/delete actions.
3. **Create/Edit Bookmark Flow** — a sub-sheet or inline edit within the management screen; mirrors the transaction form fields.

---

## Data Model (for spec context only)

A bookmark contains:
- `id`: UUID
- `name`: user-given label (e.g., "Morning Coffee")
- `type`: income / expense / transfer
- `amount`: optional pre-fill (nullable — user may prefer to enter each time)
- `categoryId`: optional
- `accountId`: optional
- `toAccountId`: optional (transfer only)
- `note`: optional pre-fill
- `iconEmoji`: optional display emoji (default: category emoji if categoryId set)
- `sortOrder`: integer (drag-to-reorder)
- `createdAt`, `updatedAt`

---

## 1. Bookmark Picker Sheet

### Purpose
Presented as a bottom sheet from the `TransactionAddEditScreen`. Allows the user to select a bookmark to pre-fill the open form, or to save the current form state as a new bookmark.

### Trigger
Tapping the bookmark icon (star/bookmark icon) in the `TransactionAddEditScreen` AppBar trailing area. The icon is always visible in add mode; in edit mode it is suppressed (bookmarks are a template tool, not a label for existing transactions).

### Layout

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                              drag  │
│   Bookmarks                  [+ New] title  │
├─────────────────────────────────────────────┤
│  [🌙] Morning Coffee    Expense  €3,20 56dp │
│  [🏠] Rent              Expense  €950  56dp │
│  [💼] Salary            Income   €3,200 56dp│
│  [🚌] Monthly Pass      Expense  €49   56dp │
│   ·   ·   ·                                 │
├─────────────────────────────────────────────┤
│  (empty state if no bookmarks)              │
└─────────────────────────────────────────────┘
```

### Token Specs

| Element | Token |
|---------|-------|
| Sheet background | `AppColors.bgSecondary` |
| Top radius | `AppRadius.xl` (24dp) |
| Drag handle | 36x4dp pill, `AppColors.textTertiary`, 12dp top margin, centered |
| Header height | 52dp |
| Header title | `AppTypography.headline`, `AppColors.textPrimary`, left-aligned, `AppSpacing.lg` padding |
| "+ New" button | `AppTypography.bodyMedium`, `AppColors.brandPrimary`, right-aligned ghost button, 44x44dp tap target |
| Bookmark row height | 56dp |
| Leading emoji/icon | 40dp circle, `AppColors.bgTertiary` background, emoji 20dp centered |
| Bookmark name | `AppTypography.bodyMedium`, `AppColors.textPrimary` |
| Sub-label | `AppTypography.caption1`, `AppColors.textSecondary`; format: "[Type] · [Account name]" (if accountId set) |
| Amount | `AppTypography.moneySmall`, right-aligned; `AppColors.expense` for expense, `AppColors.income` for income, `AppColors.textSecondary` if amount is null |
| Amount null indicator | "—" in `AppColors.textTertiary` |
| Row tap highlight | `AppColors.bgTertiary` background, 100ms fade |
| Bottom padding | `AppSpacing.xxxl` (32dp) + system safe area inset |
| Max sheet height | 60% of screen height; scrollable beyond |

### States

#### Default (bookmarks exist)
- List shows all bookmarks sorted by `sortOrder`
- Amount column shows pre-fill value or "—" if null

#### Empty (no bookmarks saved yet)
- `EmptyStateView` inside sheet body: bookmark icon (64dp, `AppColors.textTertiary`), title "No bookmarks yet", subtitle "Tap + New to save this form as a template."
- "+ New" button in header still active

#### Loading
- 4 skeleton rows (40dp circle + two `AppColors.bgTertiary` rectangles + amount rectangle), shimmer animation

#### Applying a Bookmark
- User taps a bookmark row
- Sheet auto-dismisses with slide-down 250ms `easeInCubic`
- Parent form fields (type, amount, category, account, note) fill with bookmark values
- Fields that were null in the bookmark remain as they were in the form (no overwrite)
- Snackbar: "Bookmark applied" (2s, no action)

#### "+ New" Button
- Opens `BookmarkSaveSheet` (see Section 3) as a second bottom sheet layered on top

---

## 2. Bookmark Management Screen

### Purpose
Full-screen list of all bookmarks. Accessible from More > Bookmarks. Users can create, edit, reorder, and delete bookmarks.

### Route
`/more/bookmarks`

### Layout

```
┌─────────────────────────────────────────────┐
│ ←   Bookmarks                      [+ Add]  │  ← AppBar 44dp
├─────────────────────────────────────────────┤
│                                             │
│  ⠿  [🌙] Morning Coffee  Expense  €3,20     │  ← BookmarkListItem 64dp
│  ⠿  [🏠] Rent            Expense  €950      │
│  ⠿  [💼] Salary          Income   €3,200    │
│  ⠿  [🚌] Monthly Pass    Expense  €49   ·  │
│   ·   ·   ·                                 │
│                                             │
└─────────────────────────────────────────────┘
```

### Token Specs

#### AppBar
| Element | Token |
|---------|-------|
| Height | 44dp |
| Background | `AppColors.bgPrimary` |
| Title | `AppTypography.title2`, `AppColors.textPrimary` |
| Back arrow | `AppColors.textPrimary`, 44x44dp |
| "+ Add" action | `AppTypography.bodyMedium`, `AppColors.brandPrimary`, right-aligned, 44x44dp |

#### BookmarkListItem
| Element | Token |
|---------|-------|
| Row height | 64dp |
| Background | `AppColors.bgPrimary` |
| Reorder handle | Left edge, `⠿` drag icon 20dp, `AppColors.textTertiary`, 44x44dp tap area |
| Leading icon circle | 44dp, `AppColors.bgSecondary` background, emoji 22dp centered |
| Name | `AppTypography.bodyMedium`, `AppColors.textPrimary` |
| Sub-label | `AppTypography.caption1`, `AppColors.textSecondary`; format: "[Type] · [Account name]" |
| Amount | `AppTypography.moneySmall`, right-aligned, colored by type |
| Trailing chevron | `AppColors.textTertiary`, 20dp |
| Bottom divider | 1dp `AppColors.divider` |
| Horizontal content padding | `AppSpacing.lg` (16dp) |

### States

#### Default (populated)
- Reorderable list; drag handle visible on all rows

#### Reordering
- Dragged row: `AppColors.bgSecondary` background + subtle 4dp elevation shadow
- Other rows shift with `AnimatedList` 200ms slide animation
- `sortOrder` updated on drag release

#### Swipe-to-Delete (iOS)
- Swipe left reveals red delete action, same spec as `TransactionListItem` (SPEC-009)
- Confirmation: `AlertDialog` — "Delete '[Bookmark Name]'? This cannot be undone." — Cancel / Delete (red)
- On confirm: row collapses out 200ms `easeInCubic`

#### Long-press Context Menu (Android)
- Options: "Edit", "Delete"

#### Empty
- `EmptyStateView`: bookmark icon (64dp, `AppColors.textTertiary`), title "No bookmarks", subtitle "Save frequently used transactions as bookmarks for faster entry.", CTA "Add Bookmark" → opens `BookmarkSaveSheet`

#### Loading
- 5 skeleton rows (44dp circle, two text rectangles, amount rectangle), shimmer

#### Error
- `EmptyStateView` with Phosphor `Warning` icon, title "Could not load bookmarks", subtitle "Pull down to retry."
- `RefreshIndicator` (`AppColors.brandPrimary`) wraps the list

### Interactions

| Trigger | Action |
|---------|--------|
| Tap "+ Add" in AppBar | Open `BookmarkSaveSheet` as bottom sheet |
| Tap a bookmark row | Open `BookmarkSaveSheet` in edit mode for that bookmark |
| Drag reorder handle | Reorder list; persist new `sortOrder` values on release |
| Swipe left (iOS) | Reveal delete action |
| Long-press (Android) | Context menu: Edit / Delete |
| Delete confirmed | Remove from DB, collapse row |
| Back arrow | `context.pop()` |

---

## 3. Bookmark Save Sheet (Create / Edit)

### Purpose
A bottom sheet form for creating a new bookmark or editing an existing one. Mirrors the transaction form fields but with a mandatory "Bookmark Name" at the top. Amount, category, account, and note are all optional (null = user enters each time).

### Layout

```
┌─────────────────────────────────────────────┐
│   ━━━━━━                                    │
│   New Bookmark           (or "Edit Bookmark")│
├─────────────────────────────────────────────┤
│  [income][expense][transfer]          44dp  │  ← Type toggle
├─────────────────────────────────────────────┤
│  [✏️ icon] Name  ____________________  56dp  │  ← Required
├─────────────────────────────────────────────┤
│  [💲 icon] Amount  ____  (optional)    56dp  │
├─────────────────────────────────────────────┤
│  [🗂️ icon] Category  ____              56dp  │
├─────────────────────────────────────────────┤
│  [💳 icon] Account  ____               56dp  │
├─────────────────────────────────────────────┤
│  [📝 icon] Note  ____                  56dp  │
├─────────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  52dp │
│  │              Save                │       │
│  └──────────────────────────────────┘       │
│  (edit mode only)                           │
│  ┌──────────────────────────────────┐  44dp │
│  │         Delete Bookmark          │       │  ← ghost, error color
│  └──────────────────────────────────┘       │
└─────────────────────────────────────────────┘
```

### Token Specs

| Element | Token |
|---------|-------|
| Sheet background | `AppColors.bgSecondary` |
| Top radius | `AppRadius.xl` (24dp) |
| Drag handle | 36x4dp, `AppColors.textTertiary`, 12dp top |
| Title | `AppTypography.headline`, `AppColors.textPrimary`, `AppSpacing.lg` padding |
| Type toggle | Reuse `_TypeSegmentedButton` widget from `TransactionAddEditScreen`; height 44dp; same token spec |
| Form rows | Reuse `_PickerTile` pattern — icon left, label/value, chevron right, 56dp height |
| Name field | `TextFormField` with label "Name", `AppTypography.body` `AppColors.textPrimary`, no border, 56dp row height |
| Amount field | `TextFormField`, numeric, hint "Optional — leave blank to enter each time", `AppColors.textTertiary` hint |
| Category row | Taps to `CategoryPickerSheet` (existing) |
| Account row | Taps to `AccountPickerSheet` (existing) |
| Note field | Single-line `TextFormField`, optional |
| Save button | `AppButton` primary, full width, 52dp height, disabled if Name is empty |
| Delete button | `AppButton` ghost, `AppColors.error` text, full width, 44dp height (edit mode only) |
| Bottom padding | `AppSpacing.xxxl` (32dp) + safe area |
| Keyboard avoiding | Sheet uses `isScrollControlled: true` + `Padding(bottom: viewInsets.bottom)` |

### States

#### Create Mode (no existing bookmark)
- Type defaults to "expense"
- All fields empty
- Sheet title: "New Bookmark"
- No Delete button

#### Edit Mode (existing bookmark passed)
- Fields pre-populated with existing bookmark values
- Sheet title: "Edit Bookmark"
- Delete button visible at bottom

#### Submitting (Save tapped)
- Save button shows circular spinner 16dp white
- Form disabled
- On success: sheet dismisses, parent list reloads
- On error: Snackbar "Could not save bookmark. Try again."

#### Deleting (Delete button tapped, edit mode)
- `AlertDialog`: "Delete '[Name]'? This cannot be undone." — Cancel / Delete (red)
- On confirm: bookmark removed, sheet dismisses, management list updates

#### Dirty Confirmation (sheet dismissed via drag with unsaved changes)
- `AlertDialog`: "Discard changes?" — Cancel / Discard
- Triggered only when at least one field has been modified

### Validation
- "Name" is the only required field
- Name max length: 50 characters (inline character counter appears at 40+ characters: `AppTypography.caption1` `AppColors.textTertiary`)
- Amount, if entered, must be > 0 (same validator as `TransactionAddEditScreen`)
- Transfer type requires both Account and To Account if both are set (not required; just enforced when both are partially filled)

---

## 4. Bookmark to Transaction Flow

When the user selects a bookmark from the `BookmarkPickerSheet` while adding a transaction, the form is pre-filled as follows:

| Bookmark Field | Form Field | Behaviour |
|----------------|------------|-----------|
| `type` | Type toggle | Always applied (overrides current toggle) |
| `amount` | Amount field | Applied only if bookmark amount is non-null |
| `categoryId` | Category picker | Applied only if non-null |
| `accountId` | Account picker | Applied only if non-null |
| `toAccountId` | To Account picker | Applied only if non-null and type = transfer |
| `note` | Note field | Applied only if non-null |

After applying, the user can edit any pre-filled field before saving. The transaction is saved normally — the bookmark is not modified.

---

## Full User Flows

### Flow A: Apply Bookmark While Adding a Transaction

```
TransactionAddEditScreen
        |
        | Tap bookmark icon (AppBar)
        v
BookmarkPickerSheet opens (slide up, 300ms easeOutCubic)
        |
        |--[empty]→ Tap "+ New" → BookmarkSaveSheet opens
        |
        | Tap a bookmark row
        v
Sheet dismisses (slide down, 250ms easeInCubic)
        |
Form fields pre-filled
        |
User adjusts & taps Save
        v
Transaction saved → TransactionAddEditScreen pops
```

### Flow B: Create a New Bookmark from the Picker

```
BookmarkPickerSheet
        |
        | Tap "+ New"
        v
BookmarkSaveSheet opens (new layer on top of picker)
        |
        | Fill name (required), optionally fill other fields
        | Tap Save
        v
BookmarkSaveSheet dismisses → BookmarkPickerSheet list refreshes
        |
        | New bookmark now selectable
```

### Flow C: Manage Bookmarks from More

```
MoreScreen
        |
        | Tap "Bookmarks" row
        v
BookmarksScreen (/more/bookmarks)
        |
        |--Tap row → BookmarkSaveSheet (edit mode)
        |--Drag handle → reorder
        |--Swipe left (iOS) / long-press (Android) → delete
        |
        | Tap "+ Add"
        v
BookmarkSaveSheet (create mode)
        |
        | Save
        v
List updates, new bookmark at bottom
```

---

## Accessibility

### BookmarkPickerSheet
- **Sheet announced as:** "Bookmarks panel. [N] bookmarks available."
- **Each row:** "[Emoji] [Name]. [Type]. [Amount if set, or 'Amount not set']. Double-tap to apply."
- **"+ New" button:** "Create new bookmark."
- **Focus order:** Drag handle (excluded) → "+ New" button → bookmark rows top to bottom → Close (swipe-down gesture not focusable; back swipe serves as dismiss)

### BookmarksScreen
- **AppBar:** "Bookmarks management screen"
- **Reorder handle:** "Drag handle for [bookmark name]. Hold and drag to reorder."
- **Each row:** "[Emoji] [Name]. [Type]. [Amount if set]. Double-tap to edit."
- **Swipe-to-delete hint (iOS):** "Swipe left to reveal delete action."
- **Focus order:** Back arrow → "+ Add" → list rows top to bottom

### BookmarkSaveSheet
- **Sheet title announced as:** "New bookmark form" / "Edit bookmark form"
- **Name field:** "Bookmark name. Required text field."
- **Amount field:** "Pre-fill amount. Optional. Leave blank to enter each time."
- **Save button:** "Save bookmark. [Disabled until name is entered / Active]."
- **Delete button:** "Delete bookmark. Destructive action."
- **Color contrast:** All text passes WCAG AA 4.5:1
- **Dynamic Type:** Form rows maintain 56dp min height; long bookmark names wrap to 2 lines within the row if needed

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Bookmark has `categoryId` that was deleted | Category row in picker sheet shows "[Deleted category]" in `AppColors.textTertiary`; applying fills category as null in form |
| Bookmark has `accountId` that was deleted | Same as above; account shown as "[Deleted account]" |
| 0 bookmarks, user opens picker | Empty state shown; "+ New" creates first bookmark |
| 50+ bookmarks | Picker sheet and management screen both scroll; no cap on bookmark count in V1 |
| Bookmark name is empty on submit | Save button remains disabled; name field shows inline "Name is required" `AppColors.error` text below field |
| Two bookmarks have identical names | Allowed; both shown; no uniqueness constraint in V1 |
| Applying bookmark overwrites unsaved form data | Amount field already filled by user — bookmark amount (if non-null) replaces it. Show brief Snackbar confirming: "Bookmark applied." User can edit before saving. |
| Amount in bookmark uses different currency than selected account | For V1: no automatic conversion; amount is applied as-is; user is responsible for adjusting |
| Drag reorder while loading | Drag handle disabled during loading state |

---

## New Components Required (Sprint 6)

| Component | File | Notes |
|-----------|------|-------|
| `BookmarkPickerSheet` | `features/bookmarks/presentation/widgets/bookmark_picker_sheet.dart` | `onBookmarkSelected` callback, `onCreateNew` callback. Shows list + empty state. |
| `BookmarkListItem` (picker row) | `features/bookmarks/presentation/widgets/bookmark_list_item.dart` | 56dp (picker) / 64dp (management) variants via `compact` bool prop. Emoji circle, name, sub-label, amount. |
| `BookmarkSaveSheet` | `features/bookmarks/presentation/widgets/bookmark_save_sheet.dart` | `bookmark` (nullable — null = create mode). Full form with type toggle, name, optional fields, Save + Delete. |
| `BookmarksScreen` | `features/bookmarks/presentation/screens/bookmarks_screen.dart` | Reorderable list screen. Delegates rows to `BookmarkListItem`. |
