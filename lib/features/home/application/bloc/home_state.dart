import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../domain/models/track.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState implements BaseBlocState {
  const factory HomeState({
    required ScreenStatus screenStatus,
    required List<Track> searchResults,
    required String searchQuery,
  }) = _HomePageState;

  factory HomeState.initial() {
    return const HomeState(
      screenStatus: ScreenStatus.content,
      searchResults: [],
      searchQuery: '',
    );
  }
}
