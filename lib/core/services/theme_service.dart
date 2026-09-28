import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import 'language_service.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(AppThemeMode.system);
  
  static const List<AppThemeMode> supportedThemes = [
    AppThemeMode.system,
    AppThemeMode.light,
    AppThemeMode.dark,
  ];
  
  static String getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return lsl10n.system;
      case AppThemeMode.light:
        return lsl10n.light;
      case AppThemeMode.dark:
        return lsl10n.dark;
    }
  }
  
  static IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }
  
  static Future<AppThemeMode> getSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0; // Default to system
    return AppThemeMode.values[themeIndex];
  }
  
  static Future<void> saveTheme(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    // Update the notifier immediately
    themeNotifier.value = theme;
  }
  
  static Future<void> initialize() async {
    final savedTheme = await getSavedTheme();
    themeNotifier.value = savedTheme;
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
