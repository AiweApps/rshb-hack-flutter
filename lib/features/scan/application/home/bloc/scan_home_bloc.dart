import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/application/bloc/base_bloc.dart';
import '../../../../../core/application/bloc/screen_status.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/router/pages.dart';
import '../../../../../core/services/camera_service.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/services/photo_picker_service.dart';
import '../../../../../shared/domain/models/camera_availability.dart';
import '../../../../../shared/domain/service_availability.dart';
import '../../../../../shared/helpers/service_locator.dart';
import '../../../../history/domain/models/scan_record.dart';
import '../../../../history/domain/scan_history_repository.dart';
import '../../../domain/models/camera_status.dart';
import '../../../domain/scan_api_repository.dart';
import 'scan_home_state.dart';
import 'scan_home_uieffect.dart';

part 'scan_home_event.dart';

/// The scan tab: the viewfinder, the shutter, the gallery, the service
/// status, and — while the camera cannot run — the last scans.
///
/// The camera runs only while the tab is the screen and the app is in the
/// foreground; both are tracked here and the camera is started and stopped
/// as they change.
class ScanHomeBloc extends BaseBloc<ScanHomeEvent, ScanHomeState> {
  final ScanApiRepository _api = sl<ScanApiRepository>();
  final ScanHistoryRepository _history = sl<ScanHistoryRepository>();
  final PhotoPickerService _picker = sl<PhotoPickerService>();
  final CameraService _camera = sl<CameraService>();
  final AppRouter _router = sl<AppRouter>();

  Timer? _statusTimer;
  CancelToken? _statusToken;
  StreamSubscription<List<ScanHistoryItem>>? _recentSubscription;
  bool _appVisible = true;
  bool _routeVisible = true;
  bool _cameraStarting = false;

  ScanHomeBloc() : super(ScanHomeState.initial()) {
    on<StartScanHome>(_start);
    on<RefreshStatus>(_refreshStatus, transformer: restartable());
    on<ScanHomeVisibilityChanged>(_visibilityChanged);
    on<RouteChanged>(_routeChanged);
    on<CameraPermissionRequested>(
      _permissionRequested,
      transformer: droppable(),
    );
    on<OpenSettingsPressed>(_openSettings);
    on<ShutterPressed>(_shutter, transformer: droppable());
    on<FlashToggled>(_flashToggled, transformer: droppable());
    on<StatusTapped>(_statusTapped);
    on<PickPhotoPressed>(_pickPhoto, transformer: droppable());
    on<RecentScansChanged>(_recentChanged);
    on<RecentScanTapped>(_recentTapped);
    on<AllScansPressed>(_allScansPressed);
    _router.addLocationListener(_onLocation);
  }

  @override
  Future<void> close() async {
    _router.removeLocationListener(_onLocation);
    _statusTimer?.cancel();
    _statusToken?.cancel();
    await _recentSubscription?.cancel();
    await _camera.stop();
    return super.close();
  }

  Future<void> _start(StartScanHome event, Emitter<ScanHomeState> emit) async {
    emit(state.copyWith(screenStatus: ScreenStatus.content));
    _startPolling();
    await _recentSubscription?.cancel();
    _recentSubscription = _history
        .watchRecent(LimitConstants.maxRecentScansOnHome)
        .listen(
          (items) => add(RecentScansChanged(items: items)),
          onError: (Object e) => debugPrint('Recent scans stream: $e'),
        );
    _routeVisible = _router.currentLocation == Pages.scan.navigationPath;
    await _syncCamera(emit);
  }

  // ------------------------------------------------------------- visibility

  Future<void> _visibilityChanged(
    ScanHomeVisibilityChanged event,
    Emitter<ScanHomeState> emit,
  ) async {
    _appVisible = event.isVisible;
    if (event.isVisible) {
      _startPolling();
    } else {
      _statusTimer?.cancel();
      _statusToken?.cancel();
    }
    await _syncCamera(emit);
  }

  void _onLocation() {
    if (!isClosed) add(const RouteChanged());
  }

  Future<void> _routeChanged(
    RouteChanged event,
    Emitter<ScanHomeState> emit,
  ) async {
    _routeVisible = _router.currentLocation == Pages.scan.navigationPath;
    await _syncCamera(emit);
  }

  /// Starts or stops the camera to match where the user is. Only a running
  /// camera is stopped when the tab is left; a permission refusal stays on
  /// screen as its own state and is re-read silently (no system dialog)
  /// until the user asks again or comes back from the settings.
  Future<void> _syncCamera(Emitter<ScanHomeState> emit) async {
    final bool shouldRun = _appVisible && _routeVisible;
    if (!shouldRun) {
      if (_camera.isRunning) {
        await _camera.stop();
        if (emit.isDone) return;
        emit(
          state.copyWith(cameraStatus: CameraStatus.starting, isFlashOn: false),
        );
      }
      return;
    }
    if (_camera.isRunning || _cameraStarting) return;
    _cameraStarting = true;
    try {
      final availability = await _camera.start(
        mayPrompt: state.cameraStatus == CameraStatus.starting,
      );
      // Checked before `emit.isDone`: a bloc closed mid-start must still
      // switch off the camera it just got, else it stays on for good.
      if (isClosed || !(_appVisible && _routeVisible)) {
        await _camera.stop();
        return;
      }
      if (emit.isDone) return;
      emit(
        state.copyWith(
          cameraStatus: switch (availability) {
            CameraAvailability.ready => CameraStatus.ready,
            CameraAvailability.denied => CameraStatus.denied,
            CameraAvailability.permanentlyDenied =>
              CameraStatus.permanentlyDenied,
            CameraAvailability.unavailable => CameraStatus.unavailable,
          },
          isFlashOn: false,
        ),
      );
    } finally {
      _cameraStarting = false;
    }
  }

  Future<void> _permissionRequested(
    CameraPermissionRequested event,
    Emitter<ScanHomeState> emit,
  ) async {
    emit(state.copyWith(cameraStatus: CameraStatus.starting));
    await _syncCamera(emit);
  }

  void _openSettings(OpenSettingsPressed event, Emitter<ScanHomeState> emit) {
    emitUiEffect(OpenAppSettings());
  }

  // ---------------------------------------------------------------- camera

  Future<void> _shutter(
    ShutterPressed event,
    Emitter<ScanHomeState> emit,
  ) async {
    if (state.cameraStatus != CameraStatus.ready || state.isCapturing) return;
    emit(state.copyWith(isCapturing: true));
    try {
      final path = await _camera.takePicture();
      if (emit.isDone) return;
      if (path != null) emitUiEffect(OpenNewScan(photoPath: path));
    } on CameraException catch (e) {
      debugPrint('Capture failed: $e');
      if (emit.isDone) return;
      emitSnackBar.error(lsl10n.scanErrorPhotoOpen);
    } finally {
      if (!emit.isDone) emit(state.copyWith(isCapturing: false));
    }
  }

  Future<void> _flashToggled(
    FlashToggled event,
    Emitter<ScanHomeState> emit,
  ) async {
    if (state.cameraStatus != CameraStatus.ready) return;
    final bool on = !state.isFlashOn;
    try {
      await _camera.setFlash(on: on);
    } on CameraException catch (e) {
      // A device without a flash: the switch simply does not take.
      debugPrint('Flash unavailable: $e');
      return;
    }
    if (emit.isDone) return;
    emit(state.copyWith(isFlashOn: on));
  }

  // ---------------------------------------------------------------- status

  void _startPolling() {
    add(const RefreshStatus());
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      ApiConstants.statusRefreshInterval,
      (_) => add(const RefreshStatus()),
    );
  }

  Future<void> _refreshStatus(
    RefreshStatus event,
    Emitter<ScanHomeState> emit,
  ) async {
    _statusToken?.cancel();
    final token = _statusToken = CancelToken();
    final result = await _api.status(cancelToken: token);
    if (emit.isDone || token.isCancelled) return;
    emit(state.copyWith(serviceState: ServiceState.fromResult(result)));
  }

  void _statusTapped(StatusTapped event, Emitter<ScanHomeState> emit) {
    emitUiEffect(
      ShowStatusDetail(availability: state.serviceState.availability),
    );
    add(const RefreshStatus());
  }

  // --------------------------------------------------------------- gallery

  Future<void> _pickPhoto(
    PickPhotoPressed event,
    Emitter<ScanHomeState> emit,
  ) async {
    emit(state.copyWith(isPicking: true));
    try {
      final photo = await _picker.pick(PhotoSource.gallery);
      if (emit.isDone) return;
      if (photo != null) {
        emitUiEffect(OpenNewScan(photoPath: photo.path));
      }
    } on PlatformException catch (e) {
      debugPrint('Photo picker failed: $e');
      if (emit.isDone) return;
      emitSnackBar.error(lsl10n.scanErrorPhotoOpen);
    } finally {
      if (!emit.isDone) emit(state.copyWith(isPicking: false));
    }
  }

  // ---------------------------------------------------------------- recent

  void _recentChanged(RecentScansChanged event, Emitter<ScanHomeState> emit) {
    emit(state.copyWith(recent: event.items));
  }

  void _recentTapped(RecentScanTapped event, Emitter<ScanHomeState> emit) {
    emitUiEffect(OpenStoredScan(scanId: event.scanId));
  }

  void _allScansPressed(AllScansPressed event, Emitter<ScanHomeState> emit) {
    emitUiEffect(OpenHistory());
  }
}
