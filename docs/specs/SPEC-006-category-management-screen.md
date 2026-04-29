# SPEC-006: Category Management Screen

**Related:** Sprint 2 — Category management feature
**Reference:** SPEC.md Section 9.9 (Ekran 6, 7), SPEC.md Section 6.3 (categories table)
**Route:** `/more/category-management` with query param `?type=expense` or `?type=income`
**Component:** `lib/features/more/presentation/screens/category_management_screen.dart`

---

## Purpose

Allows users to view, reorder, edit, and delete income and expense categories. Default (system) categories are protected from deletion. Users can add custom categories with a name, emoji, and color. Sub-categories can be enabled via a toggle.

---

## Layout

```
┌─────────────────────────────────────────────────┐
│  < Settings       Income / Exp.         [+]     │  ← AppBar 44dp
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │  ← Type toggle pill (segmented)
│  │  [  Income  ]  [   Expense   ]          │   │  44dp height
│  └─────────────────────────────────────────┘   │
│                                                 │
│  Subcategory                         [●─]  OFF │  ← Toggle row 56dp
│  ─────────────────────────────────────────────  │
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← Category list (bgSecondary card)
│  │ [─] 🍜  Food                  ✏️    ☰  │   │  ← 56dp row (custom)
│  │ [─] 👫  Social Life           ✏️    ☰  │   │
│  │ [─] 🐶  Pets                  ✏️    ☰  │   │
│  │     🚕  Transport             🔒    ☰  │   │  ← default category (no delete)
│  │     🖼️  Culture               🔒    ☰  │   │
│  │     ...                                │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│                              ┌──────┐           │
│                              │  +   │           │  ← FAB (brand, 56dp)
│                              └──────┘           │
├─────────────────────────────────────────────────┤
│  [Bottom Tab Bar — 49dp]                        │
└─────────────────────────────────────────────────┘
```

---

## Top Segmented Control (Income / Expense)

- Two segments: "Income" and "Expense".
- Width: fills horizontally with `AppSpacing.lg` (16dp) margin each side.
- Height: 44dp.
- Background (container): `AppColors.bgSecondary`, `AppRadius.pill` (fully rounded).
- Active segment: `AppColors.brandPrimary` fill, `AppColors.textOnBrand` text, `AppRadius.pill`.
- Inactive segment: transparent background, `AppColors.textSecondary` text.
- Typography: `AppTypography.bodyMedium` (16/500).
- Switching segments loads the corresponding category list. No network call; driven by local Drift stream.
- Animation: active indicator slides horizontally (200ms, easeInOut).
- When the screen is opened with a `?type=` query param, the correct segment is pre-selected.

Note: if the screen is reached by tapping "Income Category Setting" or "Expenses Category Setting" from `MoreScreen`, the corresponding type is pre-selected. If reached without a param, default to Expense.

---

## Subcategory Toggle Row

- Full-width row, height 56dp, horizontal padding `AppSpacing.lg`.
- Left: label "Subcategory" (`AppTypography.body` + `AppColors.textPrimary`).
- Right: `Switch` widget.
  - ON: track `AppColors.brandPrimary`, thumb white.
  - OFF: track `AppColors.bgTertiary`, thumb white.
- Default: OFF.
- When toggled ON: each category row with sub-categories gains a trailing expand/collapse chevron. A expand/collapse mechanism is enabled.
- When toggled OFF: all groups collapse, sub-category rows hidden, expand chevrons hidden.
- Divider below the toggle row: `AppColors.divider`, 1dp.

---

## Category List

### Row Layout (56dp height)

```
┌──────────────────────────────────────────────────────────────┐
│  [delete btn 44dp]  [icon 36dp]  Name              [action] [☰]│
└──────────────────────────────────────────────────────────────┘
```

| Element | Position | Spec |
|---|---|---|
| Delete button (custom only) | Leading, 44x44dp tap target | Phosphor `MinusCircle`, 22dp, `AppColors.error`. Tap triggers delete confirmation. |
| Delete placeholder (default) | Leading, 44x44dp area | Phosphor `LockSimple`, 22dp, `AppColors.textTertiary`. Non-interactive. |
| Category icon | 36dp circle. Background = category `colorHex` or `AppColors.bgTertiary`. | Emoji at 18dp, or Phosphor icon at 18dp. |
| Category name | `AppTypography.body` + `AppColors.textPrimary`. Flexible width (fills remaining space). | Truncate with ellipsis if overflow. |
| Edit button (custom only) | Trailing, before drag handle. 44x44dp. | Phosphor `PencilSimple`, 20dp, `AppColors.textSecondary`. Tap opens Edit bottom sheet. |
| Lock icon (default) | Trailing, before drag handle. 44x44dp. | Phosphor `LockSimple`, 20dp, `AppColors.textTertiary`. Non-interactive. Tooltip on long-press: "Default categories cannot be deleted." |
| Drag handle | Trailing, rightmost. 44x44dp. | Phosphor `DotsSixVertical`, 20dp, `AppColors.textTertiary`. Initiates drag-to-reorder. |

### Expand / Collapse (Subcategory ON)

When a category has sub-categories and Subcategory toggle is ON:

```
│  [─] 🍜  Food         ▸  ✏️    ☰  │  ← parent row with chevron
│           └─ 🍕  Pizza  ✏️    ☰  │  ← sub-category, 48dp, 32dp left indent
│           └─ 🍣  Sushi  ✏️    ☰  │
```

- Parent row gains a Phosphor `CaretRight` (16dp, `AppColors.textTertiary`) between the name and the edit button.
- Tapping the parent row (not the edit or delete buttons): toggles expansion (not navigation).
- Sub-category rows: 48dp height (4dp shorter), 32dp additional left indentation, icon 28dp circle.
- Collapsed: sub-rows hidden with an animated size transition (200ms, easeOutCubic).

### Default Category List — Expense

1. 🍜 Food
2. 👫 Social Life
3. 🐶 Pets
4. 🚕 Transport
5. 🖼️ Culture
6. 🪑 Household
7. 🧥 Apparel
8. 💄 Beauty
9. 🧘 Health
10. 📚 Education
11. 🎁 Gift
12. Other
13. 🤵 Insurance
14. 🏠 Rent
15. 🚬 Cigarette
16. 🛒 Groceries
17. 🍽️ Restaurant
18. 🅿️ Parking
19. 🧾 Bills
20. 🏋️ Gym
21. 💊 Medicine

All of the above are system defaults (`isDefault = true`). They show the lock icon and cannot be deleted.

### Default Category List — Income

1. 🤑 Allowance
2. 💰 Salary
3. 💵 Petty Cash
4. 🥇 Bonus
5. Other
6. 💸 Dividend
7. 💸 Interest

All system defaults as above.

### Drag-to-Reorder

- Long-press (or drag from the drag handle) activates the drag.
- Dragged row: elevates to appear above the list (box shadow, `AppColors.brandPrimary` at opacity 0.2 glow), slightly scales up (1.02).
- Other rows shift to make room (animated, 200ms, easeOut).
- Only the `sortOrder` column is updated on drop; no other fields change.
- System default categories can be reordered relative to each other (only deletion is restricted).
- Sub-categories can be reordered within their parent but cannot be dragged to become top-level or moved to a different parent via drag.

### Swipe-to-Delete (iOS, custom categories only)

- iOS: swipe left on a custom category row to reveal "Delete" trailing action (`AppColors.error` background, Phosphor `Trash` white icon, "Delete" label).
- Android: the leading delete button (Phosphor `MinusCircle`) serves as the primary delete affordance.
- Swipe on default category rows: no action exposed (swipe is a no-op with a gentle rubber-band bounce).

---

## FAB

- 56dp circle, `AppColors.brandPrimary` background, white `+` icon (Phosphor `Plus`, 24dp).
- Position: bottom-right, `AppSpacing.lg` (16dp) from right edge and above banner ad (or tab bar if no ad).
- Tap: opens the Add/Edit Category bottom sheet (in "add" mode).
- Minimum tap target: 56dp (already meets the 44dp requirement).

---

## Add / Edit Category — Bottom Sheet

Opened by:
- Tapping FAB (add mode).
- Tapping the edit (pencil) icon on a row (edit mode).

```
┌─────────────────────────────────────────────────┐
│  ╌╌╌╌╌╌╌╌  (drag handle)                        │
│  Add Category         /  Edit Category          │  ← sheet title 56dp
├─────────────────────────────────────────────────┤
│                                                 │
│         ┌──────────┐                            │
│         │ [preview]│  56dp circle preview       │
│         └──────────┘                            │
│                                                 │
│  ┌─────────────────────────────────────────┐   │  ← form area
│  │ Name      [TextField                ]   │   │  56dp
│  │ ─────────────────────────────────────── │   │
│  │ Sub of    (none)                   >    │   │  56dp (sub-category parent picker)
│  └─────────────────────────────────────────┘   │
│                                                 │
│  COLOR                                         │  ← section label
│  ● ● ● ● ● ● ● ● ● ●  (10 swatches, 32dp)    │
│                                                 │
│  EMOJI                                         │  ← section label
│  [emoji grid — scrollable, 6 cols, 44dp cells] │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │               Save                      │   │  ← AppButton primary 52dp
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Sheet Fields

**Name**
- Required. Single-line text field.
- Max 50 characters.
- Label: "Name" (`AppColors.textSecondary`).
- Placeholder: empty.
- Validation: non-empty for Save to be enabled.

**Sub of (parent picker)**
- Label: "Sub of"
- Value: "(none)" by default, or name of selected parent.
- Tap: opens a nested sheet or inline list of top-level categories from the current type (Income or Expense). User selects one to make this category a sub-category.
- Only shown when Subcategory toggle is ON on the main screen. If toggle is OFF this row is hidden.

**Color swatches**
- 10 preset colors, 32dp each, 8dp gap, horizontal scrollable row.
- First swatch is always the "default" neutral color (`AppColors.bgTertiary`).
- Selected: 2dp `AppColors.textPrimary` ring.

**Emoji grid**
- Grid of ~60 curated finance/lifestyle emoji relevant to income/expense categories.
- 6 columns, each cell 44dp, 4dp spacing.
- Scrollable within the sheet.
- Selected emoji: `AppColors.brandPrimary` border (2dp) + `AppColors.bgTertiary` background.
- Alternatively the user may type any emoji directly into the Name field — the system will detect and offer to use it as the category icon.
- If no emoji is selected, the category displays its first letter as a text avatar.

**Preview circle**
- 56dp circle above the form. Updates live as user selects color and emoji.
- Background: selected color.
- Content: selected emoji (18dp).

**Save button**
- `AppButton` primary, 52dp, `AppRadius.md`, full width with `AppSpacing.lg` side padding.
- Disabled (opacity 0.4) until Name is non-empty.
- Tap: saves (add or update) and dismisses the sheet.
- Loading state: shows inline `LoadingIndicator` (16dp, white) replacing the label.

### Sheet Dimensions
- Height: 65% of screen height minimum. If keyboard appears, the sheet expands to accommodate and the form scrolls.
- Background: `AppColors.bgSecondary`, top corners `AppRadius.xl` (24dp).
- Drag handle: centered, 4dp × 36dp, `AppColors.textTertiary`.
- Dismiss: drag down or tap outside the sheet. If form is dirty, present a discard confirmation (same pattern as SPEC-005).

---

## States

### Default (categories loaded)
- Shows the category list for the currently selected type (default: Expense).
- Subcategory toggle: OFF.
- FAB visible.

### Loading
- List area: 6 skeleton rows, each 56dp. Shimmer between `AppColors.bgSecondary` and `AppColors.bgTertiary`.
- FAB visible.
- Segmented control interactive (can switch before load completes; new stream fires).

### Empty (no categories — should not normally occur; system defaults always present)
This state is documented for completeness. It can only occur if defaults failed to seed.

```
│              [Illustration: empty tag/label]   │
│          No categories yet                     │
│       Tap + to add your first category         │
│                                                │
│       ┌─────────────────────────────┐          │
│       │   + Add category            │          │
│       └─────────────────────────────┘          │
```

- CTA button navigates to the Add/Edit sheet.

### Error
- Centered error message with Phosphor `WarningCircle` (40dp, `AppColors.error`) + "Could not load categories" text + "Try again" ghost button.

---

## Delete Confirmation

### Custom category with no transactions
- Alert title: "Delete category?"
- Alert body: "This will permanently delete [Category Name]."
- Actions: "Cancel" (default) + "Delete" (`AppColors.error`).

### Custom category with linked transactions
- Alert title: "Delete category?"
- Alert body: "[Category Name] is used by [N] transaction(s). What would you like to do?"
- Actions (sheet-style, multiple options):
  1. "Move transactions to Other" — reassigns all linked transactions to the system "Other" category.
  2. "Delete transactions too" — deletes the category and all linked transactions.
  3. "Cancel" — dismisses without change.
- Actions 1 and 2 both then delete the category.
- This multi-action confirmation is best presented as a `CupertinoActionSheet` (iOS) or a multi-button `AlertDialog` (Android).

---

## User Flows

### Add custom category (happy path)
```
FAB tap
  → Add/Edit bottom sheet opens (add mode, empty)
    → User types name
    → User taps color swatch
    → User taps emoji
    → Preview circle updates
    → User taps Save
      → Loading state (button spinner)
      → Category appended to list (reactive stream)
      → Sheet dismisses
```

### Edit category
```
Tap ✏️ on row
  → Add/Edit bottom sheet opens (edit mode, pre-populated)
    → User modifies fields
    → User taps Save
      → Loading state
      → Row updates in list
      → Sheet dismisses
```

### Delete custom category (no transactions)
```
Tap [─] delete button (or swipe left on iOS)
  → Confirmation alert
    → Tap Delete
      → Row animates out (slide + fade, 300ms)
      → Snackbar: "Category deleted"
```

### Delete custom category (with transactions)
```
Tap [─] delete button
  → Multi-option alert
    → "Move to Other" or "Delete transactions too"
      → Appropriate action executed
      → Row animates out
      → Snackbar: "Category deleted. [N] transaction(s) moved to Other." or "Category and [N] transaction(s) deleted."
```

---

## Accessibility

- Screen title announced: "Income categories" or "Expense categories" depending on active tab.
- Segmented control: semanticLabel "Category type. [Income/Expense] selected." Role = tab.
- Subcategory toggle: semanticLabel "Subcategory grouping, [on/off]."
- Category row: semanticLabel "[emoji] [Name], [default/custom] category. [actions available]."
- Delete button: semanticLabel "Delete [Category Name]." Disabled for default categories; label changes to "Locked. Cannot delete default category."
- Edit button: semanticLabel "Edit [Category Name]."
- Drag handle: semanticLabel "Reorder [Category Name]. Hold to drag." (accessible alternative: long-press opens a "Move up / Move down" context menu).
- FAB: semanticLabel "Add new category."
- Add/Edit sheet: focus moves into the sheet on open. Focus trap within the sheet. First focus: Name text field.
- Emoji grid cells: semanticLabel "[emoji description] emoji." Navigable via D-pad/switch access.
- Color swatches: semanticLabel "[Color name] color. [Selected/not selected]."
- Save button: semanticLabel "Save category. Disabled until name is entered." when disabled.
- Color is never the sole differentiator: default vs custom categories are distinguished by both icon (lock vs delete button) and label ("default" in semantics).
- Minimum tap target on all elements: 44x44dp.
- Focus order within sheet: Name → Sub of → Color swatches → Emoji grid → Save.

---

## Animation Summary

| Event | Element | Duration | Curve |
|---|---|---|---|
| Segment switch | Indicator slide | 200ms | easeInOut |
| Category list switch (type) | Cross-fade | 150ms | easeInOut |
| Sub-category expand | Animated size | 200ms | easeOutCubic |
| Sub-category collapse | Animated size | 150ms | easeInCubic |
| Drag row lift | Shadow + scale 1.02 | 100ms | easeOut |
| Row deletion | Slide + fade out | 300ms | easeInCubic |
| Swipe action reveal | Slide | 200ms | easeOut |
| Bottom sheet entry | Slide up | 300ms | easeOutCubic |
| Bottom sheet exit | Slide down | 250ms | easeInCubic |
| Card-specific fields appear | Animated size | 250ms | easeOutCubic |

---

## Open Questions

- Q: Should the screen be reachable from both the MoreScreen menu items ("Income Category Setting" AND "Expenses Category Setting") as two separate routes, or as one route with a query param? Assumption: single route with `?type=expense` / `?type=income` query param; MoreScreen passes the appropriate param.
- Q: Should sub-categories be addable to default categories, or only to custom categories? Assumption: sub-categories can be added to any category, including defaults.
- Q: Is there a maximum number of custom categories per type? Assumption: no hard limit in V1.
