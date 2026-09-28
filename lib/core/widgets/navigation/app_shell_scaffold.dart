import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/language_service.dart';
import 'custom_bottom_navigation_bar.dart';
import 'nav_bar_height_provider.dart';

/// Chrome around the tab branches: the bottom bar and the nav-bar height
/// published to the tree, so toasts shown from tab screens sit above the bar.
/// The router only knows that this shell exists.
class AppShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Scaffold(
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
          AppTabItem(
            icon: Icons.photo_camera_outlined,
            selectedIcon: Icons.photo_camera,
            label: l10n.tabScan,
          ),
          AppTabItem(
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            label: l10n.tabHistory,
          ),
          AppTabItem(
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
