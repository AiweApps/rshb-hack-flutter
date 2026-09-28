import 'package:flutter/material.dart';

import '../../shared/helpers/service_locator.dart';
import '../misc/preferences/app_preferences.dart';

enum AppThemeMode { system, light, dark }

/// Current theme mode, stored through [AppPreferences].
class ThemeService {
  static final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(
    AppThemeMode.system,
  );

  static Future<void> initialize() async {
    final index = sl<AppPreferences>().themeModeIndex;
    themeNotifier.value = index == null || index >= AppThemeMode.values.length
        ? AppThemeMode.system
        : AppThemeMode.values[index];
  }

  static Future<void> saveTheme(AppThemeMode theme) async {
    await sl<AppPreferences>().setThemeModeIndex(theme.index);
    themeNotifier.value = theme;
  }

  static ThemeMode getFlutterThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
