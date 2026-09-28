import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:winescan/features/splash/application/bloc/splash_uieffect.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/constants/app_style_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/language_service.dart';
import '../../../shared/helpers/service_locator.dart';
import '../application/bloc/splash_bloc.dart';
import '../application/bloc/splash_state.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BaseBlocPresentationListener<SplashBloc>(
        listener: (BuildContext context, event) {
          if (event is SplashFinished) {
            sl<AppRouter>().navigateToHome();
          }
        },
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) {
            switch (state.screenStatus) {
              case ScreenStatus.loading:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.localization.splashApp),
                      const SizedBox(height: AppSize.s16),
                      const CircularProgressIndicator(),
                    ],
                  ),
                );
              case ScreenStatus.content:
              case ScreenStatus.error:
                return Center(child: Text(context.localization.splashApp));
            }
          },
        ),
      ),
    );
  }
}
