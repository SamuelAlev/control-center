import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// Horizontal cubic handle length used by the pipeline edge painter. Exposed so
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

/// The cubic between two port centres, drawn with the painter's horizontal
/// handles.
///
/// Shared so a wire and the ghost drawn while it is being dragged are
/// literally the same curve, and so [PipelineEdgeGeometryCache] caches the
/// curve the painter would have built anyway.
Path pipelineEdgeCubicPath(Offset from, Offset to) => Path()
  ..moveTo(from.dx, from.dy)
  ..cubicTo(
    from.dx + kPipelineEdgeHandleOffset,
    from.dy,
    to.dx - kPipelineEdgeHandleOffset,
    to.dy,
    to.dx,
    to.dy,
  );

/// One drawn wire, resolved once and kept until one of its ends moves.
///
/// Every coordinate here is in *node* space: [start] is the source tile's
/// output-port centre, [end] the target tile's input-port centre, and [path]
/// the cubic between them. The painter adds its scene translation at paint
/// time, so panning a canvas or re-basing its origin rebuilds nothing — only a
/// wire whose port centres actually moved does.
@immutable
class PipelineEdgeSegment {
  /// Creates a [PipelineEdgeSegment].
  const PipelineEdgeSegment({
    required this.fromId,
    required this.toId,
    required this.start,
    required this.end,
    required this.path,
    required this.routeKey,
  });

  /// Source step id.
  final String fromId;

  /// Target step id.
  final String toId;

  /// Source tile's output-port centre, in node space.
  final Offset start;

  /// Target tile's input-port centre, in node space.
  final Offset end;

  /// Cubic from [start] to [end], in node space.
  final Path path;

  /// Router branch label carried by the source trigger, or null when the wire
  /// is unconditional.
  final String? routeKey;
}

/// Identifies one wire: its source step, its target step, and the route label
/// it carries.
///
/// A record rather than a joined string: the key is built on every sync, and a
/// record compares by value without allocating a key string to do it.
typedef _WireKey = ({String fromId, String toId, String? routeKey});

/// Persistent, incrementally-updated geometry for the pipeline edge layer.
///
/// The naive version of this walk rebuilds every cubic on every frame,
/// including the frames where the only thing that moved was the pointer over
/// one tile. Keeping the resolved wires and rebuilding only the ones whose
/// port centres moved is what makes a node drag cost that node's incident
/// wires instead of the whole document.
///
/// The cache is self-validating: [sync] re-resolves every endpoint on every
/// call, so a segment is reused only when its own two ends still hold. There is
/// no revision to bump and no way to serve a stale wire.
class PipelineEdgeGeometryCache {
  /// Creates an empty cache. Nothing is held until the first [sync].
  PipelineEdgeGeometryCache();

  final Map<_WireKey, PipelineEdgeSegment> _segments =
      <_WireKey, PipelineEdgeSegment>{};

  /// Port anchors, rebuilt in place. Cleared rather than re-created so a sync
  /// that changes nothing does not allocate a fresh graph-sized pair.
  final Map<String, Offset> _starts = <String, Offset>{};
  final Map<String, Offset> _ends = <String, Offset>{};

  /// The wire order now held, and the scratch list the next walk fills. They
  /// swap when the order changes, so neither is allocated more than once.
  List<_WireKey> _order = <_WireKey>[];
  List<_WireKey> _scratch = <_WireKey>[];

  List<PipelineEdgeSegment>? _ordered;
  int _lastRebuilt = 0;

  /// Wires rebuilt by the most recent [sync].
  ///
  /// The number to watch: dragging one node should move this by that node's
  /// incident wire count, not by the size of the graph.
  int get lastRebuiltCount => _lastRebuilt;

  /// Resolves every wire implied by [steps] and returns them in draw order.
  ///
  /// [positions] overrides stored coordinates the way the run canvas's
  /// auto-layout does; [nodeWidths] must cover the steps that draw outgoing
  /// wires, and [nodeHeight] is the single tile height both canvases use.
  ///
  /// Cheap enough to call whenever a painter is built: it walks the graph and
  /// allocates the two port anchors per node, but the wires it rebuilds are
  /// only the ones whose ends moved, and the walk itself reuses its anchor maps
  /// and order lists instead of allocating a fresh graph-sized set per call.
  /// The returned list is retained by the caller and never mutated afterwards —
  /// a later call that changes something builds a new list.
  List<PipelineEdgeSegment> sync({
    required List<PipelineStepDefinition> steps,
    required Map<String, double> nodeWidths,
    required double nodeHeight,
    Map<String, Offset>? positions,
  }) {
    final half = nodeHeight / 2;
    final starts = _starts..clear();
    final ends = _ends..clear();
    for (final step in steps) {
      final topLeft = positions?[step.id] ?? Offset(step.x ?? 0, step.y ?? 0);
      final middle = topLeft.dy + half;
      ends[step.id] = Offset(topLeft.dx, middle);
      final width = nodeWidths[step.id];
      if (width != null) {
        starts[step.id] = Offset(topLeft.dx + width, middle);
      }
    }

    final order = _scratch..clear();
    var rebuilt = 0;
    var fresh = false;
    for (final step in steps) {
      final end = ends[step.id]!;
      for (final trigger in step.triggers) {
        for (final source in trigger.sourceStepIds) {
          final sourceEnd = ends[source];
          if (sourceEnd == null) {
            // Deleted or dangling source nodes have no wire to draw.
            continue;
          }
          final start =
              starts[source] ??
              Offset(sourceEnd.dx + nodeWidths[source]!, sourceEnd.dy);
          final key = (
            fromId: source,
            toId: step.id,
            routeKey: trigger.routeKey,
          );
          order.add(key);
          final cached = _segments[key];
          if (cached == null) {
            fresh = true;
          } else if (cached.start == start && cached.end == end) {
            continue;
          }
          _segments[key] = PipelineEdgeSegment(
            fromId: source,
            toId: step.id,
            start: start,
            end: end,
            path: pipelineEdgeCubicPath(start, end),
            routeKey: trigger.routeKey,
          );
          rebuilt++;
        }
      }
    }
    _lastRebuilt = rebuilt;

    // Wires whose ends are gone — a deleted node, a rewritten trigger — go with
    // them, so a removed edge stops painting and stops hit-testing. Only a sync
    // that added or dropped a wire pays to build the lookup set: the anchor
    // maps and order lists it walks are reused, so the per-call allocation is
    // the two port anchors a node's own entry needs.
    if (fresh || _segments.length != order.length) {
      final live = order.toSet();
      _segments.removeWhere((key, _) => !live.contains(key));
    }
    if (rebuilt > 0 || !const ListEquality<_WireKey>().equals(_order, order)) {
      // The walk filled the scratch list; adopt it and hand the previous order
      // back to be refilled next time.
      final previous = _order;
      _order = order;
      _scratch = previous;
      _ordered = [for (final key in _order) _segments[key]!];
    }
    return _ordered ??= const <PipelineEdgeSegment>[];
  }
}
