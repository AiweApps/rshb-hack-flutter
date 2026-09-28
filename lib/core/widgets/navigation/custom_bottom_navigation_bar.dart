import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../helpers/app_haptics.dart';

/// One tab of the bottom bar.
class AppTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// The app's bottom bar: a hairline, then the tabs in the control face of the
/// design, the selected one in wine.
///
/// It measures itself and publishes the height through [heightNotifier], so
/// toasts drawn in the root overlay can sit above it.
class CustomBottomNavigationBar extends StatefulWidget {
  /// Measured height of the bar, including the bottom safe area.
  static final ValueNotifier<double> heightNotifier = ValueNotifier<double>(0);

  final StatefulNavigationShell navigationShell;
  final List<AppTabItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishHeight());
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishHeight());

    return DecoratedBox(
      key: _barKey,
      decoration: BoxDecoration(
        color: context.colors.card,
        border: Border(top: BorderSide(color: context.colors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSize.s64,
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++)
                Expanded(
                  child: _TabButton(
                    item: widget.items[i],
                    isSelected: i == currentIndex,
                    onTap: () => _onItemTapped(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _publishHeight() {
    if (!mounted) return;
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    CustomBottomNavigationBar.heightNotifier.value = box.size.height;
  }

  void _onItemTapped(int index) {
    AppHaptics.select();
    // Tapping the current tab again returns it to its root, as on iOS.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _TabButton extends StatelessWidget {
  final AppTabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? context.colors.wine : context.colors.muted;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: AppSize.s24,
              color: color,
            ),
            const SizedBox(height: AppSpaces.s4),
            Text(
              item.label.toUpperCase(),
              style: context.ts.tab.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
