import 'package:flutter/widgets.dart';

/// Fades the edges of a scrollable (or any) child to signal that it scrolls.
///
/// Wraps [child] in an alpha-only [ShaderMask], so long lists stop looking
/// static and reveal that there is more content beyond the visible bounds.
/// Because the mask is pure alpha ([BlendMode.dstIn]) it works identically in
/// light and dark mode — no theme awareness required.
///
/// By default both the start and end edges fade. For one-sided hints (a common
/// choice — once a user has scrolled, they only need to know there is more in
/// one direction) set [fadeStart] or [fadeEnd] to `false`.
///
/// ```dart
/// CcFadeEdges(
///   child: ListView(children: items),
/// )
/// ```
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

    const opaque = Color(0xFFFFFFFF);
    const transparent = Color(0x00FFFFFF);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: <Color>[
            (fadeStart && !solid) ? transparent : opaque,
            opaque,
            opaque,
            (fadeEnd && !solid) ? transparent : opaque,
          ],
          stops: <double>[0.0, extent, 1.0 - extent, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
