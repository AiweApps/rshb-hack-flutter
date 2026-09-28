// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MusicApiError _$MusicApiErrorFromJson(Map<String, dynamic> json) =>
    MusicApiError(
      error: ErrorDetails.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MusicApiErrorToJson(MusicApiError instance) =>
    <String, dynamic>{'error': instance.error};

ErrorDetails _$ErrorDetailsFromJson(Map<String, dynamic> json) => ErrorDetails(
  type: json['type'] as String,
  message: json['message'] as String,
  code: (json['code'] as num).toInt(),
);

Map<String, dynamic> _$ErrorDetailsToJson(ErrorDetails instance) =>
    <String, dynamic>{
      'type': instance.type,
      'message': instance.message,
      'code': instance.code,
    };
