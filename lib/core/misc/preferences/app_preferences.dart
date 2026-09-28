import 'package:shared_preferences/shared_preferences.dart';

const String _keyIsOnboardingDone = 'is_onboarding_done';
const String _keyLanguageCode = 'selected_language';
const String _keyThemeModeIndex = 'selected_theme';
const String _keyRescanHintShown = 'hint_rescan_one_shown';

/// Thin typed wrapper over [SharedPreferences].
///
/// Resolve it through the service locator: `sl<AppPreferences>()`. Every
/// stored value is a named pair; the keys stay private to this file.
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get isOnboardingDone => _prefs.getBool(_keyIsOnboardingDone) ?? false;

  Future<void> setIsOnboardingDone(bool value) async {
    await _prefs.setBool(_keyIsOnboardingDone, value);
  }

  /// Saved UI language code, or null to follow the system.
  String? get languageCode => _prefs.getString(_keyLanguageCode);

  Future<void> setLanguageCode(String value) async {
    await _prefs.setString(_keyLanguageCode, value);
  }

  /// Index into `AppThemeMode.values`, or null for the default.
  int? get themeModeIndex => _prefs.getInt(_keyThemeModeIndex);

  Future<void> setThemeModeIndex(int value) async {
    await _prefs.setInt(_keyThemeModeIndex, value);
  }

  /// The "what does «Распознать» do" bubble opens by itself the first time
  /// only, as on the web.
  bool get isRescanHintShown => _prefs.getBool(_keyRescanHintShown) ?? false;

  Future<void> setIsRescanHintShown(bool value) async {
    await _prefs.setBool(_keyRescanHintShown, value);
  }
}
