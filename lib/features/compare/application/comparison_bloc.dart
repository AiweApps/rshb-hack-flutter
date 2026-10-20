import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../scan/domain/models/reference_access.dart';
import '../../scan/domain/models/wine_card.dart';
import '../../scan/domain/scan_api_repository.dart';
import '../domain/comparison_repository.dart';
import '../domain/gastronomy_catalog.dart';

sealed class ComparisonEvent {
  const ComparisonEvent();
}

class LoadComparison extends ComparisonEvent {
  const LoadComparison();
}

class AddComparisonWine extends ComparisonEvent {
  final WineCard wine;
  const AddComparisonWine(this.wine);
}

class RemoveComparisonWine extends ComparisonEvent {
  final String slug;
  const RemoveComparisonWine(this.slug);
}

class SelectComparisonDish extends ComparisonEvent {
  final String dish;
  const SelectComparisonDish(this.dish);
}

class SaveComparisonChoice extends ComparisonEvent {
  final String slug;
  const SaveComparisonChoice(this.slug);
}

class RemoveSavedChoice extends ComparisonEvent {
  final String id;
  const RemoveSavedChoice(this.id);
}

class RefreshComparisonAccess extends ComparisonEvent {
  const RefreshComparisonAccess();
}

class ComparisonAccessLoaded extends ComparisonEvent {
  final ReferenceAccess access;
  const ComparisonAccessLoaded(this.access);
}

enum ComparisonNotice { added, alreadyAdded, full, saved, saveFailed }

class ComparisonState {
  final bool loading;
  final bool catalogReady;
  final List<WineCard> wines;
  final List<SavedWineChoice> saved;
  final String? dish;
  final ReferenceAccess? referenceAccess;
  final ComparisonNotice? notice;
  final int revision;

  const ComparisonState({
    this.loading = true,
    this.catalogReady = false,
    this.wines = const [],
    this.saved = const [],
    this.dish,
    this.referenceAccess,
    this.notice,
    this.revision = 0,
  });

  ComparisonState withValues({
    bool? loading,
    bool? catalogReady,
    List<WineCard>? wines,
    List<SavedWineChoice>? saved,
    String? dish,
    ReferenceAccess? referenceAccess,
    ComparisonNotice? notice,
    bool clearNotice = false,
  }) => ComparisonState(
    loading: loading ?? this.loading,
    catalogReady: catalogReady ?? this.catalogReady,
    wines: wines ?? this.wines,
    saved: saved ?? this.saved,
    dish: dish ?? this.dish,
    referenceAccess: referenceAccess ?? this.referenceAccess,
    notice: clearNotice ? null : notice ?? this.notice,
    revision: revision + 1,
  );
}

/// One app-wide selection, restored before processing later user events.
/// Storage failures leave the current screen usable and surface a message.
class ComparisonBloc extends Bloc<ComparisonEvent, ComparisonState> {
  final ComparisonRepository _repository;
  final GastronomyCatalog catalog;
  final ScanApiRepository _api;

  ComparisonBloc(this._repository, this.catalog, this._api)
    : super(const ComparisonState()) {
    on<ComparisonEvent>(_handle, transformer: sequential());
    add(const LoadComparison());
  }

  Future<void> _handle(
    ComparisonEvent event,
    Emitter<ComparisonState> emit,
  ) async {
    switch (event) {
      case LoadComparison():
        var catalogReady = true;
        try {
          await catalog.load();
        } catch (_) {
          catalogReady = false;
        }
        emit(
          state.withValues(
            loading: false,
            catalogReady: catalogReady,
            wines: _repository.readSelected(),
            saved: _repository.readChoices(),
            clearNotice: true,
          ),
        );
        unawaited(_loadReferenceAccess());
      case RefreshComparisonAccess():
        unawaited(_loadReferenceAccess());
      case ComparisonAccessLoaded(:final access):
        emit(state.withValues(referenceAccess: access, clearNotice: true));
      case AddComparisonWine(:final wine):
        if (wine.slug.isEmpty || !wine.inCatalog) return;
        if (state.wines.any((item) => item.slug == wine.slug)) {
          emit(state.withValues(notice: ComparisonNotice.alreadyAdded));
        } else if (state.wines.length >= 3) {
          emit(state.withValues(notice: ComparisonNotice.full));
        } else {
          final wines = [...state.wines, wine];
          emit(state.withValues(wines: wines, notice: ComparisonNotice.added));
          try {
            await _repository.writeSelected(wines);
          } catch (_) {
            emit(state.withValues(notice: ComparisonNotice.saveFailed));
          }
        }
      case RemoveComparisonWine(:final slug):
        final wines = state.wines.where((wine) => wine.slug != slug).toList();
        emit(state.withValues(wines: wines, clearNotice: true));
        try {
          await _repository.writeSelected(wines);
        } catch (_) {
          emit(state.withValues(notice: ComparisonNotice.saveFailed));
        }
      case SelectComparisonDish(:final dish):
        if (!catalog.dishes.contains(dish)) return;
        emit(
          ComparisonState(
            loading: false,
            catalogReady: state.catalogReady,
            wines: state.wines,
            saved: state.saved,
            dish: dish,
            referenceAccess: state.referenceAccess,
            revision: state.revision + 1,
          ),
        );
      case SaveComparisonChoice(:final slug):
        final dish = state.dish;
        if (dish == null) return;
        final wine = state.wines.where((item) => item.slug == slug).firstOrNull;
        if (wine == null ||
            !(catalog.dishesFor(slug)?.contains(dish) ?? false)) {
          return;
        }
        final now = DateTime.now();
        final choice = SavedWineChoice(
          id: now.microsecondsSinceEpoch.toString(),
          wine: wine,
          dish: dish,
          savedAt: now,
        );
        final saved = [choice, ...state.saved];
        try {
          await _repository.writeChoices(saved);
          emit(state.withValues(saved: saved, notice: ComparisonNotice.saved));
        } catch (_) {
          emit(state.withValues(notice: ComparisonNotice.saveFailed));
        }
      case RemoveSavedChoice(:final id):
        final saved = state.saved.where((item) => item.id != id).toList();
        try {
          await _repository.writeChoices(saved);
          emit(state.withValues(saved: saved, clearNotice: true));
        } catch (_) {
          emit(state.withValues(notice: ComparisonNotice.saveFailed));
        }
    }
  }

  Future<void> _loadReferenceAccess() async {
    try {
      final access = await _api.referenceAccess();
      if (!isClosed) add(ComparisonAccessLoaded(access));
    } catch (_) {
      // Offline comparison still works with bundled catalogue facts.
    }
  }
}
