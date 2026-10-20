import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/language_service.dart';
import '../../../core/widgets/remote_image.dart';
import '../../../shared/helpers/service_locator.dart';
import '../../scan/domain/models/wine_card.dart';
import '../application/comparison_bloc.dart';

/// Side-by-side catalogue facts. The dish decision only uses exact source
/// pairings; missing data is not interpreted as a negative recommendation.
class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  @override
  void initState() {
    super.initState();
    context.read<ComparisonBloc>().add(const RefreshComparisonAccess());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    return BlocListener<ComparisonBloc, ComparisonState>(
      listenWhen: (a, b) => a.revision != b.revision && b.notice != null,
      listener: (context, state) {
        final text = switch (state.notice) {
          ComparisonNotice.added => l10n.compareAdded,
          ComparisonNotice.alreadyAdded => l10n.compareAlreadyAdded,
          ComparisonNotice.full => l10n.compareFull,
          ComparisonNotice.saved => l10n.compareSaved,
          ComparisonNotice.saveFailed => l10n.compareSaveFailed,
          null => null,
        };
        if (text != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.compareTitle)),
        body: BlocBuilder<ComparisonBloc, ComparisonState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final bloc = context.read<ComparisonBloc>();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Text(
                  l10n.compareCount(state.wines.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (state.wines.isEmpty) ...[
                  _Message(text: l10n.compareEmpty),
                ] else ...[
                  _ComparisonTable(state: state, bloc: bloc),
                  if (state.referenceAccess == null)
                    TextButton.icon(
                      onPressed: () =>
                          bloc.add(const RefreshComparisonAccess()),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.compareRetryPhotos),
                    ),
                  if (state.wines.length == 1) ...[
                    const SizedBox(height: 16),
                    _Message(text: l10n.compareNeedSecond),
                  ],
                ],
                const SizedBox(height: 16),
                if (state.wines.length < 3)
                  OutlinedButton.icon(
                    onPressed: () => sl<AppRouter>().navigateToScan(),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.compareAddWine),
                  )
                else
                  _Message(text: l10n.compareFull),
                if (state.wines.isNotEmpty) ...[
                  TextButton(
                    onPressed: () => sl<AppRouter>().navigateToHistory(),
                    child: Text(l10n.compareAddFromHistory),
                  ),
                ],
                if (state.wines.length >= 2) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.compareChooseDish,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (!state.catalogReady)
                    _Message(text: l10n.compareDataError)
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: state.dish,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.compareDish,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final dish in bloc.catalog.dishes)
                          DropdownMenuItem(value: dish, child: Text(dish)),
                      ],
                      onChanged: (dish) {
                        if (dish != null) bloc.add(SelectComparisonDish(dish));
                      },
                    ),
                    if (state.dish case final dish?) ...[
                      const SizedBox(height: 16),
                      _DishMatches(state: state, dish: dish, bloc: bloc),
                    ],
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  static const double _headerHeight = 264;
  final ComparisonState state;
  final ComparisonBloc bloc;

  const _ComparisonTable({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final wines = state.wines;
    final width = MediaQuery.sizeOf(context).width;
    // A pair fits on one phone screen; only a third card needs horizontal
    // scrolling. The fixed label column keeps the comparison legible.
    final columnWidth = wines.length == 2
        ? (width - 124) / 2
        : (width - 124).clamp(148.0, 190.0);
    final rows = <_FactRow>[
      _FactRow(l10n.compareType, [for (final w in wines) w.category]),
      _FactRow(l10n.compareSourceCategory, [
        for (final w in wines)
          state.catalogReady ? bloc.catalog.sourceCategoryFor(w.slug) : null,
      ]),
      _FactRow(l10n.compareGrapes, [for (final w in wines) w.grapes]),
      _FactRow(l10n.compareRegion, [for (final w in wines) w.region]),
      _FactRow(l10n.compareTemperature, [
        for (final w in wines)
          state.catalogReady ? bloc.catalog.temperatureFor(w.slug) : null,
      ]),
      _FactRow(l10n.comparePairings, [
        for (final w in wines)
          state.catalogReady
              ? bloc.catalog.dishesFor(w.slug)?.join(', ')
              : null,
      ], height: 128),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        border: Border.all(color: context.colors.rule),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              child: Column(
                children: [
                  const SizedBox(height: _headerHeight),
                  for (final row in rows)
                    SizedBox(
                      height: row.height,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < wines.length; index++)
                      SizedBox(
                        width: columnWidth,
                        child: Column(
                          children: [
                            _WineHeader(
                              wine: wines[index],
                              state: state,
                              height: _headerHeight,
                              onRemove: () => bloc.add(
                                RemoveComparisonWine(wines[index].slug),
                              ),
                            ),
                            for (final row in rows)
                              _FactCell(
                                value: row.values[index],
                                height: row.height,
                                differs: row.differs,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactRow {
  final String label;
  final List<String?> values;
  final double height;

  const _FactRow(this.label, this.values, {this.height = 84});

  bool get differs =>
      values.length > 1 &&
      values.map((s) => s?.trim() ?? '').toSet().length > 1;
}

class _WineHeader extends StatelessWidget {
  final WineCard wine;
  final ComparisonState state;
  final double height;
  final VoidCallback onRemove;

  const _WineHeader({
    required this.wine,
    required this.state,
    required this.height,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final access = state.referenceAccess;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: onRemove,
                  tooltip: context.localization.compareRemoveWine,
                  icon: const Icon(Icons.close),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            RemoteImage(
              url: access?.resolve(wine.reference),
              headers: access?.headers,
              width: 62,
              height: 76,
              fit: BoxFit.contain,
              borderRadius: 8,
              errorWidget: SizedBox(
                width: 62,
                height: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wine_bar_outlined, size: 32),
                    Text(
                      context.localization.compareNoPhoto,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                wine.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (wine.producer?.isNotEmpty ?? false)
              Text(
                wine.producer!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  final String? value;
  final double height;
  final bool differs;

  const _FactCell({
    required this.value,
    required this.height,
    required this.differs,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null || value!.trim().isEmpty
        ? context.localization.compareNoData
        : value!;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      decoration: BoxDecoration(
        color: differs ? context.colors.wine.withAlpha(18) : null,
        border: Border(top: BorderSide(color: context.colors.rule)),
      ),
      child: Text(
        text,
        maxLines: height > 100 ? 6 : 4,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _DishMatches extends StatelessWidget {
  final ComparisonState state;
  final String dish;
  final ComparisonBloc bloc;

  const _DishMatches({
    required this.state,
    required this.dish,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.localization;
    final matching = state.wines
        .where(
          (wine) => bloc.catalog.dishesFor(wine.slug)?.contains(dish) ?? false,
        )
        .toList();
    final unknown = state.wines
        .where((wine) => bloc.catalog.dishesFor(wine.slug) == null)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (matching.isEmpty) _Message(text: l10n.compareNoMatches),
        for (final wine in matching)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wine.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.compareReason(dish)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => bloc.add(SaveComparisonChoice(wine.slug)),
                    child: Text(l10n.compareSaveChoice),
                  ),
                ],
              ),
            ),
          ),
        if (unknown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.compareUnknownPairings,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );
}
