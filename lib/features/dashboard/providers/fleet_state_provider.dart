import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An agent paired with its derived live state and most-recent run, ready for
/// the fleet rail and the greeting pill. The single source of truth for "what
/// is each agent doing right now" on the dashboard.
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
}

/// The active workspace's agents with their live states, sorted so the ones
/// that need attention surface first (running → blocked → failed → idle →
/// never-run, then by name). Workspace-scoped via [workspaceAgentsProvider].
final dashboardFleetProvider = Provider<List<FleetAgent>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const [];
  }
  final agents =
      ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
      const <Agent>[];

  final fleet = <FleetAgent>[];
  for (final agent in agents) {
    final logs = ref.watch(agentRunLogsProvider(agent.id)).asData?.value;
    final state =
        logs == null ? AgentLiveState.idle : deriveAgentLiveState(logs);
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
  return fleet;
});

/// Compact tallies for the greeting pill: how many agents are running and how
/// many are blocked right now.
typedef FleetTally = ({int running, int blocked, int failed});

/// Running / blocked / failed counts derived from [dashboardFleetProvider].
final fleetTallyProvider = Provider<FleetTally>((ref) {
  final fleet = ref.watch(dashboardFleetProvider);
  var running = 0;
  var blocked = 0;
  var failed = 0;
  for (final f in fleet) {
    switch (f.state) {
      case AgentLiveState.running:
        running++;
      case AgentLiveState.blocked:
        blocked++;
      case AgentLiveState.failed:
        failed++;
      case AgentLiveState.idle:
      case AgentLiveState.neverRun:
        break;
    }
  }
  return (running: running, blocked: blocked, failed: failed);
});
