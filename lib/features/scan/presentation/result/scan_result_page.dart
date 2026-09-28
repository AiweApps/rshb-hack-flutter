import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/helpers/app_haptics.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../../../shared/presentation/photo_source_sheet.dart';
import '../../application/result/bloc/scan_result_bloc.dart';
import '../../application/result/bloc/scan_result_state.dart';
import '../../application/result/bloc/scan_result_uieffect.dart';
import 'components/compare_viewer.dart';
import 'components/more_sheet.dart';
import 'components/tech_details_sheet.dart';
import 'scan_result_content.dart';
import 'scan_result_error.dart';
import 'scan_result_loading.dart';

class ScanResultPage extends StatelessWidget {
  static const String _jsonMimeType = 'application/json';

  const ScanResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Over a frame answer "back" means one answer level up and the bloc
    // handles it; otherwise the screen pops like any other, which also keeps
    // the iOS edge swipe, available only while `canPop` is true.
    return BlocSelector<ScanResultBloc, ScanResultState, bool>(
      selector: (state) => state.canGoBackToAll,
      builder: (context, canGoBackToAll) => PopScope(
        canPop: !canGoBackToAll,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            context.read<ScanResultBloc>().add(const BackPressed());
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.ink,
          body: BaseBlocPresentationListener<ScanResultBloc>(
            listener: _onUiEffect,
            child: BlocListener<ScanResultBloc, ScanResultState>(
              // A result landing or a request failing is felt, not only seen.
              listenWhen: (previous, current) =>
                  previous.phase != current.phase,
              listener: (context, state) => switch (state.phase) {
                ResultPhase.answer => AppHaptics.confirm(),
                ResultPhase.failed => AppHaptics.warn(),
                ResultPhase.recognizing || ResultPhase.waitingRetry => null,
              },
              child: BlocBuilder<ScanResultBloc, ScanResultState>(
                builder: (context, state) => switch (state.screenStatus) {
                  ScreenStatus.loading => const ScanResultLoading(),
                  ScreenStatus.content => ScanResultContent(state: state),
                  ScreenStatus.error => ScanResultError(state: state),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onUiEffect(
    BuildContext context,
    BaseBlocUiEffect effect,
  ) async {
    final bloc = context.read<ScanResultBloc>();
    switch (effect) {
      case OpenPhotoSourceSheet():
        final source = await PhotoSourceSheet.show(context);
        if (!context.mounted) return;
        bloc.add(NewPhotoSourceChosen(source: source));
      case OpenCompare(:final args):
        await CompareViewer.show(context, args);
      case OpenMoreSheet(:final args):
        final option = await MoreSheet.show(context, args);
        if (!context.mounted) return;
        bloc.add(MoreOptionChosen(option: option));
      case ShareJson(:final json, :final fileName):
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                utf8.encode(json),
                mimeType: _jsonMimeType,
                name: fileName,
              ),
            ],
            fileNameOverrides: [fileName],
          ),
        );
      case ShowTechDetails(:final rows):
        await TechDetailsSheet.show(context, rows);
      case OpenExternalUrl(:final url):
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      case CloseScreen():
        sl<AppRouter>().navigateBack();
    }
  }
}
