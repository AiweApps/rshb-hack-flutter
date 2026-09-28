import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/application/bloc/base_bloc.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../../core/services/api/models/result.dart';
import '../../../../shared/helpers/service_locator.dart';
import '../../domain/models/track.dart';
import '../../domain/music_api_repository.dart';
import 'home_state.dart';

part 'home_event.dart';

class HomePageBloc extends BaseBloc<HomeEvent, HomeState> {
  final MusicApiRepository _musicApiRepository = sl<MusicApiRepository>();

  HomePageBloc() : super(HomeState.initial()) {
    on<StartHome>(_homeStart);
    on<InitialSearch>(_initialSearch);
    on<Search>(_search);
    on<UpdateSearchQuery>(_updateSearchQuery);
  }

  FutureOr<void> _homeStart(StartHome event, Emitter<HomeState> emit) async {
    // Set initial query to 'easy' and trigger search
    const query = 'easy';
    emit(state.copyWith(searchQuery: query));
    add(InitialSearch(query: query));
  }

  FutureOr<void> _initialSearch(
    InitialSearch event,
    Emitter<HomeState> emit,
  ) async {
    await _performSearch(event.query, emit);
  }

  FutureOr<void> _search(Search event, Emitter<HomeState> emit) async {
    await _performSearch(event.query, emit);
  }

  FutureOr<void> _updateSearchQuery(
    UpdateSearchQuery event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
  }

  FutureOr<void> _performSearch(String query, Emitter<HomeState> emit) async {
    if (query.trim().isEmpty) return;

    emit(state.copyWith(screenStatus: ScreenStatus.loading));

    final Result<List<Track>> result = await _musicApiRepository.searchTracks(
      query,
    );

    switch (result) {
      case Success<List<Track>>():
        emit(
          state.copyWith(
            screenStatus: ScreenStatus.content,
            searchResults: result.data,
          ),
        );
        break;
      case Error<List<Track>>():
        emit(state.copyWith(screenStatus: ScreenStatus.content));
        emitErrorSnackBar(result.error);
        break;
    }
  }
}
