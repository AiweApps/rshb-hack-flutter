import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/home/bloc/scan_home_bloc.dart';
import '../../application/home/bloc/scan_home_state.dart';
import '../../domain/models/camera_status.dart';
import 'components/camera_stage.dart';
import 'components/camera_unavailable_view.dart';
import 'scan_home_loading.dart';

class ScanHomeContent extends StatelessWidget {
  final ScanHomeState state;
  final ValueListenable<CameraController?> preview;

  const ScanHomeContent({
    super.key,
    required this.state,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScanHomeBloc>();

    return switch (state.cameraStatus) {
      CameraStatus.starting => const ScanHomeLoading(),
      CameraStatus.ready => CameraStage(
        preview: preview,
        isFlashOn: state.isFlashOn,
        isCapturing: state.isCapturing,
        isPicking: state.isPicking,
        onShutter: () => bloc.add(const ShutterPressed()),
        onGallery: () => bloc.add(const PickPhotoPressed()),
        onFlash: () => bloc.add(const FlashToggled()),
      ),
      CameraStatus.denied ||
      CameraStatus.permanentlyDenied ||
      CameraStatus.unavailable => CameraUnavailableView(
        status: state.cameraStatus,
        recent: state.recent,
        isPicking: state.isPicking,
        onAllow: () => bloc.add(const CameraPermissionRequested()),
        onOpenSettings: () => bloc.add(const OpenSettingsPressed()),
        onGallery: () => bloc.add(const PickPhotoPressed()),
        onRecentTap: (id) => bloc.add(RecentScanTapped(scanId: id)),
        onAllRecent: () => bloc.add(const AllScansPressed()),
      ),
    };
  }
}
