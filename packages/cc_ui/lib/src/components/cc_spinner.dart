import 'dart:math' as math;

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// An indeterminate circular progress spinner.
///
/// A thin arc sweeps continuously around a square box, painted flat with
/// rounded stroke caps.
/// When motion is reduced (`CcMotion.reduced`) it stops rotating and shows a
/// static partial ring instead, so it never animates against an accessibility
/// preference.
class CcSpinner extends StatefulWidget {
  /// Creates a [CcSpinner].
  const CcSpinner({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color,
    this.semanticLabel,
  });

  /// The width and height of the spinner box, in logical pixels.
  final double size;

  /// The thickness of the spinning arc, in logical pixels.
  final double strokeWidth;

  /// The arc color. Defaults to the design-system accent.
  final Color? color;

  /// An optional semantics label announced to assistive tech.
  final String? semanticLabel;

  @override
  State<CcSpinner> createState() => _CcSpinnerState();
}

class _CcSpinnerState extends State<CcSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    if (CcMotion.reduced(context)) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final color = widget.color ?? t.accent;
    final reduced = CcMotion.reduced(context);
    _syncAnimation();

    Widget paint(double rotation) {
      return CustomPaint(
        painter: _SpinnerPainter(
          color: color,
          strokeWidth: widget.strokeWidth,
          rotation: rotation,
        ),
      );
    }

    final Widget spinner = SizedBox(
      width: widget.size,
      height: widget.size,
      child: reduced
          ? paint(0)
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  paint(_controller.value * 2 * math.pi),
            ),
    );

    final label = widget.semanticLabel;
    if (label == null) {
      return spinner;
    }
    return Semantics(
      label: label,
      child: spinner,
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.color,
    required this.strokeWidth,
    required this.rotation,
  });

  final Color color;
  final double strokeWidth;
  final double rotation;

  /// The visible fraction of the full circle (roughly three-quarters).
  static const double _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    // Start at the top, sweep clockwise; rotation animates the whole arc.
    final start = rotation - math.pi / 2;
    canvas.drawArc(rect, start, _sweep, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.rotation != rotation;
}
