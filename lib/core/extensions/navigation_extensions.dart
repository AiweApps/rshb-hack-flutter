import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/pages.dart';

/// Route to fall back to when the current route has nothing to pop — derived
/// from the `navigationParent` declared in [Pages].
String? _parentRoute(BuildContext context) {
  try {
    final location = GoRouterState.of(context).uri.toString();
    return Pages.parentNavigationPathOf(location);
  } catch (_) {
    // No GoRouter above this context (e.g. inside a dialog built off the
    // root overlay) — there is nothing we can resolve.
    return null;
  }
}

/// Whether a back action would go anywhere — either popping the current route
/// or falling back to the declared parent route.
bool canNavigateBack(BuildContext context) {
  return context.canPop() || _parentRoute(context) != null;
}

/// Performs a back action, returning false if there was nowhere to go.
///
/// Prefer this over `context.pop()` for back buttons: deep links open a route
/// with an empty stack, where `pop` alone would do nothing.
bool tryNavigateBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return true;
  }

  final parentRoute = _parentRoute(context);
  if (parentRoute != null) {
    context.go(parentRoute);
    return true;
  }

  return false;
}
