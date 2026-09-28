import 'package:flutter/material.dart';

import '../../../../../core/constants/app_style_constants.dart';
import '../../../domain/models/bottle_box.dart';
import '../../../domain/models/recognition_view.dart';
import 'photo_geometry.dart';

/// Draws over the photo: one box per bottle (the selected one in gold), a
/// number badge when there is something to choose, the request frame, and
/// the frame being drawn.
class BottleOverlayPainter extends CustomPainter {
  static const double _dash = 8;
  static const double _gap = 5;

  final PhotoGeometry geometry;
  final RecognitionView? view;
  final String? selectedInstanceId;
  final BottleBox? requestRoi;
  final BottleBox? draft;
  final bool isEditingDraft;
  final bool showBadges;
  final Color boxColor;
  final Color activeColor;
  final Color shadowColor;
  final Color badgeColor;
  final Color activeBadgeColor;
  final Color roiColor;
  final TextStyle badgeStyle;

  const BottleOverlayPainter({
    required this.geometry,
    required this.view,
    required this.selectedInstanceId,
    required this.requestRoi,
    required this.draft,
    required this.isEditingDraft,
    required this.showBadges,
    required this.boxColor,
    required this.activeColor,
    required this.shadowColor,
    required this.badgeColor,
    required this.activeBadgeColor,
    required this.roiColor,
    required this.badgeStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final BottleBox? roi = requestRoi;
    if (roi != null) {
      _dashedRect(canvas, geometry.toScreenRect(roi), roiColor);
    }

    final RecognitionView? answer = view;
    if (answer != null) {
      for (final bottle in answer.bottles) {
        final BottleBox? box = bottle.geometry;
        if (box == null) continue;
        final Rect rect = geometry.toScreenRect(box);
        final bool active = bottle.instanceId == selectedInstanceId;
        final RRect rrect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(AppRadius.r8),
        );
        canvas.drawRRect(
          rrect.inflate(AppSize.s1),
          Paint()
            ..color = shadowColor.withAlpha(AppAlpha.a40)
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSize.bottleBoxStroke + AppSize.s2,
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = active ? activeColor : boxColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSize.bottleBoxStroke,
        );
        if (showBadges) {
          _badge(canvas, rect.topLeft, bottle.number, active);
        }
      }
    }

    final BottleBox? d = draft;
    if (d != null) {
      final Rect rect = geometry.toScreenRect(d);
      _dashedRect(canvas, rect, isEditingDraft ? activeColor : roiColor);
      if (isEditingDraft) {
        final Paint fill = Paint()..color = activeColor;
        for (final corner in [
          rect.topLeft,
          rect.topRight,
          rect.bottomLeft,
          rect.bottomRight,
        ]) {
          canvas.drawCircle(corner, AppSize.s6, fill);
        }
      }
    }
  }

  void _badge(Canvas canvas, Offset corner, int number, bool active) {
    final Offset center = corner + const Offset(AppSize.s16, AppSize.s16);
    canvas.drawCircle(
      center,
      AppSize.s14,
      Paint()..color = active ? activeBadgeColor : badgeColor,
    );
    final painter = TextPainter(
      text: TextSpan(text: '$number', style: badgeStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _dashedRect(Canvas canvas, Rect rect, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSize.roiStroke;
    final Path path = Path()..addRect(rect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + _dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BottleOverlayPainter old) =>
      old.geometry.box != geometry.box ||
      old.geometry.frame != geometry.frame ||
      old.view != view ||
      old.selectedInstanceId != selectedInstanceId ||
      old.requestRoi != requestRoi ||
      old.draft != draft ||
      old.isEditingDraft != isEditingDraft ||
      old.showBadges != showBadges ||
      old.boxColor != boxColor ||
      old.activeColor != activeColor;
}
