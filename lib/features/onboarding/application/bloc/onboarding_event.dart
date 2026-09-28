part of 'onboarding_bloc.dart';

sealed class OnboardingEvent {
  const OnboardingEvent();
}

final class StartOnboarding extends OnboardingEvent {
  const StartOnboarding();
}

/// The user swiped to another page.
final class OnboardingPageChanged extends OnboardingEvent {
  final int pageIndex;

  const OnboardingPageChanged({required this.pageIndex});
}

final class OnboardingNextPressed extends OnboardingEvent {
  const OnboardingNextPressed();
}

final class OnboardingSkipPressed extends OnboardingEvent {
  const OnboardingSkipPressed();
}
