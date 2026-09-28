import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/navigation/nav_bar_height_provider.dart';
import '../application/bloc/history_bloc.dart';
import '../application/bloc/history_state.dart';
import 'components/history_empty.dart';
import 'components/history_tile.dart';

class HistoryContent extends StatelessWidget {
  final HistoryState state;

  const HistoryContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.sections.isEmpty) {
      return HistoryEmpty(
        onScan: () => context.read<HistoryBloc>().add(const ScanPressed()),
      );
    }

    // One "now" per build so every header agrees on what "today" is.
    final now = DateTime.now();
    final bloc = context.read<HistoryBloc>();
    final l10n = context.localization;
    final double barHeight = NavBarHeightProvider.maybeOf(context) ?? 0;

    // Slivers so only the visible tiles are built, however long the history.
    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: AppPadding.p8)),
        for (final section in state.sections) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppPadding.p20,
              AppPadding.p16,
              AppPadding.p20,
              AppPadding.p8,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                section.day.relativeDay(l10n, now: now),
                style: context.ts.kicker,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
            sliver: SliverList.builder(
              itemCount: section.items.length,
              itemBuilder: (context, index) {
                final item = section.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppPadding.p8),
                  child: HistoryTile(
                    item: item,
                    onTap: () => bloc.add(ScanTapped(id: item.id)),
                    onDismissed: () => bloc.add(ScanDismissed(id: item.id)),
                  ),
                );
              },
            ),
          ),
        ],
        SliverPadding(
          padding: EdgeInsets.only(bottom: barHeight + AppPadding.p16),
        ),
      ],
    );
  }
}
