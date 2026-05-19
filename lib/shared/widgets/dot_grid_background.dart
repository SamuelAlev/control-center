import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Soft dot-grid canvas background that pans and zooms with its content.
///
/// [offset] shifts the dot phase (in screen pixels) so the grid scrolls in
/// lockstep with panned content; [scale] scales the dot spacing so the grid
/// zooms with it. The grid tiles infinitely, so only [offset] modulo the
/// (scaled) step and the current [scale] are ever visible.
///
/// Shared by the pipeline canvases and the memory knowledge graph so every
/// node canvas in the app draws the same backdrop.
class DotGridBackground extends StatelessWidget {
  /// Creates a [DotGridBackground].
  const DotGridBackground({
    super.key,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  /// Pan offset, in screen pixels, applied to the dot phase.
  final Offset offset;

  /// Zoom factor applied to the dot spacing and radius.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return ClipRect(
      child: CustomPaint(
        painter: _DotGridPainter(
          fill: colors.background,
          dot: colors.border,
          offset: offset,
          scale: scale,
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({
    required this.fill,
    required this.dot,
    required this.offset,
    required this.scale,
  });

  final Color fill;
  final Color dot;
  final Offset offset;
  final double scale;

  static const double _baseStep = 18;
  static const double _baseRadius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);

    // Spacing and dot size track the zoom; spacing is clamped so an extreme
    // zoom-out can't ask for an unbounded number of dots.
    final step = (_baseStep * scale).clamp(10.0, 240.0);
    final radius = (_baseRadius * scale).clamp(0.6, 3.0);

    // Phase the grid by the pan offset (positive modulo of the step) and start
    // one step before the edge so the leading row/column never leaves a gap.
    double phase(double v) => (((v + step / 2) % step) + step) % step;
    final startX = phase(offset.dx);
    final startY = phase(offset.dy);

    final p = Paint()..color = dot;
    for (var x = startX - step; x < size.width + step; x += step) {
      for (var y = startY - step; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), radius, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.fill != fill ||
      old.dot != dot ||
      old.offset != offset ||
      old.scale != scale;
}
