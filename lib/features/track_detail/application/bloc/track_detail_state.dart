import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/application/bloc/base_bloc_state.dart';
import '../../../../core/application/bloc/screen_status.dart';
import '../../../home/domain/models/track.dart';

part 'track_detail_state.freezed.dart';

@freezed
abstract class TrackDetailState with _$TrackDetailState
    implements BaseBlocState {
  const factory TrackDetailState({
    required ScreenStatus screenStatus,
    required Track? track,
  }) = _TrackDetailState;

  factory TrackDetailState.initial() {
    return const TrackDetailState(
      screenStatus: ScreenStatus.content,
      track: null,
    );
  }
}
