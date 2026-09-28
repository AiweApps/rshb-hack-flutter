import 'package:flutter/widgets.dart';

import '../../../core/services/api/models/app_error.dart';
import '../../../core/services/language_service.dart';

/// What went wrong — decides the copy shown in the error widgets.
enum ErrorType { connection, server }

/// The one mapping from a technical failure to what the user is told.
extension AppErrorType on AppError {
  ErrorType get asErrorType => switch (this) {
    ApiError(isConnectionIssue: true) => ErrorType.connection,
    _ => ErrorType.server,
  };
}

String errorBlockTitle(BuildContext context, ErrorType type) {
  final l10n = context.localization;
  return switch (type) {
    ErrorType.connection => l10n.errorConnectionTitle,
    ErrorType.server => l10n.errorServerTitle,
  };
}

String errorFullScreenTitle(BuildContext context, ErrorType type) {
  final l10n = context.localization;
  return switch (type) {
    ErrorType.connection => l10n.errorConnectionFullScreenTitle,
    ErrorType.server => l10n.errorServerTitle,
  };
}

String errorSubtitle(BuildContext context, ErrorType type) {
  final l10n = context.localization;
  return switch (type) {
    ErrorType.connection => l10n.errorConnectionSubtitle,
    ErrorType.server => l10n.errorServerSubtitle,
  };
}
