import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Scroll container that fades an edge only while content remains beyond it.
/// Prefer over static [CcFadeEdges] on scrollables (those dim content at rest).
///
/// The hint is a short scrim painted over the edge, the same color as the
/// surface behind the scroll view, so the list itself is never masked. A
/// [ShaderMask] over the whole viewport would force an offscreen layer and
/// disable compositor scrolling — the list would re-raster every frame.
///
/// [fadeColor] must match that surface (page canvas by default, `panel` or
/// `bgPrimary` when the area sits in a dialog or flyout). The scrim never
/// intercepts pointers. Animates with [CcMotion.moderate] (short fade under
/// reduced motion). Driven by the nearest scrollable of matching [axis]
/// (depth zero); nested deeper ignored. [ScrollMetricsNotification]
/// re-evaluates on content-size change. [ScrollMetrics.axisDirection]
/// orients reversed/RTL hints.
class CcScrollArea extends StatefulWidget {
  /// Creates a [CcScrollArea].
  const CcScrollArea({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeSize = 32.0,
    this.fadeStart = true,
    this.fadeEnd = true,
    this.fadeColor,
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

  /// Color the edge scrim fades toward. Defaults to the theme canvas, which
  /// is the page behind the inbox, PR queue and pipelines. Pass the flyout
  /// or dialog fill when this area sits on one of those, or the scrim reads
  /// as a band of the wrong color.
  final Color? fadeColor;

  @override
  State<CcScrollArea> createState() => CcScrollAreaState();
}

/// State for [CcScrollArea]. Public so tests can assert which edge hints are
/// active without decoding the painted gradient.
class CcScrollAreaState extends State<CcScrollArea> {
  /// Scrollable extent below which an edge counts as flush: sub-pixel layout
  /// rounding must not flash a hint.
  static const double _tolerance = 0.5;

  static const Duration _fadeDuration = CcMotion.moderate;

  bool _startHinted = false;
  bool _endHinted = false;
  late AxisDirection _axisDirection = _defaultDirection;
  bool _applyScheduled = false;
  ScrollMetrics? _pendingMetrics;

  /// Whether the leading edge currently hints at more content.
  @visibleForTesting
  bool get startEdgeVisible => _startHinted;

  /// Whether the trailing edge currently hints at more content.
  @visibleForTesting
  bool get endEdgeVisible => _endHinted;

  // Before the first metrics arrive, assume the ambient reading direction for
  // a horizontal area (the metrics then confirm or correct it).
  AxisDirection get _defaultDirection => widget.axis == Axis.vertical
      ? AxisDirection.down
      : textDirectionToAxisDirection(Directionality.of(context));

  @override
  void didUpdateWidget(CcScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.axis != widget.axis) {
      _startHinted = false;
      _endHinted = false;
      _axisDirection = _defaultDirection;
      _pendingMetrics = null;
    }
  }

  @override
  void dispose() {
    _pendingMetrics = null;
    super.dispose();
  }

  void _readMetrics(ScrollMetrics metrics) {
    if (metrics.axis != widget.axis || !metrics.hasContentDimensions) {
      return;
    }
    // [ScrollPosition.applyContentDimensions] dispatches both
    // [ScrollMetricsNotification] and [ScrollEndNotification] from
    // [RenderViewport.performLayout] (a ballistic fling that relayouts
    // newly-attached slivers is the usual trigger). setState during that
    // phase schedules a build in the middle of the frame.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      _pendingMetrics = metrics;
      if (!_applyScheduled) {
        _applyScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyScheduled = false;
          final pending = _pendingMetrics;
          _pendingMetrics = null;
          if (pending != null && mounted) {
            _commitMetrics(pending);
          }
        });
      }
      return;
    }
    _commitMetrics(metrics);
  }

  void _commitMetrics(ScrollMetrics metrics) {
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

  // RTL carve-out: scrim edges are physical — they come from the scrollable's
  // live [AxisDirection], which already encodes text direction for a
  // horizontal list.
  @override
  Widget build(BuildContext context) {
    final duration = CcMotion.resolveFade(context, _fadeDuration);
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

  // The scrollable stays the first child of a stable [Stack] for the life of
  // this area. Adding or removing a scrim sibling must not remount it — that
  // is what used to reset the scroll position when a hint appeared.
  Widget _mask(double startVisibility, double endVisibility) {
    final color = widget.fadeColor ?? context.ds.canvas;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (startVisibility > 0)
          _scrim(atStart: true, visibility: startVisibility, color: color),
        if (endVisibility > 0)
          _scrim(atStart: false, visibility: endVisibility, color: color),
      ],
    );
  }

  /// A [fadeSize]-tall (or wide) gradient on the physical edge that [atStart]
  /// names for the current [AxisDirection]. Opaque at the outer edge, clear
  /// inward, so content appears to fade into [color].
  Widget _scrim({
    required bool atStart,
    required double visibility,
    required Color color,
  }) {
    final extent = widget.fadeSize;
    final (begin, end) = _scrimAlignments(atStart);
    final band = IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: <Color>[
              color.withValues(alpha: visibility.clamp(0.0, 1.0)),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
    return switch (_axisDirection) {
      AxisDirection.down when atStart => Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: extent,
        child: band,
      ),
      AxisDirection.down => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: extent,
        child: band,
      ),
      AxisDirection.up when atStart => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: extent,
        child: band,
      ),
      AxisDirection.up => Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: extent,
        child: band,
      ),
      AxisDirection.right when atStart => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: extent,
        child: band,
      ),
      AxisDirection.right => Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: extent,
        child: band,
      ),
      AxisDirection.left when atStart => Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: extent,
        child: band,
      ),
      AxisDirection.left => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: extent,
        child: band,
      ),
    };
  }

  /// Gradient runs from the outer edge inward, so the opaque stop sits on the
  /// physical side that has more content.
  (Alignment, Alignment) _scrimAlignments(bool atStart) =>
      switch (_axisDirection) {
        AxisDirection.down when atStart => (
          Alignment.topCenter,
          Alignment.bottomCenter,
        ),
        AxisDirection.down => (Alignment.bottomCenter, Alignment.topCenter),
        AxisDirection.up when atStart => (
          Alignment.bottomCenter,
          Alignment.topCenter,
        ),
        AxisDirection.up => (Alignment.topCenter, Alignment.bottomCenter),
        AxisDirection.right when atStart => (
          Alignment.centerLeft,
          Alignment.centerRight,
        ),
        AxisDirection.right => (Alignment.centerRight, Alignment.centerLeft),
        AxisDirection.left when atStart => (
          Alignment.centerRight,
          Alignment.centerLeft,
        ),
        AxisDirection.left => (Alignment.centerLeft, Alignment.centerRight),
      };
}
