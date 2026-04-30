// Light and dark ThemeData for MoneyWise, built from AppColors tokens.
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgPrimary,
          selectedItemColor: AppColors.brandPrimary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgPrimaryLight,
          selectedItemColor: AppColors.brandPrimary,
          unselectedItemColor: AppColors.textSecondaryLight,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
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
