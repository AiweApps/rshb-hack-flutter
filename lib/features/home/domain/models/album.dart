import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final int id;
  final String title;
  final String? cover;
  @JsonKey(name: 'cover_small')
  final String? coverSmall;
  @JsonKey(name: 'cover_medium')
  final String? coverMedium;
  @JsonKey(name: 'cover_big')
  final String? coverBig;
  @JsonKey(name: 'cover_xl')
  final String? coverXl;
  @JsonKey(name: 'md5_image')
  final String? md5Image;
  final String? tracklist;
  final String? type;

  Album({
    required this.id,
    required this.title,
    this.cover,
    this.coverSmall,
    this.coverMedium,
    this.coverBig,
    this.coverXl,
    this.md5Image,
    this.tracklist,
    this.type,
  });

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);
}
