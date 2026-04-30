// Unit tests for BudgetProgressBar.colorForRatio colour thresholds — core/widgets.
import 'package:flutter_test/flutter_test.dart';
import 'package:moneywise/core/constants/app_colors.dart';
import 'package:moneywise/core/widgets/budget_progress_bar.dart';

void main() {
  group('BudgetProgressBar.colorForRatio', () {
    test('colorForRatio returns brandPrimary when ratio is below 0.70', () {
      expect(
        BudgetProgressBar.colorForRatio(0.0),
        equals(AppColors.brandPrimary),
      );
      expect(
        BudgetProgressBar.colorForRatio(0.5),
        equals(AppColors.brandPrimary),
      );
      // 0.699 is still below the threshold
      expect(
        BudgetProgressBar.colorForRatio(0.699),
        equals(AppColors.brandPrimary),
      );
    });

    test('colorForRatio returns warning when ratio is >= 0.70 and < 1.0', () {
      expect(
        BudgetProgressBar.colorForRatio(0.70),
        equals(AppColors.warning),
      );
      expect(
        BudgetProgressBar.colorForRatio(0.85),
        equals(AppColors.warning),
      );
      // 0.999 is still below the over-budget threshold
      expect(
        BudgetProgressBar.colorForRatio(0.999),
        equals(AppColors.warning),
      );
    });

    test('colorForRatio returns error when ratio is >= 1.0', () {
      expect(
        BudgetProgressBar.colorForRatio(1.0),
        equals(AppColors.error),
      );
      expect(
        BudgetProgressBar.colorForRatio(1.5),
        equals(AppColors.error),
      );
      expect(
        BudgetProgressBar.colorForRatio(2.0),
        equals(AppColors.error),
      );
    });
  });
}
