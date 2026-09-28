class Pages {
  static const String _splash = 'splash';
  static const String _onboarding = 'onboarding';
  static const String _scan = 'scan';
  static const String _scanResult = 'result';
  static const String _history = 'history';
  static const String _settings = 'settings';

  static PageInfo root = const PageInfo(path: '/', name: 'root');

  static PageInfo splash = PageInfo(
    path: _splash,
    name: _splash,
    navigationParent: root,
  );

  static PageInfo onboarding = PageInfo(
    path: _onboarding,
    name: _onboarding,
    navigationParent: root,
  );

  /// Tab 1: the scan screen.
  static PageInfo scan = PageInfo(
    path: _scan,
    name: _scan,
    navigationParent: root,
  );

  /// The answer for one photo, over the tabs. Opened with `ScanResultArgs`
  /// in `extra` and not reachable by link: the photo only exists on this
  /// device.
  static PageInfo scanResult = PageInfo(
    path: _scanResult,
    name: _scanResult,
    navigationParent: scan,
  );

  /// Tab 2.
  static PageInfo history = PageInfo(
    path: _history,
    name: _history,
    navigationParent: root,
  );

  /// Tab 3.
  static PageInfo settings = PageInfo(
    path: _settings,
    name: _settings,
    navigationParent: root,
  );

  /// Every declared page. Keep in sync when adding a [PageInfo] above —
  /// it backs the parent-route lookup used by `tryNavigateBack`.
  static List<PageInfo> get all => [
    splash,
    onboarding,
    scan,
    scanResult,
    history,
    settings,
  ];

  /// Navigation path of the parent of [navigationPath], or null when the
  /// location is unknown or its parent is the (non-navigable) root.
  static String? parentNavigationPathOf(String navigationPath) {
    for (final page in all) {
      if (page.navigationPath != navigationPath) continue;
      final parent = page.navigationParent;
      if (parent == null || parent == root) return null;
      return parent.navigationPath;
    }
    return null;
  }
}

class PageInfo {
  const PageInfo({
    required this.path,
    required this.name,
    this.navigationParent,
  });

  final String path;
  final String name;
  final PageInfo? navigationParent;

  String get navigationPath {
    if (navigationParent != null) {
      if (navigationParent!.navigationPath.endsWith('/')) {
        return '${navigationParent!.navigationPath}$path';
      } else {
        return '${navigationParent!.navigationPath}/$path';
      }
    } else {
      return path;
    }
  }
}
