import 'dart:async';
import 'dart:convert';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/application/bloc/base_bloc.dart';
import '../../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../../core/application/bloc/screen_status.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/extensions/format_extensions.dart';
import '../../../../../core/misc/preferences/app_preferences.dart';
import '../../../../../core/services/api/models/app_error.dart';
import '../../../../../core/services/api/models/result.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/services/photo_picker_service.dart';
import '../../../../../shared/helpers/service_locator.dart';
import '../../../../../shared/presentation/errors/error_type.dart';
import '../../../../history/domain/scan_history_repository.dart';
import '../../../domain/models/bottle_box.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/reference_access.dart';
import '../../../domain/models/scan_failure.dart';
import '../../../domain/models/scan_result_args.dart';
import '../../../domain/models/tech_row.dart';
import '../../../domain/models/wine_card.dart';
import '../../../domain/scan_api_repository.dart';
import 'scan_result_state.dart';
import 'scan_result_uieffect.dart';

part 'scan_result_event.dart';

/// The answer for one photo: recognition, bottle selection, manual frames,
/// retries, sharing, and saving the automatic answer to the history.
class ScanResultBloc extends BaseBloc<ScanResultEvent, ScanResultState> {
  final ScanApiRepository _api = sl<ScanApiRepository>();
  final ScanHistoryRepository _history = sl<ScanHistoryRepository>();
  final PhotoPickerService _picker = sl<PhotoPickerService>();
  final AppPreferences _preferences = sl<AppPreferences>();

  CancelToken? _cancelToken;
  Timer? _retryTimer;

  ScanResultBloc() : super(ScanResultState.initial()) {
    on<StartScanResult>(_start);
    on<ReferenceAccessLoaded>(_referenceAccessLoaded);
    on<BackPressed>(_backPressed);
    on<RetryPressed>(_retryPressed, transformer: droppable());
    on<NewPhotoPressed>(_newPhotoPressed);
    on<NewPhotoSourceChosen>(_newPhotoSourceChosen, transformer: droppable());
    on<BottleSelected>(_bottleSelected);
    on<RescanBottlePressed>(_rescanBottle, transformer: droppable());
    on<RescanHintDismissed>(_rescanHintDismissed);
    on<DrawModeToggled>(_drawModeToggled);
    on<DraftChanged>(_draftChanged);
    on<DraftCleared>(_draftCleared);
    on<DraftEditToggled>(_draftEditToggled);
    on<DraftRecognizePressed>(_draftRecognize, transformer: droppable());
    on<BackToAllPressed>(_backToAll);
    on<CardLinkPressed>(_cardLinkPressed);
    on<CompareTapped>(_compareTapped);
    on<MorePressed>(_morePressed);
    on<MoreOptionChosen>(_moreOptionChosen);
    on<ClosePressed>(_closePressed);
    on<RetryTicked>(_retryTicked);
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel();
    _retryTimer?.cancel();
    return super.close();
  }

  Future<void> _start(
    StartScanResult event,
    Emitter<ScanResultState> emit,
  ) async {
    // The reference images need a session; the photo and the answer do not
    // wait for one (the interceptor asks for a session on its own).
    unawaited(_loadReferenceAccess());

    switch (event.args) {
      case NewScanArgs(:final photoPath):
        emit(
          state.copyWith(
            screenStatus: ScreenStatus.content,
            photoPath: photoPath,
            showRescanHint: !_preferences.isRescanHintShown,
          ),
        );
        await _recognize(emit, roi: null);
      case StoredScanArgs(:final scanId):
        final record = await _history.byId(scanId);
        if (emit.isDone) return;
        if (record == null) {
          emit(
            state.copyWith(
              screenStatus: ScreenStatus.error,
              errorType: ErrorType.server,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            screenStatus: ScreenStatus.content,
            photoPath: record.photoPath,
            isStored: true,
            historyId: record.id,
            showRescanHint: !_preferences.isRescanHintShown,
          ),
        );
        // A stored answer was seen once already: no tip the second time.
        _showAnswer(emit, record.view, roi: null, announce: false);
    }
  }

  void _referenceAccessLoaded(
    ReferenceAccessLoaded event,
    Emitter<ScanResultState> emit,
  ) {
    emit(state.copyWith(referenceAccess: event.access));
  }

  void _backPressed(BackPressed event, Emitter<ScanResultState> emit) {
    // The system back goes one level up, as the browser's does: from a
    // frame answer to all bottles, then off the screen.
    if (state.canGoBackToAll) {
      add(const BackToAllPressed());
    } else {
      emitUiEffect(CloseScreen());
    }
  }

  // ---------------------------------------------------------------- requests

  Future<void> _recognize(
    Emitter<ScanResultState> emit, {
    required BottleBox? roi,
  }) async {
    _retryTimer?.cancel();
    _cancelToken?.cancel();
    final token = _cancelToken = CancelToken();

    emit(
      state.copyWith(
        phase: ResultPhase.recognizing,
        isRoiRequest: roi != null,
        pendingRoi: roi,
        isDrawing: false,
        draft: null,
        isEditingDraft: false,
        failure: null,
      ),
    );

    final result = await _api.recognize(
      imagePath: state.photoPath,
      targetRoi: roi,
      cancelToken: token,
    );
    if (emit.isDone || token.isCancelled) return;
    _cancelToken = null;

    switch (result) {
      case Success<RecognitionView>(:final data):
        emit(state.copyWith(retryAttempt: 0));
        _showAnswer(emit, data, roi: roi);
        await _storeIfNew(emit, data, roi: roi);
      case Error<RecognitionView>(:final error):
        _handleFailure(emit, error);
    }
  }

  void _showAnswer(
    Emitter<ScanResultState> emit,
    RecognitionView view, {
    required BottleBox? roi,
    bool announce = true,
  }) {
    emit(
      state.copyWith(
        phase: ResultPhase.answer,
        view: view,
        overview: roi == null ? view : state.overview,
        selectedInstanceId: _initialSelection(view),
        pendingRoi: null,
        failure: null,
        techRows: _techRows(view, _initialSelection(view)),
      ),
    );
    if (announce) _announce(view);
  }

  Future<void> _storeIfNew(
    Emitter<ScanResultState> emit,
    RecognitionView view, {
    required BottleBox? roi,
  }) async {
    if (roi != null || state.isStored || state.historyId != null) return;
    final String photoPath = state.photoPath;
    try {
      final id = await _history.save(photoPath: photoPath, view: view);
      // The store moved the photo under its own name; the record is what the
      // history opens later, so the screen follows the new path.
      final record = await _history.byId(id);
      // A new photo may have replaced this one meanwhile: its scan is not
      // this record.
      if (emit.isDone || state.photoPath != photoPath) return;
      emit(
        state.copyWith(
          historyId: id,
          photoPath: record?.photoPath ?? state.photoPath,
        ),
      );
    } on Exception catch (e) {
      // A full disk or a missing file: the answer is still on screen, it
      // just will not be in the history.
      debugPrint('Could not store the scan: $e');
    }
  }

  void _handleFailure(Emitter<ScanResultState> emit, AppError error) {
    debugPrint(error.getErrorMessage());
    if (error is ApiError && error.isCancelled) return;

    // 429 and a busy 503 both say when to come back: wait and retry by
    // ourselves a few times instead of showing an error.
    if (error is ApiError && _shouldAutoRetry(error)) {
      final seconds =
          (error.retryAfter ?? ApiConstants.defaultRetryAfter).inSeconds;
      emit(
        state.copyWith(
          phase: ResultPhase.waitingRetry,
          retryAttempt: state.retryAttempt + 1,
          retrySecondsLeft: seconds < 1 ? 1 : seconds,
          retryReason: error.errorCode == 429
              ? RetryReason.tooMany
              : RetryReason.busy,
        ),
      );
      _retryTimer?.cancel();
      _retryTimer = Timer.periodic(
        DurationConstant.d1s,
        (_) => add(const RetryTicked()),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: ResultPhase.failed,
        failure: ScanFailure.fromError(error),
      ),
    );
  }

  bool _shouldAutoRetry(ApiError error) {
    if (state.retryAttempt >= ApiConstants.maxAutoRetries) return false;
    final code = error.errorCode;
    return code == 429 || (code == 503 && error.retryAfter != null);
  }

  Future<void> _retryTicked(
    RetryTicked event,
    Emitter<ScanResultState> emit,
  ) async {
    if (state.phase != ResultPhase.waitingRetry) {
      _retryTimer?.cancel();
      return;
    }
    final left = state.retrySecondsLeft - 1;
    if (left > 0) {
      emit(state.copyWith(retrySecondsLeft: left));
      return;
    }
    _retryTimer?.cancel();
    await _recognize(emit, roi: state.pendingRoi);
  }

  Future<void> _retryPressed(
    RetryPressed event,
    Emitter<ScanResultState> emit,
  ) async {
    emit(state.copyWith(retryAttempt: 0));
    await _recognize(emit, roi: state.pendingRoi);
  }

  // -------------------------------------------------------------- new photo

  void _newPhotoPressed(NewPhotoPressed event, Emitter<ScanResultState> emit) {
    emitUiEffect(OpenPhotoSourceSheet());
  }

  Future<void> _newPhotoSourceChosen(
    NewPhotoSourceChosen event,
    Emitter<ScanResultState> emit,
  ) async {
    final source = event.source;
    if (source == null) return;
    final PickedPhoto? photo;
    try {
      photo = await _picker.pick(source);
    } on PlatformException catch (e) {
      debugPrint('Photo picker failed: $e');
      emitSnackBar.error(lsl10n.scanErrorPhotoOpen);
      return;
    }
    if (emit.isDone || photo == null) return;

    _cancelToken?.cancel();
    _retryTimer?.cancel();
    // A new photo is a new scan: nothing of the previous answer applies.
    emit(
      ScanResultState.initial().copyWith(
        screenStatus: ScreenStatus.content,
        photoPath: photo.path,
        referenceAccess: state.referenceAccess,
        showRescanHint: state.showRescanHint,
      ),
    );
    await _recognize(emit, roi: null);
  }

  // -------------------------------------------------------------- selection

  void _bottleSelected(BottleSelected event, Emitter<ScanResultState> emit) {
    final view = state.view;
    if (view == null || state.isDrawing) return;
    // Tapping the selected bottle again returns to "all" when there are
    // several, as on the web.
    final String? next =
        event.instanceId == state.selectedInstanceId && view.bottles.length > 1
        ? null
        : event.instanceId;
    emit(
      state.copyWith(selectedInstanceId: next, techRows: _techRows(view, next)),
    );
  }

  Future<void> _rescanBottle(
    RescanBottlePressed event,
    Emitter<ScanResultState> emit,
  ) async {
    final roi = state.view?.bottleById(event.instanceId)?.selectRoi;
    if (roi == null) return;
    await _recognize(emit, roi: roi);
  }

  Future<void> _rescanHintDismissed(
    RescanHintDismissed event,
    Emitter<ScanResultState> emit,
  ) async {
    emit(state.copyWith(showRescanHint: false));
    await _preferences.setIsRescanHintShown(true);
  }

  void _backToAll(BackToAllPressed event, Emitter<ScanResultState> emit) {
    final overview = state.overview;
    if (overview == null) return;
    _cancelToken?.cancel();
    _retryTimer?.cancel();
    emit(
      state.copyWith(
        phase: ResultPhase.answer,
        view: overview,
        selectedInstanceId: null,
        pendingRoi: null,
        isRoiRequest: false,
        failure: null,
        isDrawing: false,
        draft: null,
        isEditingDraft: false,
        techRows: _techRows(overview, null),
      ),
    );
  }

  // ------------------------------------------------------------ manual frame

  void _drawModeToggled(DrawModeToggled event, Emitter<ScanResultState> emit) {
    emit(
      state.copyWith(
        isDrawing: !state.isDrawing,
        draft: null,
        isEditingDraft: false,
      ),
    );
  }

  void _draftChanged(DraftChanged event, Emitter<ScanResultState> emit) {
    emit(state.copyWith(draft: event.draft));
  }

  void _draftCleared(DraftCleared event, Emitter<ScanResultState> emit) {
    emit(state.copyWith(draft: null, isEditingDraft: false));
  }

  void _draftEditToggled(
    DraftEditToggled event,
    Emitter<ScanResultState> emit,
  ) {
    if (state.draft == null) return;
    emit(state.copyWith(isEditingDraft: !state.isEditingDraft));
  }

  Future<void> _draftRecognize(
    DraftRecognizePressed event,
    Emitter<ScanResultState> emit,
  ) async {
    final draft = state.draft;
    if (draft == null) return;
    final frame = state.frame;
    final roi = frame == null
        ? draft
        : draft.clampTo(frame[0].toDouble(), frame[1].toDouble());
    await _recognize(emit, roi: roi);
  }

  // ----------------------------------------------------------------- actions

  void _cardLinkPressed(CardLinkPressed event, Emitter<ScanResultState> emit) {
    emitUiEffect(OpenExternalUrl(url: event.url));
  }

  void _compareTapped(CompareTapped event, Emitter<ScanResultState> emit) {
    final view = state.view;
    final bottle = view?.bottleById(event.instanceId);
    if (view == null || bottle == null) return;
    emitUiEffect(
      OpenCompare(
        args: CompareArgs(
          photoPath: state.photoPath,
          crop: bottle.geometry ?? (view.isExplicitRoi ? view.roi : null),
          frame: view.frame,
          bottleNumber: bottle.number,
          cardTitle: event.card.title,
          referenceUrl: state.referenceAccess?.resolve(event.card.reference),
          referenceHeaders: state.referenceAccess?.headers ?? const {},
        ),
      ),
    );
  }

  void _morePressed(MorePressed event, Emitter<ScanResultState> emit) {
    final view = state.view;
    emitUiEffect(
      OpenMoreSheet(
        args: MoreSheetArgs(
          hasAnswer: view != null && state.phase == ResultPhase.answer,
          isRoi: view?.isExplicitRoi ?? false,
          bottleNumber: state.selectedBottle?.number,
        ),
      ),
    );
  }

  void _moreOptionChosen(
    MoreOptionChosen event,
    Emitter<ScanResultState> emit,
  ) {
    final view = state.view;
    if (view == null) return;
    switch (event.option) {
      case null:
        return;
      case ResultMoreOption.shareFull:
        emitUiEffect(
          ShareJson(
            json: _prettyJson(view.toJson()),
            fileName: _fileName('scan'),
          ),
        );
      case ResultMoreOption.shareBottle:
        final bottle = state.selectedBottle;
        if (bottle == null) return;
        final payload = {
          _JsonKeys.mode: view.mode.apiName,
          _JsonKeys.roi: view.roi?.toList(),
          _JsonKeys.frameSize: view.frameSize,
          _JsonKeys.image: view.image?.toJson(),
          _JsonKeys.bottle: bottle.toJson(),
        };
        emitUiEffect(
          ShareJson(
            json: _prettyJson(payload),
            fileName: _fileName(
              view.isExplicitRoi
                  ? 'scan-frame'
                  : 'scan-bottle-${bottle.number}',
            ),
          ),
        );
      case ResultMoreOption.techDetails:
        emitUiEffect(ShowTechDetails(rows: state.techRows));
    }
  }

  void _closePressed(ClosePressed event, Emitter<ScanResultState> emit) {
    emitUiEffect(CloseScreen());
  }

  // ----------------------------------------------------------------- helpers

  /// No session means the references will not load; the scan itself still
  /// can. The result arrives as an event, never as an `emit` after the
  /// handler that started it is gone.
  Future<void> _loadReferenceAccess() async {
    try {
      final access = await _api.referenceAccess();
      if (isClosed) return;
      add(ReferenceAccessLoaded(access: access));
    } on Exception catch (e) {
      debugPrint('Reference access unavailable: $e');
    }
  }

  String? _initialSelection(RecognitionView view) {
    if (view.bottles.length == 1) return view.bottles.first.instanceId;
    if (view.isExplicitRoi && view.primaryInstanceId != null) {
      return view.primaryInstanceId;
    }
    return null;
  }

  /// Once per answer, the same short tips the web shows under «Результат».
  void _announce(RecognitionView view) {
    final int n = view.bottles.length;
    if (view.isExplicitRoi) {
      emitSnackBar.info(
        n > 0 ? lsl10n.noticeRoiFound : lsl10n.noticeRoiEmpty,
        duration: SnackBarDuration.long,
      );
    } else if (n > 1) {
      emitSnackBar.info(
        lsl10n.noticeManyBottles(n),
        duration: SnackBarDuration.long,
      );
    }
  }

  List<TechRow> _techRows(RecognitionView view, String? selectedId) {
    final l10n = lsl10n;
    final bottle = view.bottleById(selectedId);
    final WineCard? card = bottle?.best ?? view.publishedCard;
    final String none = l10n.techNone;
    final image = view.image;

    String orNone(Object? value) =>
        value == null || value.toString().isEmpty ? none : value.toString();

    return [
      TechRow(label: l10n.techDecision, value: view.decision.apiName),
      TechRow(label: l10n.techPrimaryBasis, value: orNone(view.primaryBasis)),
      TechRow(label: l10n.techMode, value: view.mode.apiName),
      TechRow(label: l10n.techRawSlug, value: orNone(view.rawSlug)),
      TechRow(label: l10n.techBestCandidate, value: orNone(view.bestSlug)),
      TechRow(label: l10n.techCardSlug, value: orNone(card?.slug)),
      TechRow(label: l10n.techPageUrl, value: orNone(card?.pageUrl)),
      TechRow(label: l10n.techPageSource, value: orNone(card?.pageSource)),
      TechRow(
        label: l10n.techSnapshot,
        value: switch (card?.pageInSiteSnapshot) {
          true => l10n.techSnapshotYes,
          false => l10n.techSnapshotNo,
          null => none,
        },
      ),
      TechRow(
        label: l10n.techRoi,
        value: view.roi == null ? none : view.roi!.toList().join(', '),
      ),
      TechRow(label: l10n.techBottles, value: '${view.bottleCount}'),
      TechRow(label: l10n.techFrame, value: view.frame?.join(' × ') ?? none),
      TechRow(
        label: l10n.techFile,
        value: image?.format != null && image?.bytes != null
            ? l10n.techFileValue(image!.format!, image.bytes!)
            : none,
      ),
      TechRow(label: l10n.techProbability, value: l10n.techProbabilityValue),
      TechRow(
        label: l10n.techBackendTime,
        value: view.backendMs == null
            ? none
            : l10n.techSeconds(view.backendMs!.toSecondsText(l10n)),
      ),
      TechRow(label: l10n.techProfile, value: orNone(view.profileChecksum)),
      TechRow(
        label: l10n.techReasons,
        value: view.reasons.isEmpty ? none : view.reasons.join(', '),
      ),
    ];
  }

  String _prettyJson(Map<String, dynamic> data) =>
      const JsonEncoder.withIndent('  ').convert(data);

  String _fileName(String prefix) {
    final stamp = DateTime.now().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    return '$prefix-$stamp.json';
  }
}

class _JsonKeys {
  static const String mode = 'mode';
  static const String roi = 'roi';
  static const String frameSize = 'frame_size';
  static const String image = 'image';
  static const String bottle = 'bottle';
}
