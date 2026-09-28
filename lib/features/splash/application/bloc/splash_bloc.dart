import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/misc/preferences/app_preferences.dart';
import '../../../../shared/helpers/service_locator.dart';
import 'splash_state.dart';
import 'splash_uieffect.dart';

part 'splash_event.dart';

/// Shows the mark for a moment and sends the user to the intro or to the
/// scanner, depending on whether the intro was seen.
class SplashBloc extends BaseBloc<SplashEvent, SplashState> {
  final AppPreferences _preferences = sl<AppPreferences>();

  SplashBloc() : super(SplashState.initial()) {
    on<SplashStart>(_start);
  }

  Future<void> _start(SplashStart event, Emitter<SplashState> emit) async {
    emit(state.copyWith(screenStatus: ScreenStatus.content));
    await Future<void>.delayed(DurationConstant.d900ms);
    if (emit.isDone) return;
    if (_preferences.isOnboardingDone) {
      emitUiEffect(OpenScan());
    } else {
      emitUiEffect(OpenOnboarding());
    }
  }
}
