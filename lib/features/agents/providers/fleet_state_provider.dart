import 'dart:collection';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An agent paired with its derived live state and most-recent run. The
/// single source of truth for "what is each agent doing right now" in the
/// active workspace.
class FleetAgent {
  /// Creates a [FleetAgent].
  const FleetAgent({
    required this.agent,
    required this.state,
    this.latestRun,
    this.lastActive,
  });

  /// The agent.
  final Agent agent;

  /// Its derived live state.
  final AgentLiveState state;

  /// The most-recent run log, if any.
  final AgentRunLog? latestRun;

  /// When the agent last showed activity.
  final DateTime? lastActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleetAgent &&
          runtimeType == other.runtimeType &&
          agent == other.agent &&
          state == other.state &&
          latestRun == other.latestRun &&
          lastActive == other.lastActive;

  @override
  int get hashCode => Object.hash(agent, state, latestRun, lastActive);
}

/// An immutable [List] of [FleetAgent] that compares by **value**.
///
/// Riverpod decides whether to notify a provider's listeners with
/// `previous != next` and a plain `List` compares by identity. Since
/// [agentFleetProvider] rebuilds a fresh list on every recompute — and it
/// recomputes on every tick of any agent's run-log stream — an identity
/// comparison meant every tick invalidated every dependent, even when the
/// fleet was byte-for-byte unchanged.
///
/// That mattered beyond wasted work. The fleet recomputes lazily, so a widget
/// mounting mid-frame and calling `ref.watch` is what flushes it and the
/// resulting dependent invalidations re-enter Riverpod's scheduler, which
/// calls `setState` on the `UncontrolledProviderScope` while the tree is
/// building — the "setState() called during build" crash. Value equality
/// collapses a no-op recompute into no notification at all, so the cascade
/// never leaves the fleet.
class FleetList extends UnmodifiableListView<FleetAgent> {
  /// Wraps [agents] in a value-comparable, unmodifiable list.
  FleetList(super.agents);

  // Deliberately equal only to another FleetList: being equal to a plain
  // List<FleetAgent> would be asymmetric, since List uses identity equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleetList && listEquals<FleetAgent>(this, other);

  @override
  int get hashCode => Object.hashAll(this);
}

/// The active workspace's agents with their live states, sorted so the ones
/// that need attention surface first (running → blocked → failed → idle →
/// never-run, then by name). Workspace-scoped via [workspaceAgentsProvider].
///
/// Always a [FleetList], so an unchanged recompute does not notify dependents.
final agentFleetProvider = Provider<List<FleetAgent>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return FleetList(const []);
  }
  final agents =
      ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
      const <Agent>[];

  final fleet = <FleetAgent>[];
  for (final agent in agents) {
    final logs = ref
        .watch(
          agentRunLogsProvider((
            workspaceId: agent.workspaceId,
            agentId: agent.id,
          )),
        )
        .asData
        ?.value;
    final state = logs == null
        ? AgentLiveState.idle
        : deriveAgentLiveState(logs);
    fleet.add(
      FleetAgent(
        agent: agent,
        state: state,
        latestRun: (logs != null && logs.isNotEmpty) ? logs.first : null,
        lastActive: logs == null ? null : agentLastActive(logs),
      ),
    );
  }

  fleet.sort((a, b) {
    final byState = a.state.sortPriority.compareTo(b.state.sortPriority);
    if (byState != 0) {
      return byState;
    }
    return a.agent.name.toLowerCase().compareTo(b.agent.name.toLowerCase());
  });
  return FleetList(fleet);
});
