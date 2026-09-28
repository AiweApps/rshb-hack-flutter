import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/errors/app_error_widget.dart';
import '../../application/result/bloc/scan_result_bloc.dart';
import '../../application/result/bloc/scan_result_state.dart';

/// A stored scan that no longer exists; the only way out is back.
class ScanResultError extends StatelessWidget {
  final ScanResultState state;

  const ScanResultError({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    void onRefresh() =>
        context.read<ScanResultBloc>().add(const ClosePressed());

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
