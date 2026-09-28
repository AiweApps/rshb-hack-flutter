import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_style_constants.dart';
import '../../application/result/bloc/scan_result_bloc.dart';
import '../../application/result/bloc/scan_result_state.dart';
import 'components/draw_bar.dart';
import 'components/photo_stage.dart';
import 'components/result_sheet.dart';
import 'components/result_top_bar.dart';

/// Photo on top, the answer in a draggable sheet below; in frame mode the
/// sheet folds away and the draw bar takes its place.
class ScanResultContent extends StatelessWidget {
  final ScanResultState state;

  const ScanResultContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScanResultBloc>();
    // While a frame request is in flight or has failed, only that frame is
    // drawn, as on the web: the overview boxes belong to another answer.
    final bool showAnswerBoxes = state.pendingRoi == null;
    final double sheetInset =
        MediaQuery.sizeOf(context).height * AppSize.resultSheetMin;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: sheetInset),
          child: PhotoStage(
            photoPath: state.photoPath,
            frame: state.frame,
            view: showAnswerBoxes ? state.view : null,
            selectedInstanceId: state.selectedInstanceId,
            requestRoi: state.pendingRoi ?? state.view?.roi,
            isDrawing: state.isDrawing,
            draft: state.draft,
            isEditingDraft: state.isEditingDraft,
            onBottleTap: (id) => bloc.add(BottleSelected(instanceId: id)),
            onDraftChanged: (box) => bloc.add(DraftChanged(draft: box)),
            onDraftCleared: () => bloc.add(const DraftCleared()),
            onDraftEditToggled: () => bloc.add(const DraftEditToggled()),
            onDraftRecognize: () => bloc.add(const DraftRecognizePressed()),
          ),
        ),
        // Under the sheet on purpose: a fully raised sheet covers the bar
        // instead of sharing the screen with it.
        Align(
          alignment: Alignment.topCenter,
          child: ResultTopBar(
            canGoBackToAll: state.canGoBackToAll && !state.isDrawing,
            onClose: () => bloc.add(const ClosePressed()),
            onBackToAll: () => bloc.add(const BackToAllPressed()),
          ),
        ),
        if (!state.isDrawing)
          ResultSheet(
            state: state,
            onBottleSelected: (id) => bloc.add(BottleSelected(instanceId: id)),
            onRescan: (id) => bloc.add(RescanBottlePressed(instanceId: id)),
            onRescanHintDismissed: () => bloc.add(const RescanHintDismissed()),
            onCompare: (id, card) =>
                bloc.add(CompareTapped(instanceId: id, card: card)),
            onLinkTap: (url) => bloc.add(CardLinkPressed(url: url)),
            onRetry: () => bloc.add(const RetryPressed()),
            onNewPhoto: () => bloc.add(const NewPhotoPressed()),
            onDrawFrame: () => bloc.add(const DrawModeToggled()),
            onMore: () => bloc.add(const MorePressed()),
          )
        else
          Align(
            alignment: Alignment.bottomCenter,
            child: DrawBar(
              hasDraft: state.draft != null,
              onCancel: () => bloc.add(const DrawModeToggled()),
            ),
          ),
      ],
    );
  }
}
