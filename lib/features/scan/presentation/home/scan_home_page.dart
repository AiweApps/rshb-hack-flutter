import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/constants/app_style_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/language_service.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../../../shared/presentation/service_detail_sheet.dart';
import '../../../../shared/presentation/service_status_pill.dart';
import '../../application/home/bloc/scan_home_bloc.dart';
import '../../application/home/bloc/scan_home_state.dart';
import '../../application/home/bloc/scan_home_uieffect.dart';
import '../../domain/models/camera_status.dart';
import '../../domain/models/scan_result_args.dart';
import 'scan_home_content.dart';
import 'scan_home_error.dart';
import 'scan_home_loading.dart';

class ScanHomePage extends StatefulWidget {
  /// The live camera from `CameraService`, handed in by the route so the
  /// preview widget can paint it without the bloc state carrying a handle.
  final ValueListenable<CameraController?> preview;

  const ScanHomePage({super.key, required this.preview});

  @override
  State<ScanHomePage> createState() => _ScanHomePageState();
}

class _ScanHomePageState extends State<ScanHomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // The camera and the status poll run only while the app is on screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ScanHomeBloc>().add(
      ScanHomeVisibilityChanged(isVisible: state == AppLifecycleState.resumed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBlocPresentationListener<ScanHomeBloc>(
      listener: _onUiEffect,
      child: BlocBuilder<ScanHomeBloc, ScanHomeState>(
        builder: (context, state) {
          final bool overCamera = state.cameraStatus == CameraStatus.ready;
          return Scaffold(
            // The viewfinder fills the screen; the bar floats over it.
            extendBodyBehindAppBar: overCamera,
            backgroundColor: overCamera
                ? context.colors.scrim
                : context.colors.paper,
            appBar: AppBar(
              backgroundColor: overCamera
                  ? Colors.transparent
                  : context.colors.paper,
              foregroundColor: overCamera
                  ? context.colors.onPhoto
                  : context.colors.ink,
              title: Text(
                context.localization.tabScan,
                style: context.ts.appBarTitle.copyWith(
                  color: overCamera
                      ? context.colors.onPhoto
                      : context.colors.ink,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppPadding.p12),
                  // Long statuses («service temporarily unavailable») get
                  // an ellipsis instead of pushing the title aside.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppSize.s160),
                    child: ServiceStatusPill(
                      state: state.serviceState,
                      onTap: () => context.read<ScanHomeBloc>().add(
                        const StatusTapped(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: switch (state.screenStatus) {
              ScreenStatus.loading => const ScanHomeLoading(),
              ScreenStatus.content => ScanHomeContent(
                state: state,
                preview: widget.preview,
              ),
              ScreenStatus.error => ScanHomeError(state: state),
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _onUiEffect(
    BuildContext context,
    BaseBlocUiEffect effect,
  ) async {
    switch (effect) {
      case ShowStatusDetail(:final availability):
        await ServiceDetailSheet.show(context, availability);
      case OpenNewScan(:final photoPath):
        sl<AppRouter>().navigateToScanResult(NewScanArgs(photoPath: photoPath));
      case OpenStoredScan(:final scanId):
        sl<AppRouter>().navigateToScanResult(StoredScanArgs(scanId: scanId));
      case OpenHistory():
        sl<AppRouter>().navigateToHistory();
      case OpenAppSettings():
        await openAppSettings();
    }
  }
}
