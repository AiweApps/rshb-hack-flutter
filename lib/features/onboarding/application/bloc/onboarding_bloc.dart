import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/misc/preferences/app_preferences.dart';
import '../../../../shared/helpers/service_locator.dart';
import 'onboarding_state.dart';
import 'onboarding_uieffect.dart';

part 'onboarding_event.dart';

/// Three intro pages; finishing (or skipping) marks the intro as seen and
/// opens the scanner.
class OnboardingBloc extends BaseBloc<OnboardingEvent, OnboardingState> {
  final AppPreferences _preferences = sl<AppPreferences>();

  OnboardingBloc() : super(OnboardingState.initial()) {
    on<StartOnboarding>(_start);
    on<OnboardingPageChanged>(_pageChanged);
    on<OnboardingNextPressed>(_nextPressed, transformer: droppable());
    on<OnboardingSkipPressed>(_skipPressed, transformer: droppable());
  }

  void _start(StartOnboarding event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(screenStatus: ScreenStatus.content, pageIndex: 0));
  }

  void _pageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(pageIndex: event.pageIndex));
  }

  Future<void> _nextPressed(
    OnboardingNextPressed event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.isLastPage) {
      await _finish();
      return;
    }
    emitUiEffect(ScrollToPage(pageIndex: state.pageIndex + 1));
  }

  Future<void> _skipPressed(
    OnboardingSkipPressed event,
    Emitter<OnboardingState> emit,
  ) async {
    await _finish();
  }

  Future<void> _finish() async {
    await _preferences.setIsOnboardingDone(true);
    emitUiEffect(OpenScan());
  }
}
