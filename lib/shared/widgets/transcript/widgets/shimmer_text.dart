import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// A short text label with an animated left-to-right shimmer sweep, used for
/// live "Thinking…" / status lines.
///
/// The sweep adds emphasis *above* a fully readable base — it never dims the
/// label below it. The base is the colour the caller already chose in [style]
/// (a design-system text token), so a status line stays legible at the sweep's
/// dimmest point; the highlight is the brighter end. Fading a real status
/// report down to a whisper is exactly the "decoration over presence" trade
/// DESIGN.md rules out, and the old default (onSurface at 0.35 alpha, applied
/// even over the caller's own colour) sat far under the 4.5:1 AA floor.
///
/// Honors reduced-motion: when `MediaQuery.disableAnimations` is set the
/// animation never runs and the label renders as static text at the base
/// colour, so the state is still conveyed (by the words) without motion.
class ShimmerText extends StatefulWidget {
  /// Creates a [ShimmerText].
  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.baseColor,
    this.highlightColor,
  });

  /// The label to render.
  final String text;

  /// Base text style. Its colour is the sweep's readable floor unless
  /// [baseColor] overrides it.
  final TextStyle? style;

  /// Colour at the sweep's dimmest point — the label's readable floor.
  /// Defaults to [style]'s colour, then to `onSurfaceVariant`.
  final Color? baseColor;

  /// Bright color at the center of the sweep. Defaults to onSurface.
  final Color? highlightColor;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  AnimationController _ensureController() {
    return _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final theme = Theme.of(context);
    final resolved =
        widget.style ??
        CcTypography.caption.copyWith(color: context.ds.textTertiary);
    // Honour the caller's colour as the floor rather than overwriting it — the
    // callers pass design-system text tokens that are already contrast-checked.
    final base =
        widget.baseColor ??
        resolved.color ??
        theme.colorScheme.onSurfaceVariant;
    final highlight = widget.highlightColor ?? theme.colorScheme.onSurface;
    final style = resolved.copyWith(color: base);

    final label = Text(
      widget.text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (reduceMotion) {
      // No motion: convey "live" purely through the (dimmed) words.
      return label;
    }

    // The sweep repaints every frame; the boundary keeps that repaint in its
    // own layer instead of dirtying the surrounding bubble/feed.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ensureController(),
        builder: (context, child) {
          final t = _controller!.value;
          // Travel the highlight's CENTRE from just off the left edge to just
          // past the right, so the sweep crosses every glyph.
          //
          // `begin`/`end` map gradient stop 0 and stop 1 onto those alignments,
          // so the highlight (stop 0.5) sits at their midpoint. The previous
          // math spanned `(-1 + 3t) → (1 + 3t)`: a full-width band whose
          // midpoint started at the centre of the text and only ever moved
          // right, so the first half of a label was never lit — "Thinking…"
          // appeared to shimmer only from the "k" on.
          final centre = -1.4 + 2.8 * t;
          const halfBand = 0.6;
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(centre - halfBand, 0),
              end: Alignment(centre + halfBand, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: child,
          );
        },
        child: label,
      ),
    );
  }
}
