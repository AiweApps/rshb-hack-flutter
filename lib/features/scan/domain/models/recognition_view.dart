import 'package:freezed_annotation/freezed_annotation.dart';

import 'bottle_box.dart';
import 'wine_card.dart';

part 'recognition_view.freezed.dart';
part 'recognition_view.g.dart';

/// How the request addressed the photo.
@JsonEnum()
enum ScanMode {
  automatic,
  @JsonValue('explicit_roi')
  explicitRoi,
  unknown,
}

/// The service's verdict for the photo or for one bottle. `uncertain` is the
/// normal "here are candidates" outcome; there is no accepted state, because
/// confidence is not calibrated.
@JsonEnum()
enum ScanDecision {
  uncertain,
  matched,
  unknown,
  @JsonValue('insufficient_evidence')
  insufficientEvidence,
  @JsonValue('ambiguous_target')
  ambiguousTarget,
  @JsonValue('no_target')
  noTarget,
  @JsonValue('invalid_image')
  invalidImage,
  other,
}

/// The wire value of an enum, for the technical details (`explicit_roi`,
/// not `explicitRoi`). The maps are generated next to `fromJson`.
extension ScanModeApi on ScanMode {
  String get apiName => _$ScanModeEnumMap[this] ?? name;
}

extension ScanDecisionApi on ScanDecision {
  String get apiName => _$ScanDecisionEnumMap[this] ?? name;
}

/// The `view` object of `POST /api/recognize` (gateway `build_view`).
@freezed
abstract class RecognitionView with _$RecognitionView {
  const factory RecognitionView({
    @JsonKey(unknownEnumValue: ScanDecision.other)
    @Default(ScanDecision.other)
    ScanDecision decision,
    @JsonKey(name: 'decision_text') String? decisionText,
    @JsonKey(name: 'raw_slug') String? rawSlug,
    @JsonKey(name: 'best_slug') String? bestSlug,
    @JsonKey(name: 'published_card') WineCard? publishedCard,
    @JsonKey(unknownEnumValue: ScanMode.unknown)
    @Default(ScanMode.unknown)
    ScanMode mode,
    @BottleBoxConverter() BottleBox? roi,
    @JsonKey(name: 'bottle_count') @Default(0) int bottleCount,
    @JsonKey(name: 'primary_instance_id') String? primaryInstanceId,
    @JsonKey(name: 'primary_basis') String? primaryBasis,
    @JsonKey(name: 'frame_size') List<int>? frameSize,
    ImageInfo? image,
    @Default(<RecognizedBottle>[]) List<RecognizedBottle> bottles,
    @Default(<String>[]) List<String> reasons,
    @JsonKey(name: 'profile_checksum') String? profileChecksum,
    @JsonKey(name: 'backend_ms') int? backendMs,
  }) = _RecognitionView;

  const RecognitionView._();

  factory RecognitionView.fromJson(Map<String, dynamic> json) =>
      _$RecognitionViewFromJson(json);

  /// Width and height of the EXIF-oriented frame every box refers to.
  List<int>? get frame => frameSize ?? image?.size;

  bool get isExplicitRoi => mode == ScanMode.explicitRoi;

  /// The bottle the service suggests as the central one, when it says so.
  bool isNearCenter(RecognizedBottle bottle) =>
      bottle.primary && primaryBasis == 'central_suggestion';

  RecognizedBottle? bottleById(String? instanceId) {
    if (instanceId == null) return null;
    for (final bottle in bottles) {
      if (bottle.instanceId == instanceId) return bottle;
    }
    return null;
  }
}

/// One physical bottle found in the photo, with its candidates.
@freezed
abstract class RecognizedBottle with _$RecognizedBottle {
  const factory RecognizedBottle({
    required int number,
    @JsonKey(name: 'instance_id') required String instanceId,
    @BottleBoxConverter() BottleBox? geometry,
    @JsonKey(name: 'label_bbox') @BottleBoxConverter() BottleBox? labelBbox,
    @JsonKey(name: 'select_roi') @BottleBoxConverter() BottleBox? selectRoi,
    String? selectable,
    @Default(false) bool primary,
    @Default(false) bool addressed,
    @JsonKey(unknownEnumValue: ScanDecision.other)
    @Default(ScanDecision.other)
    ScanDecision decision,
    @JsonKey(name: 'decision_text') String? decisionText,
    @Default(<String>[]) List<String> reasons,
    WineCard? best,
    @Default(<WineCard>[]) List<WineCard> alternatives,
  }) = _RecognizedBottle;

  factory RecognizedBottle.fromJson(Map<String, dynamic> json) =>
      _$RecognizedBottleFromJson(json);
}

/// What the service saw in the uploaded file.
@freezed
abstract class ImageInfo with _$ImageInfo {
  const factory ImageInfo({
    String? format,
    String? mime,
    List<int>? size,
    int? bytes,
  }) = _ImageInfo;

  factory ImageInfo.fromJson(Map<String, dynamic> json) =>
      _$ImageInfoFromJson(json);
}
