import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';

part 'splash_state.freezed.dart';

@freezed
abstract class SplashState with _$SplashState implements BaseBlocState {
  const factory SplashState({required ScreenStatus screenStatus}) =
      _SplashState;

  factory SplashState.initial() {
    return const SplashState(screenStatus: ScreenStatus.loading);
  }
}
