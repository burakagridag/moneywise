// Unit tests for seed data content correctness — data/local feature.
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/data/local/seed_data.dart';

void main() {
  group('defaultAccountGroups', () {
    test('returns exactly 11 groups', () {
      final groups = defaultAccountGroups();
      expect(groups.length, 11);
    });

    test('first group is Cash with type cash', () {
      final groups = defaultAccountGroups();
      expect(groups.first.name.value, 'Cash');
      expect(groups.first.type.value, 'cash');
    });

    test('last group is Others', () {
      final groups = defaultAccountGroups();
      expect(groups.last.name.value, 'Others');
      expect(groups.last.type.value, 'others');
    });

    test('all groups have sortOrder matching their index', () {
      final groups = defaultAccountGroups();
      for (var i = 0; i < groups.length; i++) {
        expect(groups[i].sortOrder.value, i);
      }
    });

    test('all groups have includeInTotals = true', () {
      final groups = defaultAccountGroups();
      for (final g in groups) {
        expect(g.includeInTotals.value, isTrue);
      }
    });

    test('all groups have unique non-empty ids', () {
      final groups = defaultAccountGroups();
      final ids = groups.map((g) => g.id.value).toSet();
      expect(ids.length, groups.length);
      for (final id in ids) {
        expect(id, isNotEmpty);
      }
    });

    test('group types cover all expected values', () {
      final groups = defaultAccountGroups();
      final types = groups.map((g) => g.type.value).toSet();
      expect(
        types,
        containsAll([
          'cash',
          'accounts',
          'card',
          'debitCard',
          'savings',
          'topUpPrepaid',
          'investments',
          'overdrafts',
          'loan',
          'insurance',
          'others',
        ]),
      );
    });
  });

  group('defaultIncomeCategories', () {
    test('returns 7 income categories', () {
      final cats = defaultIncomeCategories();
      expect(cats.length, 7);
    });

    test('all categories have type income', () {
      final cats = defaultIncomeCategories();
      for (final c in cats) {
        expect(c.type.value, 'income');
      }
    });

    test('all categories are marked as default', () {
      final cats = defaultIncomeCategories();
      for (final c in cats) {
        expect(c.isDefault.value, isTrue);
      }
    });

    test('Salary is the second income category', () {
      final cats = defaultIncomeCategories();
      expect(cats[1].name.value, 'Salary');
    });

    test('all categories have unique ids', () {
      final cats = defaultIncomeCategories();
      final ids = cats.map((c) => c.id.value).toSet();
      expect(ids.length, cats.length);
    });
  });

  group('defaultExpenseCategories', () {
    test('returns 21 expense categories', () {
      final cats = defaultExpenseCategories();
      expect(cats.length, 21);
    });

    test('all categories have type expense', () {
      final cats = defaultExpenseCategories();
      for (final c in cats) {
        expect(c.type.value, 'expense');
      }
    });

    test('first expense category is Food', () {
      final cats = defaultExpenseCategories();
      expect(cats.first.name.value, 'Food');
    });

    test('all expense categories are marked as default', () {
      final cats = defaultExpenseCategories();
      for (final c in cats) {
        expect(c.isDefault.value, isTrue);
      }
    });

    test('all expense categories have unique ids', () {
      final cats = defaultExpenseCategories();
      final ids = cats.map((c) => c.id.value).toSet();
      expect(ids.length, cats.length);
    });

    test('income and expense ids do not overlap', () {
      final incomeIds =
          defaultIncomeCategories().map((c) => c.id.value).toSet();
      final expenseIds =
          defaultExpenseCategories().map((c) => c.id.value).toSet();
      expect(incomeIds.intersection(expenseIds), isEmpty);
    });
  });
}
