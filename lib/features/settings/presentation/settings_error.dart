import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/errors/app_error_widget.dart';
import '../application/bloc/settings_bloc.dart';
import '../application/bloc/settings_state.dart';

/// The tab has nothing that can fail on its own (a bad service status only
/// changes the pill); kept so the status switch stays exhaustive.
class SettingsError extends StatelessWidget {
  final SettingsState state;

  const SettingsError({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() => context.read<SettingsBloc>().add(const RetrySettings());

    return switch (state.errorType) {
      ErrorType.connection => AppErrorWidget.connection(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
      ErrorType.server || null => AppErrorWidget.serverError(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
    };
  }
}
