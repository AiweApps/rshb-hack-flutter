import 'package:flutter/widgets.dart';

/// Inherited widget that exposes the bottom navigation bar's total height
/// (from the screen's absolute bottom edge to the bar's top edge).
///
/// Provided by the shell route on screens where the nav bar is visible.
/// Absent on full-screen routes that don't show the nav bar — consumers should
/// fall back to the safe area inset.
class NavBarHeightProvider extends InheritedWidget {
  final double height;

  const NavBarHeightProvider({
    super.key,
    required this.height,
    required super.child,
  });

  /// Returns the nav bar height, or null if no nav bar is present in the tree.
  static double? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NavBarHeightProvider>()
        ?.height;
  }

  @override
  bool updateShouldNotify(NavBarHeightProvider old) => old.height != height;
}
