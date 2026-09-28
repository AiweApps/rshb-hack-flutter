import 'package:json_annotation/json_annotation.dart';
import 'album.dart';
import 'artist.dart';

part 'track.g.dart';

@JsonSerializable()
class Track {
  final int id;
  final bool? readable;
  final String title;
  @JsonKey(name: 'title_short')
  final String? titleShort;
  @JsonKey(name: 'title_version')
  final String? titleVersion;
  final String? link;
  final int? duration;
  final int? rank;
  @JsonKey(name: 'explicit_lyrics')
  final bool? explicitLyrics;
  @JsonKey(name: 'explicit_content_lyrics')
  final int? explicitContentLyrics;
  @JsonKey(name: 'explicit_content_cover')
  final int? explicitContentCover;
  final String? preview;
  @JsonKey(name: 'md5_image')
  final String? md5Image;
  final Artist artist;
  final Album album;
  final String? type;

  Track({
    required this.id,
    this.readable,
    required this.title,
    this.titleShort,
    this.titleVersion,
    this.link,
    this.duration,
    this.rank,
    this.explicitLyrics,
    this.explicitContentLyrics,
    this.explicitContentCover,
    this.preview,
    this.md5Image,
    required this.artist,
    required this.album,
    this.type,
  });

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
  Map<String, dynamic> toJson() => _$TrackToJson(this);
}
