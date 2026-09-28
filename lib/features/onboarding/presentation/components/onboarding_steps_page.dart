import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/language_service.dart';

/// Page 2: the three steps, numbered in gold like the web's step numerals.
class OnboardingStepsPage extends StatelessWidget {
  const OnboardingStepsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final steps = [
      (l10n.onboardingStep1Title, l10n.onboardingStep1Body),
      (l10n.onboardingStep2Title, l10n.onboardingStep2Body),
      (l10n.onboardingStep3Title, l10n.onboardingStep3Body),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpaces.s40),
          Text(l10n.onboardingTitle2, style: context.ts.h1),
          const SizedBox(height: AppSpaces.s24),
          for (int i = 0; i < steps.length; i++) ...[
            _Step(number: i + 1, title: steps[i].$1, body: steps[i].$2),
            if (i < steps.length - 1) const SizedBox(height: AppSpaces.s20),
          ],
          const SizedBox(height: AppSpaces.s24),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String body;

  const _Step({required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSize.s40,
          child: Text(
            '$number',
            style: context.ts.h2.copyWith(color: context.colors.gold),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$title ', style: context.ts.paragraphBold),
                TextSpan(text: body, style: context.ts.paragraph),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
