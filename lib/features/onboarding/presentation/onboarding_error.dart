import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/errors/app_error_widget.dart';
import '../application/bloc/onboarding_bloc.dart';

/// The intro has nothing to load; kept so the status switch is exhaustive.
class OnboardingError extends StatelessWidget {
  const OnboardingError({super.key});

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget.serverError(
      display: ErrorDisplay.fullScreen,
      onRefresh: () =>
          context.read<OnboardingBloc>().add(const StartOnboarding()),
    );
  }
}
