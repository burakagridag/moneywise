// Light and dark ThemeData for MoneyWise, built from AppColors tokens.
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgPrimary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.brandPrimary,
          secondary: AppColors.brandPrimary,
          surface: AppColors.bgSecondary,
          error: AppColors.error,
          onPrimary: AppColors.textOnBrand,
          onSecondary: AppColors.textOnBrand,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textOnBrand,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgPrimary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.bgPrimary,
          indicatorColor: AppColors.brandPrimary.withAlpha(38),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTypography.caption1.copyWith(
                color: AppColors.brandPrimary,
              );
            }
            return AppTypography.caption1.copyWith(
              color: AppColors.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.brandPrimary, size: 24);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 24);
          }),
        ),
        dividerColor: AppColors.divider,
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),
        cardColor: AppColors.bgSecondary,
        cardTheme: CardThemeData(
          color: AppColors.bgSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.borderFocus),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgPrimaryLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.brandPrimary,
          secondary: AppColors.brandPrimary,
          surface: AppColors.bgSecondaryLight,
          error: AppColors.error,
          onPrimary: AppColors.textOnBrand,
          onSecondary: AppColors.textOnBrand,
          onSurface: AppColors.textPrimaryLight,
          onError: AppColors.textOnBrand,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgPrimaryLight,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          centerTitle: true,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.bgSecondaryLight,
          indicatorColor: AppColors.brandPrimary.withAlpha(38),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTypography.caption1.copyWith(
                color: AppColors.brandPrimary,
              );
            }
            return AppTypography.caption1.copyWith(
              color: AppColors.textSecondaryLight,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.brandPrimary, size: 24);
            }
            return const IconThemeData(
              color: AppColors.textSecondaryLight,
              size: 24,
            );
          }),
        ),
        dividerColor: AppColors.bgTertiaryLight,
        cardColor: AppColors.bgSecondaryLight,
        cardTheme: CardThemeData(
          color: AppColors.bgSecondaryLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.borderFocusLight),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
}
