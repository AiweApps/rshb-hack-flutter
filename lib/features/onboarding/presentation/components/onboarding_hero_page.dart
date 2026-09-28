import 'package:flutter/material.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/presentation/bottle_art.dart';

/// Page 1: the bottle illustration and what the scanner is for.
class OnboardingHeroPage extends StatelessWidget {
  const OnboardingHeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpaces.s24),
          const Center(child: BottleArt(height: AppSize.s240)),
          const SizedBox(height: AppSpaces.s32),
          Text(
            l10n.onboardingKicker,
            style: context.ts.kicker.copyWith(color: context.colors.gold),
          ),
          const SizedBox(height: AppSpaces.s8),
          Text(l10n.onboardingTitle1, style: context.ts.h1),
          const SizedBox(height: AppSpaces.s16),
          Text(l10n.onboardingBody1, style: context.ts.paragraph),
          const SizedBox(height: AppSpaces.s24),
        ],
      ),
    );
  }
}
