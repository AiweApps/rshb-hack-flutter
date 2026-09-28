import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../presentation/app_icons.dart';

/// Standard modal sheet chrome: rounded top corners, a drag handle, an optional
/// title row with a close button, and the content below, sized to it.
///
/// Show it with `showModalBottomSheet(isScrollControlled: true, ...)`. The
/// content is wrapped so the sheet never sits under the home indicator or the
/// keyboard (adaptive.md §3).
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
    final bool hasHeader = title != null || showCloseButton;
    final double bottomInset =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.r24),
          topRight: Radius.circular(AppRadius.r24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DragHandle(),
            if (hasHeader) ...[
              _Header(title: title, showCloseButton: showCloseButton),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                child: Divider(),
              ),
            ],
            Flexible(
              child: Padding(
                padding:
                    padding ??
                    const EdgeInsets.symmetric(
                      horizontal: AppPadding.p16,
                      vertical: AppPadding.p16,
                    ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: AppPadding.p8),
        child: Container(
          width: AppSize.s36,
          height: AppSize.s4,
          decoration: BoxDecoration(
            color: context.colors.rule,
            borderRadius: BorderRadius.circular(AppRadius.rPill),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? title;
  final bool showCloseButton;

  const _Header({required this.title, required this.showCloseButton});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppPadding.p16,
        right: AppPadding.p8,
        top: AppPadding.p8,
        bottom: AppPadding.p4,
      ),
      child: Row(
        children: [
          Expanded(
            child: title != null
                ? Text(title!, style: context.ts.h3)
                : const SizedBox.shrink(),
          ),
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: SvgIconRes.close24.widget(
                width: AppSize.s24,
                height: AppSize.s24,
                colorFilter: ColorFilter.mode(
                  context.colors.ink,
                  BlendMode.srcIn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
