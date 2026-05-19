import 'dart:math';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Displays the age of a PR with flame animation when very old.
class AgeText extends StatefulWidget {
  /// Creates an [AgeText].
  const AgeText({
    super.key,
    required this.ageText,
    required this.date,
    required this.neutral,
    required this.style,
  });

  /// Display text for the age (e.g. "3 days ago").
  final String ageText;

  /// The date this age is based on.
  final DateTime? date;

  /// Neutral color fallback when not in flame mode.
  final Color neutral;

  /// Text style override.
  final TextStyle? style;

  @override
  State<AgeText> createState() => _AgeTextState();
}

class _AgeTextState extends State<AgeText> with SingleTickerProviderStateMixin {
  // Created lazily and only while the flame is actually animating — see
  // [_animate]. A frozen flame (web / reduced motion) never spins one up.
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Lazily creates (once) and starts the repeating flame controller, returning
  /// it so the animated branch can drive its [AnimatedBuilder].
  AnimationController _runningController() {
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    if (!isFlameAge(widget.date)) {
      _controller?.stop();
      return Text(
        widget.ageText,
        style: widget.style?.copyWith(
          color: ageColor(widget.date, neutral: widget.neutral),
        ),
      );
    }

    final textStyle = (widget.style ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
    );

    // A single flame frame paints a `saveLayer` + a dozen `MaskFilter.blur`
    // glyph passes + a gradient shader (see [FlameTextPainter]). Animating it
    // means re-running that whole stack EVERY frame (`shouldRepaint` is always
    // true), for every flame-age row at once — the dominant source of PR-list
    // scroll jank on the web/CanvasKit renderer, where `saveLayer`/`MaskFilter`
    // are far costlier and uncached. So we only spin the controller on a native
    // target that can afford it and when motion is allowed; web and
    // reduced-motion render a single frozen frame that paints once and is then
    // held by the row's `RepaintBoundary` (zero per-frame cost during scroll).
    final animate = !kIsWeb && !CcMotion.reduced(context);
    if (!animate) {
      _controller?.stop();
      return _FlameText(ageText: widget.ageText, style: textStyle, t: 0);
    }

    final controller = _runningController();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) =>
          _FlameText(ageText: widget.ageText, style: textStyle, t: controller.value),
    );
  }
}

/// The flame-styled age label at a single animation frame [t]. Pulled out of
/// [AgeText] so both the animated (per-frame [t]) and the frozen (fixed [t])
/// paths share one layout and one [FlameTextPainter].
class _FlameText extends StatelessWidget {
  const _FlameText({
    required this.ageText,
    required this.style,
    required this.t,
  });

  final String ageText;
  final TextStyle style;
  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0, child: Text(ageText, style: style)),
        Positioned(
          top: -FlameTextPainter.flameHeight,
          left: -FlameTextPainter.sidePad,
          right: -FlameTextPainter.sidePad,
          bottom: -FlameTextPainter.emberDepth,
          child: IgnorePointer(
            child: CustomPaint(
              painter: FlameTextPainter(text: ageText, style: style, t: t),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints text with a flame-like animated effect at the top.
class FlameTextPainter extends CustomPainter {
  /// Creates a [FlameTextPainter] for animating text with a flame effect.
  FlameTextPainter({required this.text, required this.style, required this.t});

  /// Height of the flame effect in logical pixels.
  static const double flameHeight = 7;

  /// Depth of ember glow below the text.
  static const double emberDepth = 5;

  /// Horizontal padding so flames don't clip.
  static const double sidePad = 4;
  static const int _upwardLayers = 8;
  static const int _downwardLayers = 4;

  static double _hash(double x, double y) {
    final s = sin(x * 12.9898 + y * 78.233) * 43758.5453;
    return s - s.floorToDouble();
  }

  static double _noise(double x, double y) {
    final xi = x.floorToDouble();
    final yi = y.floorToDouble();
    final xf = x - xi;
    final yf = y - yi;
    final u = xf * xf * (3 - 2 * xf);
    final v = yf * yf * (3 - 2 * yf);
    final a = _hash(xi, yi);
    final b = _hash(xi + 1, yi);
    final c = _hash(xi, yi + 1);
    final d = _hash(xi + 1, yi + 1);
    final ab = a + (b - a) * u;
    final cd = c + (d - c) * u;
    return ab + (cd - ab) * v;
  }

  /// The text to paint with flame effect.
  final String text;

  /// Base text style for sizing and font.
  final TextStyle style;

  /// Animation progress (0.0 to 1.0).
  final double t;

  static const double _tau = 2 * pi;

  TextPainter _glyphPainter(Paint paint) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(foreground: paint, color: null),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) {
      return;
    }

    final phase = t * _tau;
    const textY = flameHeight;
    final textHeight = size.height - flameHeight - emberDepth;
    final textRect = Rect.fromLTWH(
      sidePad,
      textY,
      size.width - sidePad * 2,
      textHeight,
    );

    canvas.saveLayer(Offset.zero & size, Paint());

    for (var i = _upwardLayers; i >= 1; i--) {
      final p = i / _upwardLayers;

      final sway = (_noise(i * 0.6 + phase, 1.7) - 0.5) * 5.0 * p;
      final bob = (_noise(i * 0.9 + 13.0, phase * 1.4) - 0.5) * 1.4 * p;

      final paint = Paint()
        ..color = _flameColor(p)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.35 + p * 1.6);

      _glyphPainter(
        paint,
      ).paint(canvas, Offset(sidePad + sway, textY - p * flameHeight + bob));
    }

    for (var i = _downwardLayers; i >= 1; i--) {
      final p = i / _downwardLayers;

      final sway = (_noise(i * 0.7 + phase + 5.0, 2.3) - 0.5) * 4.0 * p;
      final bob = (_noise(i * 0.8 + 23.0, phase * 1.6) - 0.5) * 0.9 * p;

      final paint = Paint()
        ..color = _flameColor(p)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.4 + p * 1.2);

      _glyphPainter(
        paint,
      ).paint(canvas, Offset(sidePad + sway, textY + p * emberDepth + bob));
    }

    canvas.restore();

    final shader = const LinearGradient(
      colors: [
        DesignSystemPalette.red950,
        DesignSystemPalette.red800,
        DesignSystemPalette.red600,
      ],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(textRect);

    _glyphPainter(
      Paint()..shader = shader,
    ).paint(canvas, const Offset(sidePad, textY));
  }

  Color _flameColor(double p) {
    if (p < 0.3) {
      final u = p / 0.3;
      return Color.lerp(
        DesignSystemPalette.amber200,
        DesignSystemPalette.amber400,
        u,
      )!.withValues(alpha: 0.24);
    } else if (p < 0.65) {
      final u = (p - 0.3) / 0.35;
      return Color.lerp(
        DesignSystemPalette.amber400,
        DesignSystemPalette.orange500,
        u,
      )!.withValues(alpha: 0.22 - u * 0.08);
    } else {
      final u = (p - 0.65) / 0.35;
      return Color.lerp(
        DesignSystemPalette.orange500,
        DesignSystemPalette.red500,
        u,
      )!.withValues(alpha: (0.14 - u * 0.14).clamp(0.0, 1.0));
    }
  }

  @override
  bool shouldRepaint(covariant FlameTextPainter old) =>
      t != old.t || text != old.text || style != old.style;
}
