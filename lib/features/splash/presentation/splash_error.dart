import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/errors/app_error_widget.dart';
import '../application/bloc/splash_bloc.dart';

/// The splash reads only local preferences, so this is not expected to show;
/// it exists so the status switch stays exhaustive and a retry is possible.
class SplashError extends StatelessWidget {
  const SplashError({super.key});

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget.serverError(
      display: ErrorDisplay.fullScreen,
      onRefresh: () => context.read<SplashBloc>().add(const SplashStart()),
    );
  }
}
