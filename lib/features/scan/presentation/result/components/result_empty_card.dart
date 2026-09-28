import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';

/// A framed note where a card would be: no match, no bottle.
class ResultEmptyCard extends StatelessWidget {
  final String? title;
  final String text;

  const ResultEmptyCard({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: context.colors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: context.colors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: context.ts.h4),
            const SizedBox(height: AppSpaces.s6),
          ],
          Text(text, style: context.ts.paragraphSmall),
        ],
      ),
    );
  }
}
