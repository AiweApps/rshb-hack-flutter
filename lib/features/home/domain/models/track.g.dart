// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Track _$TrackFromJson(Map<String, dynamic> json) => Track(
  id: (json['id'] as num).toInt(),
  readable: json['readable'] as bool?,
  title: json['title'] as String,
  titleShort: json['title_short'] as String?,
  titleVersion: json['title_version'] as String?,
  link: json['link'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  rank: (json['rank'] as num?)?.toInt(),
  explicitLyrics: json['explicit_lyrics'] as bool?,
  explicitContentLyrics: (json['explicit_content_lyrics'] as num?)?.toInt(),
  explicitContentCover: (json['explicit_content_cover'] as num?)?.toInt(),
  preview: json['preview'] as String?,
  md5Image: json['md5_image'] as String?,
  artist: Artist.fromJson(json['artist'] as Map<String, dynamic>),
  album: Album.fromJson(json['album'] as Map<String, dynamic>),
  type: json['type'] as String?,
);

Map<String, dynamic> _$TrackToJson(Track instance) => <String, dynamic>{
  'id': instance.id,
  'readable': instance.readable,
  'title': instance.title,
  'title_short': instance.titleShort,
  'title_version': instance.titleVersion,
  'link': instance.link,
  'duration': instance.duration,
  'rank': instance.rank,
  'explicit_lyrics': instance.explicitLyrics,
  'explicit_content_lyrics': instance.explicitContentLyrics,
  'explicit_content_cover': instance.explicitContentCover,
  'preview': instance.preview,
  'md5_image': instance.md5Image,
  'artist': instance.artist,
  'album': instance.album,
  'type': instance.type,
};
