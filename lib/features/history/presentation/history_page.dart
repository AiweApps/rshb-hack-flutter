import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/base_bloc_uieffect.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/dialog/confirmation_dialog.dart';
import '../../../shared/helpers/service_locator.dart';
import '../../scan/domain/models/scan_result_args.dart';
import '../application/bloc/history_bloc.dart';
import '../application/bloc/history_state.dart';
import '../application/bloc/history_uieffect.dart';
import 'history_content.dart';
import 'history_error.dart';
import 'history_loading.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.localization.historyTitle),
        actions: const [_ClearAction()],
      ),
      body: SafeArea(
        child: BaseBlocPresentationListener<HistoryBloc>(
          listener: _onUiEffect,
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) => switch (state.screenStatus) {
              ScreenStatus.loading => const HistoryLoading(),
              ScreenStatus.content => HistoryContent(state: state),
              ScreenStatus.error => HistoryError(state: state),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onUiEffect(
    BuildContext context,
    BaseBlocUiEffect effect,
  ) async {
    switch (effect) {
      case OpenScan():
        sl<AppRouter>().navigateToScan();
      case OpenStoredScan(:final scanId):
        sl<AppRouter>().navigateToScanResult(StoredScanArgs(scanId: scanId));
      case ConfirmClearHistory():
        final l10n = context.localization;
        final confirmed = await showConfirmationDialog(
          context: context,
          title: l10n.historyClearConfirmTitle,
          message: l10n.historyClearConfirmBody,
          confirmButtonText: l10n.historyClearConfirm,
          cancelButtonText: l10n.commonCancel,
          isDangerous: true,
        );
        if (!context.mounted) return;
        // A dismissed dialog is a "no": nothing to tell the bloc.
        if (!confirmed) return;
        context.read<HistoryBloc>().add(const ClearHistoryConfirmed());
    }
  }
}

/// "Clear history" in the app bar; hidden while there is nothing to clear.
class _ClearAction extends StatelessWidget {
  const _ClearAction();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HistoryBloc, HistoryState, bool>(
      selector: (state) => state.canClear,
      builder: (context, canClear) {
        if (!canClear) return const SizedBox.shrink();
        return TextButton(
          onPressed: () =>
              context.read<HistoryBloc>().add(const ClearHistoryPressed()),
          child: Text(context.localization.historyClear),
        );
      },
    );
  }
}
