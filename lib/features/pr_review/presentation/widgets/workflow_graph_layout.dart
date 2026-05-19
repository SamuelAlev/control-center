import 'dart:ui' show Offset;

import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';

/// Computes an automatic left-to-right layered layout for a workflow job
/// graph so run nodes never overlap. Mirrors `PipelineGraphLayout.compute`
/// (the pipeline run canvas), retyped on [WorkflowJobNode] — edges come from
/// each job's `needs` upstream ids parsed out of the workflow YAML.
///
/// Nodes are placed in columns by their longest-path depth from a root and
/// stacked vertically within a column (centered around y = 0) with enough gap
/// that tiles cannot collide.
///
/// Returns a map of job id → top-left offset in canvas-local coordinates,
/// with the leftmost column starting at x = 0.
class WorkflowGraphLayout {
  const WorkflowGraphLayout._();

  /// Horizontal gap inserted between adjacent columns, on top of the node
  /// width, so neighbouring tiles never touch.
  static const double columnGap = 72;

  /// Vertical gap between two nodes stacked in the same column.
  static const double rowGap = 28;

  /// Computes positions for [jobs]. Column = longest-path depth from a root
  /// over `needs`; nodes stack vertically within a column (centered around
  /// y=0). Deterministic.
  static Map<String, Offset> compute(
    List<WorkflowJobNode> jobs, {
    required double nodeWidth,
    required double nodeHeight,
  }) {
    if (jobs.isEmpty) {
      return const {};
    }

    final byId = {for (final n in jobs) n.id: n};

    // Incoming edges per node: `needs` upstream ids, restricted to nodes
    // present in this graph and excluding self.
    final preds = <String, Set<String>>{for (final n in jobs) n.id: <String>{}};
    for (final n in jobs) {
      for (final need in n.needs) {
        if (need != n.id && byId.containsKey(need)) {
          preds[n.id]!.add(need);
        }
      }
    }

    // Longest-path depth (the column) per node, via memoized DFS. A `visiting`
    // guard breaks any cycle in a malformed graph so we can't loop forever.
    final depth = <String, int>{};
    final visiting = <String>{};
    int depthOf(String id) {
      final cached = depth[id];
      if (cached != null) {
        return cached;
      }
      if (!visiting.add(id)) {
        return 0; // cycle — treat as a root to break it
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

    for (final n in jobs) {
      depthOf(n.id);
    }

    // Bucket node ids by column, preserving declaration order within a column.
    final columns = <int, List<String>>{};
    for (final n in jobs) {
      (columns[depth[n.id]!] ??= []).add(n.id);
    }
    final columnKeys = columns.keys.toList()..sort();
    final firstColumn = columnKeys.first;

    final colPitch = nodeWidth + columnGap;
    final rowPitch = nodeHeight + rowGap;

    final rowIndex = <String, int>{};
    final positions = <String, Offset>{};

    for (final col in columnKeys) {
      final ids = columns[col]!;

      // Order rows by the barycenter (mean row) of each node's already-placed
      // predecessors, which keeps edges roughly straight and cuts crossings.
      // The first column has no predecessors, so it keeps declaration order.
      final ordered = [...ids];
      if (col != firstColumn) {
        final originalIndex = <String, int>{
          for (var i = 0; i < ordered.length; i++) ids[i]: i,
        };
        final key = <String, double>{};
        for (var i = 0; i < ordered.length; i++) {
          final id = ordered[i];
          final placedRows = preds[id]!
              .map((p) => rowIndex[p])
              .whereType<int>()
              .toList();
          key[id] = placedRows.isEmpty
              ? i.toDouble()
              : placedRows.reduce((a, b) => a + b) / placedRows.length;
        }
        // Deterministic order: barycenter, then original index for ties (since
        // List.sort is not guaranteed stable).
        ordered.sort((a, b) {
          final cmp = key[a]!.compareTo(key[b]!);
          return cmp != 0
              ? cmp
              : originalIndex[a]!.compareTo(originalIndex[b]!);
        });
      }

      final count = ordered.length;
      for (var i = 0; i < count; i++) {
        final id = ordered[i];
        rowIndex[id] = i;
        positions[id] = Offset(
          col * colPitch,
          (i - (count - 1) / 2) * rowPitch,
        );
      }
    }

    return positions;
  }
}
