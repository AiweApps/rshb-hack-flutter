import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../application/bloc/history_bloc.dart';
import '../application/bloc/history_state.dart';
import 'components/history_empty.dart';
import 'components/history_tile.dart';

class HistoryContent extends StatelessWidget {
  final HistoryState state;

  const HistoryContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return HistoryEmpty(
        onScan: () => context.read<HistoryBloc>().add(const ScanPressed()),
      );
    }

    // One "now" per build so every row agrees on what "today" is.
    final now = DateTime.now();
    final bloc = context.read<HistoryBloc>();

    return ListView.separated(
      padding: const EdgeInsets.all(AppPadding.p16),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpaces.s12),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return HistoryTile(
          item: item,
          now: now,
          onTap: () => bloc.add(ScanTapped(id: item.id)),
          onDismissed: () => bloc.add(ScanDismissed(id: item.id)),
        );
      },
    );
  }
}
