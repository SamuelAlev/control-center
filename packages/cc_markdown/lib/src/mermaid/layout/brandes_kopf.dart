/// Brandes–Köpf in-rank coordinate assignment, as dagre runs it.
///
/// Four passes (up/down × left/right) each align every node with a median
/// neighbor into vertical blocks, then compact the blocks as tightly as the
/// separation allows; the result balances the four. Long edges come out as
/// straight runs because dummy-to-dummy segments are never sacrificed to an
/// alignment that would cross them.
library;

import 'dart:math' as math;

/// Assigns an in-rank center to every node.
///
/// Nodes are integers `0 … n-1`. [layers] lists each rank's nodes in order;
/// [up] / [down] are each node's neighbors in the previous / next rank;
/// [isDummy] marks routing dummies; [separation] is the minimum distance
/// between the CENTERS of two adjacent nodes in a rank (half widths included).
List<double> brandesKopfPositions({
  required int nodeCount,
  required List<List<int>> layers,
  required List<List<int>> up,
  required List<List<int>> down,
  required List<bool> isDummy,
  required double Function(int left, int right) separation,
  required List<double> widths,
}) {
  final conflicts = _type1Conflicts(layers, up, isDummy, nodeCount);
  final passes = <List<double>>[];
  for (final vertical in const [true, false]) {
    var layering = vertical ? layers : layers.reversed.toList();
    for (final leftToRight in const [true, false]) {
      if (!leftToRight) {
        layering = [for (final layer in layering) layer.reversed.toList()];
      }
      final neighbors = vertical ? up : down;
      final (root, align) = _verticalAlignment(
        layering,
        neighbors,
        conflicts,
        nodeCount,
      );
      var xs = _horizontalCompaction(
        layering,
        root,
        align,
        nodeCount,
        separation,
      );
      if (!leftToRight) {
        xs = [for (final x in xs) -x];
      }
      passes.add(xs);
    }
  }

  // Align every pass to the narrowest one, then take the median of the four.
  var narrowest = 0;
  var narrowestWidth = double.infinity;
  for (var p = 0; p < passes.length; p++) {
    final (lo, hi) = _extent(passes[p], widths);
    if (hi - lo < narrowestWidth) {
      narrowestWidth = hi - lo;
      narrowest = p;
    }
  }
  final (targetLo, targetHi) = _extent(passes[narrowest], widths);
  for (var p = 0; p < passes.length; p++) {
    if (p == narrowest) {
      continue;
    }
    final (lo, hi) = _extent(passes[p], widths);
    // Passes 0 and 2 compacted leftward, 1 and 3 rightward.
    final delta = p.isEven ? targetLo - lo : targetHi - hi;
    if (delta != 0) {
      passes[p] = [for (final x in passes[p]) x + delta];
    }
  }
  return [
    for (var v = 0; v < nodeCount; v++)
      () {
        final values = [for (final xs in passes) xs[v]]..sort();
        return (values[1] + values[2]) / 2;
      }(),
  ];
}

(double, double) _extent(List<double> xs, List<double> widths) {
  var lo = double.infinity;
  var hi = double.negativeInfinity;
  for (var v = 0; v < xs.length; v++) {
    lo = math.min(lo, xs[v] - widths[v] / 2);
    hi = math.max(hi, xs[v] + widths[v] / 2);
  }
  return (lo, hi);
}

/// Marks segments that cross an inner (dummy-to-dummy) segment: aligning
/// along them would bend a long edge.
Set<int> _type1Conflicts(
  List<List<int>> layers,
  List<List<int>> up,
  List<bool> isDummy,
  int nodeCount,
) {
  final conflicts = <int>{};
  final order = List<int>.filled(nodeCount, 0);
  for (final layer in layers) {
    for (var i = 0; i < layer.length; i++) {
      order[layer[i]] = i;
    }
  }
  for (var r = 1; r < layers.length; r++) {
    final previous = layers[r - 1];
    final layer = layers[r];
    var k0 = 0;
    var scan = 0;
    for (var i = 0; i < layer.length; i++) {
      final v = layer[i];
      int? inner;
      if (isDummy[v]) {
        for (final u in up[v]) {
          if (isDummy[u]) {
            inner = u;
            break;
          }
        }
      }
      if (inner == null && i != layer.length - 1) {
        continue;
      }
      final k1 = inner == null ? previous.length : order[inner];
      for (final scanned in layer.sublist(scan, i + 1)) {
        for (final u in up[scanned]) {
          final position = order[u];
          if ((position < k0 || k1 < position) &&
              !(isDummy[u] && isDummy[scanned])) {
            conflicts.add(_key(u, scanned, nodeCount));
          }
        }
      }
      scan = i + 1;
      k0 = k1;
    }
  }
  return conflicts;
}

int _key(int a, int b, int n) => a < b ? a * n + b : b * n + a;

(List<int>, List<int>) _verticalAlignment(
  List<List<int>> layering,
  List<List<int>> neighbors,
  Set<int> conflicts,
  int nodeCount,
) {
  final root = List<int>.generate(nodeCount, (v) => v);
  final align = List<int>.generate(nodeCount, (v) => v);
  final position = List<int>.filled(nodeCount, 0);
  for (final layer in layering) {
    for (var i = 0; i < layer.length; i++) {
      position[layer[i]] = i;
    }
  }
  for (final layer in layering) {
    var previous = -1;
    for (final v in layer) {
      final ws = [...neighbors[v]]
        ..sort((a, b) => position[a].compareTo(position[b]));
      if (ws.isEmpty) {
        continue;
      }
      final middle = (ws.length - 1) / 2;
      for (var i = middle.floor(); i <= middle.ceil(); i++) {
        final w = ws[i];
        if (align[v] == v &&
            previous < position[w] &&
            !conflicts.contains(_key(v, w, nodeCount))) {
          align[w] = v;
          align[v] = root[v] = root[w];
          previous = position[w];
        }
      }
    }
  }
  return (root, align);
}

List<double> _horizontalCompaction(
  List<List<int>> layering,
  List<int> root,
  List<int> align,
  int nodeCount,
  double Function(int left, int right) separation,
) {
  // Block graph: an edge from the block on the left to the block on its
  // right, weighted by the separation the two nodes need.
  final successors = <int, Map<int, double>>{};
  final predecessors = <int, Map<int, double>>{};
  final blocks = <int>{};
  for (final layer in layering) {
    for (var i = 0; i < layer.length; i++) {
      final vRoot = root[layer[i]];
      blocks.add(vRoot);
      if (i == 0) {
        continue;
      }
      final uRoot = root[layer[i - 1]];
      final gap = separation(layer[i - 1], layer[i]);
      final existing = successors[uRoot]?[vRoot] ?? 0;
      final weight = math.max(gap, existing);
      (successors[uRoot] ??= {})[vRoot] = weight;
      (predecessors[vRoot] ??= {})[uRoot] = weight;
    }
  }

  // Topological order of the block graph (it is acyclic by construction).
  final indegree = <int, int>{
    for (final block in blocks) block: predecessors[block]?.length ?? 0,
  };
  final queue = [
    for (final block in blocks)
      if (indegree[block] == 0) block,
  ];
  final topo = <int>[];
  var head = 0;
  while (head < queue.length) {
    final block = queue[head++];
    topo.add(block);
    for (final next in (successors[block] ?? const {}).keys) {
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) {
        queue.add(next);
      }
    }
  }
  // Should a malformed alignment ever leave a cycle, keep every block placed.
  if (topo.length < blocks.length) {
    topo.addAll(blocks.where((block) => !topo.contains(block)));
  }

  final xs = <int, double>{};
  for (final block in topo) {
    var x = 0.0;
    for (final MapEntry(key: left, value: gap)
        in (predecessors[block] ?? const <int, double>{}).entries) {
      x = math.max(x, (xs[left] ?? 0) + gap);
    }
    xs[block] = x;
  }
  for (final block in topo.reversed) {
    var limit = double.infinity;
    for (final MapEntry(key: right, value: gap)
        in (successors[block] ?? const <int, double>{}).entries) {
      limit = math.min(limit, xs[right]! - gap);
    }
    if (limit.isFinite) {
      xs[block] = math.max(xs[block]!, limit);
    }
  }
  return [for (var v = 0; v < nodeCount; v++) xs[root[v]] ?? 0];
}
