import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';
import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';

/// Composes the two-dimensional [AgentPresence] (availability × workload) for
/// agents in a workspace, combining runtime health, governance lifecycle, the
/// count of actively-running runs and the queue of assigned-but-unstarted
/// tasks against each agent's concurrency capacity.
class AgentPresenceService {
  /// Creates an [AgentPresenceService].
  AgentPresenceService({
    required AgentRepository agentRepository,
    required AgentRuntimeStateRepository runtimeStateRepository,
    required AgentRunLogRepository runLogRepository,
    required TicketRepository ticketRepository,
  }) : _agents = agentRepository,
       _runtimeStates = runtimeStateRepository,
       _runLogs = runLogRepository,
       _tickets = ticketRepository;

  final AgentRepository _agents;
  final AgentRuntimeStateRepository _runtimeStates;
  final AgentRunLogRepository _runLogs;
  final TicketRepository _tickets;

  /// Computes presence for every agent in [workspaceId], keyed by agent id.
  Future<Map<String, AgentPresence>> presenceForWorkspace(
    String workspaceId, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final agents = await _agents.watchByWorkspace(workspaceId).first;
    final states = await _runtimeStates.listByWorkspace(workspaceId);
    final stateById = {for (final s in states) s.agentId: s};

    final result = <String, AgentPresence>{};
    for (final agent in agents) {
      final running = await _runningCount(workspaceId, agent.id);
      final queued = await _queuedCount(workspaceId, agent.id);
      result[agent.id] = presenceFor(
        agent: agent,
        runtimeState: stateById[agent.id],
        runningCount: running,
        queuedCount: queued,
        now: at,
      );
    }
    return result;
  }

  /// Pure composition of presence for a single [agent] from its inputs. A null
  /// [runtimeState] (the agent never phoned home) derives as offline.
  AgentPresence presenceFor({
    required Agent agent,
    required AgentRuntimeState? runtimeState,
    required int runningCount,
    required int queuedCount,
    required DateTime now,
  }) {
    return deriveAgentPresence(
      health: runtimeState?.healthAt(now) ?? RuntimeHealth.offline,
      lifecycle: agent.lifecycleStatus,
      runningCount: runningCount,
      queuedCount: queuedCount,
      capacity: agent.maxConcurrentTasks,
    );
  }

  Future<int> _runningCount(String workspaceId, String agentId) async {
    final logs = await _runLogs.watchByAgent(workspaceId, agentId).first;
    return logs.where((l) => l.status == RunStatus.running).length;
  }

  Future<int> _queuedCount(String workspaceId, String agentId) async {
    final tickets = await _tickets.forAgent(workspaceId, agentId);
    return tickets
        .where(
          (t) =>
              t.status == TicketStatus.open || t.status == TicketStatus.backlog,
        )
        .length;
  }
}
