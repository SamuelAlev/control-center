import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_shortcuts.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_viewport.dart';
import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Editor-mode canvas. Pan/zoom via [InteractiveViewer], tiles are draggable,
/// edges are drawn by PipelineEdgesPainter, and new nodes drop from the
/// sidebar onto the definition-space point under the pointer.
class PipelineEditorCanvas extends ConsumerStatefulWidget {
  /// Creates a [PipelineEditorCanvas].
  const PipelineEditorCanvas({
    super.key,
    required this.definition,
    required this.selectedStepId,
    required this.library,
    required this.triggers,
    required this.onSelect,
    required this.onDropNodeType,
    required this.onMoveNode,
    required this.onConnect,
    required this.onDisconnect,
    required this.onInsertLinked,
    required this.onDeleteStep,
    required this.selectedTriggerId,
    required this.onSelectTrigger,
    required this.onAddTrigger,
    required this.onDeleteTrigger,
    required this.onTidy,
  });

  /// Rendered width of every node tile. Seeded templates are pitched on a
  /// 240×120 grid; a layout test pins that those tiles do not overlap.
  static const double nodeWidth = kPipelineEditorNodeWidth;

  /// Rendered height of every node tile. See [nodeWidth].
  static const double nodeHeight = kPipelineEditorNodeHeight;

  /// The current draft definition being edited.
  final PipelineDefinition definition;

  /// The currently selected step ID, or null.
  final String? selectedStepId;

  /// Palette used to resolve tile icons.
  final NodeTypeLibrary library;

  /// This template's start triggers, each rendered as its own graph node.
  final List<PipelineTrigger> triggers;

  /// The currently selected trigger node id, or null. Mutually exclusive with
  /// [selectedStepId]; the screen enforces that.
  final String? selectedTriggerId;

  /// Called when the user clicks a trigger node.
  final void Function(String triggerId) onSelectTrigger;

  /// A trigger entry was dropped from the sidebar or picked from the ghost
  /// tile's picker. `eventType` is PipelineTrigger.manualEventType,
  /// .scheduleEventType, .webhookEventType, or a domain event type name.
  /// [canvasOffset] is the drop's definition-space top-left when the entry
  /// came from the palette; omitted for the ghost picker.
  final void Function(String eventType, [Offset? canvasOffset]) onAddTrigger;

  /// Delete/Backspace on a selected trigger node.
  final void Function(String triggerId) onDeleteTrigger;

  /// Called when the user clicks a node.
  final void Function(String stepId) onSelect;

  /// Drop from the palette. `canvasOffset` is the new tile's top-left in
  /// the definition's x/y space (already snapped).
  final void Function(NodeType type, Offset canvasOffset) onDropNodeType;

  /// Fired at drag end with the final definition-space top-left.
  final void Function(String stepId, Offset position) onMoveNode;

  /// On-canvas connect (port drag or `e` then Enter).
  final void Function(String fromStepId, String toStepId) onConnect;

  /// Midpoint-handle disconnect.
  final void Function(String fromStepId, String toStepId) onDisconnect;

  /// Drop-picker pick: create the chosen type at the drop offset and link
  /// it from the connect source.
  final void Function(NodeType type, String fromStepId, Offset canvasOffset)
  onInsertLinked;

  /// Delete/Backspace on a non-trigger selected node.
  final void Function(String stepId) onDeleteStep;

  /// Auto-layout control; the screen recomputes stored x/y.
  final VoidCallback onTidy;

  @override
  ConsumerState<PipelineEditorCanvas> createState() =>
      _PipelineEditorCanvasState();
}

class _PipelineEditorCanvasState extends ConsumerState<PipelineEditorCanvas> {
  final _focus = FocusNode(debugLabel: 'pipeline-editor-canvas');
  final _transform = TransformationController();
  final _viewerKey = GlobalKey();
  late final CanvasWheelPan _wheelPan = CanvasWheelPan(_transform);

  Size _viewport = Size.zero;
  Offset _shift = Offset.zero;
  bool _hasCentered = false;
  final _dragPositions = <String, Offset>{};
  String? _connectFrom;
  String? _connectFromTriggerId;
  Offset? _connectPointerScene;
  String? _connectHoverId;
  Offset? _insertAt;
  bool _handleHover = false;

  List<PipelineStepDefinition> get _renderable => [
    for (final s in widget.definition.steps)
      if (s.kind != StepKind.terminal) s,
  ];

  @override
  void didUpdateWidget(covariant PipelineEditorCanvas old) {
    super.didUpdateWidget(old);
    _dragPositions.removeWhere((id, pos) {
      final step = widget.definition.step(id);
      if (step == null) {
        return true;
      }
      return (step.x ?? 0) == pos.dx && (step.y ?? 0) == pos.dy;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderable = _renderable;
    final insertSlot = _insertSlotTopLeft();
    final connecting = _connectFrom != null || _insertAt != null;
    final scene = computePipelineEditorScene(
      nodes: renderable,
      positionOverrides: _dragPositions,
      viewport: _viewport,
      triggerCount: widget.triggers.length,
      shiftOverride: connecting ? _shift : null,
    );
    if (!connecting) {
      _shift = scene.shift;
    }

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: _focus.requestFocus,
        child: DragTarget<TriggerPaletteEntry>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            final def = _toDefinition(details.offset);
            Offset? at;
            if (def != null) {
              at = snapPipelineEditorOffset(
                def -
                    const Offset(
                      kPipelineEditorNodeWidth / 2,
                      kPipelineEditorNodeHeight / 2,
                    ),
              );
            }
            widget.onAddTrigger(details.data.eventType, at);
          },
          builder: (context, triggerCandidates, _) {
            return DragTarget<NodeType>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: _onDrop,
              builder: (context, candidates, _) {
                final dropping =
                    candidates.isNotEmpty || triggerCandidates.isNotEmpty;
                return MouseRegion(
                  cursor: dropping
                      ? SystemMouseCursors.grabbing
                      : MouseCursor.defer,
                  child: PipelineEditorViewport(
                    viewerKey: _viewerKey,
                    transform: _transform,
                    wheelPan: _wheelPan,
                    scene: scene,
                    onViewport: _onViewport,
                    dropping: dropping,
                    empty: renderable.isEmpty,
                    definition: widget.definition,
                    library: widget.library,
                    triggers: widget.triggers,
                    selectedStepId: widget.selectedStepId,
                    selectedTriggerId: widget.selectedTriggerId,
                    dragPositions: _dragPositions,
                    connectFrom: _connectFrom,
                    connectFromTriggerId: _connectFromTriggerId,
                    connectPointerScene: _connectPointerScene,
                    connectHoverId: _connectHoverId,
                    lockViewer: connecting || _handleHover,
                    onConnectHandleHover: _onConnectHandleHover,
                    onSelect: _onTapNode,
                    onSelectTrigger: _onTapTrigger,
                    onAddTrigger: widget.onAddTrigger,
                    onMoveUpdate: _onMoveUpdate,
                    onMoveEnd: _onMoveEnd,
                    onConnectDragStart: _onConnectDragStart,
                    onTriggerConnectDragStart: _onTriggerConnectDragStart,
                    onConnectDragUpdate: _onConnectDragUpdate,
                    onConnectDragEnd: _onConnectDragEnd,
                    onConnectDragCancel: _clearConnect,
                    insertTopLeft: insertSlot,
                    showInsertPicker: _insertAt != null,
                    onInsertPick: _onInsertPick,
                    onCancelInsert: _clearConnect,
                    onDisconnect: widget.onDisconnect,
                    onFit: _fitToContent,
                    onTidy: widget.onTidy,
                    viewport: () => _viewport,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    return handlePipelineEditorKey(
      event: event,
      definition: widget.definition,
      selectedStepId: widget.selectedStepId,
      selectedTriggerId: widget.selectedTriggerId,
      connectFrom: _connectFrom,
      dragPositions: _dragPositions,
      onSelect: widget.onSelect,
      onBeginConnect: (id) => setState(() {
        _connectFrom = id;
        final step = widget.definition.step(id);
        _connectFromTriggerId = step != null && step.kind == StepKind.trigger
            ? id
            : null;
      }),
      onCompleteConnect: (from, to) {
        _tryConnect(from, to);
        _clearConnect();
      },
      onCancelConnect: _clearConnect,
      onDeleteStep: widget.onDeleteStep,
      onDeleteTrigger: widget.onDeleteTrigger,
    );
  }

  void _clearConnect() {
    setState(() {
      _connectFrom = null;
      _connectFromTriggerId = null;
      _connectPointerScene = null;
      _connectHoverId = null;
      _insertAt = null;
    });
  }

  void _onConnectHandleHover(bool hover) {
    if (_handleHover == hover) {
      return;
    }
    setState(() => _handleHover = hover);
  }

  Offset? _insertSlotTopLeft() {
    if (_insertAt != null) {
      return _insertAt;
    }
    if (_connectFrom == null ||
        _connectHoverId != null ||
        _connectPointerScene == null) {
      return null;
    }
    final slot = _slotFromDefinition(_connectPointerScene! - _shift);
    if (!_slotFarEnough(_connectFrom!, slot)) {
      return null;
    }
    return slot;
  }

  Offset _slotFromDefinition(Offset def) => snapPipelineEditorOffset(
    def -
        const Offset(
          kPipelineEditorNodeWidth / 2,
          kPipelineEditorNodeHeight / 2,
        ),
  );

  bool _slotFarEnough(String fromId, Offset slot) {
    final from = widget.definition.step(fromId);
    if (from == null) {
      return true;
    }
    final origin = pipelineEditorNodeOffset(from, _dragPositions);
    final start = Offset(
      origin.dx + kPipelineEditorNodeWidth,
      origin.dy + kPipelineEditorNodeHeight / 2,
    );
    final end = Offset(slot.dx, slot.dy + kPipelineEditorNodeHeight / 2);
    return (end - start).distance >= 24;
  }

  void _onInsertPick(NodeType type) {
    final from = _connectFrom;
    final at = _insertAt;
    if (from == null || at == null) {
      _clearConnect();
      return;
    }
    widget.onInsertLinked(type, from, at);
    _clearConnect();
  }

  void _onTapTrigger(String triggerId) {
    _focus.requestFocus();
    if (_connectFrom != null) {
      _clearConnect();
    }
    widget.onSelectTrigger(triggerId);
  }

  void _onTapNode(String id) {
    _focus.requestFocus();
    final from = _connectFrom;
    if (from != null && from != id) {
      _tryConnect(from, id);
      _clearConnect();
      return;
    }
    widget.onSelect(id);
  }

  void _tryConnect(String from, String to) {
    if (from == to) {
      return;
    }
    final target = widget.definition.step(to);
    if (target == null || target.kind == StepKind.trigger) {
      return;
    }
    widget.onConnect(from, to);
  }

  void _onMoveUpdate(String id, Offset delta) {
    final step = widget.definition.step(id);
    if (step == null) {
      return;
    }
    final current = pipelineEditorNodeOffset(step, _dragPositions);
    setState(() => _dragPositions[id] = current + delta);
  }

  void _onMoveEnd(String id) {
    final step = widget.definition.step(id);
    if (step == null) {
      return;
    }
    final snapped = snapPipelineEditorOffset(
      pipelineEditorNodeOffset(step, _dragPositions),
    );
    setState(() => _dragPositions[id] = snapped);
    widget.onMoveNode(id, snapped);
  }

  void _onConnectDragStart(String id) {
    // Do not requestFocus here: a focus change mid-pointer-down cancels the
    // pan, so the first drag pans the canvas and only a second drag connects.
    setState(() {
      _connectFrom = id;
      _connectFromTriggerId = null;
      _connectHoverId = null;
      _insertAt = null;
    });
  }

  void _onTriggerConnectDragStart(String triggerId) {
    setState(() {
      _connectFrom = triggerId;
      _connectFromTriggerId = triggerId;
      _connectHoverId = null;
      _insertAt = null;
    });
  }

  void _onConnectDragUpdate(Offset global) {
    final def = _toDefinition(global);
    if (def == null) {
      return;
    }
    final hover = hitTestPipelineEditorNode(
      definitionPoint: def,
      nodes: _renderable,
      overrides: _dragPositions,
    );
    final from = _connectFrom;
    final valid =
        hover != null &&
        from != null &&
        hover != from &&
        widget.definition.step(hover)?.kind != StepKind.trigger;
    setState(() {
      _connectPointerScene = def + _shift;
      _connectHoverId = valid ? hover : null;
    });
  }

  void _onConnectDragEnd(Offset global) {
    final def = _toDefinition(global);
    final from = _connectFrom;
    if (from == null) {
      _clearConnect();
      return;
    }
    if (def != null) {
      final to = hitTestPipelineEditorNode(
        definitionPoint: def,
        nodes: _renderable,
        overrides: _dragPositions,
      );
      if (to != null) {
        _tryConnect(from, to);
        _clearConnect();
        return;
      }
      final slot = _slotFromDefinition(def);
      if (_slotFarEnough(from, slot)) {
        setState(() {
          _insertAt = slot;
          _connectPointerScene =
              slot +
              _shift +
              const Offset(
                kPipelineEditorNodeWidth / 2,
                kPipelineEditorNodeHeight / 2,
              );
          _connectHoverId = null;
        });
        return;
      }
    }
    _clearConnect();
  }

  void _onDrop(DragTargetDetails<NodeType> details) {
    final def = _toDefinition(details.offset);
    if (def == null) {
      return;
    }
    final topLeft = snapPipelineEditorOffset(
      def -
          const Offset(
            kPipelineEditorNodeWidth / 2,
            kPipelineEditorNodeHeight / 2,
          ),
    );
    widget.onDropNodeType(details.data, topLeft);
  }

  Offset? _toDefinition(Offset global) {
    final ctx = _viewerKey.currentContext;
    if (ctx == null) {
      return null;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }
    return _transform.toScene(box.globalToLocal(global)) - _shift;
  }

  void _onViewport(Size size) {
    final firstLayout = _viewport.isEmpty && size.width > 0 && size.height > 0;
    _viewport = size;
    if (!firstLayout || _hasCentered) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerInViewport();
      }
    });
  }

  /// First open: native-size, centred. Not flushed to the top-left of the
  /// pane — InteractiveViewer's child origin is top-left, so identity would
  /// pin a short pipeline under the header.
  void _centerInViewport() {
    _hasCentered = true;
    _applyFit(maxScale: 1);
  }

  void _fitToContent() {
    _applyFit(maxScale: kPipelineEditorMaxScale);
  }

  void _applyFit({required double maxScale}) {
    final renderable = _renderable;
    if (renderable.isEmpty || _viewport.isEmpty) {
      _transform.value = Matrix4.identity();
      return;
    }
    _transform.value = pipelineEditorFitMatrix(
      bounds: pipelineEditorNodesSceneBounds(
        nodes: renderable,
        overrides: _dragPositions,
        shift: _shift,
        triggerCount: widget.triggers.length,
      ),
      viewport: _viewport,
      maxScale: maxScale,
    );
  }
}
