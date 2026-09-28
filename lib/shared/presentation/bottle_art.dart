import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_style_constants.dart';
import '../../core/extensions/context_extensions.dart';

/// The landing illustration of the web UI: a bottle with a label, viewfinder
/// corners and a scan line sweeping over it. Drawn so it follows the theme.
class BottleArt extends StatefulWidget {
  final double height;

  const BottleArt({super.key, required this.height});

  @override
  State<BottleArt> createState() => _BottleArtState();
}

class _BottleArtState extends State<BottleArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: DurationConstant.d3s)
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.height * _BottleArtPainter.aspect,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _scan,
          builder: (context, _) => CustomPaint(
            painter: _BottleArtPainter(
              bottle: colors.wine,
              label: colors.card,
              lines: colors.rule,
              corners: colors.gold,
              scanLine: colors.gold,
              progress: _scan.value,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }
}

class _BottleArtPainter extends CustomPainter {
  // The web art lives on a 120 × 150 grid.
  static const double _gridWidth = 120;
  static const double _gridHeight = 150;
  static const double aspect = _gridWidth / _gridHeight;

  final Color bottle;
  final Color label;
  final Color lines;
  final Color corners;
  final Color scanLine;
  final double progress;

  const _BottleArtPainter({
    required this.bottle,
    required this.label,
    required this.lines,
    required this.corners,
    required this.scanLine,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.height / _gridHeight;

    final Path body = Path()
      ..moveTo(50 * k, 10 * k)
      ..lineTo(70 * k, 10 * k)
      ..lineTo(70 * k, 40 * k)
      ..cubicTo(70 * k, 49 * k, 88 * k, 57 * k, 88 * k, 84 * k)
      ..lineTo(88 * k, 134 * k)
      ..arcToPoint(Offset(82 * k, 140 * k), radius: Radius.circular(6 * k))
      ..lineTo(38 * k, 140 * k)
      ..arcToPoint(Offset(32 * k, 134 * k), radius: Radius.circular(6 * k))
      ..lineTo(32 * k, 84 * k)
      ..cubicTo(32 * k, 57 * k, 50 * k, 49 * k, 50 * k, 40 * k)
      ..close();
    canvas.drawPath(body, Paint()..color = bottle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(38 * k, 88 * k, 44 * k, 32 * k),
        Radius.circular(2 * k),
      ),
      Paint()..color = label,
    );

    final Paint line = Paint()
      ..color = lines
      ..strokeWidth = AppSize.s2 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(45 * k, 99 * k), Offset(75 * k, 99 * k), line);
    canvas.drawLine(Offset(49 * k, 106 * k), Offset(71 * k, 106 * k), line);
    canvas.drawLine(Offset(52 * k, 113 * k), Offset(68 * k, 113 * k), line);

    final Paint corner = Paint()
      ..color = corners
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSize.s2_5 * k
      ..strokeCap = StrokeCap.round;
    final Path cornerPath = Path()
      ..moveTo(18 * k, 70 * k)
      ..lineTo(18 * k, 58 * k)
      ..lineTo(30 * k, 58 * k)
      ..moveTo(102 * k, 70 * k)
      ..lineTo(102 * k, 58 * k)
      ..lineTo(90 * k, 58 * k)
      ..moveTo(18 * k, 124 * k)
      ..lineTo(18 * k, 136 * k)
      ..lineTo(30 * k, 136 * k)
      ..moveTo(102 * k, 124 * k)
      ..lineTo(102 * k, 136 * k)
      ..lineTo(90 * k, 136 * k);
    canvas.drawPath(cornerPath, corner);

    // The scan line travels between the corners and back.
    final double t = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    final double y = (60 + t * 74) * k;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(22 * k, y, 76 * k, 2.5 * k),
        Radius.circular(1.25 * k),
      ),
      Paint()..color = scanLine.withAlpha(AppAlpha.a85),
    );
  }

  @override
  bool shouldRepaint(covariant _BottleArtPainter old) =>
      old.progress != progress ||
      old.bottle != bottle ||
      old.label != label ||
      old.lines != lines ||
      old.corners != corners;
}
