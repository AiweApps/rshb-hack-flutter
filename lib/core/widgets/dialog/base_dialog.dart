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
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.neutrals100,
            borderRadius: useBottomBorderRadius
                ? BorderRadius.circular(AppRadius.r24)
                : const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.r24),
                  ),
          ),
          child: title != null
              ? _buildTitledContent(context)
              : _buildPlainContent(context),
        ),
      ),
    );
  }

  Widget _buildPlainContent(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: childPadding?.left ?? AppPadding.p24,
            right: childPadding?.right ?? AppPadding.p24,
            top: childPadding?.top ?? AppPadding.p32,
            bottom:
                (childPadding?.bottom ?? AppPadding.p24) +
                MediaQuery.of(context).padding.bottom,
          ),
          child: child,
        ),
        if (showCloseButton)
          Positioned(
            top: closeButtonPosition?.top ?? AppSize.s12,
            right: closeButtonPosition?.right ?? AppSize.s12,
            child: GestureDetector(
              onTap: onClose,
              child: SvgIconRes.close24.widget(
                width: AppSize.s24,
                height: AppSize.s24,
                colorFilter: ColorFilter.mode(
                  context.colors.neutrals900,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitledContent(BuildContext context) {
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
                  title!,
                  style: context.ts.paragraphBold.copyWith(
                    fontSize: FontSize.s20,
                    color: context.colors.neutrals900,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              if (showCloseButton)
                GestureDetector(
                  onTap: onClose,
                  child: SvgIconRes.close24.widget(
                    width: AppSize.s24,
                    height: AppSize.s24,
                    colorFilter: ColorFilter.mode(
                      context.colors.neutrals900,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: EdgeInsets.only(
            left: childPadding?.left ?? AppPadding.p24,
            right: childPadding?.right ?? AppPadding.p24,
            bottom:
                (childPadding?.bottom ?? AppPadding.p24) +
                MediaQuery.of(context).padding.bottom,
          ),
          child: child,
        ),
      ],
    );
  }
}
