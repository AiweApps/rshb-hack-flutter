import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/application/bloc/base_bloc.dart';
import '../../../home/domain/models/track.dart';
import 'track_detail_state.dart';

part 'track_detail_event.dart';

class TrackDetailBloc extends BaseBloc<TrackDetailEvent, TrackDetailState> {
  TrackDetailBloc() : super(TrackDetailState.initial()) {
    on<TrackDetailStart>(_trackDetailStart);
    on<PlayTrackPreview>(_playPreviewTrack);
  }

  Future<void> _trackDetailStart(
    TrackDetailStart event,
    Emitter<TrackDetailState> emit,
  ) async {
    emit(state.copyWith(track: event.track));
  }

  Future<void> _playPreviewTrack(
    PlayTrackPreview event,
    Emitter<TrackDetailState> emit,
  ) async {
    emitSnackBar.info(event.previewUrl);
  }
}
