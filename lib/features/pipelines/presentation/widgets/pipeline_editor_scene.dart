import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_edge_handle.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_node_tile.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The InteractiveViewer child: edges, tiles, midpoint handles.
///
/// Each [PipelineTrigger] row owns a [StepKind.trigger] graph node. The tile
/// is that node — not a proxy of a hidden shared entry — so a wire leaving
/// Schedule belongs only to Schedule.
class PipelineEditorSceneStack extends StatelessWidget {
  /// Creates a [PipelineEditorSceneStack].
  const PipelineEditorSceneStack({
    super.key,
    required this.shift,
    required this.tokens,
    required this.l10n,
    required this.definition,
    required this.library,
    required this.triggers,
    required this.selectedStepId,
    required this.selectedTriggerId,
    required this.dragPositions,
    required this.connectFrom,
    required this.connectFromTriggerId,
    required this.connectHoverId,
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
    required this.onDisconnect,
  });

  /// Definition → scene translation.
  final Offset shift;

  /// Design tokens for edges / ghost.
  final DesignSystemTokens tokens;

  /// Localized eyebrow copy.
  final AppLocalizations l10n;

  /// Draft graph.
  final PipelineDefinition definition;

  /// Palette for tile icons.
  final NodeTypeLibrary library;

  /// Start trigger rows, each paired with a trigger graph node of the same id.
  final List<PipelineTrigger> triggers;

  /// Selected step, or null.
  final String? selectedStepId;

  /// Selected trigger node, or null.
  final String? selectedTriggerId;

  /// Live drag overrides, keyed by step id.
  final Map<String, Offset> dragPositions;

  /// Keyboard / port connect source (a step id, including trigger nodes).
  final String? connectFrom;

  /// Trigger that started the in-flight connect, or null. Same as
  /// [connectFrom] when the source is a trigger node.
  final String? connectFromTriggerId;

  /// Valid drop-target under the port drag.
  final String? connectHoverId;

  /// Body-tile tap.
  final void Function(String id) onSelect;

  /// Trigger-node tap.
  final void Function(String triggerId) onSelectTrigger;

  /// Ghost-picker pick.
  final void Function(String eventType, [Offset? canvasOffset]) onAddTrigger;

  /// Tile pan.
  final void Function(String id, Offset delta) onMoveUpdate;

  /// Tile pan end.
  final void Function(String id) onMoveEnd;

  /// Output-port pan start on a body step.
  final void Function(String id) onConnectDragStart;

  /// Output-port pan start on a trigger node.
  final void Function(String triggerId) onTriggerConnectDragStart;

  /// Output-port pan update (global).
  final void Function(Offset global) onConnectDragUpdate;

  /// Output-port pan end (global).
  final void Function(Offset global) onConnectDragEnd;

  /// Output-port pan cancelled.
  final VoidCallback? onConnectDragCancel;

  /// Pointer entered/left an output handle.
  final ValueChanged<bool>? onConnectHandleHover;

  /// Midpoint-handle click.
  final void Function(String from, String to) onDisconnect;

  @override
  Widget build(BuildContext context) {
    final bodySteps = [
      for (final s in definition.steps)
        if (s.kind != StepKind.terminal && s.kind != StepKind.trigger) s,
    ];
    final triggerSteps = [
      for (final s in definition.steps)
        if (s.kind == StepKind.trigger) s,
    ];
    final stacked = sortedPipelineTriggers(triggers);
    final graphSteps = [...triggerSteps, ...bodySteps];
    final widths = {for (final s in graphSteps) s.id: kPipelineEditorNodeWidth};
    final positions = {
      for (final s in graphSteps)
        s.id: pipelineEditorNodeOffset(s, dragPositions),
    };
    final triggerIds = {for (final s in triggerSteps) s.id};
    final doThisIds = {
      for (final id in triggerIds)
        for (final s in definition.listenersOf(id)) s.id,
    };
    final edges = pipelineGraphEdges(graphSteps);
    final highlightId = selectedStepId ?? selectedTriggerId;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: PipelineEdgesPainter(
                steps: graphSteps,
                color: tokens.borderSecondary,
                nodeWidths: widths,
                nodeHeight: kPipelineEditorNodeHeight,
                offset: shift,
                positions: positions,
                highlightStepId: highlightId,
                highlightColor: tokens.accent,
              ),
            ),
          ),
        ),
        ..._triggerColumn(stacked, triggerSteps, positions),
        for (final step in bodySteps)
          _positionedTile(step, positions[step.id] ?? Offset.zero, doThisIds),
        for (final edge in edges) _positionedHandle(edge, graphSteps),
      ],
    );
  }

  List<Widget> _triggerColumn(
    List<PipelineTrigger> stacked,
    List<PipelineStepDefinition> triggerSteps,
    Map<String, Offset> positions,
  ) {
    if (stacked.isEmpty) {
      final origin = triggerSteps.isEmpty
          ? Offset.zero
          : pipelineEditorNodeOffset(triggerSteps.first, dragPositions);
      return [
        Positioned(
          // RTL carve-out: a DAG canvas — node placement is canvas-coordinate
          // math over the laid-out graph, and diagram canvases stay LTR.
          left: origin.dx + shift.dx,
          top: origin.dy + shift.dy,
          width: kPipelineEditorNodeWidth,
          height: kPipelineEditorNodeHeight,
          child: PipelineEditorGhostTriggerTile(onAddTrigger: onAddTrigger),
        ),
      ];
    }
    return [
      for (var i = 0; i < stacked.length; i++)
        _positionedTriggerTile(
          trigger: stacked[i],
          origin:
              positions[stacked[i].id] ??
              pipelineEditorTriggerStackOffset(
                entryOrigin: triggerSteps.isEmpty
                    ? Offset.zero
                    : pipelineEditorNodeOffset(
                        triggerSteps.first,
                        dragPositions,
                      ),
                index: i,
              ),
          first: i == 0,
        ),
    ];
  }

  Widget _positionedTriggerTile({
    required PipelineTrigger trigger,
    required Offset origin,
    required bool first,
  }) {
    final fromThis =
        connectFrom == trigger.id || connectFromTriggerId == trigger.id;
    return Positioned(
      // RTL carve-out: a DAG canvas — node placement is canvas-coordinate
      // math over the laid-out graph, and diagram canvases stay LTR.
      left: origin.dx + shift.dx,
      top: origin.dy + shift.dy,
      width: kPipelineEditorTileExtentWidth,
      height: kPipelineEditorNodeHeight,
      child: PipelineEditorTriggerTile(
        key: ValueKey('pipeline-trigger-${trigger.id}'),
        trigger: trigger,
        selected: trigger.id == selectedTriggerId,
        connectSource: fromThis,
        eyebrow: first ? l10n.pipelineWhenThisHappens : null,
        onSelect: () => onSelectTrigger(trigger.id),
        onMoveUpdate: (d) => onMoveUpdate(trigger.id, d),
        onMoveEnd: () => onMoveEnd(trigger.id),
        onConnectDragStart: () => onTriggerConnectDragStart(trigger.id),
        onConnectDragUpdate: onConnectDragUpdate,
        onConnectDragEnd: onConnectDragEnd,
        onConnectDragCancel: onConnectDragCancel,
        onConnectHandleHover: onConnectHandleHover,
      ),
    );
  }

  Widget _positionedTile(
    PipelineStepDefinition step,
    Offset origin,
    Set<String> doThisIds,
  ) {
    // RTL carve-out: a DAG canvas — node placement is canvas-coordinate
    // math over the laid-out graph, and diagram canvases stay LTR per policy.
    return Positioned(
      left: origin.dx + shift.dx,
      top: origin.dy + shift.dy,
      width: kPipelineEditorTileExtentWidth,
      height: kPipelineEditorNodeHeight,
      child: PipelineEditorNodeTile(
        step: step,
        library: library,
        selected: step.id == selectedStepId,
        connectSource: step.id == connectFrom,
        dropTarget: step.id == connectHoverId,
        awaitingConnect: connectFrom != null && step.id != connectFrom,
        eyebrow: doThisIds.contains(step.id) ? l10n.pipelineDoThis : null,
        onSelect: () => onSelect(step.id),
        onMoveUpdate: (d) => onMoveUpdate(step.id, d),
        onMoveEnd: () => onMoveEnd(step.id),
        onConnectDragStart: () => onConnectDragStart(step.id),
        onConnectDragUpdate: onConnectDragUpdate,
        onConnectDragEnd: onConnectDragEnd,
        onConnectDragCancel: onConnectDragCancel,
        onConnectHandleHover: onConnectHandleHover,
      ),
    );
  }

  Widget _positionedHandle(
    PipelineGraphEdge edge,
    List<PipelineStepDefinition> steps,
  ) {
    final mid = pipelineEditorEdgeMidpoint(
      fromId: edge.fromId,
      toId: edge.toId,
      nodes: steps,
      overrides: dragPositions,
      shift: shift,
    );
    return Positioned(
      left: mid.dx,
      top: mid.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: PipelineEditorEdgeHandle(
          routeKey: edge.routeKey,
          onDisconnect: () => onDisconnect(edge.fromId, edge.toId),
        ),
      ),
    );
  }
}
