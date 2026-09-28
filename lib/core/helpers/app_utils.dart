import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Facts about the build read once at start-up: the version and the build
/// number from `pubspec.yaml`, as the platform reports them.
class AppUtils {
  static String? _appVersion;
  static String? _buildNumber;

  const AppUtils._();

  /// Null until [initialize] ran, or when the platform gave nothing.
  static String? get appVersion => _appVersion;
  static String? get buildNumber => _buildNumber;

  static Future<void> initialize() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    } on Exception catch (e) {
      // Only the settings footer depends on it; the app runs without.
      debugPrint('Package info unavailable: $e');
    }
  }
}
