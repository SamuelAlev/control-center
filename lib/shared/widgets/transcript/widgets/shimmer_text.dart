import 'package:flutter/material.dart';

/// A short text label with an animated left-to-right shimmer sweep, used for
/// live "Thinking…" / status lines.
///
/// Honors reduced-motion: when `MediaQuery.disableAnimations` is set the
/// animation never runs and the label renders as static dimmed text, so the
/// state is still conveyed (by the words) without motion.
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

  /// Base text style (color is overridden by the sweep when animating).
  final TextStyle? style;

  /// Dimmed base color of the sweep. Defaults to a faded onSurface.
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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final theme = Theme.of(context);
    final base = widget.baseColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.35);
    final highlight = widget.highlightColor ?? theme.colorScheme.onSurface;
    final style = (widget.style ?? theme.textTheme.labelSmall ?? const TextStyle())
        .copyWith(color: base);

    final label = Text(widget.text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);

    if (reduceMotion) {
      // No motion: convey "live" purely through the (dimmed) words.
      return label;
    }

    return AnimatedBuilder(
      animation: _ensureController(),
      builder: (context, child) {
        final t = _controller!.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final dx = bounds.width;
            return LinearGradient(
              begin: Alignment(-1 + 3 * t, 0),
              end: Alignment(1 + 3 * t, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(Rect.fromLTWH(0, 0, dx, bounds.height));
          },
          child: child,
        );
      },
      child: label,
    );
  }
}
