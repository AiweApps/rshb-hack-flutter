part of 'track_detail_bloc.dart';

sealed class TrackDetailEvent {
  const TrackDetailEvent();
}

final class TrackDetailStart extends TrackDetailEvent {
  Track track;

  TrackDetailStart({required this.track});
}

final class PlayTrackPreview extends TrackDetailEvent {
  String previewUrl;

  PlayTrackPreview({required this.previewUrl});
}
