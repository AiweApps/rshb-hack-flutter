import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../presentation/app_icons.dart';

class CustomChildPadding {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  const CustomChildPadding({this.left, this.right, this.top, this.bottom});
}

class CloseButtonPosition {
  final double? top;
  final double? right;

  const CloseButtonPosition({this.top, this.right});
}

/// Rounded dialog container that keeps clear of the keyboard and dismisses
/// focus on a background tap.
///
/// With a [title] it renders a title row + divider above the content; without
/// one the close button floats over the top-right corner.
class BaseDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final CustomChildPadding? childPadding;
  final CloseButtonPosition? closeButtonPosition;
  final bool showCloseButton;

  /// Round the bottom corners too. Leave false when the dialog is anchored to
  /// the bottom edge of the screen.
  final bool useBottomBorderRadius;

  const BaseDialog({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.childPadding,
    this.closeButtonPosition,
    this.showCloseButton = true,
    this.useBottomBorderRadius = false,
  }) : assert(
         !showCloseButton || onClose != null,
         'onClose must be provided when showCloseButton is true',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: useBottomBorderRadius
                ? BorderRadius.circular(AppRadius.r24)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.r24),
                  ),
          ),
          child: title != null
              ? _TitledContent(
                  title: title!,
                  showCloseButton: showCloseButton,
                  onClose: onClose,
                  childPadding: childPadding,
                  child: child,
                )
              : _PlainContent(
                  showCloseButton: showCloseButton,
                  onClose: onClose,
                  childPadding: childPadding,
                  closeButtonPosition: closeButtonPosition,
                  child: child,
                ),
        ),
      ),
    );
  }
}

class _PlainContent extends StatelessWidget {
  final Widget child;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final CustomChildPadding? childPadding;
  final CloseButtonPosition? closeButtonPosition;

  const _PlainContent({
    required this.child,
    required this.showCloseButton,
    required this.onClose,
    required this.childPadding,
    required this.closeButtonPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: childPadding?.left ?? AppPadding.p24,
            right: childPadding?.right ?? AppPadding.p24,
            top: childPadding?.top ?? AppPadding.p32,
            bottom:
                (childPadding?.bottom ?? AppPadding.p24) +
                MediaQuery.paddingOf(context).bottom,
          ),
          child: child,
        ),
        if (showCloseButton)
          Positioned(
            top: closeButtonPosition?.top ?? AppSize.s12,
            right: closeButtonPosition?.right ?? AppSize.s12,
            child: _CloseButton(onClose: onClose),
          ),
      ],
    );
  }
}

class _TitledContent extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final CustomChildPadding? childPadding;

  const _TitledContent({
    required this.title,
    required this.child,
    required this.showCloseButton,
    required this.onClose,
    required this.childPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppPadding.p20,
            right: AppPadding.p16,
            top: AppPadding.p16,
            bottom: AppPadding.p8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.ts.h3,
                  textAlign: TextAlign.left,
                ),
              ),
              if (showCloseButton) _CloseButton(onClose: onClose),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: EdgeInsets.only(
            left: childPadding?.left ?? AppPadding.p24,
            right: childPadding?.right ?? AppPadding.p24,
            top: childPadding?.top ?? AppPadding.p16,
            bottom:
                (childPadding?.bottom ?? AppPadding.p24) +
                MediaQuery.paddingOf(context).bottom,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback? onClose;

  const _CloseButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onClose,
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      icon: SvgIconRes.close24.widget(
        width: AppSize.s24,
        height: AppSize.s24,
        colorFilter: ColorFilter.mode(context.colors.ink, BlendMode.srcIn),
      ),
    );
  }
}
