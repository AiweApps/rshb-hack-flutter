import 'package:flutter/widgets.dart';

import '../../../core/services/language_service.dart';

/// What went wrong — decides the copy shown in the error widgets.
enum ErrorType { connection, server }

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
