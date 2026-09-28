// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Artist _$ArtistFromJson(Map<String, dynamic> json) => Artist(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  link: json['link'] as String?,
  picture: json['picture'] as String?,
  pictureSmall: json['picture_small'] as String?,
  pictureMedium: json['picture_medium'] as String?,
  pictureBig: json['picture_big'] as String?,
  pictureXl: json['picture_xl'] as String?,
  tracklist: json['tracklist'] as String?,
  type: json['type'] as String?,
);

Map<String, dynamic> _$ArtistToJson(Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'link': instance.link,
  'picture': instance.picture,
  'picture_small': instance.pictureSmall,
  'picture_medium': instance.pictureMedium,
  'picture_big': instance.pictureBig,
  'picture_xl': instance.pictureXl,
  'tracklist': instance.tracklist,
  'type': instance.type,
};
