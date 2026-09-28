import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/helpers/app_haptics.dart';
import '../../../../../core/presentation/app_icons.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/scan_failure.dart';

/// The failed request, with retry and «Новый скан».
class ResultErrorPanel extends StatelessWidget {
  final ScanFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onNewScan;

  const ResultErrorPanel({
    super.key,
    required this.failure,
    required this.onRetry,
    required this.onNewScan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPadding.p16,
        AppPadding.p12,
        AppPadding.p16,
        AppPadding.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcon.error.data, color: context.colors.bad),
              const SizedBox(width: AppSpaces.s10),
              Expanded(
                child: Text(
                  _title(l10n, failure),
                  style: context.ts.h4.copyWith(color: context.colors.bad),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpaces.s8),
          Text(_text(l10n, failure), style: context.ts.paragraph),
          const SizedBox(height: AppSpaces.s16),
          Row(
            children: [
              if (failure.retryable) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AppHaptics.tap();
                      onRetry();
                    },
                    child: Text(l10n.scanErrorRetry),
                  ),
                ),
                const SizedBox(width: AppSpaces.s10),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.tap();
                    onNewScan();
                  },
                  child: Text(l10n.resultNewScan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _title(AppLocalizations l10n, ScanFailure f) =>
      switch (f.kind) {
        ScanFailureKind.noAccess => l10n.scanErrorNoAccess,
        ScanFailureKind.tooLarge => l10n.scanErrorTooLarge,
        ScanFailureKind.format => l10n.scanErrorFormat,
        ScanFailureKind.unprocessed ||
        ScanFailureKind.badRoi => l10n.scanErrorUnprocessed,
        ScanFailureKind.tooMany => l10n.scanErrorTooMany,
        ScanFailureKind.service => l10n.scanErrorService,
        ScanFailureKind.busy => l10n.scanErrorBusy,
        ScanFailureKind.timeout => l10n.scanErrorTimeout,
        ScanFailureKind.noResponse ||
        ScanFailureKind.offline => l10n.scanErrorNoResponse,
        ScanFailureKind.photoOpen => l10n.scanErrorPhotoOpen,
        ScanFailureKind.other =>
          f.statusCode == null
              ? l10n.scanErrorTitleDefault
              : l10n.scanErrorCode(f.statusCode!),
      };

  static String _text(AppLocalizations l10n, ScanFailure f) => switch (f.kind) {
    ScanFailureKind.noAccess => l10n.scanErrorTextNoAccess,
    ScanFailureKind.tooLarge => l10n.scanErrorTextTooLarge,
    ScanFailureKind.format => l10n.scanErrorTextFormat,
    ScanFailureKind.unprocessed => l10n.scanErrorTextUnprocessed,
    ScanFailureKind.badRoi => l10n.scanErrorTextBadRoi,
    ScanFailureKind.tooMany => l10n.scanErrorTextTooMany,
    ScanFailureKind.service => l10n.scanErrorTextService,
    ScanFailureKind.busy => l10n.scanErrorTextBusy,
    ScanFailureKind.timeout => l10n.scanErrorTextTimeout,
    ScanFailureKind.offline => l10n.scanErrorTextOffline,
    ScanFailureKind.noResponse => l10n.scanErrorTextOffline,
    ScanFailureKind.photoOpen => l10n.scanErrorTextPhotoOpen,
    ScanFailureKind.other => l10n.scanErrorTextDefault,
  };
}
