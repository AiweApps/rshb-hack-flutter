// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecognitionView _$RecognitionViewFromJson(Map<String, dynamic> json) =>
    _RecognitionView(
      decision:
          $enumDecodeNullable(
            _$ScanDecisionEnumMap,
            json['decision'],
            unknownValue: ScanDecision.other,
          ) ??
          ScanDecision.other,
      decisionText: json['decision_text'] as String?,
      rawSlug: json['raw_slug'] as String?,
      bestSlug: json['best_slug'] as String?,
      publishedCard: json['published_card'] == null
          ? null
          : WineCard.fromJson(json['published_card'] as Map<String, dynamic>),
      mode:
          $enumDecodeNullable(
            _$ScanModeEnumMap,
            json['mode'],
            unknownValue: ScanMode.unknown,
          ) ??
          ScanMode.unknown,
      roi: const BottleBoxConverter().fromJson(json['roi']),
      bottleCount: (json['bottle_count'] as num?)?.toInt() ?? 0,
      primaryInstanceId: json['primary_instance_id'] as String?,
      primaryBasis: json['primary_basis'] as String?,
      frameSize: (json['frame_size'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      image: json['image'] == null
          ? null
          : ImageInfo.fromJson(json['image'] as Map<String, dynamic>),
      bottles:
          (json['bottles'] as List<dynamic>?)
              ?.map((e) => RecognizedBottle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RecognizedBottle>[],
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      profileChecksum: json['profile_checksum'] as String?,
      backendMs: (json['backend_ms'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecognitionViewToJson(_RecognitionView instance) =>
    <String, dynamic>{
      'decision': _$ScanDecisionEnumMap[instance.decision]!,
      'decision_text': instance.decisionText,
      'raw_slug': instance.rawSlug,
      'best_slug': instance.bestSlug,
      'published_card': instance.publishedCard,
      'mode': _$ScanModeEnumMap[instance.mode]!,
      'roi': const BottleBoxConverter().toJson(instance.roi),
      'bottle_count': instance.bottleCount,
      'primary_instance_id': instance.primaryInstanceId,
      'primary_basis': instance.primaryBasis,
      'frame_size': instance.frameSize,
      'image': instance.image,
      'bottles': instance.bottles,
      'reasons': instance.reasons,
      'profile_checksum': instance.profileChecksum,
      'backend_ms': instance.backendMs,
    };

const _$ScanDecisionEnumMap = {
  ScanDecision.uncertain: 'uncertain',
  ScanDecision.matched: 'matched',
  ScanDecision.unknown: 'unknown',
  ScanDecision.insufficientEvidence: 'insufficient_evidence',
  ScanDecision.ambiguousTarget: 'ambiguous_target',
  ScanDecision.noTarget: 'no_target',
  ScanDecision.invalidImage: 'invalid_image',
  ScanDecision.other: 'other',
};

const _$ScanModeEnumMap = {
  ScanMode.automatic: 'automatic',
  ScanMode.explicitRoi: 'explicit_roi',
  ScanMode.unknown: 'unknown',
};

_RecognizedBottle _$RecognizedBottleFromJson(Map<String, dynamic> json) =>
    _RecognizedBottle(
      number: (json['number'] as num).toInt(),
      instanceId: json['instance_id'] as String,
      geometry: const BottleBoxConverter().fromJson(json['geometry']),
      labelBbox: const BottleBoxConverter().fromJson(json['label_bbox']),
      selectRoi: const BottleBoxConverter().fromJson(json['select_roi']),
      selectable: json['selectable'] as String?,
      primary: json['primary'] as bool? ?? false,
      addressed: json['addressed'] as bool? ?? false,
      decision:
          $enumDecodeNullable(
            _$ScanDecisionEnumMap,
            json['decision'],
            unknownValue: ScanDecision.other,
          ) ??
          ScanDecision.other,
      decisionText: json['decision_text'] as String?,
      reasons:
          (json['reasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      best: json['best'] == null
          ? null
          : WineCard.fromJson(json['best'] as Map<String, dynamic>),
      alternatives:
          (json['alternatives'] as List<dynamic>?)
              ?.map((e) => WineCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WineCard>[],
    );

Map<String, dynamic> _$RecognizedBottleToJson(_RecognizedBottle instance) =>
    <String, dynamic>{
      'number': instance.number,
      'instance_id': instance.instanceId,
      'geometry': const BottleBoxConverter().toJson(instance.geometry),
      'label_bbox': const BottleBoxConverter().toJson(instance.labelBbox),
      'select_roi': const BottleBoxConverter().toJson(instance.selectRoi),
      'selectable': instance.selectable,
      'primary': instance.primary,
      'addressed': instance.addressed,
      'decision': _$ScanDecisionEnumMap[instance.decision]!,
      'decision_text': instance.decisionText,
      'reasons': instance.reasons,
      'best': instance.best,
      'alternatives': instance.alternatives,
    };

_ImageInfo _$ImageInfoFromJson(Map<String, dynamic> json) => _ImageInfo(
  format: json['format'] as String?,
  mime: json['mime'] as String?,
  size: (json['size'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  bytes: (json['bytes'] as num?)?.toInt(),
);

Map<String, dynamic> _$ImageInfoToJson(_ImageInfo instance) =>
    <String, dynamic>{
      'format': instance.format,
      'mime': instance.mime,
      'size': instance.size,
      'bytes': instance.bytes,
    };
