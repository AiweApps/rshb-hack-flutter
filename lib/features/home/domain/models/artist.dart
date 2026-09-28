import 'package:json_annotation/json_annotation.dart';

part 'artist.g.dart';

@JsonSerializable()
class Artist {
  final int id;
  final String name;
  final String? link;
  final String? picture;
  @JsonKey(name: 'picture_small')
  final String? pictureSmall;
  @JsonKey(name: 'picture_medium')
  final String? pictureMedium;
  @JsonKey(name: 'picture_big')
  final String? pictureBig;
  @JsonKey(name: 'picture_xl')
  final String? pictureXl;
  final String? tracklist;
  final String? type;

  Artist({
    required this.id,
    required this.name,
    this.link,
    this.picture,
    this.pictureSmall,
    this.pictureMedium,
    this.pictureBig,
    this.pictureXl,
    this.tracklist,
    this.type,
  });

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
  Map<String, dynamic> toJson() => _$ArtistToJson(this);
}
