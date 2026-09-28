import 'package:flutter/widgets.dart';

import '../../../../../core/services/language_service.dart';
import '../../../domain/models/recognition_view.dart';

/// The verdict as the user reads it; `uncertain` (the normal "found" case)
/// and anything unrecognised have no label.
String? decisionLabel(BuildContext context, ScanDecision decision) {
  final l10n = context.localization;
  return switch (decision) {
    ScanDecision.unknown => l10n.decisionUnknown,
    ScanDecision.insufficientEvidence => l10n.decisionInsufficient,
    ScanDecision.ambiguousTarget => l10n.decisionAmbiguous,
    ScanDecision.noTarget => l10n.decisionNoTarget,
    ScanDecision.uncertain ||
    ScanDecision.matched ||
    ScanDecision.invalidImage ||
    ScanDecision.other => null,
  };
}
