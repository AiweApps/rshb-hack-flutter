import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/result/bloc/scan_result_bloc.dart';
import '../../application/result/bloc/scan_result_state.dart';
import 'components/result_answer_list.dart';
import 'components/result_toolbar.dart';

/// The answer as the page and the toolbar under it; the photo opens in
/// sheets from the toolbar.
class ScanResultContent extends StatelessWidget {
  final ScanResultState state;

  const ScanResultContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScanResultBloc>();

    return Column(
      children: [
        Expanded(
          child: ResultAnswerList(
            state: state,
            onBottleSelected: (id) => bloc.add(BottleSelected(instanceId: id)),
            onRescan: (id) => bloc.add(RescanBottlePressed(instanceId: id)),
            onRescanHintDismissed: () => bloc.add(const RescanHintDismissed()),
            onCompare: (id, card) =>
                bloc.add(CompareTapped(instanceId: id, card: card)),
            onLinkTap: (url) => bloc.add(CardLinkPressed(url: url)),
            onRetry: () => bloc.add(const RetryPressed()),
            onNewScan: () => bloc.add(const NewScanPressed()),
          ),
        ),
        ResultToolbar(
          canCompare: state.canCompare,
          canDraw: state.canDrawFrame,
          onCompare: () => bloc.add(const ComparePressed()),
          onDraw: () => bloc.add(const DrawFramePressed()),
          onNewScan: () => bloc.add(const NewScanPressed()),
        ),
      ],
    );
  }
}
