import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Impact-radius summary for one node, derived from its provenance refs.
class NodeImpact {
  /// Creates a summary.
  const NodeImpact({required this.files, required this.symbols});

  /// Distinct files inside the union of the node's impact subgraphs.
  final int files;

  /// Distinct symbols inside the union.
  final int symbols;
}

/// The full plan estimate (PRD 17 §3): per-node ranges plus honest totals.
class PlanEstimate {
  /// Creates an estimate.
  const PlanEstimate({
    required this.byNodeKey,
    this.totalCostCentsLow,
    this.totalCostCentsHigh,
    this.totalDurationMsLow,
    this.totalDurationMsHigh,
    this.budgetCeilingCents,
    this.isPartial = false,
  });

  /// Per-node estimates (every node in the graph gets an entry; a node with
  /// no history gets `sampleSize: 0` and null ranges).
  final Map<String, PlanNodeEstimate> byNodeKey;

  /// Plan-total cost range (sum of node ranges). Null when NO node has
  /// history.
  final int? totalCostCentsLow;

  /// Upper bound of plan-total cost.
  final int? totalCostCentsHigh;

  /// Plan-total duration range — the critical path through the DAG, not the
  /// sum (parallel branches overlap).
  final int? totalDurationMsLow;

  /// Upper bound of the critical-path duration.
  final int? totalDurationMsHigh;

  /// The proposal's `BudgetSpec.maxCostCents`, when set.
  final int? budgetCeilingCents;

  /// True when some nodes have history and some don't: the totals cover only
  /// the estimable subset and the UI must say so.
  final bool isPartial;

  /// Whether the estimated total may exceed the budget ceiling.
  bool get exceedsBudget =>
      budgetCeilingCents != null &&
      totalCostCentsHigh != null &&
      totalCostCentsHigh! > budgetCeilingCents!;
}

/// Pure per-node cost/time/risk estimator (PRD 17 §3).
///
/// Composes similar-run history (per role) and provenance-derived impact
/// summaries. **No I/O** — the server gathers inputs, this folds them.
///
/// Honesty invariants (adversarial review: "estimate mistrust is fatal"):
/// - A node whose role has no history gets `sampleSize: 0` and NULL ranges —
///   never a fabricated point value.
/// - Ranges are interquartile (p25–p75) over real samples, so one outlier
///   run cannot swing the band.
/// - Blast radius comes only from provenance refs (`impactByNodeKey`); a
///   node without refs keeps null blast-radius fields ("unknown"), never an
///   inference from prose.
class PlanEstimator {
  /// Creates the estimator.
  const PlanEstimator();

  /// Estimates every node of [graph].
  ///
  /// [historyByRoleKey] holds completed-run costs of the agent(s) filling
  /// each role (server-gathered, most recent first, pre-capped).
  /// [impactByNodeKey] holds provenance-derived impact summaries.
  PlanEstimate estimate({
    required PlanGraph graph,
    required Map<String, List<RunCost>> historyByRoleKey,
    Map<String, NodeImpact> impactByNodeKey = const {},
    int? budgetCeilingCents,
  }) {
    final byNode = <String, PlanNodeEstimate>{};
    for (final node in graph.nodes) {
      final samples = historyByRoleKey[node.roleKey] ?? const <RunCost>[];
      final costs = [for (final s in samples) s.estimatedCostCents]..sort();
      final durations = [
        for (final s in samples)
          if (s.durationMs != null) s.durationMs!,
      ]..sort();
      final impact = impactByNodeKey[node.key];
      byNode[node.key] = PlanNodeEstimate(
        costCentsLow: costs.isEmpty ? null : _percentile(costs, 0.25),
        costCentsHigh: costs.isEmpty ? null : _percentile(costs, 0.75),
        durationMsLow: durations.isEmpty ? null : _percentile(durations, 0.25),
        durationMsHigh: durations.isEmpty ? null : _percentile(durations, 0.75),
        sampleSize: samples.length,
        blastRadiusFiles: impact?.files,
        blastRadiusSymbols: impact?.symbols,
      );
    }

    final withHistory = [
      for (final e in byNode.values)
        if (e.hasHistory) e,
    ];
    int? totalCostLow;
    int? totalCostHigh;
    if (withHistory.isNotEmpty) {
      totalCostLow = 0;
      totalCostHigh = 0;
      for (final e in withHistory) {
        totalCostLow = totalCostLow! + (e.costCentsLow ?? 0);
        totalCostHigh = totalCostHigh! + (e.costCentsHigh ?? 0);
      }
    }
    final (durationLow, durationHigh) = _criticalPath(graph, byNode);

    return PlanEstimate(
      byNodeKey: byNode,
      totalCostCentsLow: totalCostLow,
      totalCostCentsHigh: totalCostHigh,
      totalDurationMsLow: durationLow,
      totalDurationMsHigh: durationHigh,
      budgetCeilingCents: budgetCeilingCents,
      isPartial: withHistory.isNotEmpty && withHistory.length < byNode.length,
    );
  }

  /// Nearest-rank percentile over a sorted, non-empty list.
  static int _percentile(List<int> sorted, double p) {
    final rank = (p * (sorted.length - 1)).round();
    return sorted[rank.clamp(0, sorted.length - 1)];
  }

  /// The longest duration path through the DAG (nodes without history count
  /// as 0 — the total is a floor, flagged via [PlanEstimate.isPartial]).
  /// Returns (null, null) when no node has a duration estimate.
  static (int?, int?) _criticalPath(
    PlanGraph graph,
    Map<String, PlanNodeEstimate> byNode,
  ) {
    final anyDuration = byNode.values.any((e) => e.durationMsLow != null);
    if (!anyDuration) {
      return (null, null);
    }
    final memoLow = <String, int>{};
    final memoHigh = <String, int>{};
    // Iterative from a topological order (validate() guarantees acyclic
    // before estimation is offered; a cyclic graph falls back to node order).
    final order = _topologicalOrder(graph);
    for (final key in order) {
      final node = graph.node(key)!;
      var bestLow = 0;
      var bestHigh = 0;
      for (final dep in node.dependsOn) {
        bestLow = bestLow < (memoLow[dep] ?? 0) ? (memoLow[dep] ?? 0) : bestLow;
        bestHigh = bestHigh < (memoHigh[dep] ?? 0)
            ? (memoHigh[dep] ?? 0)
            : bestHigh;
      }
      final est = byNode[key];
      memoLow[key] = bestLow + (est?.durationMsLow ?? 0);
      memoHigh[key] = bestHigh + (est?.durationMsHigh ?? 0);
    }
    var low = 0;
    var high = 0;
    for (final v in memoLow.values) {
      low = v > low ? v : low;
    }
    for (final v in memoHigh.values) {
      high = v > high ? v : high;
    }
    return (low, high);
  }

  static List<String> _topologicalOrder(PlanGraph graph) {
    final inDegree = <String, int>{for (final n in graph.nodes) n.key: 0};
    final dependents = <String, List<String>>{};
    for (final n in graph.nodes) {
      for (final dep in n.dependsOn) {
        if (!inDegree.containsKey(dep)) {
          continue;
        }
        inDegree[n.key] = (inDegree[n.key] ?? 0) + 1;
        dependents.putIfAbsent(dep, () => []).add(n.key);
      }
    }
    final queue = [
      for (final e in inDegree.entries)
        if (e.value == 0) e.key,
    ];
    final order = <String>[];
    while (queue.isNotEmpty) {
      final key = queue.removeAt(0);
      order.add(key);
      for (final dependent in dependents[key] ?? const <String>[]) {
        final remaining = inDegree[dependent]! - 1;
        inDegree[dependent] = remaining;
        if (remaining == 0) {
          queue.add(dependent);
        }
      }
    }
    // Cycle fallback: append unreached nodes in authored order.
    if (order.length != graph.nodes.length) {
      for (final n in graph.nodes) {
        if (!order.contains(n.key)) {
          order.add(n.key);
        }
      }
    }
    return order;
  }
}
