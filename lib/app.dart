// Root MaterialApp widget wiring router, themes, and localization.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/arb/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/more/presentation/providers/app_preferences_provider.dart';

class MoneyWiseApp extends ConsumerWidget {
  const MoneyWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BUG-S6-011: read theme mode and locale from the unified AppPreferences.
    final prefs = ref.watch(appPreferencesNotifierProvider);
    final themeMode =
        prefs.whenOrNull(data: (p) => p.themeMode) ?? ThemeMode.system;
    final locale = prefs.whenOrNull(
      data: (p) => p.languageCode.isNotEmpty ? Locale(p.languageCode) : null,
    );

    return MaterialApp.router(
      title: 'MoneyWise',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // BUG-S6-011: locale is driven by the persisted languageCode preference.
      locale: locale,
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scale = mq.textScaler.scale(1.0).clamp(0.85, 1.3);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
