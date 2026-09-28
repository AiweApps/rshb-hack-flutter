import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../../../shared/presentation/service_detail_sheet.dart';
import '../../application/home/bloc/scan_home_bloc.dart';
import '../../application/home/bloc/scan_home_state.dart';
import '../../application/home/bloc/scan_home_uieffect.dart';
import '../../domain/models/scan_result_args.dart';
import 'scan_home_content.dart';
import 'scan_home_error.dart';
import 'scan_home_loading.dart';

class ScanHomePage extends StatefulWidget {
  const ScanHomePage({super.key});

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

  // The status poll is only worth running while the app is on screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<ScanHomeBloc>().add(
      ScanHomeVisibilityChanged(isVisible: state == AppLifecycleState.resumed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BaseBlocPresentationListener<ScanHomeBloc>(
          listener: _onUiEffect,
          child: BlocBuilder<ScanHomeBloc, ScanHomeState>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const ScanHomeLoading(),
              ScreenStatus.content => ScanHomeContent(state: state),
              ScreenStatus.error => ScanHomeError(state: state),
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onUiEffect(BuildContext context, BaseBlocUiEffect effect) {
    switch (effect) {
      case ShowStatusDetail(:final availability):
        ServiceDetailSheet.show(context, availability);
      case OpenNewScan(:final photoPath):
        sl<AppRouter>().navigateToScanResult(NewScanArgs(photoPath: photoPath));
      case OpenStoredScan(:final scanId):
        sl<AppRouter>().navigateToScanResult(StoredScanArgs(scanId: scanId));
      case OpenHistory():
        sl<AppRouter>().navigateToHistory();
    }
  }
}
