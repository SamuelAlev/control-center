/// The layered (Sugiyama-style) layout that serves every box-and-arrow dialect:
/// flowchart, state, class, and ER.
///
/// Pipeline, in order:
///
///  1. **measure** every node from its text, per shape;
///  2. **break cycles** by reversing back edges found in a DFS (remembering the
///     flip so the arrow still points the way the author wrote it);
///  3. **rank** with longest-path over the resulting DAG. Ranks are DOUBLED so
///     every edge crosses at least one free intermediate rank — that rank is
///     where labels live, which is why an `A -->|label| B` never has its text
///     land on top of a box;
///  4. **insert dummies** along every multi-rank edge (label dummies carry the
///     label's measured size, so labels reserve real space);
///  5. **order** within ranks by iterated barycenter sweeps, keeping the best
///     crossing count, with cluster members constrained to stay contiguous so a
///     `subgraph` box can be drawn without swallowing outsiders;
///  6. **position** across the rank with median-of-neighbors relaxation plus a
///     feasibility pass, then down the rank axis by layer height;
///  7. **transform** from layout space to visual space — the one place `LR`/`RL`
///     (axes swapped) and `BT`/`RL` (axis flipped) are handled, so the five
///     directions cost one coordinate map instead of five layouts.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/geometry.dart';
import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Widest a node label grows before it soft-wraps.
const double _kMaxLabelWidth = 210;

/// Widest an edge label grows before it soft-wraps.
const double _kMaxEdgeLabelWidth = 160;

/// How far a self-loop bulges out from its node.
const double _kSelfLoopReach = 26;

/// Lays [graph] out into a paint-ready scene.
CcMermaidScene layoutMermaidGraph(
  CcMermaidGraph graph, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  return _GraphLayout(graph: graph, style: style, ruler: ruler).run();
}

/// A node in the layered graph: either a real diagram node or a routing dummy.
class _LNode {
  _LNode.real({required this.node, required this.visualSize})
    : id = node!.id,
      isLabel = false,
      labelLines = const [],
      clusterPath = const [];

  _LNode.dummy({
    required this.visualSize,
    this.isLabel = false,
    this.labelLines = const [],
  }) : node = null,
       id = null,
       clusterPath = const [];

  final CcMermaidNode? node;
  final String? id;

  /// Size in VISUAL space (what the painter draws).
  Size visualSize;

  /// Size in LAYOUT space (axes swapped for `LR`/`RL`).
  late Size layoutSize;

  /// Label carried by a label dummy.
  final bool isLabel;
  final List<String> labelLines;

  List<String> clusterPath;

  int rank = 0;
  int order = 0;

  /// Center along the in-rank axis (layout space).
  double x = 0;

  /// Center along the rank axis (layout space).
  double y = 0;

  /// Neighbors in the previous / next rank, after dummy insertion.
  final List<_LNode> up = [];
  final List<_LNode> down = [];

  bool get isDummy => node == null;
}

/// One edge after routing: the ranked chain of layout nodes it passes through.
class _LEdge {
  _LEdge({required this.edge, required this.chain, required this.reversed});

  final CcMermaidEdge edge;

  /// Layout nodes from low rank to high rank.
  final List<_LNode> chain;

  /// True when the edge was flipped to break a cycle: the drawn polyline runs
  /// against the ranked chain.
  final bool reversed;
}

class _GraphLayout {
  _GraphLayout({required this.graph, required this.style, required this.ruler});

  final CcMermaidGraph graph;
  final CcMermaidStyle style;
  final CcMermaidTextRuler ruler;

  final Map<String, _LNode> _byId = {};
  final List<_LNode> _all = [];
  final List<_LEdge> _routed = [];
  final List<(CcMermaidEdge, _LNode)> _selfLoops = [];
  List<List<_LNode>> _layers = [];

  bool get _horizontal => graph.direction.isHorizontal;

  CcMermaidScene run() {
    _createNodes();
    if (_all.isEmpty) {
      return CcMermaidScene.empty;
    }
    final edges = _resolveEdges();
    final reversed = _breakCycles(edges);
    _rank(edges, reversed);
    _buildLayers();
    _insertDummies(edges, reversed);
    _order();
    _assignInRank();
    final yExtent = _assignRankAxis();
    return _emit(yExtent);
  }

  // ── 1. measure ────────────────────────────────────────────────────────────

  void _createNodes() {
    for (final node in graph.nodes) {
      final layoutNode = _LNode.real(node: node, visualSize: _measure(node));
      layoutNode.layoutSize = _horizontal
          ? swapAxes(layoutNode.visualSize)
          : layoutNode.visualSize;
      layoutNode.clusterPath = _clusterPath(node.clusterId);
      _byId[node.id] = layoutNode;
      _all.add(layoutNode);
    }
  }

  List<String> _clusterPath(String? clusterId) {
    if (clusterId == null) {
      return const [];
    }
    final path = <String>[];
    var current = clusterId;
    // Guard against a malformed parent cycle in the source.
    for (var guard = 0; guard < 16; guard++) {
      path.insert(0, current);
      final cluster = graph.clusters.firstWhere(
        (c) => c.id == current,
        orElse: () => const CcMermaidCluster(id: '', lines: []),
      );
      final parent = cluster.parentId;
      if (parent == null || parent == current) {
        break;
      }
      current = parent;
    }
    return path;
  }

  Size _measure(CcMermaidNode node) {
    switch (node.shape) {
      case CcMermaidNodeShape.startPoint:
        return const Size(16, 16);
      case CcMermaidNodeShape.endPoint:
        return const Size(20, 20);
      case CcMermaidNodeShape.choice:
        return const Size(34, 34);
      case CcMermaidNodeShape.bar:
        return _horizontal ? const Size(8, 64) : const Size(64, 8);
      case CcMermaidNodeShape.compartments:
        return _measureCompartments(node);
      case CcMermaidNodeShape.note:
        final lines = wrapMermaidLines(
          node.displayLines,
          CcMermaidTextRole.note,
          ruler,
          maxWidth: _kMaxLabelWidth,
        );
        final text = measureMermaidLines(
          lines,
          CcMermaidTextRole.note,
          ruler,
          lineSpacing: style.lineSpacing,
        );
        return Size(
          math.max(text.width + style.nodePadding.horizontal, 60),
          text.height + style.nodePadding.vertical,
        );
      default:
        final lines = wrapMermaidLines(
          node.displayLines,
          CcMermaidTextRole.label,
          ruler,
          maxWidth: _kMaxLabelWidth,
        );
        final text = measureMermaidLines(
          lines,
          CcMermaidTextRole.label,
          ruler,
          lineSpacing: style.lineSpacing,
        );
        final inflation = shapeInflation(node.shape);
        return Size(
          math.max(
            text.width * inflation.widthFactor + style.nodePadding.horizontal,
            inflation.minWidth,
          ),
          math.max(
            text.height * inflation.heightFactor + style.nodePadding.vertical,
            26,
          ),
        );
    }
  }

  Size _measureCompartments(CcMermaidNode node) {
    final header = measureMermaidLines(
      [
        if (node.stereotype != null) '«${node.stereotype}»',
        ...node.displayLines,
      ],
      CcMermaidTextRole.label,
      ruler,
      lineSpacing: style.lineSpacing,
    );
    var width = header.width;
    var height = header.height + style.nodePadding.vertical;
    for (final compartment in node.compartments) {
      for (final row in compartment) {
        final size = ruler.measure(row, CcMermaidTextRole.compartment);
        width = math.max(width, size.width);
        height += size.height + style.lineSpacing;
      }
      height += style.nodePadding.vertical;
    }
    return Size(
      math.max(width + style.nodePadding.horizontal, 90),
      math.max(height, 34),
    );
  }

  // ── 2. edges & cycles ─────────────────────────────────────────────────────

  /// Resolves edge endpoints to layout nodes, redirecting an edge that names a
  /// CLUSTER to the cluster's first member (mermaid draws it to the box; landing
  /// on a member keeps the connection legible without a cluster-aware router).
  List<CcMermaidEdge> _resolveEdges() {
    final out = <CcMermaidEdge>[];
    for (final edge in graph.edges) {
      final from = _endpoint(edge.fromId);
      final to = _endpoint(edge.toId);
      if (from == null || to == null) {
        continue;
      }
      final resolved = edge.copyWith(fromId: from, toId: to);
      if (from == to) {
        _selfLoops.add((resolved, _byId[from]!));
        continue;
      }
      out.add(resolved);
    }
    return out;
  }

  String? _endpoint(String id) {
    if (_byId.containsKey(id)) {
      return id;
    }
    for (final node in graph.nodes) {
      if (node.clusterId != null && _clusterPath(node.clusterId).contains(id)) {
        return node.id;
      }
    }
    return null;
  }

  /// Reverses back edges so ranking sees a DAG. Returns the reversed set (by
  /// index into [edges]).
  Set<int> _breakCycles(List<CcMermaidEdge> edges) {
    final outgoing = <String, List<int>>{};
    for (var i = 0; i < edges.length; i++) {
      (outgoing[edges[i].fromId] ??= []).add(i);
    }
    final reversed = <int>{};
    final state = <String, int>{}; // 0 unseen, 1 on stack, 2 done

    void visit(String id) {
      state[id] = 1;
      for (final index in outgoing[id] ?? const <int>[]) {
        final target = edges[index].toId;
        final targetState = state[target] ?? 0;
        if (targetState == 1) {
          reversed.add(index);
          continue;
        }
        if (targetState == 0) {
          visit(target);
        }
      }
      state[id] = 2;
    }

    for (final node in graph.nodes) {
      if ((state[node.id] ?? 0) == 0) {
        visit(node.id);
      }
    }
    return reversed;
  }

  (String, String) _oriented(CcMermaidEdge edge, bool reversed) =>
      reversed ? (edge.toId, edge.fromId) : (edge.fromId, edge.toId);

  // ── 3. rank ───────────────────────────────────────────────────────────────

  void _rank(List<CcMermaidEdge> edges, Set<int> reversed) {
    final indegree = <String, int>{for (final node in _all) node.id!: 0};
    final adjacency = <String, List<(String, int)>>{};
    for (var i = 0; i < edges.length; i++) {
      final (from, to) = _oriented(edges[i], reversed.contains(i));
      // Ranks are doubled so every edge has a free intermediate rank for its
      // label; `minRankSpan` (mermaid's extra dashes) multiplies that.
      (adjacency[from] ??= []).add((to, 2 * edges[i].minRankSpan));
      indegree[to] = (indegree[to] ?? 0) + 1;
    }

    final queue = <String>[
      for (final node in _all)
        if ((indegree[node.id] ?? 0) == 0) node.id!,
    ];
    final ranks = <String, int>{for (final id in queue) id: 0};
    var head = 0;
    while (head < queue.length) {
      final id = queue[head++];
      final rank = ranks[id] ?? 0;
      for (final (target, minlen) in adjacency[id] ?? const <(String, int)>[]) {
        final candidate = rank + minlen;
        if (candidate > (ranks[target] ?? -1)) {
          ranks[target] = candidate;
        }
        indegree[target] = (indegree[target] ?? 1) - 1;
        if (indegree[target] == 0) {
          queue.add(target);
        }
      }
    }
    // Anything still unranked sat on a cycle the DFS could not open (possible
    // with self-referential aliases); park it after everything else.
    var maxRank = 0;
    for (final rank in ranks.values) {
      maxRank = math.max(maxRank, rank);
    }
    for (final node in _all) {
      node.rank = ranks[node.id] ?? (maxRank += 2);
    }
  }

  void _buildLayers() {
    var maxRank = 0;
    for (final node in _all) {
      maxRank = math.max(maxRank, node.rank);
    }
    _layers = List.generate(maxRank + 1, (_) => <_LNode>[]);
    for (final node in _all) {
      _layers[node.rank].add(node);
    }
  }

  // ── 4. dummies ────────────────────────────────────────────────────────────

  void _insertDummies(List<CcMermaidEdge> edges, Set<int> reversed) {
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final isReversed = reversed.contains(i);
      final (fromId, toId) = _oriented(edge, isReversed);
      final source = _byId[fromId]!;
      final target = _byId[toId]!;
      final chain = <_LNode>[source];

      final labelLines = edge.hasLabel
          ? wrapMermaidLines(
              edge.labelLines,
              CcMermaidTextRole.edgeLabel,
              ruler,
              maxWidth: _kMaxEdgeLabelWidth,
            )
          : const <String>[];
      final labelSize = labelLines.isEmpty
          ? Size.zero
          : measureMermaidLines(
              labelLines,
              CcMermaidTextRole.edgeLabel,
              ruler,
              lineSpacing: style.lineSpacing,
            );
      final labelRank = source.rank + ((target.rank - source.rank) ~/ 2);

      for (var rank = source.rank + 1; rank < target.rank; rank++) {
        final carriesLabel = labelLines.isNotEmpty && rank == labelRank;
        final visual = carriesLabel
            ? Size(labelSize.width + 10, labelSize.height + 4)
            : const Size(1, 1);
        final dummy = _LNode.dummy(
          visualSize: visual,
          isLabel: carriesLabel,
          labelLines: carriesLabel ? labelLines : const [],
        );
        dummy.layoutSize = _horizontal ? swapAxes(visual) : visual;
        dummy.rank = rank;
        // A dummy inherits the cluster path shared by both ends, so a long edge
        // inside a subgraph is packed inside the box instead of splitting it.
        dummy.clusterPath = _sharedPath(source.clusterPath, target.clusterPath);
        _layers[rank].add(dummy);
        _all.add(dummy);
        chain.add(dummy);
      }
      chain.add(target);
      _routed.add(_LEdge(edge: edge, chain: chain, reversed: isReversed));
      for (var j = 0; j + 1 < chain.length; j++) {
        chain[j].down.add(chain[j + 1]);
        chain[j + 1].up.add(chain[j]);
      }
    }
  }

  static List<String> _sharedPath(List<String> a, List<String> b) {
    final shared = <String>[];
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) {
        break;
      }
      shared.add(a[i]);
    }
    return shared;
  }

  // ── 5. ordering ───────────────────────────────────────────────────────────

  void _order() {
    // Seed with a BFS from the first rank so declaration order shows through.
    var next = 0;
    final seen = <_LNode>{};
    final seed = <_LNode, int>{};
    void walk(_LNode node) {
      if (!seen.add(node)) {
        return;
      }
      seed[node] = next++;
      for (final child in node.down) {
        walk(child);
      }
    }

    for (final layer in _layers) {
      for (final node in layer) {
        walk(node);
      }
    }
    for (final layer in _layers) {
      layer.sort((a, b) => (seed[a] ?? 0).compareTo(seed[b] ?? 0));
      _reindex(layer);
    }

    var best = _snapshot();
    var bestCrossings = _crossings();
    for (var iteration = 0; iteration < 8; iteration++) {
      _sweep(downward: iteration.isEven);
      final crossings = _crossings();
      if (crossings < bestCrossings) {
        bestCrossings = crossings;
        best = _snapshot();
      }
    }
    _restore(best);
  }

  void _reindex(List<_LNode> layer) {
    for (var i = 0; i < layer.length; i++) {
      layer[i].order = i;
    }
  }

  List<List<_LNode>> _snapshot() => [
    for (final layer in _layers) [...layer],
  ];

  void _restore(List<List<_LNode>> snapshot) {
    for (var r = 0; r < _layers.length; r++) {
      _layers[r] = snapshot[r];
      _reindex(_layers[r]);
    }
  }

  void _sweep({required bool downward}) {
    final indices = downward
        ? [for (var r = 1; r < _layers.length; r++) r]
        : [for (var r = _layers.length - 2; r >= 0; r--) r];
    for (final r in indices) {
      final layer = _layers[r];
      final barycenters = <_LNode, double>{};
      for (final node in layer) {
        final neighbors = downward ? node.up : node.down;
        if (neighbors.isEmpty) {
          barycenters[node] = node.order.toDouble();
          continue;
        }
        var sum = 0.0;
        for (final neighbor in neighbors) {
          sum += neighbor.order;
        }
        barycenters[node] = sum / neighbors.length;
      }
      _layers[r] = _orderWithClusters(layer, barycenters, depth: 0);
      _reindex(_layers[r]);
    }
  }

  /// Sorts a layer by barycenter while keeping cluster members contiguous:
  /// nodes are grouped by their cluster path at [depth], groups are sorted by
  /// their mean barycenter, and each group is then sorted recursively.
  List<_LNode> _orderWithClusters(
    List<_LNode> layer,
    Map<_LNode, double> barycenters, {
    required int depth,
  }) {
    final groups = <String?, List<_LNode>>{};
    final groupOrder = <String?>[];
    for (final node in layer) {
      final key = node.clusterPath.length > depth
          ? node.clusterPath[depth]
          : null;
      // Unclustered nodes each form their own group so they can interleave.
      final groupKey = key ?? ' ${node.hashCode}';
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
        groupOrder.add(groupKey);
      }
      groups[groupKey]!.add(node);
    }
    double meanOf(List<_LNode> nodes) {
      var sum = 0.0;
      for (final node in nodes) {
        sum += barycenters[node] ?? node.order.toDouble();
      }
      return sum / nodes.length;
    }

    groupOrder.sort((a, b) => meanOf(groups[a]!).compareTo(meanOf(groups[b]!)));
    final out = <_LNode>[];
    for (final key in groupOrder) {
      final group = groups[key]!;
      if (group.length == 1) {
        out.add(group.first);
        continue;
      }
      out.addAll(_orderWithClusters(group, barycenters, depth: depth + 1));
    }
    return out;
  }

  int _crossings() {
    var total = 0;
    for (var r = 0; r + 1 < _layers.length; r++) {
      final pairs = <(int, int)>[];
      for (final node in _layers[r]) {
        for (final child in node.down) {
          pairs.add((node.order, child.order));
        }
      }
      for (var i = 0; i < pairs.length; i++) {
        for (var j = i + 1; j < pairs.length; j++) {
          final (a1, a2) = pairs[i];
          final (b1, b2) = pairs[j];
          if ((a1 - b1) * (a2 - b2) < 0) {
            total++;
          }
        }
      }
    }
    return total;
  }

  // ── 6. positions ──────────────────────────────────────────────────────────

  double _separation(_LNode a, _LNode b) {
    var gap = style.nodeSpacing;
    if (a.isDummy && b.isDummy) {
      gap *= 0.5;
    } else if (a.isDummy || b.isDummy) {
      gap *= 0.75;
    }
    // Every cluster boundary crossed between the two adds breathing room for
    // the box that will be drawn there.
    final shared = _sharedPath(a.clusterPath, b.clusterPath).length;
    final boundaries =
        (a.clusterPath.length - shared) + (b.clusterPath.length - shared);
    return gap + boundaries * style.clusterPadding;
  }

  void _assignInRank() {
    for (final layer in _layers) {
      var cursor = 0.0;
      for (var i = 0; i < layer.length; i++) {
        final node = layer[i];
        if (i > 0) {
          cursor += _separation(layer[i - 1], node);
        }
        node.x = cursor + node.layoutSize.width / 2;
        cursor = node.x + node.layoutSize.width / 2;
      }
    }

    for (var iteration = 0; iteration < 6; iteration++) {
      final downward = iteration.isEven;
      final indices = downward
          ? [for (var r = 1; r < _layers.length; r++) r]
          : [for (var r = _layers.length - 2; r >= 0; r--) r];
      for (final r in indices) {
        final layer = _layers[r];
        final desired = <double>[];
        for (final node in layer) {
          final neighbors = downward ? node.up : node.down;
          desired.add(neighbors.isEmpty ? node.x : _median(neighbors));
        }
        _placeLayer(layer, desired);
      }
    }

    var minX = double.infinity;
    for (final node in _all) {
      minX = math.min(minX, node.x - node.layoutSize.width / 2);
    }
    if (minX.isFinite && minX != 0) {
      for (final node in _all) {
        node.x -= minX;
      }
    }
  }

  double _median(List<_LNode> neighbors) {
    final values = [for (final neighbor in neighbors) neighbor.x]..sort();
    final middle = values.length ~/ 2;
    if (values.length.isOdd) {
      return values[middle];
    }
    return (values[middle - 1] + values[middle]) / 2;
  }

  /// Moves a layer's nodes toward [desired] without letting them overlap: a
  /// left-to-right pass establishes a feasible packing, then a right-to-left
  /// pass reclaims slack so nodes settle as close to their neighbors as the
  /// separation allows.
  void _placeLayer(List<_LNode> layer, List<double> desired) {
    if (layer.isEmpty) {
      return;
    }
    final positions = [...desired];
    for (var i = 1; i < layer.length; i++) {
      final minimum =
          positions[i - 1] +
          layer[i - 1].layoutSize.width / 2 +
          _separation(layer[i - 1], layer[i]) +
          layer[i].layoutSize.width / 2;
      positions[i] = math.max(positions[i], minimum);
    }
    for (var i = layer.length - 2; i >= 0; i--) {
      final maximum =
          positions[i + 1] -
          layer[i + 1].layoutSize.width / 2 -
          _separation(layer[i], layer[i + 1]) -
          layer[i].layoutSize.width / 2;
      final lowerBound = i == 0
          ? double.negativeInfinity
          : positions[i - 1] +
                layer[i - 1].layoutSize.width / 2 +
                _separation(layer[i - 1], layer[i]) +
                layer[i].layoutSize.width / 2;
      positions[i] = math.max(
        math.min(math.max(desired[i], lowerBound), maximum),
        lowerBound,
      );
      if (!positions[i].isFinite) {
        positions[i] = desired[i];
      }
    }
    for (var i = 0; i < layer.length; i++) {
      layer[i].x = positions[i];
    }
  }

  /// Places ranks along the flow axis; returns the total extent.
  double _assignRankAxis() {
    final clusterLabelHeight = ruler.lineHeight(CcMermaidTextRole.cluster);
    final extraTop = List<double>.filled(_layers.length, 0);
    final extraBottom = List<double>.filled(_layers.length, 0);
    for (final cluster in graph.clusters) {
      final members = _all.where(
        (node) => !node.isDummy && node.clusterPath.contains(cluster.id),
      );
      if (members.isEmpty) {
        continue;
      }
      var first = _layers.length - 1;
      var last = 0;
      for (final member in members) {
        first = math.min(first, member.rank);
        last = math.max(last, member.rank);
      }
      // A horizontal graph puts the cluster title on the leading edge too, but
      // the reserve is along the flow axis either way.
      extraTop[first] += style.clusterPadding + clusterLabelHeight;
      extraBottom[last] += style.clusterPadding;
    }

    var cursor = 0.0;
    for (var r = 0; r < _layers.length; r++) {
      var height = 0.0;
      for (final node in _layers[r]) {
        height = math.max(height, node.layoutSize.height);
      }
      cursor += extraTop[r];
      for (final node in _layers[r]) {
        node.y = cursor + height / 2;
      }
      cursor += height + extraBottom[r];
      if (r + 1 < _layers.length) {
        cursor += style.rankSpacing / 2;
      }
    }
    return cursor;
  }

  // ── 7. transform + emit ───────────────────────────────────────────────────

  Offset _toVisual(double x, double y, double yExtent) {
    return switch (graph.direction) {
      CcMermaidDirection.topDown => Offset(x, y),
      CcMermaidDirection.bottomUp => Offset(x, yExtent - y),
      CcMermaidDirection.leftRight => Offset(y, x),
      CcMermaidDirection.rightLeft => Offset(yExtent - y, x),
    };
  }

  Rect _visualRect(_LNode node, double yExtent) {
    final center = _toVisual(node.x, node.y, yExtent);
    return Rect.fromCenter(
      center: center,
      width: node.visualSize.width,
      height: node.visualSize.height,
    );
  }

  CcMermaidScene _emit(double yExtent) {
    final primitives = <CcMermaidPrimitive>[];
    final hitTargets = <CcMermaidHitTarget>[];
    final rects = <_LNode, Rect>{};
    for (final node in _all) {
      rects[node] = _visualRect(node, yExtent);
    }

    // Clusters go first (they sit behind their members).
    primitives.addAll(_clusterPrimitives(rects));

    // Edges next, so node fills cover the stubs where a line meets a box.
    for (final routed in _routed) {
      primitives.addAll(_edgePrimitives(routed, rects));
    }
    for (final (edge, node) in _selfLoops) {
      primitives.addAll(_selfLoopPrimitives(edge, rects[node]!));
    }

    for (final node in _all) {
      if (node.isDummy) {
        if (node.isLabel) {
          primitives.addAll(
            _edgeLabelPrimitives(node.labelLines, rects[node]!),
          );
        }
        continue;
      }
      primitives.addAll(_nodePrimitives(node.node!, rects[node]!));
      final diagramNode = node.node!;
      if (diagramNode.href != null || diagramNode.tooltip != null) {
        hitTargets.add(
          CcMermaidHitTarget(
            rect: rects[node]!,
            nodeId: diagramNode.id,
            href: diagramNode.href,
            tooltip: diagramNode.tooltip,
          ),
        );
      }
    }

    return finalizeScene(
      prependSceneTitle(primitives, graph.title, ruler),
      padding: style.canvasPadding,
      hitTargets: hitTargets,
    );
  }

  List<CcMermaidPrimitive> _clusterPrimitives(Map<_LNode, Rect> rects) {
    final out = <CcMermaidPrimitive>[];
    // Outer clusters first so a nested box paints on top of its parent.
    final sorted = [...graph.clusters]
      ..sort(
        (a, b) =>
            _clusterPath(a.id).length.compareTo(_clusterPath(b.id).length),
      );
    for (final cluster in sorted) {
      Rect? bounds;
      for (final entry in rects.entries) {
        if (!entry.key.clusterPath.contains(cluster.id)) {
          continue;
        }
        if (entry.key.isDummy && !entry.key.isLabel) {
          continue;
        }
        bounds = bounds == null
            ? entry.value
            : bounds.expandToInclude(entry.value);
      }
      if (bounds == null) {
        continue;
      }
      final labelLines = cluster.lines;
      final labelSize = measureMermaidLines(
        labelLines,
        CcMermaidTextRole.cluster,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      final box = Rect.fromLTRB(
        bounds.left - style.clusterPadding,
        bounds.top - style.clusterPadding - labelSize.height,
        bounds.right + style.clusterPadding,
        bounds.bottom + style.clusterPadding,
      );
      out.add(
        CcMermaidShapePrim(
          rect: box,
          shape: CcMermaidNodeShape.roundRect,
          role: CcMermaidPaintRole.cluster,
          dashed: true,
        ),
      );
      if (labelLines.isNotEmpty) {
        out.addAll(
          stackTextLines(
            labelLines,
            CcMermaidTextRole.cluster,
            ruler,
            box: Rect.fromLTWH(
              box.left + 10,
              box.top + 3,
              box.width - 20,
              labelSize.height,
            ),
            lineSpacing: style.lineSpacing,
            align: CcMermaidTextAlign.left,
            muted: true,
          ),
        );
      }
    }
    return out;
  }

  List<CcMermaidPrimitive> _nodePrimitives(CcMermaidNode node, Rect rect) {
    final out = <CcMermaidPrimitive>[];
    switch (node.shape) {
      case CcMermaidNodeShape.startPoint:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
            stroked: false,
          ),
        );
        return out;
      case CcMermaidNodeShape.endPoint:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
          ),
        );
        return out;
      case CcMermaidNodeShape.bar:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.accent,
            stroked: false,
          ),
        );
        return out;
      case CcMermaidNodeShape.choice:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.node,
          ),
        );
        return out;
      case CcMermaidNodeShape.note:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.note,
          ),
        );
        out.addAll(
          stackTextLines(
            wrapMermaidLines(
              node.displayLines,
              CcMermaidTextRole.note,
              ruler,
              maxWidth: _kMaxLabelWidth,
            ),
            CcMermaidTextRole.note,
            ruler,
            box: rect,
            lineSpacing: style.lineSpacing,
          ),
        );
        return out;
      case CcMermaidNodeShape.compartments:
        return _compartmentPrimitives(node, rect);
      default:
        out.add(
          CcMermaidShapePrim(
            rect: rect,
            shape: node.shape,
            role: CcMermaidPaintRole.node,
          ),
        );
        out.addAll(
          stackTextLines(
            wrapMermaidLines(
              node.displayLines,
              CcMermaidTextRole.label,
              ruler,
              maxWidth: _kMaxLabelWidth,
            ),
            CcMermaidTextRole.label,
            ruler,
            box: rect,
            lineSpacing: style.lineSpacing,
          ),
        );
        return out;
    }
  }

  List<CcMermaidPrimitive> _compartmentPrimitives(
    CcMermaidNode node,
    Rect rect,
  ) {
    final out = <CcMermaidPrimitive>[
      CcMermaidShapePrim(
        rect: rect,
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.node,
      ),
    ];
    final headerLines = [
      if (node.stereotype != null) '«${node.stereotype}»',
      ...node.displayLines,
    ];
    final headerSize = measureMermaidLines(
      headerLines,
      CcMermaidTextRole.label,
      ruler,
      lineSpacing: style.lineSpacing,
    );
    var y = rect.top + style.nodePadding.top;
    out.addAll(
      stackTextLines(
        headerLines,
        CcMermaidTextRole.label,
        ruler,
        box: Rect.fromLTWH(rect.left, y, rect.width, headerSize.height),
        lineSpacing: style.lineSpacing,
      ),
    );
    y += headerSize.height + style.nodePadding.bottom;

    for (final compartment in node.compartments) {
      out.add(
        CcMermaidPathPrim(
          points: [Offset(rect.left, y), Offset(rect.right, y)],
          role: CcMermaidPaintRole.divider,
        ),
      );
      y += style.nodePadding.top;
      for (final row in compartment) {
        final size = ruler.measure(row, CcMermaidTextRole.compartment);
        out.add(
          CcMermaidTextPrim(
            text: row,
            rect: Rect.fromLTWH(
              rect.left + style.nodePadding.left,
              y,
              rect.width - style.nodePadding.horizontal,
              size.height,
            ),
            role: CcMermaidTextRole.compartment,
            align: CcMermaidTextAlign.left,
          ),
        );
        y += size.height + style.lineSpacing;
      }
      y += style.nodePadding.bottom - style.lineSpacing;
    }
    return out;
  }

  List<CcMermaidPrimitive> _edgePrimitives(
    _LEdge routed,
    Map<_LNode, Rect> rects,
  ) {
    if (routed.edge.stroke == CcMermaidEdgeStroke.invisible) {
      return const [];
    }
    var points = [for (final node in routed.chain) rects[node]!.center];
    var first = routed.chain.first;
    var last = routed.chain.last;
    if (routed.reversed) {
      points = points.reversed.toList();
      final swap = first;
      first = last;
      last = swap;
    }
    points = dedupePoints(points);
    if (points.length < 2) {
      return const [];
    }
    points[0] = clipToShape(rects[first]!, first.node!.shape, points[1]);
    points[points.length - 1] = clipToShape(
      rects[last]!,
      last.node!.shape,
      points[points.length - 2],
    );

    final out = <CcMermaidPrimitive>[
      CcMermaidPathPrim(
        points: points,
        stroke: routed.edge.stroke,
        startMarker: routed.edge.startMarker,
        endMarker: routed.edge.endMarker,
        cornerRadius: style.edgeCornerRadius,
      ),
    ];
    out.addAll(_cardinalityPrimitives(routed.edge, points));
    return out;
  }

  /// Class/ER cardinality labels, tucked just inside each end of the line.
  List<CcMermaidPrimitive> _cardinalityPrimitives(
    CcMermaidEdge edge,
    List<Offset> points,
  ) {
    final out = <CcMermaidPrimitive>[];
    void place(String text, Offset anchor, Offset toward) {
      final size = ruler.measure(text, CcMermaidTextRole.edgeLabel);
      final direction = toward - anchor;
      final length = direction.distance;
      if (length == 0) {
        return;
      }
      final along = anchor + direction / length * (size.height + 8);
      // Nudge perpendicular so the text sits beside the line, not on it.
      final normal = Offset(-direction.dy, direction.dx) / length;
      final center = along + normal * (size.height / 2 + 2);
      out.add(
        CcMermaidTextPrim(
          text: text,
          rect: Rect.fromCenter(
            center: center,
            width: size.width,
            height: size.height,
          ),
          role: CcMermaidTextRole.edgeLabel,
          muted: true,
        ),
      );
    }

    if (edge.startCardinality != null) {
      place(edge.startCardinality!, points.first, points[1]);
    }
    if (edge.endCardinality != null) {
      place(edge.endCardinality!, points.last, points[points.length - 2]);
    }
    return out;
  }

  List<CcMermaidPrimitive> _edgeLabelPrimitives(List<String> lines, Rect rect) {
    return [
      CcMermaidShapePrim(
        rect: rect,
        shape: CcMermaidNodeShape.rect,
        role: CcMermaidPaintRole.edgeLabel,
        stroked: false,
      ),
      ...stackTextLines(
        lines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        box: rect,
        lineSpacing: style.lineSpacing,
      ),
    ];
  }

  /// A self-loop leaves the trailing edge of its node, bulges out, and comes
  /// back — the label rides outside the bulge.
  List<CcMermaidPrimitive> _selfLoopPrimitives(CcMermaidEdge edge, Rect rect) {
    const reach = _kSelfLoopReach;
    final points = _horizontal
        ? <Offset>[
            Offset(rect.center.dx - rect.width / 4, rect.bottom),
            Offset(rect.center.dx - rect.width / 4, rect.bottom + reach),
            Offset(rect.center.dx + rect.width / 4, rect.bottom + reach),
            Offset(rect.center.dx + rect.width / 4, rect.bottom),
          ]
        : <Offset>[
            Offset(rect.right, rect.center.dy - rect.height / 4),
            Offset(rect.right + reach, rect.center.dy - rect.height / 4),
            Offset(rect.right + reach, rect.center.dy + rect.height / 4),
            Offset(rect.right, rect.center.dy + rect.height / 4),
          ];
    final out = <CcMermaidPrimitive>[
      CcMermaidPathPrim(
        points: points,
        stroke: edge.stroke == CcMermaidEdgeStroke.invisible
            ? CcMermaidEdgeStroke.solid
            : edge.stroke,
        startMarker: edge.startMarker,
        endMarker: edge.endMarker,
        cornerRadius: 6,
      ),
    ];
    if (edge.hasLabel) {
      final lines = wrapMermaidLines(
        edge.labelLines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        maxWidth: _kMaxEdgeLabelWidth,
      );
      final size = measureMermaidLines(
        lines,
        CcMermaidTextRole.edgeLabel,
        ruler,
        lineSpacing: style.lineSpacing,
      );
      final labelRect = _horizontal
          ? Rect.fromCenter(
              center: Offset(
                rect.center.dx,
                rect.bottom + reach + size.height / 2 + 4,
              ),
              width: size.width + 8,
              height: size.height + 4,
            )
          : Rect.fromCenter(
              center: Offset(
                rect.right + reach + size.width / 2 + 6,
                rect.center.dy,
              ),
              width: size.width + 8,
              height: size.height + 4,
            );
      out.addAll(_edgeLabelPrimitives(lines, labelRect));
    }
    return out;
  }
}
