import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/presentation/base_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/language_service.dart';
import 'core/services/theme_service.dart';
import 'l10n/app_localizations.dart';
import 'shared/helpers/service_locator.dart';

enum AppThemeMode { light, dark, system }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = sl<AppRouter>();

    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, appThemeMode, _) {
        final themeMode = ThemeService.getFlutterThemeMode(appThemeMode);

        return ValueListenableBuilder<Locale>(
          valueListenable: LanguageService.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp.router(
              routerConfig: appRouter.mainRouter,
              onGenerateTitle: (context) => context.localization.appTitle,
              theme: getBaseTheme(brightness: Brightness.light),
              darkTheme: getBaseTheme(brightness: Brightness.dark),
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LanguageService.supportedLocales,
            );
          },
        );
      },
    );
  }
}
