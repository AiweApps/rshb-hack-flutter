import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:winescan/features/splash/application/bloc/splash_state.dart';
import 'package:winescan/features/splash/application/bloc/splash_uieffect.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/services/flavors.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/helpers/service_locator.dart';

part 'splash_event.dart';

class SplashBloc extends BaseBloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashState.initial()) {
    on<SplashStart>(_splashStart);
  }

  FutureOr<void> _splashStart(
    SplashStart event,
    Emitter<SplashState> emit,
  ) async {
    emit(state.copyWith(screenStatus: ScreenStatus.loading));
    final flavorProvider = sl<AppFlavorService>();
    const snackBarDuration = SnackBarDuration.medium;
    emitSnackBar.info(
      lsl10n.flavorMessage(
        flavorProvider.flavor.toString(),
        snackBarDuration.duration.toString(),
      ),
      duration: snackBarDuration,
    );
    await Future.delayed(snackBarDuration.duration);
    emit(state.copyWith(screenStatus: ScreenStatus.content));
    emitPresentation(SplashFinished());
  }
}
