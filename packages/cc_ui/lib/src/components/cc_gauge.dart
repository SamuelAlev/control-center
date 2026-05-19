import 'dart:math' as math;

import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// A flat determinate radial gauge — a ring that fills clockwise from the top.
///
/// The counterpart to [CcProgressBar] for the cases where a score reads better
/// as a dial than a bar (workspace health, a quota, a completion percentage),
/// and the determinate answer to [CcSpinner], which is indeterminate by design.
///
/// Pass [value] in 0..1 (clamped). The track is the tertiary background token
/// and the arc defaults to the accent; pass [color] for a semantic reading
/// (success / warning / danger). [child] is centred inside the ring — usually
/// the number the gauge is reporting.
///
/// Purist: `package:flutter/widgets.dart` only, so it needs no `Material`
/// ancestor. Nothing animates, so there is nothing to suppress under reduced
/// motion — the ring is a static readout of [value].
class CcGauge extends StatelessWidget {
  /// Creates a [CcGauge].
  const CcGauge({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.child,
    this.semanticLabel,
  });

  /// Progress fraction in 0..1 (clamped).
  final double value;

  /// Width and height of the square gauge box, in logical pixels.
  final double size;

  /// Ring thickness, in logical pixels.
  final double strokeWidth;

  /// Arc color. Defaults to the design-system accent.
  final Color? color;

  /// Track (unfilled ring) color. Defaults to the tertiary background token.
  final Color? trackColor;

  /// Optional widget centred inside the ring.
  final Widget? child;

  /// Accessibility label announced with the reading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fraction = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(fraction * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CcGaugePainter(
            fraction: fraction,
            strokeWidth: strokeWidth,
            color: color ?? t.accent,
            trackColor: trackColor ?? t.bgTertiary,
          ),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class _CcGaugePainter extends CustomPainter {
  const _CcGaugePainter({
    required this.fraction,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (fraction <= 0) {
      return;
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    // Start at 12 o'clock and sweep clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_CcGaugePainter old) =>
      old.fraction != fraction ||
      old.strokeWidth != strokeWidth ||
      old.color != color ||
      old.trackColor != trackColor;
}
