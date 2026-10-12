import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_edge_geometry.dart';
import 'package:flutter/widgets.dart';

/// One scene-space slot in a pipeline canvas.
///
/// Carries the three things every tile needs and no tile should own: its
/// [Positioned] geometry, a repaint layer of its own so a hover, a spinner or
/// a drag on one tile cannot dirty its neighbours or the backdrop under them,
/// and a graph-id key so reordering the graph cannot hand one node's state to
/// another.
class PipelineSceneSlot extends StatelessWidget {
  /// Creates a [PipelineSceneSlot].
  const PipelineSceneSlot({
    super.key,
    required this.left,
    required this.top,
    this.width,
    this.height,
    required this.child,
  });

  /// Scene-space left edge.
  final double left;

  /// Scene-space top edge.
  final double top;

  /// Fixed width, or null to let [child] size itself (edge handles).
  final double? width;

  /// Fixed height, or null to let [child] size itself (edge handles).
  final double? height;

  /// Slot contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // RTL carve-out: a DAG canvas — node placement is canvas-coordinate math
    // over the laid-out graph, and diagram canvases stay LTR.
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: RepaintBoundary(child: child),
    );
  }
}

/// The wire layer of a pipeline canvas: every edge, in one repaint boundary.
///
/// The resolved geometry lives in a [PipelineEdgeGeometryCache] owned here,
/// not in the painter. Painters are rebuilt with their widget and both canvases
/// rebuild on hover and on every pointer move, while a [State] survives both —
/// so this is the one place a cache can outlive the frames it is there to
/// avoid rebuilding.
class PipelineEdgeLayer extends StatefulWidget {
  /// Creates a [PipelineEdgeLayer].
  const PipelineEdgeLayer({
    super.key,
    required this.steps,
    required this.color,
    required this.nodeWidths,
    required this.nodeHeight,
    required this.offset,
    this.positions,
    this.highlightStepId,
    this.highlightColor,
  });

  /// All steps in the rendered graph; their triggers imply the wires.
  final List<PipelineStepDefinition> steps;

  /// Wire colour.
  final Color color;

  /// Rendered width of each tile, keyed by step id.
  final Map<String, double> nodeWidths;

  /// Height of each tile.
  final double nodeHeight;

  /// Scene translation, applied at paint time.
  final Offset offset;

  /// Auto-layout positions, when the canvas does not use stored coordinates.
  final Map<String, Offset>? positions;

  /// Step whose incident wires draw accented, when set with [highlightColor].
  final String? highlightStepId;

  /// Accent colour for [highlightStepId].
  final Color? highlightColor;

  @override
  State<PipelineEdgeLayer> createState() => _PipelineEdgeLayerState();
}

class _PipelineEdgeLayerState extends State<PipelineEdgeLayer> {
  final PipelineEdgeGeometryCache _cache = PipelineEdgeGeometryCache();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: PipelineEdgesPainter(
            steps: widget.steps,
            color: widget.color,
            nodeWidths: widget.nodeWidths,
            nodeHeight: widget.nodeHeight,
            offset: widget.offset,
            positions: widget.positions,
            highlightStepId: widget.highlightStepId,
            highlightColor: widget.highlightColor,
            edgeCache: _cache,
          ),
        ),
      ),
    );
  }
}
