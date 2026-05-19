import 'dart:ui' show Offset;

import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Deterministic layered (Sugiyama-style) auto-layout for a [PlanGraph]
/// (PRD 17 §1, clarification: "layout is client-side and deterministic — same
/// graph, same layout on every client; no persisted x/y").
///
/// Mirrors the pipeline canvas's `PipelineGraphLayout`: nodes are placed in
/// ranks by their longest-path depth from a root and stacked vertically within
/// a rank (centered on y = 0), ordered by the barycenter of their already-placed
/// predecessors to cut edge crossings. Cycle-safe (a `visiting` guard demotes a
/// cycle participant to depth 0 — [PlanGraph.validate] rejects cycles before an
/// editable graph is committed, but the layout must never loop on a malformed
/// one).
///
/// **A rank wider than [defaultMaxRowsPerRank] wraps into lanes** instead of
/// stacking without a ceiling. A single-rank stack is unbounded by nature: a
/// plan with 30 independent roots (or a fan-out to 30 parallel tasks) produces a
/// one-node-wide, 30-node-tall ribbon nobody can read or pan. Wrapping trades
/// some edge crossings inside an over-wide rank for an aspect ratio that fits a
/// viewport, which is what every DAG editor of this shape does. Lanes are filled
/// after the barycenter sort and in reading order (down the first lane, then
/// across), so nodes with neighbouring barycenters share a lane and the added
/// crossings stay local.
class PlanGraphLayout {
  const PlanGraphLayout._();

  /// Horizontal gap between adjacent columns, on top of the node width.
  static const double columnGap = 88;

  /// Vertical gap between two nodes stacked in the same column.
  static const double rowGap = 36;

  /// Rows one rank may stack before it wraps into an additional lane.
  ///
  /// Six ≈ 840px tall at the canvas's node height, so a wrapped rank still
  /// fits a laptop viewport at 1.0 zoom without panning.
  static const int defaultMaxRowsPerRank = 6;

  /// Computes `nodeKey → top-left offset` for [graph]. The leftmost lane starts
  /// at x = 0; rows in each lane are centered on y = 0.
  ///
  /// [maxRowsPerRank] caps how tall one rank may grow before wrapping; values
  /// below 1 are treated as 1.
  static Map<String, Offset> compute(
    PlanGraph graph, {
    required double nodeWidth,
    required double nodeHeight,
    int maxRowsPerRank = defaultMaxRowsPerRank,
  }) {
    final nodes = graph.nodes;
    if (nodes.isEmpty) {
      return const {};
    }
    final ids = {for (final n in nodes) n.key};

    // Incoming edges: each node's dependsOn restricted to present nodes.
    final preds = <String, Set<String>>{
      for (final n in nodes) n.key: <String>{},
    };
    for (final n in nodes) {
      for (final dep in n.dependsOn) {
        if (dep != n.key && ids.contains(dep)) {
          preds[n.key]!.add(dep);
        }
      }
    }

    // Longest-path depth (the column) per node, via memoized DFS.
    final depth = <String, int>{};
    final visiting = <String>{};
    int depthOf(String id) {
      final cached = depth[id];
      if (cached != null) {
        return cached;
      }
      if (!visiting.add(id)) {
        return 0; // cycle — break it by treating this node as a root
      }
      var d = 0;
      for (final p in preds[id]!) {
        final pd = depthOf(p) + 1;
        if (pd > d) {
          d = pd;
        }
      }
      visiting.remove(id);
      return depth[id] = d;
    }

    for (final n in nodes) {
      depthOf(n.key);
    }

    // Bucket by rank, preserving authored order within a rank.
    final ranks = <int, List<String>>{};
    for (final n in nodes) {
      (ranks[depth[n.key]!] ??= []).add(n.key);
    }
    final rankKeys = ranks.keys.toList()..sort();
    final firstRank = rankKeys.first;

    final colPitch = nodeWidth + columnGap;
    final rowPitch = nodeHeight + rowGap;
    final maxRows = maxRowsPerRank < 1 ? 1 : maxRowsPerRank;

    // Placed centre-y per node, the input to the next rank's barycenter. Held
    // as the resolved y rather than a row index so wrapped lanes (whose rows
    // restart at the top) still order their successors by real geometry.
    final centreY = <String, double>{};
    final positions = <String, Offset>{};

    // Lanes consumed by ranks already placed — a wrapped rank pushes every
    // later rank right by the extra lanes it took.
    var laneCursor = 0;

    for (final rank in rankKeys) {
      final rankIds = ranks[rank]!;
      final ordered = [...rankIds];
      if (rank != firstRank) {
        final originalIndex = <String, int>{
          for (var i = 0; i < rankIds.length; i++) rankIds[i]: i,
        };
        final key = <String, double>{};
        for (var i = 0; i < ordered.length; i++) {
          final id = ordered[i];
          final placedYs = preds[id]!
              .map((p) => centreY[p])
              .whereType<double>()
              .toList();
          key[id] = placedYs.isEmpty
              ? i * rowPitch
              : placedYs.reduce((a, b) => a + b) / placedYs.length;
        }
        // Deterministic: barycenter, then authored index for ties (sort is
        // not guaranteed stable).
        ordered.sort((a, b) {
          final cmp = key[a]!.compareTo(key[b]!);
          return cmp != 0
              ? cmp
              : originalIndex[a]!.compareTo(originalIndex[b]!);
        });
      }

      final count = ordered.length;
      // Balance the lanes (13 over 3 lanes → 5/5/3) rather than filling each to
      // the cap and leaving a one-node stub lane hanging off the right.
      final lanes = count <= maxRows ? 1 : (count / maxRows).ceil();
      final rowsPerLane = (count / lanes).ceil();

      for (var i = 0; i < count; i++) {
        final id = ordered[i];
        final lane = i ~/ rowsPerLane;
        final row = i % rowsPerLane;
        // Rows are centred on y = 0 per lane, so lanes stay vertically centred
        // against each other even when the last one is short.
        final rowsInLane = count - lane * rowsPerLane < rowsPerLane
            ? count - lane * rowsPerLane
            : rowsPerLane;
        final y = (row - (rowsInLane - 1) / 2) * rowPitch;
        positions[id] = Offset((laneCursor + lane) * colPitch, y);
        centreY[id] = y;
      }

      laneCursor += lanes;
    }

    return positions;
  }
}
