import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:collection/collection.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:flutter/widgets.dart';

/// Horizontal cubic handle length used by [PipelineEdgesPainter]. Exposed so
/// the editor's midpoint widgets land on the same curve the painter draws.
const double kPipelineEdgeHandleOffset = 60;

/// Point on a pipeline edge cubic at t = 0.5.
///
/// With the painter's ±[kPipelineEdgeHandleOffset] handles this equals
/// `(start + 3·c1 + 3·c2 + end) / 8`.
Offset pipelineEdgeCubicMidpoint(Offset start, Offset end) {
  final c1 = Offset(start.dx + kPipelineEdgeHandleOffset, start.dy);
  final c2 = Offset(end.dx - kPipelineEdgeHandleOffset, end.dy);
  return (start + c1 * 3.0 + c2 * 3.0 + end) / 8.0;
}

/// Soft dot-grid background shared by the editor canvas and the run-detail
/// canvas. Thin wrapper over the app-wide [DotGridBackground] so both pipeline
/// canvases stay on the shared backdrop.
class PipelineCanvasBackground extends StatelessWidget {
  /// Creates a [PipelineCanvasBackground].
  const PipelineCanvasBackground({super.key, this.offset = Offset.zero});

  /// Pan offset applied to the dot grid so it scrolls in lockstep with the
  /// nodes and edges above it.
  final Offset offset;

  @override
  Widget build(BuildContext context) => DotGridBackground(offset: offset);
}

/// Painter that draws cubic-bezier edges between pipeline nodes. Shared by
/// the editor canvas and the run-detail canvas.
///
/// New optional arguments are additive: the run canvas and existing tests
/// construct this without them and get the original look.
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
  });

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
  /// [steps]' `StepTrigger`s. Each record is start, end, highlight.
  final List<(Offset start, Offset end, bool highlight)> extraSegments;

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final s in steps) s.id: s};
    for (final step in steps) {
      final stepTopLeft = _topLeft(step);
      final to = Offset(
        stepTopLeft.dx + offset.dx,
        stepTopLeft.dy + offset.dy + nodeHeight / 2,
      );
      for (final trigger in step.triggers) {
        for (final src in trigger.sourceStepIds) {
          final from = byId[src];
          if (from == null) {
            continue;
          }
          final fromTopLeft = _topLeft(from);
          final start = Offset(
            fromTopLeft.dx + offset.dx + nodeWidths[from.id]!,
            fromTopLeft.dy + offset.dy + nodeHeight / 2,
          );
          final highlighted =
              highlightStepId != null &&
              highlightColor != null &&
              (highlightStepId == step.id || highlightStepId == from.id);
          final paint = Paint()
            ..color = highlighted ? highlightColor! : color
            ..strokeWidth = highlighted ? 2 : 1.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          _drawArrow(canvas, paint, start, to);
          final key = trigger.routeKey;
          if (paintRouteKeys && key != null && key.isNotEmpty) {
            _paintRouteKey(canvas, pipelineEdgeCubicMidpoint(start, to), key);
          }
        }
      }
    }
    for (final segment in extraSegments) {
      final (start, end, highlighted) = segment;
      final paint = Paint()
        ..color = highlighted && highlightColor != null
            ? highlightColor!
            : color
        ..strokeWidth = highlighted ? 2 : 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawArrow(canvas, paint, start, end);
    }
  }

  /// Top-left of a node: the auto-layout position when supplied, otherwise the
  /// step's stored editor coordinates.
  Offset _topLeft(PipelineStepDefinition step) =>
      positions?[step.id] ?? Offset(step.x ?? 0, step.y ?? 0);

  void _drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) =>
      paintPipelineCubicArrow(canvas, paint, from, to);

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
      old.steps != steps ||
      old.color != color ||
      old.offset != offset ||
      old.nodeHeight != nodeHeight ||
      old.highlightStepId != highlightStepId ||
      old.highlightColor != highlightColor ||
      old.paintRouteKeys != paintRouteKeys ||
      old.routeKeyFill != routeKeyFill ||
      old.routeKeyColor != routeKeyColor ||
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
) {
  final path = Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      from.dx + kPipelineEdgeHandleOffset,
      from.dy,
      to.dx - kPipelineEdgeHandleOffset,
      to.dy,
      to.dx,
      to.dy,
    );
  canvas.drawPath(path, paint);
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
