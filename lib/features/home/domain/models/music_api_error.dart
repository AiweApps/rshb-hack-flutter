import 'package:json_annotation/json_annotation.dart';

part 'music_api_error.g.dart';

@JsonSerializable()
class MusicApiError {
  final ErrorDetails error;

  MusicApiError({required this.error});

  factory MusicApiError.fromJson(Map<String, dynamic> json) => 
      _$MusicApiErrorFromJson(json);
  
  Map<String, dynamic> toJson() => _$MusicApiErrorToJson(this);
}

@JsonSerializable()
class ErrorDetails {
  final String type;
  final String message;
  final int code;

  ErrorDetails({
    required this.type,
    required this.message,
    required this.code,
  });

  factory ErrorDetails.fromJson(Map<String, dynamic> json) => 
      _$ErrorDetailsFromJson(json);
  
  Map<String, dynamic> toJson() => _$ErrorDetailsToJson(this);
}