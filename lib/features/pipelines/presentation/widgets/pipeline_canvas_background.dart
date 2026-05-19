import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:collection/collection.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:flutter/material.dart';

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
class PipelineEdgesPainter extends CustomPainter {
  /// Creates a [PipelineEdgesPainter].
  PipelineEdgesPainter({
    required this.steps,
    required this.color,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.offset,
    this.positions,
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

  /// Width of each node tile.
  final double nodeWidth;

  /// Height of each node tile.
  final double nodeHeight;

  /// Translation applied to every node position before drawing edges, so
  /// the lines stay anchored to the rendered tiles when the canvas is
  /// centered or panned.
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
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
            fromTopLeft.dx + offset.dx + nodeWidth,
            fromTopLeft.dy + offset.dy + nodeHeight / 2,
          );
          _drawArrow(canvas, paint, start, to);
        }
      }
    }
  }

  /// Top-left of a node: the auto-layout position when supplied, otherwise the
  /// step's stored editor coordinates.
  Offset _topLeft(PipelineStepDefinition step) =>
      positions?[step.id] ?? Offset(step.x ?? 0, step.y ?? 0);

  void _drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(
        from.dx + 60,
        from.dy,
        to.dx - 60,
        to.dy,
        to.dx,
        to.dy,
      );
    canvas.drawPath(path, paint);
    const headLen = 8.0;
    final tip = to;
    final back = Offset(to.dx - headLen, to.dy);
    canvas.drawLine(tip, back + const Offset(0, -4), paint);
    canvas.drawLine(tip, back + const Offset(0, 4), paint);
  }

  @override
  bool shouldRepaint(covariant PipelineEdgesPainter old) =>
      old.steps != steps ||
      old.color != color ||
      old.offset != offset ||
      old.nodeWidth != nodeWidth ||
      old.nodeHeight != nodeHeight ||
      !const MapEquality<String, Offset>().equals(old.positions, positions);
}
