import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/helpers/service_locator.dart';
import '../application/bloc/onboarding_bloc.dart';
import '../application/bloc/onboarding_state.dart';
import '../application/bloc/onboarding_uieffect.dart';
import 'onboarding_content.dart';
import 'onboarding_error.dart';
import 'onboarding_loading.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // The pager position is widget state; which page is current lives in the
  // bloc and comes back as an event on every swipe.
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BaseBlocPresentationListener<OnboardingBloc>(
          listener: _onUiEffect,
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const OnboardingLoading(),
              ScreenStatus.content => OnboardingContent(
                state: state,
                pageController: _pageController,
              ),
              ScreenStatus.error => const OnboardingError(),
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onUiEffect(BuildContext context, BaseBlocUiEffect effect) {
    switch (effect) {
      case ScrollToPage(:final pageIndex):
        _pageController.animateToPage(
          pageIndex,
          duration: DurationConstant.d300ms,
          curve: Curves.easeOutCubic,
        );
      case OpenScan():
        sl<AppRouter>().navigateToScan();
    }
  }
}
