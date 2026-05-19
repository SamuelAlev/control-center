import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// A scroll container whose edges fade *only while there is content beyond
/// them* — the scroll-affordance hint driven by real scroll state.
///
/// Wraps a scrollable [child] and listens to the scroll and metrics
/// notifications it bubbles up. While content remains before the viewport the
/// leading edge fades; while content remains after it the trailing edge does.
/// At rest against an edge — or when the content fits entirely — that edge is
/// fully opaque, so the hint can never claim "there is more this way" when
/// there is not (the failure mode of a static [CcFadeEdges] over a scrollable,
/// which dims the first row even when the list cannot scroll up).
///
/// The hint fades the content itself through an alpha-only mask
/// ([BlendMode.dstIn]), so it needs no knowledge of the surface behind it,
/// reads identically in light and dark themes, and can never intercept a
/// pointer the way an overlaid gradient could. Edge transitions animate over
/// ~150 ms and snap instantly under reduced motion.
///
/// Hints are driven by the nearest scrollable descendant (notification depth
/// zero, matching [axis]); scrollables nested deeper are ignored. Content-size
/// changes re-evaluate the hints too (via [ScrollMetricsNotification]), so a
/// list that shrinks below one screenful while being filtered drops its
/// trailing hint without a scroll. Reversed and RTL scrollables keep their
/// hints on the correct sides ([ScrollMetrics.axisDirection] orients the
/// gradient).
///
/// ```dart
/// CcScrollArea(
///   child: ListView(children: rows),
/// )
/// ```
class CcScrollArea extends StatefulWidget {
  /// Creates a [CcScrollArea].
  const CcScrollArea({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeSize = 32.0,
    this.fadeStart = true,
    this.fadeEnd = true,
  });

  /// The scrollable this area decorates, typically a [ListView], [GridView],
  /// or [SingleChildScrollView]. One primary scrollable per area: with several
  /// siblings at the same depth, whichever notified last drives the hints.
  final Widget child;

  /// The scroll axis the hints track. Notifications for the other axis are
  /// ignored. Defaults to [Axis.vertical].
  final Axis axis;

  /// Extent of each faded edge in logical pixels, clamped to half the
  /// viewport. A modest fixed size keeps the hint consistent across container
  /// heights, unlike a proportional fade that balloons in tall panels.
  final double fadeSize;

  /// Whether the leading edge (in scroll direction) may hint. Defaults to
  /// true. Disable for a surface that marks that edge some other way.
  final bool fadeStart;

  /// Whether the trailing edge (in scroll direction) may hint. Defaults to
  /// true.
  final bool fadeEnd;

  @override
  State<CcScrollArea> createState() => CcScrollAreaState();
}

/// State for [CcScrollArea]. Public so tests can assert which edge hints are
/// active without decoding the painted gradient.
class CcScrollAreaState extends State<CcScrollArea> {
  /// Scrollable extent below which an edge counts as flush: sub-pixel layout
  /// rounding must not flash a hint.
  static const double _tolerance = 0.5;

  static const Duration _fadeDuration = Duration(milliseconds: 150);

  static const Color _opaque = Color(0xFFFFFFFF);

  bool _startHinted = false;
  bool _endHinted = false;
  late AxisDirection _axisDirection = _defaultDirection;

  /// Whether the leading edge currently hints at more content.
  @visibleForTesting
  bool get startEdgeVisible => _startHinted;

  /// Whether the trailing edge currently hints at more content.
  @visibleForTesting
  bool get endEdgeVisible => _endHinted;

  AxisDirection get _defaultDirection =>
      widget.axis == Axis.vertical ? AxisDirection.down : AxisDirection.right;

  @override
  void didUpdateWidget(CcScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.axis != widget.axis) {
      _startHinted = false;
      _endHinted = false;
      _axisDirection = _defaultDirection;
    }
  }

  void _readMetrics(ScrollMetrics metrics) {
    if (metrics.axis != widget.axis || !metrics.hasContentDimensions) {
      return;
    }
    final start = metrics.extentBefore > _tolerance;
    final end = metrics.extentAfter > _tolerance;
    if (start == _startHinted &&
        end == _endHinted &&
        metrics.axisDirection == _axisDirection) {
      return;
    }
    setState(() {
      _startHinted = start;
      _endHinted = end;
      _axisDirection = metrics.axisDirection;
    });
  }

  /// The gradient runs from the before-edge to the after-edge, whichever
  /// physical sides those are — a reversed list hints "older content" at the
  /// top, an RTL horizontal list at the right.
  (Alignment, Alignment) get _gradientAlignments => switch (_axisDirection) {
    AxisDirection.down => (Alignment.topCenter, Alignment.bottomCenter),
    AxisDirection.up => (Alignment.bottomCenter, Alignment.topCenter),
    AxisDirection.right => (Alignment.centerLeft, Alignment.centerRight),
    AxisDirection.left => (Alignment.centerRight, Alignment.centerLeft),
  };

  Color _edgeColor(double visibility) =>
      _opaque.withValues(alpha: 1.0 - visibility.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final reduced = context.ccTheme?.reducedMotion ?? false;
    final duration = reduced ? Duration.zero : _fadeDuration;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) {
          _readMetrics(notification.metrics);
        }
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            _readMetrics(notification.metrics);
          }
          return false;
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0,
            end: widget.fadeStart && _startHinted ? 1.0 : 0.0,
          ),
          duration: duration,
          curve: Curves.easeOut,
          builder: (context, startVisibility, _) =>
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: widget.fadeEnd && _endHinted ? 1.0 : 0.0,
                ),
                duration: duration,
                curve: Curves.easeOut,
                builder: (context, endVisibility, _) =>
                    _mask(startVisibility, endVisibility),
              ),
        ),
      ),
    );
  }

  // The mask stays in the tree even when both edges are opaque: swapping it in
  // and out would remount the child and reset its scroll position.
  Widget _mask(double startVisibility, double endVisibility) {
    final (begin, end) = _gradientAlignments;
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        final extent = widget.axis == Axis.vertical
            ? bounds.height
            : bounds.width;
        final fraction = extent <= 0
            ? 0.0
            : (widget.fadeSize / extent).clamp(0.0, 0.5).toDouble();
        return LinearGradient(
          begin: begin,
          end: end,
          colors: <Color>[
            _edgeColor(startVisibility),
            _opaque,
            _opaque,
            _edgeColor(endVisibility),
          ],
          stops: <double>[0.0, fraction, 1.0 - fraction, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: widget.child,
    );
  }
}
