import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_quick_insert.dart';
import 'package:flutter/widgets.dart';

/// Searchable type picker shown where a connect-drag was dropped on empty
/// canvas. Picking a row creates a node there and links it from the source.
class PipelineEditorDropPicker extends StatelessWidget {
  /// Creates a [PipelineEditorDropPicker].
  const PipelineEditorDropPicker({
    super.key,
    required this.library,
    required this.onPick,
  });

  /// Test key for the drop picker panel.
  static const Key panelKey = ValueKey('pipeline-drop-picker');

  /// Palette (work nodes; triggers stay on the sidebar).
  final NodeTypeLibrary library;

  /// Chosen type.
  final void Function(NodeType type) onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      key: panelKey,
      decoration: ShapeDecoration(
        color: tokens.bgPrimary,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: tokens.borderSecondary),
          borderRadius: AppRadii.brLg,
        ),
        shadows: AppShadows.golden,
      ),
      child: SizedBox(
        width: 280,
        height: 320,
        child: PipelineNodeTypePicker(library: library, onPick: onPick),
      ),
    );
  }
}

/// Dashed stand-in for the node that will land at a connect-drop.
class PipelineEditorGhostSlot extends StatelessWidget {
  /// Creates a [PipelineEditorGhostSlot].
  const PipelineEditorGhostSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CustomPaint(
      painter: _DashedSlotPainter(color: tokens.accent),
    );
  }
}

class _DashedSlotPainter extends CustomPainter {
  _DashedSlotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSlotPainter old) => old.color != color;
}
