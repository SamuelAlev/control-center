import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Work-aware roster for one workspace, derived from durable agents + run logs.
///
/// Dispatch writes the in-process `AgentRegistry` **inside `cc_server`**. A
/// client that watched `AgentRegistryImpl.global()` in the Flutter isolate
/// always saw an empty map. The live tab reads the same RPC streams the rest
/// of the app already uses (`agents.watchForWorkspace` + recent run logs).
///
/// Status is honest for a thin client: [AgentStatus.running] when the agent
/// has an uncompleted run, otherwise [AgentStatus.idle]. Parked/aborted are
/// server-process states the client does not reconstruct.
final workspaceAgentRosterProvider =
    Provider.family<AsyncValue<List<AgentRef>>, String>((ref, workspaceId) {
      final agentsAsync = ref.watch(workspaceAgentsProvider(workspaceId));
      final runs = ref.watch(workspaceRunLogsProvider);
      return agentsAsync.whenData((agents) => mapAgentsToRoster(agents, runs));
    });

/// Maps durable [Agent] rows plus recent run logs into roster [AgentRef]s.
///
/// Exposed for tests; the provider is the production call site.
List<AgentRef> mapAgentsToRoster(List<Agent> agents, List<AgentRunLog> runs) {
  final latestRun = <String, AgentRunLog>{};
  final activeRun = <String, AgentRunLog>{};
  for (final run in runs) {
    final prev = latestRun[run.agentId];
    if (prev == null || run.startedAt.isAfter(prev.startedAt)) {
      latestRun[run.agentId] = run;
    }
    if (run.completedAt == null) {
      final prevActive = activeRun[run.agentId];
      if (prevActive == null || run.startedAt.isAfter(prevActive.startedAt)) {
        activeRun[run.agentId] = run;
      }
    }
  }

  return [
    for (final agent in agents)
      AgentRef(
        id: agent.id,
        displayName: agent.title.isNotEmpty ? agent.title : agent.name,
        kind: AgentKind.main,
        workspaceId: agent.workspaceId,
        status: activeRun.containsKey(agent.id)
            ? AgentStatus.running
            : AgentStatus.idle,
        createdAt: agent.createdAt,
        lastActivity:
            latestRun[agent.id]?.startedAt ??
            activeRun[agent.id]?.startedAt ??
            agent.createdAt,
        conversationId: activeRun[agent.id]?.conversationId,
        dispatchId: activeRun[agent.id]?.id,
        activity: activeRun[agent.id]?.summary,
      ),
  ];
}

// Peer-to-peer agent messaging (PRD 22) no longer rides an in-memory IRC bus:
// `IrcBusImpl` and its mailboxes were deleted. Agent↔agent messages are now
// durable, workspace-isolated messaging spaces (origin = agentDm) delivered
// via the same relay/park-revive path as human spaces, exposed to agents
// through the `send_to_agent` / `ask_agent` MCP tools.
