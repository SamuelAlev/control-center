import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_drop_picker.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:flutter/widgets.dart';

/// Viewport-space ghost wire and insert slot. Painted outside the
/// InteractiveViewer child so a live connect-drag cannot rebase scene shift.
class PipelineEditorConnectOverlay extends StatelessWidget {
  /// Creates a [PipelineEditorConnectOverlay].
  const PipelineEditorConnectOverlay({
    super.key,
    required this.transform,
    required this.shift,
    required this.color,
    this.startScene,
    this.endScene,
    this.insertTopLeft,
  });

  /// Viewer matrix (definition/scene → viewport).
  final TransformationController transform;

  /// Frozen scene shift for [insertTopLeft].
  final Offset shift;

  /// Wire stroke.
  final Color color;

  /// Output-port origin in scene space.
  final Offset? startScene;

  /// Pointer or hover-port in scene space.
  final Offset? endScene;

  /// Definition-space top-left of the insert ghost, or null.
  final Offset? insertTopLeft;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: transform,
        builder: (context, _) {
          final matrix = transform.value;
          final scale = matrix.getMaxScaleOnAxis();
          final children = <Widget>[];
          final start = startScene;
          final end = endScene;
          if (start != null && end != null) {
            children.add(
              Positioned.fill(
                child: CustomPaint(
                  painter: PipelineGhostEdgePainter(
                    start: MatrixUtils.transformPoint(matrix, start),
                    end: MatrixUtils.transformPoint(matrix, end),
                    color: color,
                  ),
                ),
              ),
            );
          }
          final slot = insertTopLeft;
          if (slot != null) {
            final origin = MatrixUtils.transformPoint(matrix, slot + shift);
            children.add(
              Positioned(
                // RTL carve-out: DAG canvases stay LTR; the ghost follows
                // canvas coordinates, not reading direction.
                left: origin.dx,
                top: origin.dy,
                child: Transform.scale(
                  alignment: Alignment.topLeft,
                  scale: scale,
                  child: const SizedBox(
                    width: kPipelineEditorNodeWidth,
                    height: kPipelineEditorNodeHeight,
                    child: PipelineEditorGhostSlot(),
                  ),
                ),
              ),
            );
          }
          return Stack(children: children);
        },
      ),
    );
  }
}
