import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A one-line label with a band of light sweeping through it in reading
/// order, for live "Thinking…" / "Running tests…" status lines.
///
/// The label rests at [baseColor] and the band peaks at [highlightColor]. The
/// defaults are the quaternary and primary text tokens: the widest pair whose
/// dim end still clears 4.5:1 on the page in both themes. Sweeping between
/// the caller's own colour and primary, as this used to, lit nothing a reader
/// could see (secondary and primary are a few shades apart).
///
/// The band is [spread] logical pixels per character either side of its
/// centre, so a long line gets a proportionally wide band and every label
/// reads at the same pace. It crosses the label in [duration], linearly, and
/// starts again — off the leading edge, out past the trailing one.
///
/// Reduced motion (see [CcMotion.reduced]) renders [text] still, in [style]'s
/// own colour: the words carry the state without the sweep.
class CcShimmerText extends StatefulWidget {
  /// Creates a [CcShimmerText].
  const CcShimmerText(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(seconds: 2),
    this.spread = 2,
    this.baseColor,
    this.highlightColor,
  });

  /// The label.
  final String text;

  /// Text style, merged over the ambient [DefaultTextStyle] (like [Text]).
  /// Its colour is used only when the sweep is off.
  final TextStyle? style;

  /// One crossing of the band, leading edge to trailing edge.
  final Duration duration;

  /// The band's half-width, in logical pixels per character of [text].
  final double spread;

  /// The label's colour outside the band. Defaults to the quaternary text
  /// token.
  final Color? baseColor;

  /// The colour at the band's centre. Defaults to the primary text token.
  final Color? highlightColor;

  @override
  State<CcShimmerText> createState() => _CcShimmerTextState();
}

class _CcShimmerTextState extends State<CcShimmerText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didUpdateWidget(CcShimmerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller != null && oldWidget.duration != widget.duration) {
      controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Created on first animated build, so a reduced-motion label never owns a
  /// running ticker.
  AnimationController _ensureController() => _controller ??=
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  Widget build(BuildContext context) {
    Text label(TextStyle? style) => Text(
      widget.text,
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );

    if (CcMotion.reduced(context)) {
      _controller?.stop();
      return label(widget.style);
    }

    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final base = widget.baseColor ?? tokens.textQuaternary;
    final highlight = widget.highlightColor ?? tokens.textPrimary;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Never zero: a gradient between one point and itself has no direction.
    final halfBand = math.max(widget.spread * widget.text.runes.length, 1.0);
    final controller = _ensureController();
    if (!controller.isAnimating) {
      controller.repeat();
    }

    // The sweep repaints every frame; the boundary keeps that in its own
    // layer instead of dirtying the feed around it.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // The centre travels from a band's width before the leading edge
            // to a band's width past the trailing one, so the band enters
            // and leaves whole. Reading order: right to left under RTL.
            final travel = bounds.width + 2 * halfBand;
            final along = -halfBand + travel * controller.value;
            final centre = rtl ? bounds.width - along : along;
            return ui.Gradient.linear(
              Offset(centre - halfBand, 0),
              Offset(centre + halfBand, 0),
              [base, highlight, base],
              const [0, 0.5, 1],
            );
          },
          child: child,
        ),
        // White under the mask: `srcIn` keeps only the shader's colour.
        child: label(
          (widget.style ?? const TextStyle()).copyWith(
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}
