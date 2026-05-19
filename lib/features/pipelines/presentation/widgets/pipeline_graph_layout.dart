import 'dart:ui' show Offset;

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';

/// Computes an automatic left-to-right layered layout for a pipeline graph so
/// run nodes never overlap and the trigger always sits in the leftmost column.
///
/// The run-detail canvas is read-only — the operator can't drag nodes — so we
/// ignore the stored editor coordinates there (which can overlap, e.g. the
/// built-in templates pack columns closer than the node width) and derive
/// positions from the graph structure instead. Edges come from each step's
/// [PipelineStepDefinition.triggers] sources plus a join's
/// [PipelineStepDefinition.waitForStepIds]. Nodes are placed in columns by
/// their longest-path depth from a root and stacked vertically within a column
/// (centered around y = 0) with enough gap that tiles cannot collide.
///
/// Returns a map of step id → top-left offset in canvas-local coordinates, with
/// the leftmost (trigger) column starting at x = 0.
class PipelineGraphLayout {
  const PipelineGraphLayout._();

  /// Horizontal gap inserted between adjacent columns, on top of the node
  /// width, so neighbouring tiles never touch.
  static const double columnGap = 72;

  /// Vertical gap between two nodes stacked in the same column.
  static const double rowGap = 28;

  /// Computes positions for [steps]. [steps] should already exclude terminal
  /// sentinels (the run canvas filters those out before rendering).
  static Map<String, Offset> compute(
    List<PipelineStepDefinition> steps, {
    required double nodeWidth,
    required double nodeHeight,
  }) {
    if (steps.isEmpty) {
      return const {};
    }

    final byId = {for (final s in steps) s.id: s};

    // Incoming edges per node: trigger sources and (for joins) wait-for ids,
    // restricted to nodes present in this renderable set and excluding self.
    final preds = <String, Set<String>>{
      for (final s in steps) s.id: <String>{},
    };
    for (final s in steps) {
      for (final t in s.triggers) {
        for (final src in t.sourceStepIds) {
          if (src != s.id && byId.containsKey(src)) {
            preds[s.id]!.add(src);
          }
        }
      }
      for (final w in s.waitForStepIds) {
        if (w != s.id && byId.containsKey(w)) {
          preds[s.id]!.add(w);
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

    for (final s in steps) {
      depthOf(s.id);
    }

    // Pin the trigger to column 0 so it is always leftmost. A well-formed
    // pipeline has a single root trigger whose depth is already 0; this is a
    // defensive guarantee for the "trigger on the left at start" requirement.
    for (final s in steps) {
      if (s.kind == StepKind.trigger) {
        depth[s.id] = 0;
      }
    }

    // Bucket node ids by column, preserving definition order within a column.
    final columns = <int, List<String>>{};
    for (final s in steps) {
      (columns[depth[s.id]!] ??= []).add(s.id);
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
      // The first column has no predecessors, so it keeps definition order.
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
          return cmp != 0 ? cmp : originalIndex[a]!.compareTo(originalIndex[b]!);
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
