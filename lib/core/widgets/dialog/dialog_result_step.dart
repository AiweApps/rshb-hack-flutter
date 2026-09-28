import 'package:flutter/material.dart';

import '../../constants/app_style_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../presentation/app_icons.dart';

/// Shared layout behind `DialogSuccessStep` and `DialogErrorStep`:
/// icon, title, optional description, full-width action button.
class DialogResultStep extends StatelessWidget {
  final SvgIconRes icon;
  final String title;
  final String? description;
  final String buttonText;
  final VoidCallback onButtonTap;
  final bool hideButton;

  const DialogResultStep({
    super.key,
    required this.icon,
    required this.title,
    required this.buttonText,
    required this.onButtonTap,
    this.description,
    this.hideButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: icon.widget(width: AppSize.s60, height: AppSize.s60),
        ),
        const SizedBox(height: AppSpaces.s16),
        Text(title, textAlign: TextAlign.center, style: context.ts.h3),
        if (description != null) ...[
          const SizedBox(height: AppSpaces.s12),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: context.ts.paragraphSmall,
          ),
        ],
        if (!hideButton) ...[
          const SizedBox(height: AppSpaces.s24),
          ElevatedButton(onPressed: onButtonTap, child: Text(buttonText)),
        ],
      ],
    );
  }
}
