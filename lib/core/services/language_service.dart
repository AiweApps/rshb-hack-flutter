import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/helpers/service_locator.dart';
import '../misc/preferences/app_preferences.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get localization => AppLocalizations.of(this)!;
}

/// Localizations for code without a context (blocs, services).
AppLocalizations get lsl10n => LanguageService.localizations;

/// Current UI language. Russian is the product language and the default;
/// the choice is stored through [AppPreferences].
class LanguageService {
  static const String defaultLanguageCode = 'ru';
  static AppLocalizations? _currentLocalizations;
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale(defaultLanguageCode),
  );

  static const List<Locale> supportedLocales = [Locale('ru'), Locale('en')];

  static Future<void> initialize() async {
    final code = sl<AppPreferences>().languageCode ?? defaultLanguageCode;
    final locale = Locale(code);
    localeNotifier.value = locale;
    _currentLocalizations = lookupAppLocalizations(locale);
  }

  static Future<void> saveLanguage(Locale locale) async {
    await sl<AppPreferences>().setLanguageCode(locale.languageCode);
    _currentLocalizations = lookupAppLocalizations(locale);
    localeNotifier.value = locale;
  }

  static AppLocalizations get localizations {
    return _currentLocalizations ??
        lookupAppLocalizations(const Locale(defaultLanguageCode));
  }
}
