# US-017: CategoryManagementScreen — list, add, edit, and delete categories

## Persona
A MoneyWise user who wants to customise their income and expense categories — renaming,
reordering, or adding new ones with custom emojis and colours — so that spending reports
reflect the categories meaningful to them personally.

## Story
**As** a MoneyWise user
**I want** a Category Management screen for both income and expense types where I can view
all categories, add custom ones, edit existing ones, reorder them by drag, and delete
custom categories (with a re-assignment prompt if transactions exist)
**So that** my categories match my personal budgeting style and transaction reports are
accurate

## Source
SPEC.md §9.9 (CategoryManagementScreen, Ekran 6 & 7); SPEC.md §6.3 (categories table);
SPEC.md §3.2 (MoreNavigator — route /more/category-management?type=income|expense).
Sprint 2 goal — Account & Category Management.

## Acceptance Criteria

```gherkin
Scenario: Expense category list shows all active expense categories
  Given the database is seeded with default categories
  When the user navigates to More > Expenses Category Setting
  Then CategoryManagementScreen opens with type = expense
  And all 21 default expense categories are listed in sortOrder ASC
  And each row shows a delete icon (left), emoji + name (centre),
      edit icon, and drag handle (right)

Scenario: Income category list shows all active income categories
  When the user navigates to More > Income Category Setting
  Then CategoryManagementScreen opens with type = income
  And all 7 default income categories are listed

Scenario: Subcategory toggle ON shows nested subcategories
  Given "Food" has one subcategory "Fast Food"
  And the Subcategory toggle is OFF
  Then "Fast Food" is not visible
  When the user turns the Subcategory toggle ON
  Then "Food" shows an expand arrow
  And tapping it reveals "Fast Food" indented beneath "Food"

Scenario: Subcategory toggle OFF collapses all subcategories
  Given the toggle is ON and some categories are expanded
  When the user turns the Subcategory toggle OFF
  Then all subcategories are hidden and expand arrows disappear

Scenario: Add new custom expense category
  Given the user is on the expense CategoryManagementScreen
  When the user taps the + button
  Then an Add Category modal opens with Name, Emoji, Color Picker fields
  When the user enters name = "Coffee Shops", emoji = ☕, color = #6F4E37 and taps Save
  Then the modal closes
  And "Coffee Shops" appears at the bottom of the expense category list
  And it has isDefault = false

Scenario: Add category with duplicate name within type is rejected
  Given "Food" already exists as an expense category
  When the user tries to add a new expense category named "Food"
  Then a validation error "Category name already exists" is shown
  And no new row is saved

Scenario: Edit a default category name and emoji
  Given "Food" (isDefault = true) exists
  When the user taps the edit icon for "Food"
  Then the Edit Category modal opens pre-filled with name = "Food" and emoji = 🍜
  When the user changes the name to "Meals" and taps Save
  Then the category row updates to show "Meals"
  And isDefault remains true (editing does not reset isDefault)

Scenario: Delete a custom category with no linked transactions
  Given custom category "Coffee Shops" exists with no transactions
  When the user taps the delete icon for "Coffee Shops"
  Then a confirmation dialog "Delete Coffee Shops?" appears
  When the user confirms
  Then "Coffee Shops" is soft-deleted
  And it no longer appears in the list

Scenario: Delete a custom category that has linked transactions
  Given custom category "Coffee Shops" has 3 linked transactions
  When the user taps the delete icon for "Coffee Shops"
  Then a dialog appears: "Coffee Shops has 3 transactions.
       Move them to another category or delete all."
  With options: [Select category] [Delete all] [Cancel]
  When the user selects "Other" and confirms
  Then all 3 transactions are re-assigned to "Other"
  And "Coffee Shops" is soft-deleted atomically

Scenario: Delete a default category is blocked
  Given "Food" (isDefault = true) is in the list
  When the user taps the delete icon for "Food"
  Then a message is shown: "Default categories cannot be deleted"
  And no deletion occurs

Scenario: Drag to reorder categories
  Given expense categories in order: Food(0), Social Life(1), Pets(2)
  When the user long-presses the drag handle on "Pets" and drags it above "Food"
  Then the sortOrder updates: Pets(0), Food(1), Social Life(2)
  And the next stream from CategoryRepository reflects the new order

Scenario: Back navigation returns to MoreScreen
  Given the user is on CategoryManagementScreen
  When the user taps back
  Then the user is returned to MoreScreen without changes if none were made
```

## Edge Cases
- [ ] Empty state — no categories at all (only possible if all defaults were deleted, which is blocked; this state should not occur in practice but the screen must handle a theoretically empty list gracefully)
- [ ] Category name max 50 chars — input field enforces maxLength = 50
- [ ] Emoji picker: device may not support all emojis — gracefully display placeholder square if emoji is unsupported on older OS
- [ ] Color picker: colorHex stored as #RRGGBB; null is valid (no colour selected) — display a neutral placeholder
- [ ] Re-assignment target — the "Select category" picker in the delete dialog must not include the category being deleted itself, and must not include soft-deleted categories
- [ ] Drag reorder with Subcategory toggle ON — drag must not allow a parent category to be dragged into its own child position
- [ ] Screen opened from two tabs simultaneously (Android multi-window) — Riverpod state is shared; concurrent edits are serialised through the repository
- [ ] Offline — all operations local-first; no network dependency
- [ ] Dark mode and Light mode — both must render correctly

## Test Scenarios for QA
1. Expense screen: verify 21 default expense categories visible, in correct order, on iOS and Android
2. Income screen: verify 7 default income categories visible
3. Add custom category: verify appears at end of list with correct emoji and colour
4. Duplicate name: verify error message shown, no DB insert
5. Edit default category name: verify updated in list, isDefault still true in DB
6. Delete custom category (no transactions): verify soft-deleted, gone from list
7. Delete custom category (3 transactions): verify re-assignment dialog, atomicity
8. Attempt to delete default category: verify blocked with message
9. Drag-to-reorder: verify sortOrder updated in DB and list reflects new order
10. Subcategory toggle ON/OFF: verify subcategories show/hide correctly

## UX Spec
TBD — ux-designer to deliver `docs/specs/SPEC-006-category-management-screen.md` during Sprint 2.
Reference: SPEC.md §9.9 (Ekran 6, 7).

## Estimate
L (5–6 days)

## Dependencies
- US-014 (CategoryRepository — add/update/delete/reassign business rules)
- US-013 (Categories table and DAO)
