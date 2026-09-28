import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_status.freezed.dart';
part 'service_status.g.dart';

/// `GET /api/status`: only the fields the app acts on.
@freezed
abstract class ServiceStatus with _$ServiceStatus {
  const factory ServiceStatus({
    @JsonKey(name: 'dev_mode') @Default(false) bool devMode,
    String? message,
    @JsonKey(name: 'backend_reachable') @Default(false) bool backendReachable,
    @JsonKey(name: 'profile_match') @Default(false) bool profileMatch,
    @Default(false) bool ready,
    ServiceQueue? queue,
    ServiceLimits? limits,
    @JsonKey(name: 'expected_profile') String? expectedProfile,
    @JsonKey(name: 'runtime_descriptor') String? runtimeDescriptor,
    CatalogSummary? catalog,
  }) = _ServiceStatus;

  const ServiceStatus._();

  factory ServiceStatus.fromJson(Map<String, dynamic> json) =>
      _$ServiceStatusFromJson(json);

  bool get isBusy => (queue?.inFlight ?? 0) > 0;

  int get waiting => queue?.waiting ?? 0;
}

@freezed
abstract class ServiceQueue with _$ServiceQueue {
  const factory ServiceQueue({
    @JsonKey(name: 'in_flight') @Default(0) int inFlight,
    @Default(0) int waiting,
  }) = _ServiceQueue;

  factory ServiceQueue.fromJson(Map<String, dynamic> json) =>
      _$ServiceQueueFromJson(json);
}

@freezed
abstract class ServiceLimits with _$ServiceLimits {
  const factory ServiceLimits({
    @JsonKey(name: 'max_bytes') int? maxBytes,
    @JsonKey(name: 'max_pixels') int? maxPixels,
  }) = _ServiceLimits;

  factory ServiceLimits.fromJson(Map<String, dynamic> json) =>
      _$ServiceLimitsFromJson(json);
}

@freezed
abstract class CatalogSummary with _$CatalogSummary {
  const factory CatalogSummary({int? cards}) = _CatalogSummary;

  factory CatalogSummary.fromJson(Map<String, dynamic> json) =>
      _$CatalogSummaryFromJson(json);
}
