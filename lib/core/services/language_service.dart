import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this)!;
}

AppLocalizations get lsl10n => LanguageService.localizations;

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  static AppLocalizations? _currentLocalizations;
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale(_defaultLanguage),
  );

  static const List<Locale> supportedLocales = [Locale('en'), Locale('de')];

  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return localizations.english;
      case 'de':
        return localizations.german;
      default:
        return languageCode.toUpperCase();
    }
  }

  static Future<Locale> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? _defaultLanguage;
    return Locale(languageCode);
  }

  static Future<void> saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
    // Update the localizations and notifier immediately
    updateLocalizations(lookupAppLocalizations(locale));
    localeNotifier.value = locale;
  }

  static Future<void> initialize() async {
    final savedLocale = await getSavedLanguage();
    localeNotifier.value = savedLocale;
    updateLocalizations(lookupAppLocalizations(savedLocale));
  }

  static void updateLocalizations(AppLocalizations localizations) {
    _currentLocalizations = localizations;
  }

  static AppLocalizations get localizations {
    if (_currentLocalizations == null) {
      // Fallback to English if no localizations are set
      return lookupAppLocalizations(const Locale(_defaultLanguage));
    }
    return _currentLocalizations!;
  }
}
