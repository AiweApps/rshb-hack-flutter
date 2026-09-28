import 'package:freezed_annotation/freezed_annotation.dart';

part 'bottle_box.freezed.dart';

/// An axis-aligned box in EXIF-oriented original pixels, as the API reports
/// bottle geometry and accepts `target_roi`: `[x1, y1, x2, y2]`.
@freezed
abstract class BottleBox with _$BottleBox {
  const factory BottleBox({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) = _BottleBox;

  const BottleBox._();

  double get width => x2 - x1;

  double get height => y2 - y1;

  double get longerSide => width > height ? width : height;

  /// JSON array form for `target_roi`, rounded to whole pixels.
  List<int> toList() => [x1.round(), y1.round(), x2.round(), y2.round()];

  /// The box clamped to a frame of [frameWidth] × [frameHeight], as the API
  /// insists on `0 <= x1 < x2 <= w`.
  BottleBox clampTo(double frameWidth, double frameHeight) {
    return BottleBox(
      x1: x1.clamp(0, frameWidth),
      y1: y1.clamp(0, frameHeight),
      x2: x2.clamp(0, frameWidth),
      y2: y2.clamp(0, frameHeight),
    );
  }
}

/// Reads `[x1, y1, x2, y2]` arrays; anything else is treated as no box.
class BottleBoxConverter implements JsonConverter<BottleBox?, Object?> {
  const BottleBoxConverter();

  @override
  BottleBox? fromJson(Object? json) {
    if (json is! List || json.length != 4) return null;
    final values = json.map((v) => v is num ? v.toDouble() : null).toList();
    if (values.contains(null)) return null;
    return BottleBox(
      x1: values[0]!,
      y1: values[1]!,
      x2: values[2]!,
      y2: values[3]!,
    );
  }

  @override
  Object? toJson(BottleBox? box) => box?.toList();
}
