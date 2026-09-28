import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/domain/models/camera_availability.dart';

/// The back camera as one object: permission, the controller that feeds
/// the preview, the shutter and the flash.
///
/// The controller is created by [start] and destroyed by [stop]; the bloc
/// calls them as the scan tab comes and goes, because a running camera
/// costs battery and the platform stops it in the background anyway.
class CameraService {
  // The upload is downsized to `LimitConstants.uploadMaxSide` anyway; a
  // still from `veryHigh` is plenty and the live preview costs less.
  static const ResolutionPreset _preset = ResolutionPreset.veryHigh;
  static const String _accessDeniedCode = 'CameraAccessDenied';

  final ValueNotifier<CameraController?> _controller = ValueNotifier(null);

  /// The live controller for `CameraPreview`: set while [start] succeeded,
  /// null otherwise. A widget listens to it instead of the bloc state so no
  /// platform handle has to live in a freezed state.
  ValueListenable<CameraController?> get preview => _controller;

  bool get isRunning => _controller.value != null;

  /// [mayPrompt] false only re-reads the permission: after a refusal the
  /// system dialog must not pop up again on every return to the tab.
  Future<CameraAvailability> start({required bool mayPrompt}) async {
    if (isRunning) return CameraAvailability.ready;

    // Hardware first: a device without a camera (the simulator) must not
    // be told to grant a permission that changes nothing.
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      debugPrint('Cameras unavailable: $e');
      return CameraAvailability.unavailable;
    }
    if (cameras.isEmpty) return CameraAvailability.unavailable;

    final permission = await _ensurePermission(mayPrompt: mayPrompt);
    if (permission != CameraAvailability.ready) return permission;
    final CameraDescription camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      _preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
    } on CameraException catch (e) {
      debugPrint('Camera failed to start: $e');
      await controller.dispose();
      return e.code == _accessDeniedCode
          ? CameraAvailability.permanentlyDenied
          : CameraAvailability.unavailable;
    }
    _controller.value = controller;
    return CameraAvailability.ready;
  }

  Future<void> stop() async {
    final controller = _controller.value;
    _controller.value = null;
    await controller?.dispose();
  }

  /// Path of the JPEG the camera wrote, or null when it is not running.
  Future<String?> takePicture() async {
    final controller = _controller.value;
    if (controller == null || controller.value.isTakingPicture) return null;
    final file = await controller.takePicture();
    return file.path;
  }

  Future<void> setFlash({required bool on}) async {
    await _controller.value?.setFlashMode(on ? FlashMode.auto : FlashMode.off);
  }

  Future<CameraAvailability> _ensurePermission({
    required bool mayPrompt,
  }) async {
    PermissionStatus status = await Permission.camera.status;
    if (status.isDenied && mayPrompt) {
      status = await Permission.camera.request();
    }
    if (status.isGranted || status.isLimited) return CameraAvailability.ready;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAvailability.permanentlyDenied;
    }
    return CameraAvailability.denied;
  }
}
