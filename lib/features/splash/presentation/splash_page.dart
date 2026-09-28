import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/helpers/service_locator.dart';
import '../application/bloc/splash_bloc.dart';
import '../application/bloc/splash_state.dart';
import '../application/bloc/splash_uieffect.dart';
import 'splash_content.dart';
import 'splash_error.dart';
import 'splash_loading.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BaseBlocPresentationListener<SplashBloc>(
        listener: _onUiEffect,
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) => switch (state.screenStatus) {
            ScreenStatus.loading => const SplashLoading(),
            ScreenStatus.content => const SplashContent(),
            ScreenStatus.error => const SplashError(),
          },
        ),
      ),
    );
  }

  void _onUiEffect(BuildContext context, BaseBlocUiEffect effect) {
    switch (effect) {
      case OpenOnboarding():
        sl<AppRouter>().navigateToOnboarding();
      case OpenScan():
        sl<AppRouter>().navigateToScan();
    }
  }
}
