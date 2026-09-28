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

abstract interface class AppFlavorService {
  AppFlavor get flavor;

  static Future<AppFlavorService> fromAssets({
    AppFlavor? overrideFlavor,
  }) async {
    throw UnimplementedError();
  }
}

class AssetsAppFlavorService implements AppFlavorService {
  final AppFlavor _flavor;

  AssetsAppFlavorService({required flavor}) : _flavor = flavor;

  @override
  AppFlavor get flavor => _flavor;

  static Future<AppFlavorService> fromAssets({
    AppFlavor? overrideFlavor,
  }) async {
    final resolved = overrideFlavor ?? _readCompileTimeFlavor();
    final path = _assetPathFor(resolved);

    final raw = await rootBundle.loadString(path);
    final map = json.decode(raw) as Map<String, dynamic>;

    // eventually flavor is getting from flavor json file
    final fileFlavor = (map[_FlavorKeys.jsonFlavor] ?? '')
        .toString()
        .toAppFlavor();
    return AssetsAppFlavorService(flavor: fileFlavor);
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
  static const String envFlavor = 'FLUTTER_APP_FLAVOR';
}
