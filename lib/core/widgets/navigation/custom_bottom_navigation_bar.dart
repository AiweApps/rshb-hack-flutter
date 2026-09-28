import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../helpers/app_haptics.dart';

/// One tab of the bottom bar.
class AppTabItem {
  final IconData icon;
  final String label;

  const AppTabItem({required this.icon, required this.label});
}

/// A floating glass bar: a translucent pill with the content blurred behind
/// it, inset from the edges, over whatever the tab draws underneath.
///
/// It measures itself and publishes the height through [heightNotifier], so
/// scroll views and toasts leave room for it.
class CustomBottomNavigationBar extends StatefulWidget {
  /// Measured height of the bar including its margins and the safe area.
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
  static const double _blur = AppSize.s24;

  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishHeight());
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = widget.navigationShell.currentIndex;
    final colors = context.colors;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishHeight());

    return Padding(
      key: _barKey,
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        AppPadding.p0,
        AppPadding.p16,
        // Sits just above the home indicator, like the system tab bar; on
        // devices without one it keeps a small gap from the edge.
        math.max(
          MediaQuery.viewPaddingOf(context).bottom - AppPadding.p8,
          AppPadding.p8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.rPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card.withAlpha(AppAlpha.a75),
              borderRadius: BorderRadius.circular(AppRadius.rPill),
              border: Border.all(color: colors.rule.withAlpha(AppAlpha.a50)),
            ),
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
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: AppSize.s24, color: color),
            const SizedBox(height: AppSpaces.s2),
            Text(
              item.label,
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
