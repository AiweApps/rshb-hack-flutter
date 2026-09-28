import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/services/language_service.dart';
import '../../../application/result/bloc/scan_result_state.dart';

/// «Читаем этикетку…» and the auto-retry countdown.
class ResultLoadingPanel extends StatelessWidget {
  final ScanResultState state;

  const ResultLoadingPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final bool waiting = state.phase == ResultPhase.waitingRetry;
    final String title = waiting
        ? switch (state.retryReason) {
            RetryReason.busy => l10n.loadingBusy,
            RetryReason.tooMany => l10n.loadingTooMany,
          }
        : (state.isRoiRequest ? l10n.loadingRoi : l10n.loadingReading);
    final String note = waiting
        ? l10n.loadingRetryIn(
            state.retrySecondsLeft,
            state.retryAttempt,
            ApiConstants.maxAutoRetries,
          )
        : l10n.loadingNote;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.p24,
        AppPadding.p16,
        AppPadding.p24,
        AppPadding.p8,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: AppSize.s28,
            height: AppSize.s28,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(width: AppSpaces.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.ts.h4),
                const SizedBox(height: AppSpaces.s4),
                Text(note, style: context.ts.paragraphSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
