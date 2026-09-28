import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/application/bloc/base_bloc.dart';
import '../../../../../core/application/bloc/screen_status.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/language_service.dart';
import '../../../../../core/services/photo_picker_service.dart';
import '../../../../../shared/domain/service_availability.dart';
import '../../../../../shared/helpers/service_locator.dart';
import '../../../../history/domain/models/scan_record.dart';
import '../../../../history/domain/scan_history_repository.dart';
import '../../../domain/scan_api_repository.dart';
import 'scan_home_state.dart';
import 'scan_home_uieffect.dart';

part 'scan_home_event.dart';

/// The scan tab: where a photo is taken or chosen, with the service status
/// and the last few scans at hand.
class ScanHomeBloc extends BaseBloc<ScanHomeEvent, ScanHomeState> {
  final ScanApiRepository _api = sl<ScanApiRepository>();
  final ScanHistoryRepository _history = sl<ScanHistoryRepository>();
  final PhotoPickerService _picker = sl<PhotoPickerService>();

  Timer? _statusTimer;
  CancelToken? _statusToken;
  StreamSubscription<List<ScanHistoryItem>>? _recentSubscription;

  ScanHomeBloc() : super(ScanHomeState.initial()) {
    on<StartScanHome>(_start);
    on<RefreshStatus>(_refreshStatus, transformer: restartable());
    on<StatusTapped>(_statusTapped);
    on<ScanHomeVisibilityChanged>(_visibilityChanged);
    on<TakePhotoPressed>(_takePhoto, transformer: droppable());
    on<PickPhotoPressed>(_pickPhoto, transformer: droppable());
    on<RecentScansChanged>(_recentChanged);
    on<RecentScanTapped>(_recentTapped);
    on<AllScansPressed>(_allScansPressed);
  }

  @override
  Future<void> close() {
    _statusTimer?.cancel();
    _statusToken?.cancel();
    _recentSubscription?.cancel();
    return super.close();
  }

  void _start(StartScanHome event, Emitter<ScanHomeState> emit) {
    emit(state.copyWith(screenStatus: ScreenStatus.content));
    _startPolling();
    _recentSubscription?.cancel();
    _recentSubscription = _history
        .watchRecent(LimitConstants.maxRecentScansOnHome)
        .listen(
          (items) => add(RecentScansChanged(items: items)),
          onError: (Object e) => debugPrint('Recent scans stream: $e'),
        );
  }

  void _visibilityChanged(
    ScanHomeVisibilityChanged event,
    Emitter<ScanHomeState> emit,
  ) {
    if (event.isVisible) {
      _startPolling();
    } else {
      _statusTimer?.cancel();
      _statusToken?.cancel();
    }
  }

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

  Future<void> _takePhoto(
    TakePhotoPressed event,
    Emitter<ScanHomeState> emit,
  ) => _pick(PhotoSource.camera, emit);

  Future<void> _pickPhoto(
    PickPhotoPressed event,
    Emitter<ScanHomeState> emit,
  ) => _pick(PhotoSource.gallery, emit);

  Future<void> _pick(PhotoSource source, Emitter<ScanHomeState> emit) async {
    emit(state.copyWith(isPicking: true));
    try {
      final photo = await _picker.pick(source);
      if (emit.isDone) return;
      if (photo != null) {
        emitUiEffect(OpenNewScan(photoPath: photo.path));
      }
    } on PlatformException catch (e) {
      // Permission refused or the camera is unavailable on this device.
      debugPrint('Photo picker failed: $e');
      if (emit.isDone) return;
      emitSnackBar.error(lsl10n.scanErrorPhotoOpen);
    } finally {
      if (!emit.isDone) emit(state.copyWith(isPicking: false));
    }
  }

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
