import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/services/language_service.dart';
import '../../../application/result/bloc/scan_result_state.dart';
import '../../../domain/models/recognition_view.dart';
import '../../../domain/models/wine_card.dart';
import 'bottle_answer.dart';
import 'bottle_chips.dart';
import 'bottles_overview.dart';
import 'decision_label.dart';
import 'result_empty_card.dart';
import 'result_error_panel.dart';
import 'result_loading_panel.dart';

/// The answer for the current phase — the bottle switcher and the cards,
/// the loading or the failure — and the disclaimer under it.
class ResultAnswerList extends StatelessWidget {
  final ScanResultState state;
  final ValueChanged<String?> onBottleSelected;
  final ValueChanged<String> onRescan;
  final VoidCallback onRescanHintDismissed;
  final void Function(String instanceId, WineCard card) onCompare;
  final ValueChanged<String> onLinkTap;
  final VoidCallback onRetry;
  final VoidCallback onNewScan;

  const ResultAnswerList({
    super.key,
    required this.state,
    required this.onBottleSelected,
    required this.onRescan,
    required this.onRescanHintDismissed,
    required this.onCompare,
    required this.onLinkTap,
    required this.onRetry,
    required this.onNewScan,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
      children: [
        switch (state.phase) {
          ResultPhase.recognizing ||
          ResultPhase.waitingRetry => ResultLoadingPanel(state: state),
          ResultPhase.failed => switch (state.failure) {
            null => const SizedBox.shrink(),
            final failure => ResultErrorPanel(
              failure: failure,
              onRetry: onRetry,
              onNewScan: onNewScan,
            ),
          },
          ResultPhase.answer => switch (state.view) {
            null => const SizedBox.shrink(),
            final view => _Answer(
              state: state,
              view: view,
              onBottleSelected: onBottleSelected,
              onRescan: onRescan,
              onRescanHintDismissed: onRescanHintDismissed,
              onCompare: onCompare,
              onLinkTap: onLinkTap,
            ),
          },
        },
        const SizedBox(height: AppSpaces.s20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p24),
          child: Text(
            context.localization.disclaimer,
            style: context.ts.paragraphTiny,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// An answer that arrived: nothing found, all bottles, or one bottle.
class _Answer extends StatelessWidget {
  final ScanResultState state;
  final RecognitionView view;
  final ValueChanged<String?> onBottleSelected;
  final ValueChanged<String> onRescan;
  final VoidCallback onRescanHintDismissed;
  final void Function(String instanceId, WineCard card) onCompare;
  final ValueChanged<String> onLinkTap;

  const _Answer({
    required this.state,
    required this.view,
    required this.onBottleSelected,
    required this.onRescan,
    required this.onRescanHintDismissed,
    required this.onCompare,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    if (view.bottles.isEmpty) {
      final String title =
          decisionLabel(context, view.decision) ?? l10n.decisionInsufficient;
      final String text = switch (view.emptyAnswer) {
        EmptyAnswer.roiNoTarget => l10n.resultNoBottleAdviceRoi,
        EmptyAnswer.roi => l10n.resultNoBottleRoi,
        EmptyAnswer.autoNoTarget => l10n.resultNoBottleAdviceAuto,
        EmptyAnswer.auto => l10n.resultNoBottleAuto,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
        child: ResultEmptyCard(title: title, text: text),
      );
    }

    final selected = state.selectedBottle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view.bottles.length > 1) ...[
          BottleChips(
            view: view,
            selectedInstanceId: state.selectedInstanceId,
            onSelected: onBottleSelected,
          ),
          const SizedBox(height: AppSpaces.s16),
        ],
        if (selected == null)
          BottlesOverview(
            view: view,
            referenceAccess: state.referenceAccess,
            onBottleTap: onBottleSelected,
            onLinkTap: onLinkTap,
          )
        else
          BottleAnswer(
            view: view,
            bottle: selected,
            photoPath: state.photoPath,
            referenceAccess: state.referenceAccess,
            showRescanHint: state.showRescanHint,
            onRescan: () => onRescan(selected.instanceId),
            onRescanHintDismissed: onRescanHintDismissed,
            onCompare: (card) => onCompare(selected.instanceId, card),
            onLinkTap: onLinkTap,
          ),
      ],
    );
  }
}
