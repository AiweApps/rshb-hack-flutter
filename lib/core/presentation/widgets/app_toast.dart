import 'package:flutter/material.dart';

import '../../application/bloc/base_bloc_uieffect.dart';
import '../../constants/app_colors_constants.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../widgets/navigation/nav_bar_height_provider.dart';
import '../app_icons.dart';

void Function({bool notifyDismissed})? _dismissCurrentUndoToast;

/// Dismisses the undo toast currently on screen, if any.
void dismissCurrentUndoToast({bool notifyDismissed = true}) {
  _dismissCurrentUndoToast?.call(notifyDismissed: notifyDismissed);
}

/// Shows the app toast for a [ShowSnackBar] ui-effect.
///
/// This is the single entry point for transient messages — do not use
/// `ScaffoldMessenger.showSnackBar` anywhere in the app.
void showAppToast(BuildContext context, ShowSnackBar effect) {
  // Use root navigator overlay so the toast renders above everything,
  // including the bottom nav bar of the shell route.
  final rootOverlay = Navigator.of(context, rootNavigator: true).overlay!;
  final appColors = Theme.of(context).extension<AppColors>()!;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AppToastEntry(
      message: effect.message,
      type: effect.type,
      duration: effect.duration.duration,
      bottomOffset: _resolveBottomOffset(context),
      appColors: appColors,
      onDismissed: () => entry.remove(),
    ),
  );

  rootOverlay.insert(entry);
}

/// Shows an info toast with a trailing action (typically "Undo").
///
/// Only one undo toast is on screen at a time — showing a new one dismisses
/// the previous one and notifies its `onDismissed`.
void showUndoToast({
  required BuildContext context,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  required VoidCallback onDismissed,
  required Duration duration,
}) {
  dismissCurrentUndoToast();

  final rootOverlay = Navigator.of(context, rootNavigator: true).overlay!;
  final appColors = Theme.of(context).extension<AppColors>()!;

  late OverlayEntry entry;
  var isRemoved = false;
  void removeEntry() {
    if (isRemoved) return;
    isRemoved = true;
    _dismissCurrentUndoToast = null;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _AppToastEntry(
      message: message,
      type: SnackBarType.info,
      duration: duration,
      bottomOffset: _resolveBottomOffset(context),
      appColors: appColors,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismissed: () {
        onDismissed();
        removeEntry();
      },
    ),
  );

  _dismissCurrentUndoToast = ({bool notifyDismissed = true}) {
    if (notifyDismissed) {
      onDismissed();
    }
    removeEntry();
  };

  rootOverlay.insert(entry);
}

/// Distance from the bottom of the screen to the toast's bottom edge.
///
/// If [NavBarHeightProvider] is in the tree the nav bar is visible on this
/// screen, so sit right above it; otherwise sit above the safe area.
double _resolveBottomOffset(BuildContext context) {
  final navBarHeight = NavBarHeightProvider.maybeOf(context);
  if (navBarHeight != null) return navBarHeight + AppPadding.p8;

  final safeAreaBottom = MediaQuery.viewPaddingOf(context).bottom;
  return safeAreaBottom + AppPadding.p12;
}

class _AppToastEntry extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final double bottomOffset;
  final AppColors appColors;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _AppToastEntry({
    required this.message,
    required this.type,
    required this.duration,
    required this.bottomOffset,
    required this.appColors,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AppToastEntry> createState() => _AppToastEntryState();
}

class _AppToastEntryState extends State<_AppToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final _contentKey = GlobalKey();
  double? _contentHeight;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DurationConstant.d300ms,
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() => _contentHeight = box.size.height);
      }
      _startAnimation();
    });
  }

  void _startAnimation() {
    _controller.forward().then((_) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          _dismiss();
        }
      });
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _controller.reverse().then((_) => widget.onDismissed());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor() => switch (widget.type) {
    SnackBarType.info => widget.appColors.toastInfo,
    SnackBarType.success => widget.appColors.toastSuccess,
    SnackBarType.error => widget.appColors.toastError,
  };

  SvgIconRes _icon() => switch (widget.type) {
    SnackBarType.info => SvgIconRes.toastInfo,
    SnackBarType.success => SvgIconRes.toastSuccess,
    SnackBarType.error => SvgIconRes.toastError,
  };

  Widget _buildContent(BuildContext context) {
    return Material(
      key: _contentKey,
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _backgroundColor(),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppPadding.p16,
                top: AppPadding.p16,
                bottom: AppPadding.p16,
              ),
              child: _icon().widget(width: AppSize.s30, height: AppSize.s30),
            ),
            const SizedBox(width: AppSize.s12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppPadding.p20),
                child: Text(
                  widget.message,
                  style: context.ts.paragraphSmall.copyWith(
                    color: widget.appColors.ink,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (widget.actionLabel != null && widget.onAction != null)
              Padding(
                padding: const EdgeInsets.only(
                  right: AppPadding.p16,
                  left: AppPadding.p8,
                ),
                child: GestureDetector(
                  onTap: () {
                    widget.onAction?.call();
                    _dismiss();
                  },
                  child: Text(
                    widget.actionLabel!,
                    style: context.ts.buttonSmall.copyWith(
                      color: widget.appColors.wine,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: AppSize.s16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Total slide distance so that the toast's top edge starts at the exact
    // bottom of the screen and ends at its natural resting position.
    //
    // Natural top-edge position from the screen bottom is
    // `bottomOffset + contentHeight`, and we want to start at 0, so the slide
    // distance is exactly that.
    //
    // While _contentHeight is unknown (first frame), use a large placeholder so
    // the widget stays completely off-screen — no visible flash.
    final keyboardOffset = MediaQuery.viewInsetsOf(context).bottom;
    final slideDistance =
        widget.bottomOffset + keyboardOffset + (_contentHeight ?? 1000.0);

    return Positioned(
      bottom: widget.bottomOffset + keyboardOffset,
      left: AppPadding.p16,
      right: AppPadding.p16,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Animation value 0 → fully translated off-screen below.
          // Animation value 1 → translateY == 0, final resting position.
          final translateY = (1.0 - _animation.value) * slideDistance;
          return Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          );
        },
        child: _buildContent(context),
      ),
    );
  }
}
