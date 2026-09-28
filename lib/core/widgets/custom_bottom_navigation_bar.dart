import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

import '../extensions/context_extensions.dart';
import '../services/language_service.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  /// Measured height of the bar, published so that overlays (toasts) rendered
  /// in the root navigator can position themselves right above it.
  /// Consumed through `NavBarHeightProvider` in the shell route.
  static final ValueNotifier<double> heightNotifier = ValueNotifier<double>(0);

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

  void _publishHeight() {
    if (!mounted) return;
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    CustomBottomNavigationBar.heightNotifier.value = box.size.height;
  }

  void _onItemTapped(int index) {
    setState(() {
      TabSelectionState.selectedIndex.value = index;
    });
    widget.navigationShell.goBranch(
      index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TabSelectionState.selectedIndex,
      builder: (context, selectedIndex, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _publishHeight());
        return StylishBottomBar(
          key: _barKey,
          backgroundColor: context.colors.neutrals100,
          items: [
            _buildTabItemNew(
              index: 0,
              icon: Icons.home,
              text: context.localization.home,
              selectedIndex: selectedIndex,
            ),
            _buildTabItemNew(
              index: 1,
              icon: Icons.settings_sharp,
              text: context.localization.settings,
              selectedIndex: selectedIndex,
            ),
          ],
          option: BubbleBarOptions(
            barStyle: BubbleBarStyle.horizontal,
            bubbleFillStyle: BubbleFillStyle.fill,
            opacity: 0.2,
          ),
          currentIndex: selectedIndex,
          onTap: (value) {
            _onItemTapped(value);
          },
          notchStyle: NotchStyle.square,
        );
      },
    );
  }

  BottomBarItem _buildTabItemNew({
    required int index,
    required IconData icon,
    required String text,
    required int selectedIndex,
  }) {
    return BottomBarItem(
      icon: Icon(icon),
      title: Text(maxLines: 1, overflow: TextOverflow.ellipsis, text),
    );
  }
}

class TabSelectionState {
  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);
}
