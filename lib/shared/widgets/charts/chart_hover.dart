import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

part 'chart_point_flyout.dart';

/// How x values are laid out across the plot.
///
/// Line spots sit on the edges (`0` and `n-1`). Bar groups with
/// `BarChartAlignment.spaceAround` sit in the middle of `n` equal slots.
enum ChartHoverAxis {
  /// First and last points sit on the plot's start/end edges.
  line,

  /// Groups are centered in `n` equal slots (fl_chart `spaceAround`).
  barSpaceAround,
}

/// One series' marker at the hovered x.
@immutable
class ChartHoverDot {
  /// Creates a [ChartHoverDot].
  const ChartHoverDot({required this.y, required this.color});

  /// Pixel y of the marker, in the host's coordinate space (top-origin).
  final double y;

  /// Series color for the marker.
  final Color color;

  /// Linear interpolation used while the flyout travels between days.
  static ChartHoverDot lerp(ChartHoverDot a, ChartHoverDot b, double t) =>
      ChartHoverDot(
        y: lerpDouble(a.y, b.y, t)!,
        color: Color.lerp(a.color, b.color, t)!,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartHoverDot && y == other.y && color == other.color;

  @override
  int get hashCode => Object.hash(y, color);
}

/// Where the hover chrome (hairline, dots, flyout) should sit.
@immutable
class ChartHoverGeometry {
  /// Creates a [ChartHoverGeometry].
  const ChartHoverGeometry({required this.x, required this.dots});

  /// Pixel x of the hovered column, in the host's coordinate space.
  final double x;

  /// One marker per series, in series order.
  final List<ChartHoverDot> dots;

  /// The highest (smallest y) marker — the flyout anchors above this.
  Offset get topAnchor {
    var minY = dots.first.y;
    for (final dot in dots) {
      if (dot.y < minY) {
        minY = dot.y;
      }
    }
    return Offset(x, minY);
  }

  /// Linear interpolation used while the flyout travels between days.
  static ChartHoverGeometry lerp(
    ChartHoverGeometry a,
    ChartHoverGeometry b,
    double t,
  ) {
    final n = a.dots.length < b.dots.length ? a.dots.length : b.dots.length;
    return ChartHoverGeometry(
      x: lerpDouble(a.x, b.x, t)!,
      dots: [
        for (var i = 0; i < n; i++) ChartHoverDot.lerp(a.dots[i], b.dots[i], t),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartHoverGeometry &&
          x == other.x &&
          listEquals(dots, other.dots);

  @override
  int get hashCode => Object.hash(x, Object.hashAll(dots));
}

/// Maps a plot-local x fraction `0..1` onto a point index.
int chartHoverIndexForFx(double fx, int count, ChartHoverAxis axis) {
  if (count <= 1) {
    return 0;
  }
  final clamped = fx.clamp(0.0, 1.0);
  return switch (axis) {
    ChartHoverAxis.line => (clamped * (count - 1)).round().clamp(0, count - 1),
    ChartHoverAxis.barSpaceAround => (clamped * count).floor().clamp(
      0,
      count - 1,
    ),
  };
}

/// Maps a point index onto a plot-local x fraction `0..1`.
double chartHoverFxForIndex(int index, int count, ChartHoverAxis axis) {
  if (count <= 1) {
    return 0.5;
  }
  return switch (axis) {
    ChartHoverAxis.line => index / (count - 1),
    ChartHoverAxis.barSpaceAround => (index + 0.5) / count,
  };
}

/// Pixel geometry for the hovered column, matching fl_chart's plot inset.
ChartHoverGeometry chartHoverGeometry({
  required Size size,
  required EdgeInsets plotPadding,
  required int index,
  required int count,
  required ChartHoverAxis axis,
  required List<({double value, Color color})> seriesAt,
  required double maxY,
}) {
  final plot = Rect.fromLTRB(
    plotPadding.left,
    plotPadding.top,
    size.width - plotPadding.right,
    size.height - plotPadding.bottom,
  );
  final x = plot.left + chartHoverFxForIndex(index, count, axis) * plot.width;
  final scale = maxY <= 0 ? 0.0 : 1 / maxY;
  return ChartHoverGeometry(
    x: x,
    dots: [
      for (final series in seriesAt)
        ChartHoverDot(
          y:
              plot.top +
              (1 - (series.value * scale).clamp(0.0, 1.0)) * plot.height,
          color: series.color,
        ),
    ],
  );
}

/// Sticky hovered index: nearest column while the pointer is inside, hide
/// only after a short grace once it leaves.
///
/// The grace absorbs the frame of empty hits at the plot edge so the flyout
/// does not flicker while sweeping across a chart.
class ChartHoverController extends ChangeNotifier {
  /// Creates a [ChartHoverController].
  ChartHoverController({this.hideDelay = CcMotion.fast});

  /// Wait after the pointer leaves before clearing [index].
  final Duration hideDelay;

  Timer? _hide;
  int? _index;

  /// The hovered column, or `null` when the flyout should hide.
  int? get index => _index;

  /// The pointer is over [index].
  void pointerAt(int index) {
    _hide?.cancel();
    _hide = null;
    if (_index == index) {
      return;
    }
    _index = index;
    notifyListeners();
  }

  /// The pointer left the plot. [index] clears after [hideDelay].
  void pointerLeft() {
    if (_index == null) {
      return;
    }
    _hide?.cancel();
    _hide = Timer(hideDelay, () {
      _hide = null;
      if (_index == null) {
        return;
      }
      _index = null;
      notifyListeners();
    });
  }

  /// Drop hover immediately (data changed under the pointer).
  void clear() {
    _hide?.cancel();
    _hide = null;
    if (_index == null) {
      return;
    }
    _index = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }
}

/// Fills a plot and shows a [ChartPointFlyout] that travels between columns.
///
/// Hover is resolved from the pointer's x against [plotPadding] — the whole
/// plot is hittable, not a 10px bubble around a dot — so sweeping along a
/// line keeps the flyout up and moving instead of flickering between days.
class ChartHoverHost extends StatefulWidget {
  /// Creates a [ChartHoverHost].
  const ChartHoverHost({
    super.key,
    required this.plotPadding,
    required this.pointCount,
    required this.maxY,
    required this.seriesColors,
    required this.seriesValuesAt,
    required this.flyoutBuilder,
    required this.child,
    this.axis = ChartHoverAxis.line,
  });

  /// Inset of the plot inside [child] (axis gutters). Physical edges: fl_chart
  /// lays axes out on the left/bottom in every locale.
  ///
  /// RTL carve-out: chart canvases stay LTR.
  final EdgeInsets plotPadding;

  /// Number of columns (days, buckets).
  final int pointCount;

  /// Plot ceiling, matching the chart's `maxY`.
  final double maxY;

  /// Series colors, parallel to [seriesValuesAt].
  final List<Color> seriesColors;

  /// Y values of every series at a column.
  final List<double> Function(int index) seriesValuesAt;

  /// Flyout body for the hovered column.
  final Widget Function(int index) flyoutBuilder;

  /// The chart. Its own tooltip/touch should be disabled — this host owns hover.
  final Widget child;

  /// How columns are spaced across the plot.
  final ChartHoverAxis axis;

  @override
  State<ChartHoverHost> createState() => _ChartHoverHostState();
}

class _ChartHoverHostState extends State<ChartHoverHost> {
  final _hover = ChartHoverController();

  @override
  void didUpdateWidget(ChartHoverHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pointCount != widget.pointCount) {
      _hover.clear();
    }
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  void _at(Offset local, Size size) {
    if (widget.pointCount <= 0) {
      return;
    }
    final plotWidth = size.width - widget.plotPadding.horizontal;
    if (plotWidth <= 0) {
      return;
    }
    final fx = (local.dx - widget.plotPadding.left) / plotWidth;
    _hover.pointerAt(chartHoverIndexForFx(fx, widget.pointCount, widget.axis));
  }

  ChartHoverGeometry? _geometry(Size size) {
    final index = _hover.index;
    if (index == null || index < 0 || index >= widget.pointCount) {
      return null;
    }
    if (widget.seriesColors.isEmpty) {
      return null;
    }
    final values = widget.seriesValuesAt(index);
    return chartHoverGeometry(
      size: size,
      plotPadding: widget.plotPadding,
      index: index,
      count: widget.pointCount,
      axis: widget.axis,
      seriesAt: [
        for (var i = 0; i < widget.seriesColors.length && i < values.length; i++)
          (value: values[i], color: widget.seriesColors[i]),
      ],
      maxY: widget.maxY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          opaque: true,
          onHover: (event) => _at(event.localPosition, size),
          onExit: (_) => _hover.pointerLeft(),
          child: Listener(
            onPointerDown: (event) => _at(event.localPosition, size),
            onPointerMove: (event) => _at(event.localPosition, size),
            onPointerUp: (event) {
              if (event.kind == PointerDeviceKind.touch ||
                  event.kind == PointerDeviceKind.stylus) {
                _hover.pointerLeft();
              }
            },
            onPointerCancel: (_) => _hover.pointerLeft(),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                widget.child,
                ListenableBuilder(
                  listenable: _hover,
                  builder: (context, _) {
                    final index = _hover.index;
                    return ChartPointFlyout(
                      geometry: _geometry(size),
                      plotPadding: widget.plotPadding,
                      child: index == null
                          ? null
                          : widget.flyoutBuilder(index),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
