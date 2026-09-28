import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../presentation/app_icons.dart';

/// Standard modal sheet chrome: rounded top corners, optional title row with a
/// close button, a divider, and the content below.
///
/// Show it with `showModalBottomSheet(isScrollControlled: true, ...)`.
class BaseBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool showCloseButton;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const BaseBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showCloseButton = true,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || showCloseButton;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.neutrals300,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.r16),
          topRight: Radius.circular(AppRadius.r16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (hasHeader) _buildHeader(context),
          if (hasHeader)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
              child: Container(
                height: AppSize.s1,
                color: context.colors.neutrals900.withValues(alpha: 0.1),
              ),
            ),
          Expanded(
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppPadding.p16,
                    vertical: AppPadding.p24,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppPadding.p16),
      child: Row(
        children: [
          Expanded(
            child: title != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppPadding.p8),
                    child: Text(
                      title!,
                      style: context.ts.h2.copyWith(
                        color: context.colors.neutrals900,
                        fontSize: FontSize.s20,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (showCloseButton)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
    );
  }
}
