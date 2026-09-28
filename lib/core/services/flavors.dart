import 'dart:convert';

import 'package:flutter/services.dart';

enum AppFlavor { dev, prod }

extension _AppFlavorParsing on String {
  AppFlavor toAppFlavor() {
    switch (toLowerCase()) {
      case 'dev':
        return AppFlavor.dev;
      case 'prod':
        return AppFlavor.prod;
      default:
        return AppFlavor.dev;
    }
  }
}

/// Everything that differs between environments, read once at start-up from
/// `assets/flavors/<flavor>.json`. Code branches on the capabilities
/// ([analyticsEnabled], [logNetworkBodies]), not on [flavor] itself.
abstract interface class AppFlavorService {
  AppFlavor get flavor;

  /// Origin of the recognition API, without a trailing slash.
  String get apiBaseUrl;

  bool get analyticsEnabled;

  /// Whether the network log prints request and response bodies.
  bool get logNetworkBodies;
}

class AssetsAppFlavorService implements AppFlavorService {
  final AppFlavor _flavor;
  final String _apiBaseUrl;
  final bool _analyticsEnabled;
  final bool _logNetworkBodies;

  AssetsAppFlavorService({
    required AppFlavor flavor,
    required String apiBaseUrl,
    required bool analyticsEnabled,
    required bool logNetworkBodies,
  }) : _flavor = flavor,
       _apiBaseUrl = apiBaseUrl,
       _analyticsEnabled = analyticsEnabled,
       _logNetworkBodies = logNetworkBodies;

  @override
  AppFlavor get flavor => _flavor;

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  bool get analyticsEnabled => _analyticsEnabled;

  @override
  bool get logNetworkBodies => _logNetworkBodies;

  static Future<AppFlavorService> fromAssets({
    AppFlavor? overrideFlavor,
  }) async {
    final resolved = overrideFlavor ?? _readCompileTimeFlavor();
    final path = _assetPathFor(resolved);

    final raw = await rootBundle.loadString(path);
    final map = json.decode(raw) as Map<String, dynamic>;

    // The json decides: it is what the build actually bundled.
    final fileFlavor = _requireString(
      map,
      _FlavorKeys.jsonFlavor,
      path,
    ).toAppFlavor();
    return AssetsAppFlavorService(
      flavor: fileFlavor,
      apiBaseUrl: _requireString(map, _FlavorKeys.apiBaseUrl, path),
      analyticsEnabled: _requireBool(map, _FlavorKeys.analyticsEnabled, path),
      logNetworkBodies: _requireBool(map, _FlavorKeys.logNetworkBodies, path),
    );
  }

  // A missing key is a configuration error: fail at start-up with the name of
  // the key instead of returning a default that breaks the network later.
  static String _requireString(Map<String, dynamic> map, String key, String p) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    throw StateError('Flavor config $p: "$key" is missing or empty');
  }

  static bool _requireBool(Map<String, dynamic> map, String key, String p) {
    final value = map[key];
    if (value is bool) return value;
    throw StateError('Flavor config $p: "$key" is missing or not a bool');
  }

  static AppFlavor _readCompileTimeFlavor() {
    const f = String.fromEnvironment(
      _FlavorKeys.envFlavor,
      defaultValue: 'dev',
    );
    return f.toAppFlavor();
  }

  static String _assetPathFor(AppFlavor f) {
    switch (f) {
      case AppFlavor.dev:
        return 'assets/flavors/dev.json';
      case AppFlavor.prod:
        return 'assets/flavors/prod.json';
    }
  }
}

class _FlavorKeys {
  static const String jsonFlavor = 'FLAVOR';
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String analyticsEnabled = 'ANALYTICS_ENABLED';
  static const String logNetworkBodies = 'LOG_NETWORK_BODIES';
  static const String envFlavor = 'FLUTTER_APP_FLAVOR';
}
