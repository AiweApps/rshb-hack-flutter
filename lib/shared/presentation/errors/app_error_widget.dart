import 'package:flutter/material.dart';

import 'error_display.dart';
import 'error_type.dart';
import 'widgets/error_block_general.dart';
import 'widgets/error_full_screen.dart';

export 'error_display.dart';
export 'error_type.dart';

/// Single entry point for error states.
///
/// ```dart
/// AppErrorWidget.connection(
///   display: ErrorDisplay.general,
///   onRefresh: () => bloc.add(const Retry()),
///   isLoading: state.status == ScreenStatus.loading,
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  final ErrorType _errorType;
  final ErrorDisplay display;
  final VoidCallback onRefresh;
  final bool isLoading;

  /// [ErrorDisplay.general] only — drop the card background.
  final bool isTransparent;

  /// [ErrorDisplay.general] only — drop the 16px side padding.
  final bool useHorizontalPadding;

  const AppErrorWidget.connection({
    super.key,
    required this.display,
    required this.onRefresh,
    this.isLoading = false,
    this.isTransparent = false,
    this.useHorizontalPadding = true,
  }) : _errorType = ErrorType.connection;

  const AppErrorWidget.serverError({
    super.key,
    required this.display,
    required this.onRefresh,
    this.isLoading = false,
    this.isTransparent = false,
    this.useHorizontalPadding = true,
  }) : _errorType = ErrorType.server;

  @override
  Widget build(BuildContext context) {
    return switch (display) {
      ErrorDisplay.fullScreen => ErrorFullScreen(
        errorType: _errorType,
        onRefresh: onRefresh,
        isLoading: isLoading,
      ),
      ErrorDisplay.general => ErrorBlockGeneral(
        errorType: _errorType,
        onRefresh: onRefresh,
        isLoading: isLoading,
        isTransparent: isTransparent,
        useHorizontalPadding: useHorizontalPadding,
      ),
    };
  }
}
