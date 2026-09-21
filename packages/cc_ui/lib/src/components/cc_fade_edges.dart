import 'package:flutter/widgets.dart';

/// Unconditionally fades child edges (static crop treatment). For scrollables
/// use [CcScrollArea] instead. Alpha-only [ShaderMask] ([BlendMode.dstIn]).
/// Default both edges; set [fadeStart]/[fadeEnd] false for one-sided hints.
class CcFadeEdges extends StatelessWidget {
  /// Creates a [CcFadeEdges].
  const CcFadeEdges({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
    this.fadeExtent = 0.12,
  });

  /// The widget whose edges are faded. Typically a scrollable like
  /// [ListView], [GridView], or [SingleChildScrollView].
  final Widget child;

  /// Orientation of the fade. Vertical fades top/bottom; horizontal fades
  /// left/right. Defaults to [Axis.vertical].
  final Axis axis;

  /// Whether to fade the leading edge (top for vertical, left for horizontal).
  final bool fadeStart;

  /// Whether to fade the trailing edge (bottom for vertical, right for
  /// horizontal).
  final bool fadeEnd;

  /// Fraction of the extent (0.0–0.5) consumed by each faded edge. Larger
  /// values make a more aggressive fade. Defaults to `0.12` (subtle). Use
  /// around `0.3` for a strong hint.
  final double fadeExtent;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    final extent = fadeExtent.clamp(0.0, 0.5).toDouble();
    final solid = extent <= 0.0;
    // fadeStart/fadeEnd are logical edges, so the horizontal gradient runs
    // start→end and mirrors under RTL (the shader callback gets no ambient
    // Directionality, hence the explicit resolve).
    final direction = Directionality.of(context);

    const opaque = Color(0xFFFFFFFF);
    const transparent = Color(0x00FFFFFF);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: isVertical
              ? Alignment.topCenter
              : AlignmentDirectional.centerStart,
          end: isVertical
              ? Alignment.bottomCenter
              : AlignmentDirectional.centerEnd,
          colors: <Color>[
            (fadeStart && !solid) ? transparent : opaque,
            opaque,
            opaque,
            (fadeEnd && !solid) ? transparent : opaque,
          ],
          stops: <double>[0.0, extent, 1.0 - extent, 1.0],
        ).createShader(bounds, textDirection: direction);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
