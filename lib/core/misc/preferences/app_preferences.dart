import 'package:shared_preferences/shared_preferences.dart';

const String _keyIsFirstLaunch = "is_first_launch";

/// Thin typed wrapper over [SharedPreferences].
///
/// Resolve it through the service locator: `sl<AppPreferences>()`.
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get isFirstLaunch => _prefs.getBool(_keyIsFirstLaunch) ?? true;

  Future<void> setIsFirstLaunch(bool value) async {
    await _prefs.setBool(_keyIsFirstLaunch, value);
  }

  // Generic key/value helpers
  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
