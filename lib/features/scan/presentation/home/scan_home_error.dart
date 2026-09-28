import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/errors/app_error_widget.dart';
import '../../application/home/bloc/scan_home_bloc.dart';
import '../../application/home/bloc/scan_home_state.dart';

/// The scan tab has no blocking load — the status failing is shown in the
/// pill — so this only exists for the exhaustive status switch.
class ScanHomeError extends StatelessWidget {
  final ScanHomeState state;

  const ScanHomeError({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() => context.read<ScanHomeBloc>().add(const StartScanHome());

    return switch (state.errorType) {
      ErrorType.connection => AppErrorWidget.connection(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
      _ => AppErrorWidget.serverError(
        display: ErrorDisplay.fullScreen,
        onRefresh: onRefresh,
      ),
    };
  }
}
