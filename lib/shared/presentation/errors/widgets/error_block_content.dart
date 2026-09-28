import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/presentation/app_icons.dart';
import '../error_type.dart';

/// Icon + title + subtitle, shared by every error presentation.
///
/// While [isLoading] the icon is replaced by a spinner, so a retry tap gives
/// immediate feedback without changing the layout.
class ErrorBlockContent extends StatelessWidget {
  final ErrorType errorType;
  final bool isLoading;
  final double horizontalPadding;
  final bool useFullScreenTitle;

  const ErrorBlockContent({
    super.key,
    required this.errorType,
    this.isLoading = false,
    this.horizontalPadding = AppPadding.p12,
    this.useFullScreenTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = useFullScreenTitle
        ? errorFullScreenTitle(context, errorType)
        : errorBlockTitle(context, errorType);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSize.s44,
            height: AppSize.s44,
            child: isLoading
                ? const CircularProgressIndicator()
                : SvgIconRes.errorReload.widget(
                    width: AppSize.s44,
                    height: AppSize.s44,
                    colorFilter: ColorFilter.mode(
                      context.colors.wine,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpaces.s20),
          Text(title, style: context.ts.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpaces.s12),
          Text(
            errorSubtitle(context, errorType),
            style: context.ts.paragraphSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
