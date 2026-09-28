import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';

import '../../../../app.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getThemeDescription(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.system:
        return l10n.followSystemTheme;
      case AppThemeMode.light:
        return l10n.alwaysUseLightTheme;
      case AppThemeMode.dark:
        return l10n.alwaysUseDarkTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.localization.settings)),
      body: ValueListenableBuilder<AppThemeMode>(
        valueListenable: ThemeService.themeNotifier,
        builder: (context, themeMode, _) {
          final l10n = context.localization;
          return SettingsList(
            sections: [
              SettingsSection(
                title: Text(l10n.appearance),
                tiles: [
                  SettingsTile(
                    title: Text(l10n.themeMode),
                    description: Text(_getThemeDescription(themeMode, l10n)),
                    leading: Icon(ThemeService.getThemeIcon(themeMode)),
                    trailing: DropdownButton<AppThemeMode>(
                      value: themeMode,
                      underline: const SizedBox(),
                      items: ThemeService.supportedThemes.map((supportedTheme) {
                        return DropdownMenuItem(
                          value: supportedTheme,
                          child: Text(ThemeService.getThemeDisplayName(supportedTheme)),
                        );
                      }).toList(),
                      onChanged: (AppThemeMode? newMode) async {
                        if (newMode != null) {
                          await ThemeService.saveTheme(newMode);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: Text(l10n.language),
                tiles: [
                  SettingsTile(
                    title: Text(l10n.language),
                    description: Text(l10n.languageDescription),
                    leading: const Icon(Icons.language),
                    trailing: ValueListenableBuilder<Locale>(
                      valueListenable: LanguageService.localeNotifier,
                      builder: (context, locale, _) {
                        return DropdownButton<String>(
                          value: locale.languageCode,
                          underline: const SizedBox(),
                          items: LanguageService.supportedLocales.map((supportedLocale) {
                            return DropdownMenuItem(
                              value: supportedLocale.languageCode,
                              child: Text(LanguageService.getLanguageDisplayName(supportedLocale.languageCode)),
                            );
                          }).toList(),
                          onChanged: (String? newLanguage) async {
                            if (newLanguage != null) {
                              final newLocale = Locale(newLanguage);
                              await LanguageService.saveLanguage(newLocale);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
