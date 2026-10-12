import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_edge_geometry.dart';
import 'package:flutter/widgets.dart';

/// Painter that draws cubic-bezier edges between pipeline nodes. Shared by
/// the editor canvas and the run-detail canvas.
class PipelineEdgesPainter extends CustomPainter {
  /// Creates a [PipelineEdgesPainter].
  PipelineEdgesPainter({
    required this.steps,
    required this.color,
    required this.nodeWidths,
    required this.nodeHeight,
    required this.offset,
    this.positions,
    this.highlightStepId,
    this.highlightColor,
    this.paintRouteKeys = false,
    this.routeKeyFill,
    this.routeKeyColor,
    this.extraSegments = const [],
    this.edgeCache,
  }) {
    // Resolved once, here, rather than on every paint: every field this
    // painter reads is final, so the wires it resolves at construction
    // describe it for as long as it is in the tree. Paint then does nothing
    // but iterate them.
    _segments = (edgeCache ?? PipelineEdgeGeometryCache()).sync(
      steps: steps,
      nodeWidths: nodeWidths,
      nodeHeight: nodeHeight,
      positions: positions,
    );
  }

  /// All steps in the rendered graph; the painter walks their triggers to
  /// emit edges.
  final List<PipelineStepDefinition> steps;

  /// Optional per-step top-left positions. When supplied (the run canvas
  /// computes an auto-layout) edges anchor to these instead of the stored
  /// editor coordinates. Null falls back to each step's `x`/`y`.
  final Map<String, Offset>? positions;

  /// Edge colour.
  final Color color;

  /// Rendered width of each node tile, keyed by step id (must cover every
  /// step in [steps]); the run canvas widens title-long nodes, so arrows
  /// anchor to each source tile's own right edge.
  final Map<String, double> nodeWidths;

  /// Height of each node tile.
  final double nodeHeight;

  /// Translation applied to every node position before drawing edges, so
  /// the lines stay anchored to the rendered tiles when the canvas is
  /// centered or panned.
  final Offset offset;

  /// When set with [highlightColor], edges that touch this step draw accented.
  final String? highlightStepId;

  /// Accent colour for edges touching [highlightStepId]. Ignored when null.
  final Color? highlightColor;

  /// When true, router `StepTrigger.routeKey` values are painted as a pill
  /// at the cubic midpoint. The editor canvas leaves this off and uses a
  /// widget at that point instead (so the pill can become a disconnect ×).
  final bool paintRouteKeys;

  /// Fill for a painted route-key pill. Falls back to a wash of [color].
  final Color? routeKeyFill;

  /// Foreground for a painted route-key pill. Falls back to [color].
  final Color? routeKeyColor;

  /// Extra cubics (trigger-proxy → successor) that are not implied by
  /// [steps]' `StepTrigger`s. Each record is start, end, highlight. These are
  /// already in scene space, so the scene translation is not applied to them.
  final List<(Offset start, Offset end, bool highlight)> extraSegments;

  /// Resolved wire geometry, kept across paints. Owning one is what keeps a
  /// drag off the size of the graph: the wires are rebuilt only where the ends
  /// moved. Null falls back to a cache private to this painter.
  final PipelineEdgeGeometryCache? edgeCache;

  /// The wires to draw, resolved at construction. See the constructor.
  late final List<PipelineEdgeSegment> _segments;

  @override
  void paint(Canvas canvas, Size size) {
    final highlight = highlightStepId;
    final accent = highlightColor;
    final accented = highlight != null && accent != null;

    // One translation for the whole layer, applied here rather than folded
    // into every wire: panning or re-basing the scene must not invalidate
    // geometry.
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final base = _strokePaint(color, 1.4);
    final hot = accent == null ? null : _strokePaint(accent, 2);
    for (final segment in _segments) {
      final lit =
          accented &&
          (highlight == segment.fromId || highlight == segment.toId);
      _paintCubicArrow(canvas, lit ? hot! : base, segment.path, segment.end);
      final key = segment.routeKey;
      if (paintRouteKeys && key != null && key.isNotEmpty) {
        _paintRouteKey(
          canvas,
          pipelineEdgeCubicMidpoint(segment.start, segment.end),
          key,
        );
      }
    }
    canvas.restore();

    for (final segment in extraSegments) {
      final (start, end, highlighted) = segment;
      _paintCubicArrow(
        canvas,
        highlighted && hot != null ? hot : base,
        pipelineEdgeCubicPath(start, end),
        end,
      );
    }
  }

  /// Stroke style shared by every wire, accented or not.
  static Paint _strokePaint(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  void _paintRouteKey(Canvas canvas, Offset midpoint, String label) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: routeKeyColor ?? color,
    );
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    const padH = 6.0;
    const padV = 2.0;
    final size = Size(painter.width + padH * 2, painter.height + padV * 2);
    final origin = midpoint - Offset(size.width / 2, size.height / 2);
    final rect = origin & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(999)),
      Paint()..color = routeKeyFill ?? color.withValues(alpha: 0.14),
    );
    painter.paint(canvas, origin + const Offset(padH, padV));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant PipelineEdgesPainter old) =>
      // Content, not identity: the canvases rebuild the step list on every
      // hover and every pointer move, and an identity compare here would
      // repaint every wire on each of them for nothing.
      !const ListEquality<PipelineStepDefinition>().equals(old.steps, steps) ||
      old.color != color ||
      old.offset != offset ||
      old.nodeHeight != nodeHeight ||
      old.highlightStepId != highlightStepId ||
      old.highlightColor != highlightColor ||
      old.paintRouteKeys != paintRouteKeys ||
      old.routeKeyFill != routeKeyFill ||
      old.routeKeyColor != routeKeyColor ||
      old.edgeCache != edgeCache ||
      !const MapEquality<String, double>().equals(old.nodeWidths, nodeWidths) ||
      !const MapEquality<String, Offset>().equals(old.positions, positions) ||
      old.extraSegments != extraSegments;
}

/// Cubic bezier plus a chevron tip, matching [PipelineEdgesPainter].
void paintPipelineCubicArrow(
  Canvas canvas,
  Paint paint,
  Offset from,
  Offset to,
) => _paintCubicArrow(canvas, paint, pipelineEdgeCubicPath(from, to), to);

/// Strokes a wire: its cubic, then the chevron tip pointing at [to].
///
/// Split out so a cached wire — whose cubic is already built — costs one
/// [Canvas.drawPath] and the two head strokes, exactly as a fresh one does.
void _paintCubicArrow(Canvas canvas, Paint paint, Path curve, Offset to) {
  canvas.drawPath(curve, paint);
  const headLen = 8.0;
  final back = Offset(to.dx - headLen, to.dy);
  canvas.drawLine(to, back + const Offset(0, -4), paint);
  canvas.drawLine(to, back + const Offset(0, 4), paint);
}

/// Ghost cubic drawn while the operator is dragging a connect port.
class PipelineGhostEdgePainter extends CustomPainter {
  /// Creates a [PipelineGhostEdgePainter].
  PipelineGhostEdgePainter({
    required this.start,
    required this.end,
    required this.color,
  });

  /// Output-port origin, in the same space as the edges painter.
  final Offset start;

  /// Pointer, in the same space.
  final Offset end;

  /// Stroke colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    paintPipelineCubicArrow(canvas, paint, start, end);
  }

  @override
  bool shouldRepaint(covariant PipelineGhostEdgePainter old) =>
      old.start != start || old.end != end || old.color != color;
}
