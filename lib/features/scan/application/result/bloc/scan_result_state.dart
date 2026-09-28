import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../../core/application/bloc/screen_status.dart';
import '../../../../../shared/presentation/errors/error_type.dart';
import '../../../domain/models/bottle_box.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/reference_access.dart';
import '../../../domain/models/scan_failure.dart';
import '../../../domain/models/tech_row.dart';
import '../../../domain/models/wine_card.dart';

part 'scan_result_state.freezed.dart';

/// What the result panel shows for the current photo.
enum ResultPhase { recognizing, waitingRetry, failed, answer }

/// Why the app is waiting before retrying by itself.
enum RetryReason { busy, tooMany }

@freezed
abstract class ScanResultState with _$ScanResultState implements BaseBlocState {
  const factory ScanResultState({
    /// `loading` until the photo (or the stored scan) is at hand; `error`
    /// only when a stored scan no longer exists.
    required ScreenStatus screenStatus,
    required ErrorType? errorType,
    required String photoPath,

    /// Opened from the history: the answer is shown, not requested, and
    /// re-scans are not stored.
    required bool isStored,
    required ResultPhase phase,

    /// The request in flight (or the one that failed) was for a frame.
    required bool isRoiRequest,

    /// The answer on screen.
    required RecognitionView? view,

    /// The all-bottles answer kept while a frame answer is shown.
    required RecognitionView? overview,
    required String? selectedInstanceId,

    /// Frame of the request in flight or the one that failed.
    required BottleBox? pendingRoi,
    required int retryAttempt,
    required int retrySecondsLeft,
    required RetryReason retryReason,
    required ScanFailure? failure,
    required ReferenceAccess? referenceAccess,
    required int? historyId,

    /// The "what does «Распознать» do" bubble opens by itself once.
    required bool showRescanHint,
    required List<TechRow> techRows,
  }) = _ScanResultState;

  const ScanResultState._();

  factory ScanResultState.initial() => const ScanResultState(
    screenStatus: ScreenStatus.loading,
    errorType: null,
    photoPath: '',
    isStored: false,
    phase: ResultPhase.recognizing,
    isRoiRequest: false,
    view: null,
    overview: null,
    selectedInstanceId: null,
    pendingRoi: null,
    retryAttempt: 0,
    retrySecondsLeft: 0,
    retryReason: RetryReason.busy,
    failure: null,
    referenceAccess: null,
    historyId: null,
    showRescanHint: false,
    techRows: [],
  );

  RecognizedBottle? get selectedBottle => view?.bottleById(selectedInstanceId);

  /// The card the toolbar compares the selected bottle with.
  WineCard? get selectedCard => selectedBottle?.best;

  bool get hasAnswer => phase == ResultPhase.answer && view != null;

  /// Comparing needs a bottle with a match on screen.
  bool get canCompare => hasAnswer && selectedCard != null;

  /// A frame needs the photo's frame size, which the first answer brings,
  /// and no request in flight.
  bool get canDrawFrame =>
      frame != null &&
      phase != ResultPhase.recognizing &&
      phase != ResultPhase.waitingRetry;

  /// A frame answer is on screen and the all-bottles answer can be restored
  /// without a request.
  bool get canGoBackToAll =>
      overview != null && view != null && !identical(view, overview);

  /// The frame every box refers to, once an answer told us.
  List<int>? get frame => view?.frame;
}
