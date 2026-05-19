import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/services/node_type_library.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Editor-mode canvas. Renders [definition] as a Stack of node tiles with an
/// edges-overlay painter. Wraps the canvas in a [DragTarget] for adding
/// nodes from the sidebar, and a pan gesture so the user can shift the view.
///
/// We intentionally keep this canvas Flutter-native (rather than reusing
/// flutter_flow_chart's `Dashboard`) so we have full control over selection,
/// drop targeting, panning, and per-node hit testing — and so the look
/// matches the run-detail canvas.
class PipelineEditorCanvas extends ConsumerStatefulWidget {
  /// Creates a [PipelineEditorCanvas].
  const PipelineEditorCanvas({
    super.key,
    required this.definition,
    required this.selectedStepId,
    required this.onSelect,
    required this.onDropNodeType,
  });

  /// The current draft definition being edited.
  final PipelineDefinition definition;

  /// The currently selected step ID, or null.
  final String? selectedStepId;

  /// Called when the user clicks a node.
  final void Function(String stepId) onSelect;

  /// Called when a node type from the sidebar is dropped on the canvas.
  /// The offset is in canvas-local coordinates (already adjusted for any
  /// active centering/pan offsets).
  final void Function(NodeType type, Offset offset) onDropNodeType;

  @override
  ConsumerState<PipelineEditorCanvas> createState() =>
      _PipelineEditorCanvasState();
}

class _PipelineEditorCanvasState extends ConsumerState<PipelineEditorCanvas> {
  static const double _nodeWidth = 180;
  static const double _nodeHeight = 64;

  Offset _panOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final renderable = widget.definition.steps
        .where((s) => s.kind != StepKind.terminal)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerOffset = _centeringOffset(renderable, constraints.biggest);
        final translate = centerOffset + _panOffset;
        return DragTarget<NodeType>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) {
              return;
            }
            final local = box.globalToLocal(details.offset);
            // Convert from screen-local back to canvas-local by undoing the
            // current translation so dropped nodes land where dropped.
            final canvasLocal = local - translate;
            widget.onDropNodeType(details.data, canvasLocal);
          },
          builder: (context, candidates, _) {
            final highlight = candidates.isNotEmpty;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) =>
                  setState(() => _panOffset += d.delta),
              child: Container(
                color: colors.background,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: PipelineCanvasBackground(offset: _panOffset),
                      ),
                    ),
                    if (highlight)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: colors.primary.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    if (renderable.isEmpty)
                      Center(
                        child: Text(
                          l10n.editorEmptyCanvas,
                          style: TextStyle(color: colors.mutedForeground),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: PipelineEdgesPainter(
                            steps: renderable,
                            color: colors.border,
                            nodeWidth: _nodeWidth,
                            nodeHeight: _nodeHeight,
                            offset: translate,
                          ),
                        ),
                      ),
                    ),
                    for (final step in renderable)
                      _buildNode(step, colors, translate),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _Legend(l10n: l10n, colors: colors),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _ResetView(
                        onTap: () => setState(() => _panOffset = Offset.zero),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNode(
    PipelineStepDefinition step,
    FColors colors,
    Offset translate,
  ) {
    final selected = step.id == widget.selectedStepId;
    final position = Offset(step.x ?? 0, step.y ?? 0) + translate;
    final fill = _fillFor(step.kind, colors);
    final border = selected ? colors.primary : colors.border;
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _nodeWidth,
      height: _nodeHeight,
      child: GestureDetector(
        onTap: () => widget.onSelect(step.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: selected ? 2 : 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                step.config.label ?? step.id,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${_kindLabel(step.kind)} · ${step.bodyKey}',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _fillFor(StepKind kind, FColors colors) {
    return switch (kind) {
      StepKind.trigger => colors.primary.withValues(alpha: 0.12),
      StepKind.join => colors.secondary,
      StepKind.router => colors.muted,
      _ => colors.background,
    };
  }

  String _kindLabel(StepKind kind) {
    return switch (kind) {
      StepKind.trigger => 'trigger',
      StepKind.listen => 'listen',
      StepKind.join => 'join',
      StepKind.router => 'router',
      StepKind.forEach => 'forEach',
      StepKind.terminal => 'terminal',
    };
  }

  /// Computes the translation needed to center the node bounding box inside
  /// [viewport]. Empty graphs get zero offset so the empty-state text stays
  /// centered by the surrounding `Center` widget.
  Offset _centeringOffset(
    List<PipelineStepDefinition> nodes,
    Size viewport,
  ) {
    if (nodes.isEmpty) {
      return Offset.zero;
    }
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (final n in nodes) {
      final x = n.x ?? 0;
      final y = n.y ?? 0;
      if (x < minX) {
        minX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (x + _nodeWidth > maxX) {
        maxX = x + _nodeWidth;
      }
      if (y + _nodeHeight > maxY) {
        maxY = y + _nodeHeight;
      }
    }
    final width = maxX - minX;
    final height = maxY - minY;
    final dx = (viewport.width - width) / 2 - minX;
    final dy = (viewport.height - height) / 2 - minY;
    return Offset(dx, dy);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.l10n, required this.colors});

  final AppLocalizations l10n;
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        l10n.editorDragHint,
        style: TextStyle(fontSize: 11, color: colors.foreground),
      ),
    );
  }
}

class _ResetView extends StatelessWidget {
  const _ResetView({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Reset view',
          style: TextStyle(fontSize: 11, color: colors.foreground),
        ),
      ),
    );
  }
}
