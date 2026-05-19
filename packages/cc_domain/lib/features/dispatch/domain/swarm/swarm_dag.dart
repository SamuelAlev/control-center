/// Directed-acyclic-graph operations over swarm agent dependencies.
///
/// Builds a dependency graph from `waitsFor` / `reportsTo` relationships,
/// detects cycles, and produces parallelizable execution waves via topological
/// sort.
///
/// Ported from oh-my-pi `swarm-extension/src/swarm/dag.ts`
/// (`buildDependencyGraph`, `detectCycles`, `buildExecutionWaves`).
library;

import 'package:cc_domain/features/dispatch/domain/swarm/swarm_definition.dart';

/// Builds a dependency map: agent name to the set of agents it depends on.
///
/// Dependencies come from:
///
/// 1. Explicit [SwarmAgent.waitsFor] declarations.
/// 2. Implicit from [SwarmAgent.reportsTo]: if A reports to B, then B depends
///    on A (the inversion).
/// 3. For [SwarmMode.pipeline] / [SwarmMode.sequential] with no explicit deps:
///    chain by declaration order ([SwarmDefinition.agentOrder]).
///
/// Unknown references (a `waitsFor`/`reportsTo` naming an agent not in the
/// swarm) are silently skipped here; surface them via `validateSwarmDefinition`
/// before building the graph.
Map<String, Set<String>> buildDependencyGraph(SwarmDefinition def) {
  final deps = <String, Set<String>>{};

  for (final name in def.agents.keys) {
    deps[name] = <String>{};
  }

  // Explicit waits_for.
  for (final entry in def.agents.entries) {
    final name = entry.key;
    for (final dep in entry.value.waitsFor) {
      if (deps.containsKey(dep)) {
        deps[name]!.add(dep);
      }
    }
  }

  // reports_to implies the target waits for the reporter.
  for (final entry in def.agents.entries) {
    final name = entry.key;
    for (final target in entry.value.reportsTo) {
      if (deps.containsKey(target)) {
        deps[target]!.add(name);
      }
    }
  }

  // For pipeline/sequential with no explicit deps, chain by declaration order.
  final isChainMode =
      def.mode == SwarmMode.pipeline || def.mode == SwarmMode.sequential;
  if (isChainMode && !_hasExplicitDeps(deps)) {
    for (var i = 1; i < def.agentOrder.length; i++) {
      deps[def.agentOrder[i]]!.add(def.agentOrder[i - 1]);
    }
  }

  return deps;
}

/// Whether any node already carries at least one dependency.
bool _hasExplicitDeps(Map<String, Set<String>> deps) {
  for (final s in deps.values) {
    if (s.isNotEmpty) {
      return true;
    }
  }
  return false;
}

/// Detects cycles in the dependency graph via Kahn's algorithm.
///
/// Returns the names of agents involved in cycles (those a topological sort
/// could not place), or `null` if the graph is acyclic.
List<String>? detectCycles(Map<String, Set<String>> deps) {
  // Kahn's algorithm: if the topological sort does not include all nodes,
  // cycles exist.
  final inDegree = <String, int>{};
  final forward = <String, List<String>>{}; // dependency -> its dependents

  for (final entry in deps.entries) {
    final node = entry.key;
    final nodeDeps = entry.value;
    inDegree[node] = nodeDeps.length;
    for (final dep in nodeDeps) {
      forward.putIfAbsent(dep, () => <String>[]).add(node);
    }
  }

  final queue = <String>[];
  for (final entry in inDegree.entries) {
    if (entry.value == 0) {
      queue.add(entry.key);
    }
  }

  final sorted = <String>[];
  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    sorted.add(node);
    for (final dependent in forward[node] ?? const <String>[]) {
      final newDegree = inDegree[dependent]! - 1;
      inDegree[dependent] = newDegree;
      if (newDegree == 0) {
        queue.add(dependent);
      }
    }
  }

  if (sorted.length < deps.length) {
    final placed = sorted.toSet();
    return deps.keys.where((k) => !placed.contains(k)).toList();
  }

  return null;
}

/// Builds execution waves from the dependency graph via topological sort.
///
/// Each wave contains agents whose dependencies are all in earlier waves;
/// agents within a wave can execute in parallel. Each wave is sorted for
/// deterministic order.
///
/// Throws a [StateError] on deadlock (no node can make progress) — this should
/// never happen on an acyclic graph, so it indicates a cycle-detection bug.
List<List<String>> buildExecutionWaves(Map<String, Set<String>> deps) {
  final waves = <List<String>>[];
  final completed = <String>{};
  final remaining = deps.keys.toSet();

  while (remaining.isNotEmpty) {
    final wave = <String>[];

    for (final node in remaining) {
      final nodeDeps = deps[node]!;
      var ready = true;
      for (final dep in nodeDeps) {
        if (!completed.contains(dep)) {
          ready = false;
          break;
        }
      }
      if (ready) {
        wave.add(node);
      }
    }

    if (wave.isEmpty) {
      throw StateError(
        'Deadlock: agents [${remaining.join(', ')}] cannot make progress. '
        'This indicates a bug in cycle detection.',
      );
    }

    // Sort for deterministic execution order.
    wave.sort();

    for (final node in wave) {
      remaining.remove(node);
      completed.add(node);
    }

    waves.add(wave);
  }

  return waves;
}
