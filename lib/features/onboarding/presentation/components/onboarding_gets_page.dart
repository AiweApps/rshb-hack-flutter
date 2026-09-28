import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/language_service.dart';

/// Page 3: what the answer contains.
class OnboardingGetsPage extends StatelessWidget {
  const OnboardingGetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final items = [
      l10n.onboardingGets1,
      l10n.onboardingGets2,
      l10n.onboardingGets3,
      l10n.onboardingGets4,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpaces.s40),
          Text(l10n.onboardingTitle3, style: context.ts.h1),
          const SizedBox(height: AppSpaces.s24),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.p16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppPadding.p6),
                    child: Container(
                      width: AppSize.s12,
                      height: AppSize.s12,
                      decoration: BoxDecoration(
                        color: context.colors.wine,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpaces.s16),
                  Expanded(child: Text(item, style: context.ts.paragraph)),
                ],
              ),
            ),
          const SizedBox(height: AppSpaces.s8),
          Text(l10n.disclaimer, style: context.ts.paragraphTiny),
          const SizedBox(height: AppSpaces.s24),
        ],
      ),
    );
  }
}
