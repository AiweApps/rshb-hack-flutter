import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/navigation/nav_bar_height_provider.dart';
import '../../../core/widgets/remote_image.dart';
import '../../compare/application/comparison_bloc.dart';
import '../../compare/domain/comparison_repository.dart';
import '../application/bloc/history_bloc.dart';
import '../application/bloc/history_state.dart';
import 'components/history_empty.dart';
import 'components/history_tile.dart';

class HistoryContent extends StatelessWidget {
  final HistoryState state;

  const HistoryContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComparisonBloc, ComparisonState>(
      builder: (context, comparison) => _buildHistory(context, comparison),
    );
  }

  Widget _buildHistory(BuildContext context, ComparisonState comparison) {
    if (state.sections.isEmpty && comparison.saved.isEmpty) {
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
        if (comparison.saved.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(l10n.compareSavedChoices, style: context.ts.h4),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.builder(
              itemCount: comparison.saved.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SavedChoiceTile(
                  choice: comparison.saved[index],
                  comparison: comparison,
                ),
              ),
            ),
          ),
        ],
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

class _SavedChoiceTile extends StatelessWidget {
  final SavedWineChoice choice;
  final ComparisonState comparison;

  const _SavedChoiceTile({required this.choice, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final access = comparison.referenceAccess;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: RemoteImage(
          url: access?.resolve(choice.wine.reference),
          headers: access?.headers,
          width: 48,
          height: 64,
          fit: BoxFit.contain,
          errorWidget: const Icon(Icons.wine_bar_outlined),
        ),
        title: Text(
          choice.wine.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(choice.dish),
        trailing: IconButton(
          onPressed: () =>
              context.read<ComparisonBloc>().add(RemoveSavedChoice(choice.id)),
          tooltip: context.localization.compareDeleteChoice,
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.wine.title,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (choice.wine.producer case final producer?) Text(producer),
                  const SizedBox(height: 12),
                  Text(
                    choice.dish,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(context.localization.compareReason(choice.dish)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
