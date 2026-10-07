/// Compound Sugiyama-style layered layout for flowchart, state, class, and ER.
///
/// Every container (the diagram itself and each subgraph) is laid out as its
/// own layered graph, innermost first, and a laid-out subgraph then takes part
/// in its parent's layout as one box. An edge is ranked in the innermost
/// container that holds both of its ends; where it crosses into or out of a
/// subgraph it becomes a "leg" inside that subgraph, running between the
/// endpoint and a port on the box's leading or trailing border. That keeps
/// boxes from overlapping and lets edges enter a box where its target is.
///
/// Per container: DFS cycle-break (remember flips) → longest-path rank, with
/// sources pulled toward their successors (ranks doubled so edge labels sit on
/// free intermediate ranks) → ports → dummy nodes on multi-rank edges →
/// barycenter order → position → one transform for LR/RL/BT directions.
/// Edges are then routed orthogonally through their dummies, with parallel
/// jogs spread over separate tracks of the channel between two ranks.
library;

import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/brandes_kopf.dart';
import 'package:cc_markdown/src/mermaid/layout/geometry.dart';
import 'package:cc_markdown/src/mermaid/layout/graph_shapes.dart';
import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:cc_markdown/src/mermaid/layout/scene_ops.dart';
import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:cc_markdown/src/mermaid/model.dart';
import 'package:flutter/widgets.dart';

/// Smallest clearance between two jogs sharing a track of one channel.
const double _kTrackGap = 6;

/// Widest gap between neighboring edge ends on one side of a node.
const double _kMaxPortSpacing = 22;

/// Lays [graph] out into a paint-ready scene.
CcMermaidScene layoutMermaidGraph(
  CcMermaidGraph graph, {
  required CcMermaidStyle style,
  required CcMermaidTextRuler ruler,
}) {
  return _GraphLayout(graph: graph, style: style, ruler: ruler).run();
}

enum _Kind { node, cluster, dummy, port }

/// A node in one container's layered graph.
class _LNode {
  _LNode.real(CcMermaidNode this.node)
    : kind = _Kind.node,
      level = null,
      labelLines = const [],
      topPort = false;

  _LNode.cluster(_Level this.level)
    : kind = _Kind.cluster,
      node = null,
      labelLines = const [],
      topPort = false;

  _LNode.dummy({required this.visualSize, this.labelLines = const []})
    : kind = _Kind.dummy,
      node = null,
      level = null,
      topPort = false;

  _LNode.port({required this.topPort})
    : kind = _Kind.port,
      node = null,
      level = null,
      labelLines = const [],
      visualSize = const Size(1, 0);

  final _Kind kind;
  final CcMermaidNode? node;

  /// The container a cluster node stands for.
  final _Level? level;

  /// Label carried by a label dummy.
  final List<String> labelLines;

  /// Whether a port sits on the leading (rank 0) border rather than the
  /// trailing one.
  final bool topPort;

  /// Size in VISUAL space (what the painter draws).
  Size visualSize = Size.zero;

  /// Size in LAYOUT space (axes swapped for `LR`/`RL`).
  Size layoutSize = Size.zero;

  int rank = 0;
  int order = 0;

  /// Center along the in-rank axis (layout space).
  double x = 0;

  /// Center along the rank axis (layout space).
  double y = 0;

  /// Center inside the owning container's box (visual space).
  Offset local = Offset.zero;

  /// Final box (visual space, absolute).
  Rect rect = Rect.zero;

  /// Neighbors in the previous / next rank, after dummy insertion.
  final List<_LNode> up = [];
  final List<_LNode> down = [];

  bool get isDummy => kind == _Kind.dummy || kind == _Kind.port;
  bool get isLabel => labelLines.isNotEmpty;
}

/// An edge ranked inside a container, oriented from low to high rank.
class _LevelEdge {
  _LevelEdge({
    required this.index,
    required this.low,
    required this.high,
    required this.minlen,
    required this.labelLines,
  });

  final int index;
  final _LNode low;
  final _LNode high;
  final int minlen;
  final List<String> labelLines;
}

/// The part of an edge inside a container it crosses: between [member] and a
/// port on the leading ([top]) or trailing border.
class _Leg {
  _Leg(this.index, this.member, {required this.top});

  final int index;
  final _LNode member;
  final bool top;
}

/// The diagram itself or one subgraph, laid out as its own layered graph.
class _Level {
  _Level({required this.cluster});

  final CcMermaidCluster? cluster;
  CcMermaidDirection direction = CcMermaidDirection.topDown;

  /// Real nodes and child clusters, in first-appearance order.
  final List<_LNode> members = [];

  /// Members plus ports and dummies.
  final List<_LNode> all = [];
  final List<_LevelEdge> edges = [];
  final List<_Leg> legs = [];

  /// Edge index → the ranked chain it runs through here, low rank first.
  final Map<int, List<_LNode>> chains = {};
  List<List<_LNode>> layers = [];

  /// Box size, padding and title included (visual space).
  Size size = Size.zero;

  /// Per layer, its extent along the flow (canonical space, absolute).
  List<(double, double)>? spans;

  bool get horizontal => direction.isHorizontal;
}

/// Where an edge is ranked, and whether ranking flipped it.
class _Route {
  _Route(this.edge, this.level, {required this.reversed});

  final CcMermaidEdge edge;
  final _Level level;
  final bool reversed;
}

/// A cross-rank jog of a routed edge, placed once every route is known.
class _Jog {
  _Jog(this.level, this.rank);

  final _Level level;

  /// The jog runs in the channel between `rank` and `rank + 1`.
  final int rank;
  double lo = 0;
  double hi = 0;
  double along = 0;
  bool skip = false;
}

/// Maps visual space to a top-down "canonical" space for [direction] (rank
/// grows along +y, the in-rank axis is x) and back, so routing is written once.
Offset _canon(Offset p, CcMermaidDirection direction) => switch (direction) {
  CcMermaidDirection.topDown => p,
  CcMermaidDirection.bottomUp => Offset(p.dx, -p.dy),
  CcMermaidDirection.leftRight => Offset(p.dy, p.dx),
  CcMermaidDirection.rightLeft => Offset(p.dy, -p.dx),
};

Offset _uncanon(Offset c, CcMermaidDirection direction) => switch (direction) {
  CcMermaidDirection.topDown => c,
  CcMermaidDirection.bottomUp => Offset(c.dx, -c.dy),
  CcMermaidDirection.leftRight => Offset(c.dy, c.dx),
  CcMermaidDirection.rightLeft => Offset(-c.dy, c.dx),
};

Rect _canonRect(Rect r, CcMermaidDirection direction) => Rect.fromPoints(
  _canon(r.topLeft, direction),
  _canon(r.bottomRight, direction),
);

class _GraphLayout {
  _GraphLayout({required this.graph, required this.style, required this.ruler})
    : _shapes = MermaidGraphShapes(style: style, ruler: ruler);

  final CcMermaidGraph graph;
  final CcMermaidStyle style;
  final CcMermaidTextRuler ruler;
  final MermaidGraphShapes _shapes;

  final _Level _root = _Level(cluster: null);
  final Map<String, CcMermaidCluster> _clusters = {};
  final Map<String, _Level> _levels = {};
  final Map<String, _LNode> _nodeById = {};
  final Map<String, _LNode> _clusterNode = {};
  final Map<String, List<String>> _paths = {};
  final List<_Level> _postOrder = [];
  final Map<int, _Route> _routes = {};
  final List<(CcMermaidEdge, _LNode, _Level)> _selfLoops = [];
  final Map<_LNode, _Level> _ownerOf = {};

  /// (node, edge index) → where that edge meets the node, across the flow.
  final Map<(_LNode, int), double> _attach = {};

  CcMermaidScene run() {
    if (graph.nodes.isEmpty) {
      return CcMermaidScene.empty;
    }
    _buildLevels();
    _resolveEdges();
    _resolveDirections(_root, graph.direction);
    _collectPostOrder(_root);
    for (final level in _postOrder) {
      _layoutLevel(level);
    }
    _place(_root, Offset.zero);
    return _emit();
  }

  // ── 1. containers ─────────────────────────────────────────────────────────

  /// Cluster ids from the outermost down to [clusterId] (inclusive); empty for
  /// the diagram root or an unknown id.
  List<String> _pathOf(String? clusterId) {
    if (clusterId == null || !_clusters.containsKey(clusterId)) {
      return const [];
    }
    final cached = _paths[clusterId];
    if (cached != null) {
      return cached;
    }
    final path = <String>[];
    String? current = clusterId;
    // Guard against a malformed parent cycle in the source.
    while (current != null &&
        _clusters.containsKey(current) &&
        !path.contains(current) &&
        path.length < 16) {
      path.insert(0, current);
      current = _clusters[current]!.parentId;
    }
    return _paths[clusterId] = path;
  }

  _Level _levelOf(List<String> path) =>
      path.isEmpty ? _root : _levels[path.last]!;

  void _ensureCluster(String id) {
    if (_clusterNode.containsKey(id)) {
      return;
    }
    final path = _pathOf(id);
    final parentPath = path.sublist(0, path.length - 1);
    if (parentPath.isNotEmpty) {
      _ensureCluster(parentPath.last);
    }
    final level = _Level(cluster: _clusters[id]);
    final node = _LNode.cluster(level);
    final parent = _levelOf(parentPath);
    parent.members.add(node);
    _ownerOf[node] = parent;
    _levels[id] = level;
    _clusterNode[id] = node;
  }

  void _buildLevels() {
    for (final cluster in graph.clusters) {
      _clusters[cluster.id] = cluster;
    }
    for (final node in graph.nodes) {
      final path = _pathOf(node.clusterId);
      if (path.isNotEmpty) {
        _ensureCluster(path.last);
      }
      final layoutNode = _LNode.real(node);
      final level = _levelOf(path);
      level.members.add(layoutNode);
      _ownerOf[layoutNode] = level;
      _nodeById[node.id] = layoutNode;
    }
    for (final cluster in graph.clusters) {
      _ensureCluster(cluster.id);
    }
  }

  void _collectPostOrder(_Level level) {
    for (final member in level.members) {
      if (member.kind == _Kind.cluster) {
        _collectPostOrder(member.level!);
      }
    }
    _postOrder.add(level);
  }

  /// The containers enclosing an edge endpoint, outermost first; a cluster
  /// endpoint includes itself. Null when the id names nothing.
  List<String>? _endpointPath(String id) {
    final node = _nodeById[id];
    if (node != null) {
      return _pathOf(node.node!.clusterId);
    }
    if (_levels.containsKey(id)) {
      return _pathOf(id);
    }
    return null;
  }

  bool _isCluster(String id) =>
      !_nodeById.containsKey(id) && _levels.containsKey(id);

  // ── 2. edges ──────────────────────────────────────────────────────────────

  void _resolveEdges() {
    final pending = <_Level, List<(int, _LNode, _LNode, List<String>, int)>>{};
    final sidePaths = <int, (List<String>, List<String>, int)>{};

    for (var i = 0; i < graph.edges.length; i++) {
      final edge = graph.edges[i];
      final pathA = _endpointPath(edge.fromId);
      final pathB = _endpointPath(edge.toId);
      if (pathA == null || pathB == null) {
        continue;
      }
      if (edge.fromId == edge.toId) {
        final node = _nodeById[edge.fromId];
        if (node != null) {
          _selfLoops.add((edge, node, _ownerOf[node]!));
        }
        continue;
      }
      var common = 0;
      while (common < pathA.length &&
          common < pathB.length &&
          pathA[common] == pathB[common]) {
        common++;
      }
      final aCluster = _isCluster(edge.fromId);
      final bCluster = _isCluster(edge.toId);

      // An edge between a subgraph and something inside it runs from (or to)
      // the box's own border.
      if (aCluster && common == pathA.length) {
        _addLegs(i, pathB, pathA.length - 1, edge.toId, top: true);
        _routes[i] = _Route(edge, _levels[edge.fromId]!, reversed: false);
        continue;
      }
      if (bCluster && common == pathB.length) {
        _addLegs(i, pathA, pathB.length - 1, edge.fromId, top: false);
        _routes[i] = _Route(edge, _levels[edge.toId]!, reversed: false);
        continue;
      }

      final level = _levelOf(pathA.sublist(0, common));
      final childA = pathA.length > common
          ? _clusterNode[pathA[common]]!
          : _nodeById[edge.fromId]!;
      final childB = pathB.length > common
          ? _clusterNode[pathB[common]]!
          : _nodeById[edge.toId]!;
      final labelLines = edge.hasLabel
          ? wrapMermaidLines(
              edge.labelLines,
              CcMermaidTextRole.edgeLabel,
              ruler,
              maxWidth: kMermaidMaxEdgeLabelWidth,
            )
          : const <String>[];
      (pending[level] ??= []).add((
        i,
        childA,
        childB,
        labelLines,
        2 * edge.minRankSpan,
      ));
      sidePaths[i] = (pathA, pathB, common);
    }

    for (final MapEntry(key: level, value: edges) in pending.entries) {
      final reversed = _breakCycles(level, edges);
      for (var k = 0; k < edges.length; k++) {
        final (index, childA, childB, labelLines, minlen) = edges[k];
        final flip = reversed.contains(k);
        level.edges.add(
          _LevelEdge(
            index: index,
            low: flip ? childB : childA,
            high: flip ? childA : childB,
            minlen: minlen,
            labelLines: labelLines,
          ),
        );
        final edge = graph.edges[index];
        _routes[index] = _Route(edge, level, reversed: flip);
        final (pathA, pathB, common) = sidePaths[index]!;
        // The low end leaves its boxes through their trailing borders, the
        // high end enters through the leading ones.
        _addLegs(index, pathA, common, edge.fromId, top: flip);
        _addLegs(index, pathB, common, edge.toId, top: !flip);
      }
    }
  }

  /// Records a leg in each cluster of [path] from index [start] down to the
  /// endpoint [id] (a cluster endpoint needs no leg inside itself).
  void _addLegs(
    int index,
    List<String> path,
    int start,
    String id, {
    required bool top,
  }) {
    final endIsCluster = _isCluster(id);
    for (var k = start; k < path.length; k++) {
      if (k == path.length - 1 && endIsCluster) {
        break;
      }
      final member = k + 1 < path.length
          ? _clusterNode[path[k + 1]]!
          : _nodeById[id]!;
      _levels[path[k]]!.legs.add(_Leg(index, member, top: top));
    }
  }

  /// Reverses back edges so ranking sees a DAG. Returns the reversed set (by
  /// index into [edges]).
  Set<int> _breakCycles(
    _Level level,
    List<(int, _LNode, _LNode, List<String>, int)> edges,
  ) {
    final outgoing = <_LNode, List<int>>{};
    for (var k = 0; k < edges.length; k++) {
      (outgoing[edges[k].$2] ??= []).add(k);
    }
    final reversed = <int>{};
    final state = <_LNode, int>{}; // 0 unseen, 1 on stack, 2 done

    void visit(_LNode node) {
      state[node] = 1;
      for (final k in outgoing[node] ?? const <int>[]) {
        final target = edges[k].$3;
        final targetState = state[target] ?? 0;
        if (targetState == 1) {
          reversed.add(k);
          continue;
        }
        if (targetState == 0) {
          visit(target);
        }
      }
      state[node] = 2;
    }

    for (final member in level.members) {
      if ((state[member] ?? 0) == 0) {
        visit(member);
      }
    }
    return reversed;
  }

  /// A subgraph keeps its own `direction` only when nothing links across its
  /// border (mermaid's rule); otherwise it flows like its parent.
  void _resolveDirections(_Level level, CcMermaidDirection inherited) {
    final cluster = level.cluster;
    level.direction =
        cluster != null &&
            cluster.direction != null &&
            !_hasExternalEdge(cluster.id)
        ? cluster.direction!
        : inherited;
    for (final member in level.members) {
      if (member.kind == _Kind.cluster) {
        _resolveDirections(member.level!, level.direction);
      }
    }
  }

  bool _hasExternalEdge(String clusterId) {
    bool inside(String id) => _endpointPath(id)?.contains(clusterId) ?? false;
    for (final edge in graph.edges) {
      if (inside(edge.fromId) != inside(edge.toId)) {
        return true;
      }
    }
    return false;
  }

  // ── 3. one container ──────────────────────────────────────────────────────

  void _layoutLevel(_Level level) {
    for (final member in level.members) {
      member.visualSize = member.kind == _Kind.cluster
          ? member.level!.size
          : _shapes.measure(member.node!, horizontal: level.horizontal);
      member.layoutSize = level.horizontal
          ? swapAxes(member.visualSize)
          : member.visualSize;
    }
    level.all.addAll(level.members);
    _rank(level);
    _addPorts(level);
    _buildLayers(level);
    _insertDummies(level);
    _order(level);
    _assignInRank(level);
    final extent = _assignRankAxis(level);
    _box(level, extent);
  }

  void _rank(_Level level) {
    final members = level.members;
    final indegree = <_LNode, int>{for (final member in members) member: 0};
    final outgoing = <_LNode, List<(_LNode, int)>>{};
    for (final edge in level.edges) {
      // Ranks are doubled so every edge has a free intermediate rank for its
      // label; `minRankSpan` (mermaid's extra dashes) multiplies that.
      (outgoing[edge.low] ??= []).add((edge.high, edge.minlen));
      indegree[edge.high] = (indegree[edge.high] ?? 0) + 1;
    }
    final remaining = {...indegree};
    final queue = <_LNode>[
      for (final member in members)
        if (remaining[member] == 0) member,
    ];
    final ranks = <_LNode, int>{for (final member in queue) member: 0};
    final topo = <_LNode>[];
    var head = 0;
    while (head < queue.length) {
      final node = queue[head++];
      topo.add(node);
      final rank = ranks[node] ?? 0;
      for (final (target, minlen)
          in outgoing[node] ?? const <(_LNode, int)>[]) {
        if (rank + minlen > (ranks[target] ?? -1)) {
          ranks[target] = rank + minlen;
        }
        remaining[target] = remaining[target]! - 1;
        if (remaining[target] == 0) {
          queue.add(target);
        }
      }
    }
    var maxRank = 0;
    for (final rank in ranks.values) {
      maxRank = math.max(maxRank, rank);
    }
    // Anything still unranked sat on a cycle the DFS could not open; park it
    // after everything else.
    for (final member in members) {
      member.rank = ranks[member] ?? (maxRank += 2);
    }

    final topLegs = {
      for (final leg in level.legs)
        if (leg.top) leg.member,
    };
    final bottomLegs = {
      for (final leg in level.legs)
        if (!leg.top) leg.member,
    };
    // Longest-path ranking drags every source to the first rank; pull each one
    // down next to its nearest successor instead, as dagre's tightening does.
    // A member fed from the leading border stays up top.
    for (final node in topo.reversed) {
      final targets = outgoing[node];
      if (indegree[node] != 0 || targets == null || topLegs.contains(node)) {
        continue;
      }
      var best = 1 << 30;
      for (final (target, minlen) in targets) {
        best = math.min(best, target.rank - minlen);
      }
      node.rank = best;
    }
    // A member whose only ties leave through the trailing border sinks to the
    // last rank, so its leg does not cross the whole box.
    var last = 0;
    var first = 1 << 30;
    for (final member in members) {
      last = math.max(last, member.rank);
      first = math.min(first, member.rank);
    }
    for (final member in members) {
      if (indegree[member] == 0 &&
          outgoing[member] == null &&
          bottomLegs.contains(member) &&
          !topLegs.contains(member)) {
        member.rank = last;
      }
    }
    if (first != 0 && first != 1 << 30) {
      for (final member in members) {
        member.rank -= first;
      }
    }
  }

  void _addPorts(_Level level) {
    final hasTop = level.legs.any((leg) => leg.top);
    if (hasTop) {
      for (final member in level.members) {
        member.rank += 1;
      }
    }
    var maxRank = 0;
    for (final member in level.members) {
      maxRank = math.max(maxRank, member.rank);
    }
    for (final leg in level.legs) {
      final port = _LNode.port(topPort: leg.top);
      port.rank = leg.top ? 0 : maxRank + 1;
      level.all.add(port);
      _ownerOf[port] = level;
      if (leg.top) {
        _link(level, leg.index, port, leg.member, const []);
      } else {
        _link(level, leg.index, leg.member, port, const []);
      }
    }
  }

  /// Registers a chain to build once layers exist.
  final Map<_Level, List<(int, _LNode, _LNode, List<String>)>> _pendingChains =
      {};

  void _link(
    _Level level,
    int index,
    _LNode low,
    _LNode high,
    List<String> labelLines,
  ) {
    (_pendingChains[level] ??= []).add((index, low, high, labelLines));
  }

  void _buildLayers(_Level level) {
    var maxRank = 0;
    for (final node in level.all) {
      maxRank = math.max(maxRank, node.rank);
    }
    level.layers = List.generate(maxRank + 1, (_) => <_LNode>[]);
    for (final node in level.all) {
      level.layers[node.rank].add(node);
    }
  }

  void _insertDummies(_Level level) {
    final chains = [
      for (final edge in level.edges)
        (edge.index, edge.low, edge.high, edge.labelLines),
      ...?_pendingChains[level],
    ];
    for (final (index, source, target, labelLines) in chains) {
      final chain = <_LNode>[source];
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
        final dummy = _LNode.dummy(
          visualSize: carriesLabel
              ? Size(labelSize.width + 10, labelSize.height + 4)
              : const Size(1, 1),
          labelLines: carriesLabel ? labelLines : const [],
        );
        dummy.layoutSize = level.horizontal
            ? swapAxes(dummy.visualSize)
            : dummy.visualSize;
        dummy.rank = rank;
        level.layers[rank].add(dummy);
        level.all.add(dummy);
        _ownerOf[dummy] = level;
        chain.add(dummy);
      }
      chain.add(target);
      level.chains[index] = chain;
      for (var j = 0; j + 1 < chain.length; j++) {
        chain[j].down.add(chain[j + 1]);
        chain[j + 1].up.add(chain[j]);
      }
    }
  }

  // ── 4. ordering ───────────────────────────────────────────────────────────

  void _order(_Level level) {
    final layers = level.layers;
    // Seed with a DFS from the first rank so declaration order shows through.
    var next = 0;
    final seed = <_LNode, int>{};
    void walk(_LNode node) {
      if (seed.containsKey(node)) {
        return;
      }
      seed[node] = next++;
      for (final child in node.down) {
        walk(child);
      }
    }

    for (final layer in layers) {
      for (final node in layer) {
        walk(node);
      }
    }
    for (final layer in layers) {
      layer.sort((a, b) => seed[a]!.compareTo(seed[b]!));
      _reindex(layer);
    }

    var best = _snapshot(layers);
    var bestCrossings = _crossings(layers);
    for (var iteration = 0; iteration < 12 && bestCrossings > 0; iteration++) {
      _sweep(layers, downward: iteration.isEven);
      final crossings = _crossings(layers);
      if (crossings < bestCrossings) {
        bestCrossings = crossings;
        best = _snapshot(layers);
      }
    }
    for (var r = 0; r < layers.length; r++) {
      layers[r]
        ..clear()
        ..addAll(best[r]);
      _reindex(layers[r]);
    }
  }

  void _reindex(List<_LNode> layer) {
    for (var i = 0; i < layer.length; i++) {
      layer[i].order = i;
    }
  }

  List<List<_LNode>> _snapshot(List<List<_LNode>> layers) => [
    for (final layer in layers) [...layer],
  ];

  void _sweep(List<List<_LNode>> layers, {required bool downward}) {
    final indices = downward
        ? [for (var r = 1; r < layers.length; r++) r]
        : [for (var r = layers.length - 2; r >= 0; r--) r];
    for (final r in indices) {
      final layer = layers[r];
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
      layer.sort((a, b) {
        final byCenter = barycenters[a]!.compareTo(barycenters[b]!);
        return byCenter != 0 ? byCenter : a.order.compareTo(b.order);
      });
      _reindex(layer);
    }
  }

  int _crossings(List<List<_LNode>> layers) {
    var total = 0;
    for (var r = 0; r + 1 < layers.length; r++) {
      final pairs = <(int, int)>[];
      for (final node in layers[r]) {
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

  // ── 5. positions ──────────────────────────────────────────────────────────

  double _separation(_LNode a, _LNode b) {
    var gap = style.nodeSpacing;
    if (a.isDummy && b.isDummy) {
      gap *= 0.5;
    } else if (a.isDummy || b.isDummy) {
      gap *= 0.75;
    }
    return gap;
  }

  void _assignInRank(_Level level) {
    final nodes = level.all;
    final index = <_LNode, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i]: i,
    };
    final xs = brandesKopfPositions(
      nodeCount: nodes.length,
      layers: [
        for (final layer in level.layers)
          [for (final node in layer) index[node]!],
      ],
      up: [
        for (final node in nodes) [for (final u in node.up) index[u]!],
      ],
      down: [
        for (final node in nodes) [for (final d in node.down) index[d]!],
      ],
      isDummy: [for (final node in nodes) node.isDummy],
      widths: [for (final node in nodes) node.layoutSize.width],
      separation: (a, b) =>
          nodes[a].layoutSize.width / 2 +
          _separation(nodes[a], nodes[b]) +
          nodes[b].layoutSize.width / 2,
    );
    var minX = double.infinity;
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].x = xs[i];
      minX = math.min(minX, xs[i] - nodes[i].layoutSize.width / 2);
    }
    if (minX.isFinite && minX != 0) {
      for (final node in nodes) {
        node.x -= minX;
      }
    }
  }

  bool _isPortLayer(List<_LNode> layer) =>
      layer.isNotEmpty && layer.every((node) => node.kind == _Kind.port);

  /// Places ranks along the flow axis; returns the total extent. Port layers
  /// take no room: they are snapped onto the box border afterwards.
  double _assignRankAxis(_Level level) {
    final layers = level.layers;
    var cursor = 0.0;
    for (var r = 0; r < layers.length; r++) {
      var height = 0.0;
      for (final node in layers[r]) {
        height = math.max(height, node.layoutSize.height);
      }
      if (r > 0 && !_isPortLayer(layers[r]) && !_isPortLayer(layers[r - 1])) {
        cursor += style.rankSpacing / 2;
      }
      for (final node in layers[r]) {
        node.y = cursor + height / 2;
      }
      cursor += height;
    }
    return cursor;
  }

  /// Turns layout coordinates into the container's box: transform to visual
  /// space, add the subgraph padding and title band, snap ports to the border.
  void _box(_Level level, double extent) {
    var width = 0.0;
    for (final node in level.all) {
      width = math.max(width, node.x + node.layoutSize.width / 2);
    }
    final content = level.horizontal
        ? Size(extent, width)
        : Size(width, extent);

    final cluster = level.cluster;
    var padTop = 0.0;
    var padBottom = 0.0;
    var boxWidth = content.width;
    if (cluster != null) {
      final pad = style.clusterPadding;
      final title = _shapes.clusterTitleSize(cluster);
      padBottom = pad;
      padTop = cluster.lines.isEmpty
          ? pad
          : _shapes.clusterTitleTop + title.height + pad * 0.75;
      boxWidth = math.max(content.width + 2 * pad, title.width + 24);
    }
    final boxHeight = content.height + padTop + padBottom;
    final offset = Offset((boxWidth - content.width) / 2, padTop);

    for (final node in level.all) {
      final center = switch (level.direction) {
        CcMermaidDirection.topDown => Offset(node.x, node.y),
        CcMermaidDirection.bottomUp => Offset(node.x, extent - node.y),
        CcMermaidDirection.leftRight => Offset(node.y, node.x),
        CcMermaidDirection.rightLeft => Offset(extent - node.y, node.x),
      };
      var local = offset + center;
      if (node.kind == _Kind.port) {
        final leading = node.topPort;
        local = switch (level.direction) {
          CcMermaidDirection.topDown => Offset(
            local.dx,
            leading ? 0 : boxHeight,
          ),
          CcMermaidDirection.bottomUp => Offset(
            local.dx,
            leading ? boxHeight : 0,
          ),
          CcMermaidDirection.leftRight => Offset(
            leading ? 0 : boxWidth,
            local.dy,
          ),
          CcMermaidDirection.rightLeft => Offset(
            leading ? boxWidth : 0,
            local.dy,
          ),
        };
      }
      node.local = local;
    }
    level.size = Size(boxWidth, boxHeight);
    _clearTitle(level);
  }

  /// Whether legs reach [level]'s title band through its top border: the
  /// leading ports of a `TD` box, the trailing ones of a `BT` box.
  bool _titleSidePort(_Level level, _LNode node) =>
      node.kind == _Kind.port &&
      !level.horizontal &&
      node.topPort == (level.direction == CcMermaidDirection.topDown);

  /// Slides ports that would run down through the title text to its right.
  void _clearTitle(_Level level) {
    final cluster = level.cluster;
    if (cluster == null || cluster.lines.isEmpty) {
      return;
    }
    final ports = [
      for (final node in level.all)
        if (_titleSidePort(level, node)) node,
    ]..sort((a, b) => a.local.dx.compareTo(b.local.dx));
    var minimum = 12 + _shapes.clusterTitleSize(cluster).width + 8;
    final maximum = level.size.width - style.cornerRadius - 4;
    for (final port in ports) {
      if (port.local.dx >= minimum) {
        break;
      }
      port.local = Offset(math.min(minimum, maximum), port.local.dy);
      minimum += style.nodeSpacing / 2;
    }
  }

  void _place(_Level level, Offset origin) {
    for (final node in level.all) {
      final size = node.kind == _Kind.port ? Size.zero : node.visualSize;
      node.rect = Rect.fromCenter(
        center: origin + node.local,
        width: size.width,
        height: size.height,
      );
      if (node.kind == _Kind.cluster) {
        _place(node.level!, node.rect.topLeft);
      }
    }
  }

  // ── 6. routing ────────────────────────────────────────────────────────────

  /// Spreads the edge ends meeting one side of a node across that side, in
  /// the order of where each edge comes from, so arrowheads do not pile up.
  void _spreadAttachments(_Level level) {
    final direction = level.direction;
    final sides = <(_LNode, bool), List<(double, int)>>{};
    for (final MapEntry(key: index, value: chain) in level.chains.entries) {
      if (chain.length < 2) {
        continue;
      }
      final first = chain.first;
      if (first.kind == _Kind.node) {
        final neighbor = _canon(chain[1].rect.center, direction).dx;
        (sides[(first, false)] ??= []).add((neighbor, index));
      }
      final last = chain.last;
      if (last.kind == _Kind.node) {
        final neighbor = _canon(
          chain[chain.length - 2].rect.center,
          direction,
        ).dx;
        (sides[(last, true)] ??= []).add((neighbor, index));
      }
    }
    for (final MapEntry(key: (node, _), value: ends) in sides.entries) {
      final rect = _canonRect(node.rect, direction);
      if (ends.length == 1 || !_spreads(node.node!.shape)) {
        for (final (_, index) in ends) {
          _attach[(node, index)] = rect.center.dx;
        }
        continue;
      }
      ends.sort((a, b) {
        final byAcross = a.$1.compareTo(b.$1);
        return byAcross != 0 ? byAcross : a.$2.compareTo(b.$2);
      });
      final usable = node.node!.shape == CcMermaidNodeShape.stadium
          ? math.min(rect.width * 0.8, rect.width - rect.height)
          : rect.width * 0.8;
      final spacing = math.min(
        math.max(usable, 0) / (ends.length - 1),
        _kMaxPortSpacing,
      );
      final start = rect.center.dx - spacing * (ends.length - 1) / 2;
      for (var i = 0; i < ends.length; i++) {
        _attach[(node, ends[i].$2)] = start + spacing * i;
      }
    }
  }

  static bool _spreads(CcMermaidNodeShape shape) => switch (shape) {
    CcMermaidNodeShape.circle ||
    CcMermaidNodeShape.doubleCircle ||
    CcMermaidNodeShape.diamond ||
    CcMermaidNodeShape.choice ||
    CcMermaidNodeShape.startPoint ||
    CcMermaidNodeShape.endPoint => false,
    _ => true,
  };

  /// The canonical-space points (and pending jogs) of edge [index] through
  /// [level], descending into subgraph legs at either end.
  List<Object> _routeIn(_Level level, int index, CcMermaidDirection direction) {
    final chain = level.chains[index]!;
    final out = <Object>[];
    for (var i = 0; i < chain.length; i++) {
      final node = chain[i];
      final isFirst = i == 0;
      if (i > 0) {
        out.add(_Jog(level, chain[i - 1].rank));
      }
      switch (node.kind) {
        case _Kind.dummy || _Kind.port:
          out.add(_canon(node.rect.center, direction));
        case _Kind.node:
          final rect = _canonRect(node.rect, direction);
          final across = _attach[(node, index)] ?? rect.center.dx;
          out.add(Offset(across, isFirst ? rect.bottom : rect.top));
        case _Kind.cluster:
          if (node.level!.chains.containsKey(index)) {
            out.addAll(_routeIn(node.level!, index, direction));
            break;
          }
          // The edge names the subgraph itself: meet its border straight on
          // from wherever the neighbor is.
          final rect = _canonRect(node.rect, direction);
          final neighbor = _canon(
            chain[isFirst ? 1 : i - 1].rect.center,
            direction,
          ).dx;
          final inset = style.cornerRadius + 6;
          final across = rect.width > 2 * inset
              ? neighbor.clamp(rect.left + inset, rect.right - inset)
              : rect.center.dx;
          out.add(Offset(across, isFirst ? rect.bottom : rect.top));
      }
    }
    return out;
  }

  List<(double, double)> _spansOf(_Level level) {
    final cached = level.spans;
    if (cached != null) {
      return cached;
    }
    final spans = [
      for (final layer in level.layers) _layerSpan(layer, level.direction),
    ];
    // Jogs next to the title-side border wait until they are past the title.
    final cluster = level.cluster;
    if (cluster != null && cluster.lines.isNotEmpty && spans.isNotEmpty) {
      final band =
          _shapes.clusterTitleTop +
          _shapes.clusterTitleSize(cluster).height +
          2;
      final topDown = level.direction == CcMermaidDirection.topDown;
      final edge = topDown ? 0 : spans.length - 1;
      final layer = level.layers[edge];
      if (layer.isNotEmpty &&
          layer.every((node) => _titleSidePort(level, node))) {
        final (lo, hi) = spans[edge];
        spans[edge] = topDown ? (lo, lo + band) : (hi - band, hi);
      }
    }
    return level.spans = spans;
  }

  (double, double) _layerSpan(List<_LNode> layer, CcMermaidDirection dir) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final node in layer) {
      final rect = _canonRect(node.rect, dir);
      lo = math.min(lo, rect.top);
      hi = math.max(hi, rect.bottom);
    }
    return (lo, hi);
  }

  /// Every routed edge's points (visual space), keyed by edge index.
  Map<int, List<Offset>> _routeAll() {
    for (final level in _postOrder) {
      _spreadAttachments(level);
    }
    final raw = <int, List<Object>>{};
    final channels = <(_Level, int), List<_Jog>>{};
    for (final MapEntry(key: index, value: route) in _routes.entries) {
      if (!route.level.chains.containsKey(index)) {
        continue;
      }
      final items = _routeIn(route.level, index, route.level.direction);
      _snapEnds(items);
      for (var k = 0; k < items.length; k++) {
        final item = items[k];
        if (item is! _Jog) {
          continue;
        }
        final before = items[k - 1] as Offset;
        final after = items[k + 1] as Offset;
        if ((before.dx - after.dx).abs() < 0.5) {
          item.skip = true;
          continue;
        }
        item
          ..lo = math.min(before.dx, after.dx)
          ..hi = math.max(before.dx, after.dx);
        (channels[(item.level, item.rank)] ??= []).add(item);
      }
      raw[index] = items;
    }

    for (final MapEntry(key: (level, rank), value: jogs) in channels.entries) {
      final spans = _spansOf(level);
      final top = spans[rank].$2;
      final bottom = spans[rank + 1].$1;
      jogs.sort((a, b) => a.lo.compareTo(b.lo));
      final trackEnds = <double>[];
      final tracks = <_Jog, int>{};
      for (final jog in jogs) {
        var track = trackEnds.indexWhere((end) => end + _kTrackGap < jog.lo);
        if (track < 0) {
          track = trackEnds.length;
          trackEnds.add(jog.hi);
        } else {
          trackEnds[track] = jog.hi;
        }
        tracks[jog] = track;
      }
      final count = trackEnds.length;
      for (final jog in jogs) {
        jog.along = bottom - top < 2
            ? (top + bottom) / 2
            : top + (bottom - top) * (tracks[jog]! + 1) / (count + 1);
      }
    }

    final out = <int, List<Offset>>{};
    for (final MapEntry(key: index, value: items) in raw.entries) {
      final direction = _routes[index]!.level.direction;
      final points = <Offset>[];
      for (var k = 0; k < items.length; k++) {
        final item = items[k];
        if (item is Offset) {
          points.add(item);
          continue;
        }
        final jog = item as _Jog;
        if (jog.skip) {
          // Keep the run straight: snap onto the shared across coordinate.
          continue;
        }
        final before = items[k - 1] as Offset;
        final after = items[k + 1] as Offset;
        points
          ..add(Offset(before.dx, jog.along))
          ..add(Offset(after.dx, jog.along));
      }
      var visual = _simplify([
        for (final point in points) _uncanon(point, direction),
      ]);
      if (_routes[index]!.reversed) {
        visual = visual.reversed.toList();
      }
      out[index] = visual;
    }
    return out;
  }

  /// Slides an end point onto the run it joins when the two miss by a hair,
  /// trading a stair-step for an end a few pixels off its spread position.
  static void _snapEnds(List<Object> items) {
    const tolerance = 4.0;
    if (items.length < 3) {
      return;
    }
    final first = items.first as Offset;
    final second = items[2] as Offset;
    if ((first.dx - second.dx).abs() < tolerance) {
      items[0] = Offset(second.dx, first.dy);
    }
    final last = items.last as Offset;
    final beforeLast = items[items.length - 3] as Offset;
    if ((last.dx - beforeLast.dx).abs() < tolerance) {
      items[items.length - 1] = Offset(beforeLast.dx, last.dy);
    }
  }

  /// Drops repeated points and the middle of straight runs.
  static List<Offset> _simplify(List<Offset> points) {
    final deduped = dedupePoints(points);
    if (deduped.length < 3) {
      return deduped;
    }
    final out = <Offset>[deduped.first];
    for (var i = 1; i < deduped.length - 1; i++) {
      final a = out.last;
      final b = deduped[i];
      final c = deduped[i + 1];
      final cross =
          (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
      if (cross.abs() > 0.01) {
        out.add(b);
      }
    }
    out.add(deduped.last);
    return out;
  }

  // ── 7. emit ───────────────────────────────────────────────────────────────

  CcMermaidScene _emit() {
    final primitives = <CcMermaidPrimitive>[];
    final hitTargets = <CcMermaidHitTarget>[];

    // Clusters go first (they sit behind their members), outer before inner.
    void clusters(_Level level) {
      for (final member in level.members) {
        if (member.kind == _Kind.cluster) {
          primitives.addAll(
            _shapes.clusterPrimitives(member.level!.cluster!, member.rect),
          );
          clusters(member.level!);
        }
      }
    }

    clusters(_root);

    // Edges next, so node fills cover the stubs where a line meets a box.
    final routes = _routeAll();
    for (final MapEntry(key: index, value: points) in routes.entries) {
      primitives.addAll(_shapes.edgePrimitives(_routes[index]!.edge, points));
    }
    for (final (edge, node, level) in _selfLoops) {
      primitives.addAll(
        _shapes.selfLoopPrimitives(
          edge,
          node.rect,
          horizontal: level.horizontal,
        ),
      );
    }

    for (final level in _postOrder) {
      for (final node in level.all) {
        if (node.isLabel) {
          primitives.addAll(
            _shapes.edgeLabelPrimitives(node.labelLines, node.rect),
          );
        }
        if (node.kind != _Kind.node) {
          continue;
        }
        final diagramNode = node.node!;
        primitives.addAll(_shapes.nodePrimitives(diagramNode, node.rect));
        if (diagramNode.href != null || diagramNode.tooltip != null) {
          hitTargets.add(
            CcMermaidHitTarget(
              rect: node.rect,
              nodeId: diagramNode.id,
              href: diagramNode.href,
              tooltip: diagramNode.tooltip,
            ),
          );
        }
      }
    }

    return finalizeScene(
      prependSceneTitle(primitives, graph.title, ruler),
      padding: style.canvasPadding,
      hitTargets: hitTargets,
    );
  }
}
