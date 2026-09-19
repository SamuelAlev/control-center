import 'dart:math' as math;

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Rendered tile size. Kept here so geometry helpers do not import the
/// canvas widget (the canvas re-exports these as
/// `PipelineEditorCanvas.nodeWidth` / `nodeHeight` because a layout test
/// pins that API).
const double kPipelineEditorNodeWidth = 220;

/// See [kPipelineEditorNodeWidth].
const double kPipelineEditorNodeHeight = 72;

/// Extra width past the visual card so the output port sits inside the
/// tile's hit-test box. Edge geometry still anchors to
/// [kPipelineEditorNodeWidth] — this is chrome, not the stored tile size.
const double kPipelineEditorNodeChromeWidth = 44;

/// Outer tile width including port / insert chrome.
const double kPipelineEditorTileExtentWidth =
    kPipelineEditorNodeWidth + kPipelineEditorNodeChromeWidth;

/// Vertical gap between newly stacked start-trigger tiles (legacy expand).
const double kPipelineEditorTriggerStackGap = 24;

/// Pitch of one trigger-stack slot (tile + gap).
const double kPipelineEditorTriggerPitch =
    kPipelineEditorNodeHeight + kPipelineEditorTriggerStackGap;

/// Snap pitch for free-placed editor tiles. 8px is fine enough to align
/// columns by eye without fighting the pointer.
const double kPipelineEditorGrid = 8;

/// Padding between the scene origin and the most top-left stored node, so a
/// graph that starts at (0, 0) is not flush with the viewer's clip.
const double kPipelineEditorContentMargin = 40;

/// Pan leash for the editor viewer, shared with the wheel rewrite so a drag
/// and a wheel agree. Infinite on purpose: this canvas has draggable nodes,
/// so a card moved into the slack around the graph has to stay reachable, and
/// a finite margin also refuses the whole axis when the graph is smaller than
/// the viewport — which is why a short pipeline could scroll vertically but
/// not horizontally. "Fit to view" is the way back.
const double kPipelineEditorBoundaryMargin = double.infinity;

/// InteractiveViewer zoom floor / ceiling — match CanvasZoomControls.
const double kPipelineEditorMinScale = 0.4;

/// See [kPipelineEditorMinScale].
const double kPipelineEditorMaxScale = 2.0;

/// One directed edge of the editor graph (a step trigger's source → this step).
class PipelineGraphEdge {
  /// Creates a [PipelineGraphEdge].
  const PipelineGraphEdge({
    required this.fromId,
    required this.toId,
    this.routeKey,
  });

  /// Upstream step id.
  final String fromId;

  /// Downstream step id.
  final String toId;

  /// Router branch label, or null for an unconditional edge.
  final String? routeKey;
}

/// Scene translation + size so stored (possibly negative) coordinates paint
/// inside the InteractiveViewer child.
class PipelineEditorScene {
  /// Creates a [PipelineEditorScene].
  const PipelineEditorScene({required this.shift, required this.size});

  /// Added to every definition-space top-left to get scene coordinates.
  final Offset shift;

  /// Size of the InteractiveViewer child.
  final Size size;
}

/// Snaps [value] to [kPipelineEditorGrid].
double snapPipelineEditorAxis(double value) =>
    (value / kPipelineEditorGrid).round() * kPipelineEditorGrid;

/// Snaps a definition-space top-left to the editor grid.
Offset snapPipelineEditorOffset(Offset value) =>
    Offset(snapPipelineEditorAxis(value.dx), snapPipelineEditorAxis(value.dy));

/// Live top-left of [step], honouring an in-progress drag override.
Offset pipelineEditorNodeOffset(
  PipelineStepDefinition step,
  Map<String, Offset> overrides,
) => overrides[step.id] ?? Offset(step.x ?? 0, step.y ?? 0);

/// Manual first, then [PipelineTrigger.eventType], then id.
List<PipelineTrigger> sortedPipelineTriggers(List<PipelineTrigger> triggers) =>
    sortPipelineTriggers(triggers);

/// How many stacked slots the trigger column occupies (ghost tile = 1).
int pipelineEditorTriggerSlotCount(int triggerCount) =>
    triggerCount == 0 ? 1 : triggerCount;

/// Definition-space top-left of trigger [index] when expanding a shared entry.
Offset pipelineEditorTriggerStackOffset({
  required Offset entryOrigin,
  required int index,
}) => Offset(
  entryOrigin.dx,
  entryOrigin.dy + index * kPipelineEditorTriggerPitch,
);

/// Vertical extent of the trigger column in definition space.
double pipelineEditorTriggerColumnHeight(int triggerCount) {
  final slots = pipelineEditorTriggerSlotCount(triggerCount);
  return slots * kPipelineEditorNodeHeight +
      (slots - 1) * kPipelineEditorTriggerStackGap;
}

/// Walks [steps] into unique directed edges. Terminals are skipped because
/// the canvases do not render them.
List<PipelineGraphEdge> pipelineGraphEdges(List<PipelineStepDefinition> steps) {
  final known = {for (final step in steps) step.id};
  final edges = <PipelineGraphEdge>[];
  for (final step in steps) {
    if (step.kind == StepKind.terminal) {
      continue;
    }
    for (final trigger in step.triggers) {
      for (final src in trigger.sourceStepIds) {
        if (!known.contains(src)) {
          continue;
        }
        edges.add(
          PipelineGraphEdge(
            fromId: src,
            toId: step.id,
            routeKey: trigger.routeKey,
          ),
        );
      }
    }
  }
  return edges;
}

/// Shift + scene size for [nodes] so negative stored coordinates land inside
/// the viewer and chrome (eyebrows, ports) is not clipped.
///
/// [extraTopLeft] may grow [PipelineEditorScene.size] but never [shift] —
/// rebasing minX/minY under a live pointer makes the graph jump.
/// [shiftOverride] freezes shift for an in-flight connect-drag.
PipelineEditorScene computePipelineEditorScene({
  required List<PipelineStepDefinition> nodes,
  required Map<String, Offset> positionOverrides,
  required Size viewport,
  int triggerCount = 0,
  Offset? extraTopLeft,
  Offset? shiftOverride,
}) {
  const margin = kPipelineEditorContentMargin;
  // Extra slack past the visual card so the last tile's port is not
  // clipped by the InteractiveViewer child.
  const chrome = kPipelineEditorNodeChromeWidth;
  if (nodes.isEmpty) {
    final w = viewport.width.isFinite && viewport.width > 0
        ? viewport.width
        : 800.0;
    final h = viewport.height.isFinite && viewport.height > 0
        ? viewport.height
        : 600.0;
    return PipelineEditorScene(
      shift: const Offset(margin, margin),
      size: Size(w, h),
    );
  }

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = -double.infinity;
  var maxY = -double.infinity;
  for (final node in nodes) {
    final p = pipelineEditorNodeOffset(node, positionOverrides);
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx + kPipelineEditorNodeWidth);
    maxY = math.max(maxY, p.dy + kPipelineEditorNodeHeight);
  }
  if (extraTopLeft != null) {
    // Grow the child so a committed insert is not clipped. Never move minX/
    // minY: rebasing shift while a pointer is above/left of the graph makes
    // the wire jump (dragging down/right only grows size and is stable).
    maxX = math.max(maxX, extraTopLeft.dx + kPipelineEditorNodeWidth);
    maxY = math.max(maxY, extraTopLeft.dy + kPipelineEditorNodeHeight);
  }
  final computed = Offset(
    margin - math.min(minX, 0),
    margin - math.min(minY, 0),
  );
  final shift = shiftOverride ?? computed;
  return PipelineEditorScene(
    shift: shift,
    size: Size(
      maxX + shift.dx + margin + chrome,
      maxY + shift.dy + margin + chrome,
    ),
  );
}

/// Output-port centre in scene space (right-middle of the tile at [origin]).
Offset pipelineEditorOutputPortScene(Offset origin, Offset shift) => Offset(
  origin.dx + shift.dx + kPipelineEditorNodeWidth,
  origin.dy + shift.dy + kPipelineEditorNodeHeight / 2,
);

/// Input-port centre in scene space (left-middle of the tile at [origin]).
Offset pipelineEditorInputPortScene(Offset origin, Offset shift) => Offset(
  origin.dx + shift.dx,
  origin.dy + shift.dy + kPipelineEditorNodeHeight / 2,
);

/// Scene-space start of an in-flight connect wire.
Offset? pipelineEditorConnectGhostStart({
  required String connectFrom,
  required Map<String, Offset> positions,
  required Offset shift,
}) {
  final origin = positions[connectFrom];
  if (origin == null) {
    return null;
  }
  return pipelineEditorOutputPortScene(origin, shift);
}

/// Axis-aligned node rect in definition space.
Rect pipelineEditorNodeRect(
  PipelineStepDefinition step,
  Map<String, Offset> overrides,
) {
  final origin = pipelineEditorNodeOffset(step, overrides);
  return Rect.fromLTWH(
    origin.dx,
    origin.dy,
    kPipelineEditorNodeWidth,
    kPipelineEditorNodeHeight,
  );
}

/// The node whose tile contains [definitionPoint], or null.
String? hitTestPipelineEditorNode({
  required Offset definitionPoint,
  required List<PipelineStepDefinition> nodes,
  required Map<String, Offset> overrides,
}) {
  for (final node in nodes.reversed) {
    if (pipelineEditorNodeRect(node, overrides).contains(definitionPoint)) {
      return node.id;
    }
  }
  return null;
}

/// Scene-space endpoints of the edge [fromId] → [toId].
({Offset start, Offset end}) pipelineEditorEdgeAnchors({
  required String fromId,
  required String toId,
  required List<PipelineStepDefinition> nodes,
  required Map<String, Offset> overrides,
  required Offset shift,
}) {
  final byId = {for (final n in nodes) n.id: n};
  final from = byId[fromId];
  final to = byId[toId];
  final fromOrigin = from == null
      ? Offset.zero
      : pipelineEditorNodeOffset(from, overrides);
  final toOrigin = to == null
      ? Offset.zero
      : pipelineEditorNodeOffset(to, overrides);
  return (
    start: Offset(
      fromOrigin.dx + shift.dx + kPipelineEditorNodeWidth,
      fromOrigin.dy + shift.dy + kPipelineEditorNodeHeight / 2,
    ),
    end: Offset(
      toOrigin.dx + shift.dx,
      toOrigin.dy + shift.dy + kPipelineEditorNodeHeight / 2,
    ),
  );
}

/// Midpoint of the editor edge cubic, in scene space.
Offset pipelineEditorEdgeMidpoint({
  required String fromId,
  required String toId,
  required List<PipelineStepDefinition> nodes,
  required Map<String, Offset> overrides,
  required Offset shift,
}) {
  final anchors = pipelineEditorEdgeAnchors(
    fromId: fromId,
    toId: toId,
    nodes: nodes,
    overrides: overrides,
    shift: shift,
  );
  return pipelineEdgeCubicMidpoint(anchors.start, anchors.end);
}

/// Nearest node in [dir] from [fromId] (or the top-left node when [fromId]
/// is null). Geometry only — the same rule PlanCanvas uses so arrow keys
/// feel identical across DAG canvases.
String? nearestPipelineEditorNode({
  required String? fromId,
  required LogicalKeyboardKey dir,
  required Map<String, Offset> positions,
}) {
  if (positions.isEmpty) {
    return null;
  }
  if (fromId == null) {
    final entries = positions.entries.toList()
      ..sort((a, b) {
        final byX = a.value.dx.compareTo(b.value.dx);
        return byX != 0 ? byX : a.value.dy.compareTo(b.value.dy);
      });
    return entries.first.key;
  }
  final origin = positions[fromId];
  if (origin == null) {
    return positions.keys.first;
  }
  final horizontal =
      dir == LogicalKeyboardKey.arrowRight ||
      dir == LogicalKeyboardKey.arrowLeft;
  final forward =
      dir == LogicalKeyboardKey.arrowRight ||
      dir == LogicalKeyboardKey.arrowDown;
  String? best;
  var bestScore = double.infinity;
  for (final e in positions.entries) {
    if (e.key == fromId) {
      continue;
    }
    final d = e.value - origin;
    final primary = horizontal ? d.dx : d.dy;
    final cross = horizontal ? d.dy : d.dx;
    if (forward ? primary <= 0 : primary >= 0) {
      continue;
    }
    final score = primary.abs() + cross.abs() * 2;
    if (score < bestScore) {
      bestScore = score;
      best = e.key;
    }
  }
  return best;
}

/// Transform that fits [bounds] (scene space) into [viewport], clamped to
/// the editor zoom range and centred.
///
/// [maxScale] defaults to the editor zoom ceiling (fit-to-view). Opening
/// the editor passes `1` so a short pipeline is centred at native size
/// instead of being blown up to fill the pane.
Matrix4 pipelineEditorFitMatrix({
  required Rect bounds,
  required Size viewport,
  double maxScale = kPipelineEditorMaxScale,
}) {
  if (bounds.isEmpty || viewport.isEmpty) {
    return Matrix4.identity();
  }
  final padded = bounds.inflate(24);
  final scaleX = viewport.width / padded.width;
  final scaleY = viewport.height / padded.height;
  final scale = math
      .min(scaleX, scaleY)
      .clamp(kPipelineEditorMinScale, maxScale);
  final centre = padded.center;
  final viewCentre = Offset(viewport.width / 2, viewport.height / 2);
  return Matrix4.identity()
    ..translateByDouble(viewCentre.dx, viewCentre.dy, 0, 1)
    ..scaleByDouble(scale, scale, scale, 1)
    ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
}

/// Bounding box of [nodes] in scene space (after [shift]).
Rect pipelineEditorNodesSceneBounds({
  required List<PipelineStepDefinition> nodes,
  required Map<String, Offset> overrides,
  required Offset shift,
  int triggerCount = 0,
}) {
  if (nodes.isEmpty) {
    return Rect.zero;
  }
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = -double.infinity;
  var maxY = -double.infinity;
  for (final node in nodes) {
    final p = pipelineEditorNodeOffset(node, overrides) + shift;
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx + kPipelineEditorNodeWidth);
    maxY = math.max(maxY, p.dy + kPipelineEditorNodeHeight);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
