import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/api/models/app_error.dart';

part 'scan_failure.freezed.dart';

/// Why a recognition request produced no answer, as the user is told about
/// it. The kinds follow the web UI's table of titles by HTTP status.
enum ScanFailureKind {
  noAccess,
  tooLarge,
  format,
  unprocessed,
  badRoi,
  tooMany,
  service,
  busy,
  timeout,
  noResponse,
  offline,
  photoOpen,
  other,
}

@freezed
abstract class ScanFailure with _$ScanFailure {
  static const String _badRoiKey = 'bad_roi';

  const factory ScanFailure({
    required ScanFailureKind kind,
    required int? statusCode,

    /// Whether "retry" makes sense: a rejected file or frame will be
    /// rejected again, a busy service will not.
    required bool retryable,
  }) = _ScanFailure;

  /// The same classification the web UI does in `recognize()`.
  factory ScanFailure.fromError(AppError error) {
    if (error is! ApiError) {
      return const ScanFailure(
        kind: ScanFailureKind.photoOpen,
        statusCode: null,
        retryable: false,
      );
    }
    if (error.isTimeout) {
      return const ScanFailure(
        kind: ScanFailureKind.timeout,
        statusCode: null,
        retryable: true,
      );
    }
    if (error.isConnectionIssue) {
      return const ScanFailure(
        kind: ScanFailureKind.offline,
        statusCode: null,
        retryable: true,
      );
    }
    final code = error.errorCode;
    if (code == null) {
      return const ScanFailure(
        kind: ScanFailureKind.noResponse,
        statusCode: null,
        retryable: true,
      );
    }
    final bool badRoi = error.errorKey == _badRoiKey;
    final kind = badRoi
        ? ScanFailureKind.badRoi
        : switch (code) {
            401 => ScanFailureKind.noAccess,
            413 => ScanFailureKind.tooLarge,
            415 => ScanFailureKind.format,
            422 => ScanFailureKind.unprocessed,
            429 => ScanFailureKind.tooMany,
            502 => ScanFailureKind.service,
            503 => ScanFailureKind.busy,
            504 => ScanFailureKind.timeout,
            _ => ScanFailureKind.other,
          };
    final bool retryable = !badRoi && code != 401 && code != 413 && code != 415;
    return ScanFailure(kind: kind, statusCode: code, retryable: retryable);
  }
}
