import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState implements BaseBlocState {
  const factory OnboardingState({
    required ScreenStatus screenStatus,
    required int pageIndex,
    required int pageCount,
  }) = _OnboardingState;

  const OnboardingState._();

  factory OnboardingState.initial() => const OnboardingState(
    screenStatus: ScreenStatus.content,
    pageIndex: 0,
    pageCount: 3,
  );

  bool get isLastPage => pageIndex >= pageCount - 1;
}
