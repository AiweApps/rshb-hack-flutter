class Pages {
  static const String _splash = 'splash';
  static const String _home = 'home';
  static const String _trackDetails = 'trackDetails';
  static const String _settings = 'settings';

  static PageInfo root = const PageInfo(path: '/', name: 'root');

  static PageInfo splash = PageInfo(
    path: _splash,
    name: _splash,
    navigationParent: root,
  );

  static PageInfo home = PageInfo(
    path: _home,
    name: _home,
    navigationParent: root,
  );

  static PageInfo trackDetails = PageInfo(
    path: _trackDetails,
    name: _trackDetails,
    navigationParent: home,
  );

  static PageInfo settings = PageInfo(
    path: _settings,
    name: _settings,
    navigationParent: root,
  );

  /// Every declared page. Keep in sync when adding a [PageInfo] above —
  /// it backs the parent-route lookup used by `tryNavigateBack`.
  static List<PageInfo> get all => [splash, home, trackDetails, settings];

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
