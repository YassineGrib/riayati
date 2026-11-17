import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

class Watermark extends StatelessWidget {
  const Watermark({
    super.key,
    this.opacity = .08,
    this.align = AlignmentDirectional.topEnd,
  }) : assert(opacity >= 0 && opacity <= 1);

  final double opacity;
  final AlignmentDirectional align;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ClipRect(
          child: CustomPaint(
            painter: _RibbonPainter(
              context.c.primary.withValues(alpha: opacity),
              align.resolve(Directionality.of(context)),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter(this.color, this.align);

  final Color color;
  final Alignment align;

  // Exact geometry from 01-brand/logo/riayati-mark-abstract.svg.
  // These are artwork coordinates, not layout tokens. Never mirror the mark.
  static final _path = Path()
    ..moveTo(445.2, 417.0)
    ..cubicTo(452.2, 415.1, 459.9, 414.5, 467.7, 414.5)
    ..cubicTo(516.1, 414.5, 554.9, 453.2, 554.9, 501.9)
    ..cubicTo(554.9, 550.4, 515.8, 588.9, 467.5, 588.9)
    ..cubicTo(431.6, 588.9, 410.7, 570.9, 390.6, 547.2)
    ..cubicTo(371.2, 524.4, 356.2, 503.6, 337.8, 490.4)
    ..cubicTo(328.3, 483.4, 317.7, 479.4, 305.3, 479.4)
    ..cubicTo(286.7, 479.4, 273.6, 488.9, 267.6, 504.3)
    ..cubicTo(261.3, 520.4, 265.9, 545.5, 286.9, 554.9)
    ..cubicTo(263.0, 550.6, 245.6, 528.5, 245.6, 502.1)
    ..cubicTo(245.6, 471.0, 270.2, 446.0, 302.4, 446.0)
    ..cubicTo(336.7, 446.0, 357.8, 460.3, 375.5, 483.0)
    ..cubicTo(396.3, 508.6, 415.5, 537.8, 451.9, 537.8)
    ..cubicTo(480.3, 537.8, 505.4, 513.9, 505.4, 482.1)
    ..cubicTo(505.4, 448.8, 479.3, 421.8, 445.2, 417.0)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 311;
    final height = 176 * scale;
    final origin = align.alongOffset(Offset(0, size.height - height));
    // CSS board: 360px ribbon, end -150px, top 8px, rotation -24deg.
    final crop = size.width * (150 / 360) * align.x;
    canvas.save();
    canvas.translate(crop + size.width / 2, origin.dy + RSpace.s2 + height / 2);
    canvas.rotate(-24 * math.pi / 180);
    canvas.translate(-size.width / 2, -height / 2);
    canvas.scale(scale);
    canvas.translate(-245, -414);
    canvas.drawPath(_path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.align != align;
}
