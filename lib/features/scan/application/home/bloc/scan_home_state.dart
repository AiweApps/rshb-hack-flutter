import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../../core/application/bloc/screen_status.dart';
import '../../../../../shared/domain/service_availability.dart';
import '../../../../../shared/presentation/errors/error_type.dart';
import '../../../../history/domain/models/scan_record.dart';
import '../../../domain/models/camera_status.dart';

part 'scan_home_state.freezed.dart';

@freezed
abstract class ScanHomeState with _$ScanHomeState implements BaseBlocState {
  const factory ScanHomeState({
    required ScreenStatus screenStatus,
    required ErrorType? errorType,

    /// The live preview itself is not here: `CameraService.preview` feeds
    /// the widget, this only says which view the tab shows.
    required CameraStatus cameraStatus,
    required bool isFlashOn,
    required bool isCapturing,
    required ServiceState serviceState,

    /// Shown while the camera is not available, so the tab is not empty.
    required List<ScanHistoryItem> recent,

    /// The system picker is open; the buttons are disabled meanwhile.
    required bool isPicking,
  }) = _ScanHomeState;

  factory ScanHomeState.initial() => const ScanHomeState(
    screenStatus: ScreenStatus.content,
    errorType: null,
    cameraStatus: CameraStatus.starting,
    isFlashOn: false,
    isCapturing: false,
    serviceState: ServiceState.checking,
    recent: [],
    isPicking: false,
  );
}
