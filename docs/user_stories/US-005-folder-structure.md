# US-005: Folder structure created per SPEC.md Section 5

## Source
SPEC.md §5 (Mimari Katmanlar — folder structure), §16.1 Sprint 1 checklist — "Klasör yapısı oluştur"

## Persona
A flutter engineer who needs the full feature-first Clean Architecture folder structure in place before writing any feature code, so that files are created in the correct location from the start.

## Story
**As** a MoneyWise developer
**I want** the complete folder structure from SPEC.md §5 created with barrel files and placeholder stubs
**So that** every future file has a pre-defined, agreed-upon location and the architecture layers are clearly separated

## Acceptance Criteria

```gherkin
Scenario: Top-level lib/ directories exist
  Given the project has been set up
  When an engineer browses the lib/ directory
  Then the following top-level directories are present:
    | core/      |
    | data/      |
    | domain/    |
    | features/  |
    | services/  |
  And main.dart, app.dart, and bootstrap.dart exist at lib/ root

Scenario: core/ subdirectories and key files exist
  Given the folder structure has been created
  When an engineer browses lib/core/
  Then the following subdirectories and stub files are present:
    | constants/app_colors.dart         |
    | constants/app_typography.dart     |
    | constants/app_spacing.dart        |
    | constants/app_strings.dart        |
    | theme/app_theme.dart              |
    | theme/theme_extensions.dart       |
    | extensions/date_extensions.dart   |
    | extensions/num_extensions.dart    |
    | extensions/context_extensions.dart|
    | utils/currency_formatter.dart     |
    | utils/date_helpers.dart           |
    | utils/validators.dart             |
    | widgets/app_button.dart           |
    | widgets/app_text_field.dart       |
    | widgets/app_bottom_sheet.dart     |
    | widgets/currency_text.dart        |
    | widgets/month_year_picker.dart    |
    | widgets/loading_indicator.dart    |
    | router/app_router.dart            |
    | router/routes.dart                |
    | i18n/arb/app_tr.arb               |
    | i18n/arb/app_en.arb               |
    | i18n/locale_provider.dart         |
    | error/failures.dart               |
    | error/error_handler.dart          |

Scenario: data/ subdirectories and key files exist
  Given the folder structure has been created
  When an engineer browses lib/data/
  Then the following are present:
    | local/database.dart                     |
    | local/tables/accounts_table.dart        |
    | local/tables/account_groups_table.dart  |
    | local/tables/categories_table.dart      |
    | local/tables/transactions_table.dart    |
    | local/tables/budgets_table.dart         |
    | local/tables/bookmarks_table.dart       |
    | local/tables/recurring_table.dart       |
    | local/tables/memos_table.dart           |
    | local/tables/settings_table.dart        |
    | local/tables/currencies_table.dart      |
    | local/daos/account_dao.dart             |
    | local/daos/category_dao.dart            |
    | local/daos/transaction_dao.dart         |
    | local/daos/budget_dao.dart              |
    | repositories/account_repository.dart    |
    | repositories/transaction_repository.dart|
    | repositories/budget_repository.dart     |
    | repositories/category_repository.dart   |
    | repositories/settings_repository.dart   |

Scenario: domain/ subdirectories and key files exist
  Given the folder structure has been created
  When an engineer browses lib/domain/
  Then the following are present:
    | entities/account.dart            |
    | entities/category.dart           |
    | entities/transaction.dart        |
    | entities/budget.dart             |
    | entities/money.dart              |
    | enums/transaction_type.dart      |
    | enums/account_type.dart          |
    | enums/period.dart                |
    | usecases/add_transaction.dart    |

Scenario: features/ subdirectories exist for all 4 main tabs
  Given the folder structure has been created
  When an engineer browses lib/features/
  Then directories for transactions/, stats/, accounts/, and more/ all exist
  And each feature directory contains presentation/screens/, presentation/widgets/, and presentation/providers/ subdirectories
  And each feature has a barrel export file (e.g., transactions.dart)

Scenario: services/ stub files exist
  Given the folder structure has been created
  When an engineer browses lib/services/
  Then stub files for biometric_service.dart, notification_service.dart, backup_service.dart, and recurring_scheduler_service.dart are present

Scenario: Project compiles with empty stubs
  Given all stub files contain valid (empty or minimal) Dart code
  When `flutter analyze` is run
  Then zero errors and zero warnings are reported
```

## Edge Cases
- [ ] All stub Dart files must be valid Dart (e.g., `// TODO: implement` comment is acceptable; empty files with no declaration will cause analyzer warnings)
- [ ] Barrel files must not create circular import chains
- [ ] The `remote/` subdirectory inside `data/` must exist as a placeholder even though it is not implemented until Phase 2
- [ ] The `auth/` feature directory must exist as a stub for Phase 2 alignment
- [ ] File names must follow snake_case throughout; PascalCase filenames will fail the project's naming convention

## Test Scenarios for QA
1. Clone repo and run `flutter pub get` followed by `flutter analyze` — expect zero errors
2. Verify every directory listed in SPEC.md §5 exists by browsing the repo
3. Verify each stub Dart file is valid Dart (no syntax errors) by running `dart analyze lib/`
4. Verify barrel export files exist for each feature
5. Confirm no circular imports using `dart pub deps`

## UX Spec
N/A — no UI involved

## Estimate
S (1 day)

## Dependencies
- US-001 (project skeleton must exist first)
