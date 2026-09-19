import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_connect_overlay.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_controls.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_drop_picker.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_scene.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:flutter/widgets.dart';

/// Viewport chrome around the editor scene: grid, viewer, empty state, hint,
/// zoom/tidy. Lives beside PipelineEditorCanvas so that file stays focused
/// on interaction state.
class PipelineEditorViewport extends StatelessWidget {
  /// Creates a [PipelineEditorViewport].
  const PipelineEditorViewport({
    super.key,
    required this.viewerKey,
    required this.transform,
    required this.wheelPan,
    required this.scene,
    required this.onViewport,
    required this.dropping,
    required this.empty,
    required this.definition,
    required this.library,
    required this.triggers,
    required this.selectedStepId,
    required this.selectedTriggerId,
    required this.dragPositions,
    required this.connectFrom,
    required this.connectFromTriggerId,
    required this.connectPointerScene,
    required this.connectHoverId,
    required this.lockViewer,
    required this.onSelect,
    required this.onSelectTrigger,
    required this.onAddTrigger,
    required this.onMoveUpdate,
    required this.onMoveEnd,
    required this.onConnectDragStart,
    required this.onTriggerConnectDragStart,
    required this.onConnectDragUpdate,
    required this.onConnectDragEnd,
    this.onConnectDragCancel,
    this.onConnectHandleHover,
    this.insertTopLeft,
    required this.showInsertPicker,
    required this.onInsertPick,
    required this.onCancelInsert,
    required this.onDisconnect,
    required this.onFit,
    required this.onTidy,
    required this.viewport,
  });

  /// Hit-test root for pointer → scene conversion.
  final Key viewerKey;

  /// Shared with the zoom controls.
  final TransformationController transform;

  /// Rewrites a mouse wheel into a pan.
  final CanvasWheelPan wheelPan;

  /// Shift + child size for the viewer.
  final PipelineEditorScene scene;

  /// Captures the laid-out viewport for fit-to-content.
  final ValueChanged<Size> onViewport;

  /// True while a palette entry is hovering the drop target.
  final bool dropping;

  /// True when no renderable tiles exist.
  final bool empty;

  /// Draft graph.
  final PipelineDefinition definition;

  /// Palette.
  final NodeTypeLibrary library;

  /// Template start triggers.
  final List<PipelineTrigger> triggers;

  /// Selected body step, or null.
  final String? selectedStepId;

  /// Selected trigger proxy, or null.
  final String? selectedTriggerId;

  /// Live drag overrides.
  final Map<String, Offset> dragPositions;

  /// Connect source (a step id; trigger ports use the entry).
  final String? connectFrom;

  /// Trigger proxy that started the in-flight connect, or null.
  final String? connectFromTriggerId;

  /// Port-drag pointer in scene space.
  final Offset? connectPointerScene;

  /// Valid hover target during a port drag.
  final String? connectHoverId;

  /// True while a connect-drag is in flight or the pointer is over a handle.
  /// InteractiveViewer still installs a scale recognizer when pan is off, so
  /// locking before pointer-down is what stops the first drag from panning.
  final bool lockViewer;

  /// Body-tile tap.
  final void Function(String id) onSelect;

  /// Trigger-proxy tap.
  final void Function(String triggerId) onSelectTrigger;

  /// Ghost picker or palette drop.
  final void Function(String eventType, [Offset? canvasOffset]) onAddTrigger;

  /// Tile pan.
  final void Function(String id, Offset delta) onMoveUpdate;

  /// Tile pan end.
  final void Function(String id) onMoveEnd;

  /// Port pan start on a body step.
  final void Function(String id) onConnectDragStart;

  /// Port pan start on a trigger proxy.
  final void Function(String triggerId) onTriggerConnectDragStart;

  /// Port pan update.
  final void Function(Offset global) onConnectDragUpdate;

  /// Port pan end.
  final void Function(Offset global) onConnectDragEnd;

  /// Port pan cancelled.
  final VoidCallback? onConnectDragCancel;

  /// Pointer entered/left an output handle.
  final ValueChanged<bool>? onConnectHandleHover;

  /// Definition-space top-left of the ghost insert slot, or null.
  final Offset? insertTopLeft;

  /// True after a connect-drag was dropped on empty canvas.
  final bool showInsertPicker;

  /// Drop-picker pick.
  final void Function(NodeType type) onInsertPick;

  /// Barrier tap from the drop picker.
  final VoidCallback onCancelInsert;

  /// Edge handle.
  final void Function(String from, String to) onDisconnect;

  /// Fit-to-content.
  final VoidCallback onFit;

  /// Auto-layout.
  final VoidCallback onTidy;

  /// Latest viewport, read by zoom controls on press.
  final ValueGetter<Size> viewport;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: transform,
            builder: (context, _) {
              final m = transform.value;
              return DotGridBackground(
                offset: Offset(m.getTranslation().x, m.getTranslation().y),
                scale: m.getMaxScaleOnAxis(),
              );
            },
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            onViewport(constraints.biggest);
            return Listener(
              key: viewerKey,
              onPointerSignal: (event) => wheelPan.onPointerSignal(
                event,
                viewport: constraints.biggest,
                canvas: scene.size,
                boundaryMargin: kPipelineEditorBoundaryMargin,
              ),
              child: InteractiveViewer(
                transformationController: transform,
                constrained: false,
                panEnabled: !lockViewer,
                scaleEnabled: !lockViewer,
                minScale: kPipelineEditorMinScale,
                maxScale: kPipelineEditorMaxScale,
                boundaryMargin: const EdgeInsets.all(
                  kPipelineEditorBoundaryMargin,
                ),
                onInteractionStart: (_) => wheelPan.beginInteraction(),
                child: SizedBox(
                  width: scene.size.width,
                  height: scene.size.height,
                  child: PipelineEditorSceneStack(
                    shift: scene.shift,
                    tokens: tokens,
                    l10n: l10n,
                    definition: definition,
                    library: library,
                    triggers: triggers,
                    selectedStepId: selectedStepId,
                    selectedTriggerId: selectedTriggerId,
                    dragPositions: dragPositions,
                    connectFrom: connectFrom,
                    connectFromTriggerId: connectFromTriggerId,
                    connectHoverId: connectHoverId,
                    onSelect: onSelect,
                    onSelectTrigger: onSelectTrigger,
                    onAddTrigger: onAddTrigger,
                    onMoveUpdate: onMoveUpdate,
                    onMoveEnd: onMoveEnd,
                    onConnectDragStart: onConnectDragStart,
                    onTriggerConnectDragStart: onTriggerConnectDragStart,
                    onConnectDragUpdate: onConnectDragUpdate,
                    onConnectDragEnd: onConnectDragEnd,
                    onConnectDragCancel: onConnectDragCancel,
                    onConnectHandleHover: onConnectHandleHover,
                    onDisconnect: onDisconnect,
                  ),
                ),
              ),
            );
          },
        ),
        if (dropping)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: tokens.textPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),
        if (empty)
          Center(
            child: Text(
              l10n.editorEmptyCanvas,
              style: TextStyle(color: tokens.textTertiary),
            ),
          ),
        if (connectFrom != null || insertTopLeft != null)
          Positioned.fill(
            child: PipelineEditorConnectOverlay(
              transform: transform,
              shift: scene.shift,
              color: tokens.accent,
              startScene: _ghostStart(scene.shift),
              endScene: _ghostEnd(scene.shift),
              insertTopLeft: insertTopLeft,
            ),
          ),
        if (showInsertPicker && insertTopLeft != null)
          _DropPickerOverlay(
            insertTopLeft: insertTopLeft!,
            shift: scene.shift,
            transform: transform,
            library: library,
            onPick: onInsertPick,
            onCancel: onCancelInsert,
          ),
        PositionedDirectional(
          start: kCanvasControlInset,
          bottom: kCanvasControlInset,
          child: PipelineEditorHintChip(label: l10n.pipelineEditorHint),
        ),
        PositionedDirectional(
          end: kCanvasControlInset,
          bottom: kCanvasControlInset,
          child: PipelineEditorControls(
            controller: transform,
            viewport: viewport,
            onFit: onFit,
            onTidy: onTidy,
          ),
        ),
      ],
    );
  }

  Offset? _ghostStart(Offset shift) {
    final from = connectFrom;
    if (from == null) {
      return null;
    }
    return pipelineEditorConnectGhostStart(
      connectFrom: from,
      positions: {
        for (final step in definition.steps)
          if (step.kind != StepKind.terminal)
            step.id: pipelineEditorNodeOffset(step, dragPositions),
      },
      shift: shift,
    );
  }

  Offset? _ghostEnd(Offset shift) {
    final hover = connectHoverId;
    if (hover != null) {
      for (final step in definition.steps) {
        if (step.id == hover) {
          return pipelineEditorInputPortScene(
            pipelineEditorNodeOffset(step, dragPositions),
            shift,
          );
        }
      }
    }
    final slot = insertTopLeft;
    if (slot != null) {
      return pipelineEditorInputPortScene(slot, shift);
    }
    return connectPointerScene;
  }
}

/// Viewport-space type picker next to the ghost insert slot.
class _DropPickerOverlay extends StatelessWidget {
  const _DropPickerOverlay({
    required this.insertTopLeft,
    required this.shift,
    required this.transform,
    required this.library,
    required this.onPick,
    required this.onCancel,
  });

  final Offset insertTopLeft;
  final Offset shift;
  final TransformationController transform;
  final NodeTypeLibrary library;
  final void Function(NodeType type) onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final origin = _pickerOrigin(constraints.biggest);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCancel,
                ),
              ),
              Positioned(
                // RTL carve-out: DAG canvases stay LTR; picker follows the
                // ghost slot in canvas coordinates, not reading direction.
                left: origin.dx,
                top: origin.dy,
                child: PipelineEditorDropPicker(
                  library: library,
                  onPick: onPick,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _pickerOrigin(Size viewport) {
    const pickerW = 280.0;
    const pickerH = 320.0;
    const gap = 12.0;
    final scene = Offset(
      insertTopLeft.dx + shift.dx + kPipelineEditorNodeWidth + gap,
      insertTopLeft.dy + shift.dy,
    );
    final view = MatrixUtils.transformPoint(transform.value, scene);
    var x = view.dx;
    var y = view.dy;
    if (x + pickerW > viewport.width - 8) {
      x = viewport.width - pickerW - 8;
    }
    if (y + pickerH > viewport.height - 8) {
      y = viewport.height - pickerH - 8;
    }
    return Offset(x < 8 ? 8 : x, y < 8 ? 8 : y);
  }
}
