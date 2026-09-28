import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A kicker label over a card of rows separated by hairlines.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppPadding.p16,
            bottom: AppPadding.p8,
          ),
          child: Text(title.toUpperCase(), style: context.ts.kicker),
        ),
        Material(
          color: colors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            side: BorderSide(
              color: colors.rule,
              width: AppSize.dividerThickness,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    indent: AppPadding.p16,
                    endIndent: AppPadding.p16,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
