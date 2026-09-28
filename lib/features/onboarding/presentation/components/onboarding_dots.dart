import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Page indicator: the current dot stretches into a short bar.
class OnboardingDots extends StatelessWidget {
  final int count;
  final int current;

  const OnboardingDots({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: DurationConstant.d200ms,
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpaces.s4),
            width: i == current ? AppSize.s24 : AppSize.s8,
            height: AppSize.s8,
            decoration: BoxDecoration(
              color: i == current ? context.colors.wine : context.colors.rule,
              borderRadius: BorderRadius.circular(AppRadius.rPill),
            ),
          ),
      ],
    );
  }
}
