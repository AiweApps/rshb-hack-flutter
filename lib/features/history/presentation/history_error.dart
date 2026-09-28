import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/errors/app_error_widget.dart';
import '../application/bloc/history_bloc.dart';
import '../application/bloc/history_state.dart';

class HistoryError extends StatelessWidget {
  final HistoryState state;

  const HistoryError({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() => context.read<HistoryBloc>().add(const RetryHistory());

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
