import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/models/bottle_box.dart';

/// Maps between EXIF-oriented frame pixels (what the API speaks) and the
/// screen box the photo is letterboxed into. Pure layout arithmetic.
class PhotoGeometry {
  final Size box;
  final Size frame;
  final double scale;
  final Offset origin;

  PhotoGeometry.fit({required this.box, required this.frame})
    : scale = math.min(box.width / frame.width, box.height / frame.height),
      origin = Offset(
        (box.width -
                frame.width *
                    math.min(
                      box.width / frame.width,
                      box.height / frame.height,
                    )) /
            2,
        (box.height -
                frame.height *
                    math.min(
                      box.width / frame.width,
                      box.height / frame.height,
                    )) /
            2,
      );

  Offset toScreen(Offset framePoint) => origin + framePoint * scale;

  Rect toScreenRect(BottleBox b) => Rect.fromPoints(
    toScreen(Offset(b.x1, b.y1)),
    toScreen(Offset(b.x2, b.y2)),
  );

  /// Screen point → frame pixels, clamped to the photo.
  Offset toFrame(Offset screenPoint) {
    final Offset p = (screenPoint - origin) / scale;
    return Offset(p.dx.clamp(0, frame.width), p.dy.clamp(0, frame.height));
  }

  /// A box from two frame points in any order.
  static BottleBox boxFromPoints(Offset a, Offset b) => BottleBox(
    x1: math.min(a.dx, b.dx),
    y1: math.min(a.dy, b.dy),
    x2: math.max(a.dx, b.dx),
    y2: math.max(a.dy, b.dy),
  );
}
