// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceStatus _$ServiceStatusFromJson(Map<String, dynamic> json) =>
    _ServiceStatus(
      devMode: json['dev_mode'] as bool? ?? false,
      message: json['message'] as String?,
      backendReachable: json['backend_reachable'] as bool? ?? false,
      profileMatch: json['profile_match'] as bool? ?? false,
      ready: json['ready'] as bool? ?? false,
      queue: json['queue'] == null
          ? null
          : ServiceQueue.fromJson(json['queue'] as Map<String, dynamic>),
      limits: json['limits'] == null
          ? null
          : ServiceLimits.fromJson(json['limits'] as Map<String, dynamic>),
      expectedProfile: json['expected_profile'] as String?,
      runtimeDescriptor: json['runtime_descriptor'] as String?,
      catalog: json['catalog'] == null
          ? null
          : CatalogSummary.fromJson(json['catalog'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ServiceStatusToJson(_ServiceStatus instance) =>
    <String, dynamic>{
      'dev_mode': instance.devMode,
      'message': instance.message,
      'backend_reachable': instance.backendReachable,
      'profile_match': instance.profileMatch,
      'ready': instance.ready,
      'queue': instance.queue,
      'limits': instance.limits,
      'expected_profile': instance.expectedProfile,
      'runtime_descriptor': instance.runtimeDescriptor,
      'catalog': instance.catalog,
    };

_ServiceQueue _$ServiceQueueFromJson(Map<String, dynamic> json) =>
    _ServiceQueue(
      inFlight: (json['in_flight'] as num?)?.toInt() ?? 0,
      waiting: (json['waiting'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ServiceQueueToJson(_ServiceQueue instance) =>
    <String, dynamic>{
      'in_flight': instance.inFlight,
      'waiting': instance.waiting,
    };

_ServiceLimits _$ServiceLimitsFromJson(Map<String, dynamic> json) =>
    _ServiceLimits(
      maxBytes: (json['max_bytes'] as num?)?.toInt(),
      maxPixels: (json['max_pixels'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ServiceLimitsToJson(_ServiceLimits instance) =>
    <String, dynamic>{
      'max_bytes': instance.maxBytes,
      'max_pixels': instance.maxPixels,
    };

_CatalogSummary _$CatalogSummaryFromJson(Map<String, dynamic> json) =>
    _CatalogSummary(cards: (json['cards'] as num?)?.toInt());

Map<String, dynamic> _$CatalogSummaryToJson(_CatalogSummary instance) =>
    <String, dynamic>{'cards': instance.cards};
