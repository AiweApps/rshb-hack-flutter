import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/app_icons.dart';
import '../../services/language_service.dart';
import 'custom_bottom_navigation_bar.dart';
import 'nav_bar_height_provider.dart';

/// Chrome around the tab branches: the floating bar over the content and
/// the bar's height published to the tree, so lists and toasts on the tabs
/// keep clear of it. The router only knows that this shell exists.
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Scaffold(
      // The bar floats over the tab: the tab paints under it.
      extendBody: true,
      body: ValueListenableBuilder<double>(
        valueListenable: CustomBottomNavigationBar.heightNotifier,
        builder: (context, navBarHeight, child) {
          return NavBarHeightProvider(height: navBarHeight, child: child!);
        },
        child: navigationShell,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        navigationShell: navigationShell,
        items: [
          AppTabItem(icon: AppIcon.camera.data, label: l10n.tabScan),
          AppTabItem(icon: AppIcon.history.data, label: l10n.tabHistory),
          AppTabItem(icon: AppIcon.settings.data, label: l10n.tabSettings),
        ],
      ),
    );
  }
}
