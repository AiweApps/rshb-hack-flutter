import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/helpers/app_haptics.dart';
import '../../../core/services/language_service.dart';
import '../application/bloc/onboarding_bloc.dart';
import '../application/bloc/onboarding_state.dart';
import 'components/onboarding_dots.dart';
import 'components/onboarding_gets_page.dart';
import 'components/onboarding_hero_page.dart';
import 'components/onboarding_steps_page.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingState state;
  final PageController pageController;

  const OnboardingContent({
    super.key,
    required this.state,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final bloc = context.read<OnboardingBloc>();

    return Column(
      children: [
        // The last page has nothing left to skip; the row keeps its height
        // so the pager does not jump.
        SizedBox(
          height: AppSize.minTapTarget + AppPadding.p8,
          child: state.isLastPage
              ? null
              : Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.p8,
                      vertical: AppPadding.p4,
                    ),
                    child: TextButton(
                      onPressed: () {
                        AppHaptics.tap();
                        bloc.add(const OnboardingSkipPressed());
                      },
                      child: Text(l10n.onboardingSkip),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: (index) {
              AppHaptics.select();
              bloc.add(OnboardingPageChanged(pageIndex: index));
            },
            children: const [
              OnboardingHeroPage(),
              OnboardingStepsPage(),
              OnboardingGetsPage(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.p24,
            AppPadding.p16,
            AppPadding.p24,
            AppPadding.p16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingDots(count: state.pageCount, current: state.pageIndex),
              const SizedBox(height: AppSpaces.s20),
              ElevatedButton(
                onPressed: () {
                  AppHaptics.tap();
                  bloc.add(const OnboardingNextPressed());
                },
                child: Text(
                  state.isLastPage ? l10n.onboardingStart : l10n.onboardingNext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
