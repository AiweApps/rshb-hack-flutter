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
import 'result_actions.dart';
import 'result_empty_card.dart';
import 'result_error_panel.dart';
import 'result_loading_panel.dart';

/// The draggable sheet under the photo with whatever the current phase has
/// to say, the actions and the disclaimer. Scrolls inside itself; the photo
/// never scrolls.
class ResultSheet extends StatelessWidget {
  final ScanResultState state;
  final ValueChanged<String?> onBottleSelected;
  final ValueChanged<String> onRescan;
  final VoidCallback onRescanHintDismissed;
  final void Function(String instanceId, WineCard card) onCompare;
  final ValueChanged<String> onLinkTap;
  final VoidCallback onRetry;
  final VoidCallback onNewPhoto;
  final VoidCallback onDrawFrame;
  final VoidCallback onMore;

  const ResultSheet({
    super.key,
    required this.state,
    required this.onBottleSelected,
    required this.onRescan,
    required this.onRescanHintDismissed,
    required this.onCompare,
    required this.onLinkTap,
    required this.onRetry,
    required this.onNewPhoto,
    required this.onDrawFrame,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: AppSize.resultSheetInitial,
      minChildSize: AppSize.resultSheetMin,
      maxChildSize: AppSize.resultSheetMax,
      snap: true,
      snapSizes: const [AppSize.resultSheetInitial],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.paper,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.r24),
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.scrim.withAlpha(AppAlpha.a30),
                blurRadius: AppSize.s24,
                offset: const Offset(0, -AppSize.s4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + AppPadding.p24,
            ),
            children: [
              const _Handle(),
              ..._panel(context),
              const SizedBox(height: AppSpaces.s20),
              if (state.phase != ResultPhase.recognizing &&
                  state.phase != ResultPhase.waitingRetry)
                ResultActions(
                  onDrawFrame: onDrawFrame,
                  onNewPhoto: onNewPhoto,
                  onMore: onMore,
                ),
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
          ),
        );
      },
    );
  }

  List<Widget> _panel(BuildContext context) {
    switch (state.phase) {
      case ResultPhase.recognizing:
      case ResultPhase.waitingRetry:
        return [ResultLoadingPanel(state: state)];
      case ResultPhase.failed:
        final failure = state.failure;
        if (failure == null) return const [];
        return [
          ResultErrorPanel(
            failure: failure,
            onRetry: onRetry,
            onOtherPhoto: onNewPhoto,
          ),
        ];
      case ResultPhase.answer:
        final view = state.view;
        if (view == null) return const [];
        return _answer(context, view);
    }
  }

  List<Widget> _answer(BuildContext context, RecognitionView view) {
    final l10n = context.localization;
    if (view.bottles.isEmpty) {
      final String title =
          decisionLabel(context, view.decision) ?? l10n.decisionInsufficient;
      // When the verdict already says "no bottle", only the advice follows.
      final bool titleIsLead = view.decision == ScanDecision.noTarget;
      final String text = switch ((view.isExplicitRoi, titleIsLead)) {
        (true, true) => l10n.resultNoBottleAdviceRoi,
        (true, false) => l10n.resultNoBottleRoi,
        (false, true) => l10n.resultNoBottleAdviceAuto,
        (false, false) => l10n.resultNoBottleAuto,
      };
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
          child: ResultEmptyCard(title: title, text: text),
        ),
      ];
    }

    final selected = state.selectedBottle;
    return [
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
    ];
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(
          top: AppPadding.p8,
          bottom: AppPadding.p12,
        ),
        width: AppSize.s36,
        height: AppSize.s4,
        decoration: BoxDecoration(
          color: context.colors.rule,
          borderRadius: BorderRadius.circular(AppRadius.rPill),
        ),
      ),
    );
  }
}
