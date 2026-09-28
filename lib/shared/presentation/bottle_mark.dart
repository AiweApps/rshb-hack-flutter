import 'package:flutter/material.dart';

import '../../core/constants/app_style_constants.dart';
import '../../core/extensions/context_extensions.dart';

/// The app mark: a bottle on a rounded wine-coloured square, as in the web
/// icon. Drawn, not an asset, so it follows the theme.
class BottleMark extends StatelessWidget {
  final double size;

  const BottleMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BottleMarkPainter(
            background: context.colors.wine,
            bottle: context.colors.onWine,
            label: context.colors.gold,
          ),
        ),
      ),
    );
  }
}

class _BottleMarkPainter extends CustomPainter {
  // Geometry of static/icon.svg, on a 64-unit grid.
  static const double _grid = 64;

  final Color background;
  final Color bottle;
  final Color label;

  const _BottleMarkPainter({
    required this.background,
    required this.bottle,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double k = size.width / _grid;
    final RRect square = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(AppRadius.r12 * k),
    );
    canvas.drawRRect(square, Paint()..color = background);

    final Path body = Path()
      ..moveTo(28 * k, 8 * k)
      ..lineTo(36 * k, 8 * k)
      ..lineTo(36 * k, 18 * k)
      ..cubicTo(36 * k, 22 * k, 43 * k, 25 * k, 43 * k, 36 * k)
      ..lineTo(43 * k, 54 * k)
      ..arcToPoint(Offset(41 * k, 56 * k), radius: Radius.circular(2 * k))
      ..lineTo(23 * k, 56 * k)
      ..arcToPoint(Offset(21 * k, 54 * k), radius: Radius.circular(2 * k))
      ..lineTo(21 * k, 36 * k)
      ..cubicTo(21 * k, 25 * k, 28 * k, 22 * k, 28 * k, 18 * k)
      ..close();
    canvas.drawPath(body, Paint()..color = bottle);
    canvas.drawRect(
      Rect.fromLTWH(24 * k, 37 * k, 16 * k, 11 * k),
      Paint()..color = label,
    );
  }

  @override
  bool shouldRepaint(covariant _BottleMarkPainter old) =>
      old.background != background ||
      old.bottle != bottle ||
      old.label != label;
}
