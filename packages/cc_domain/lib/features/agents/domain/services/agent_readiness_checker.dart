import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';

/// Readiness state of an agent for dispatch.
enum AgentReadiness {
  /// Agent is ready to be dispatched.
  ready,
  /// Agent has been archived and cannot be dispatched.
  archived,
  /// Agent has no runtime adapter configured.
  noAdapter,
  /// The CLI tool for this agent's adapter was not found.
  cliNotFound,
  /// The sandbox required by this agent is unavailable.
  sandboxUnavailable,
  /// The system is at capacity and cannot accept new dispatches.
  atCapacity,
  /// Agent belongs to the wrong workspace.
  wrongWorkspace,
}

/// Result of an agent readiness check.
class AgentReadinessResult {
  /// Creates a readiness result with a [readiness] state and optional [reason].
  const AgentReadinessResult(this.readiness, {this.reason});
  /// The readiness state determined by the checker.
  final AgentReadiness readiness;
  /// Human-readable reason explaining the readiness state.
  final String? reason;
  /// Whether the agent is ready for dispatch.
  bool get isReady => readiness == AgentReadiness.ready;
}

/// Checks whether an agent is ready for dispatch.
class AgentReadinessChecker {
  /// Creates a readiness checker backed by an [agentRepository].
  AgentReadinessChecker({required AgentRepository agentRepository})
      : _agentRepo = agentRepository;

  final AgentRepository _agentRepo;

  /// Checks whether [agent] is ready for dispatch in the given [workspaceId].
  Future<AgentReadinessResult> check(
    Agent agent, {
    required String? workspaceId,
  }) async {
    // Workspace isolation: never dispatch an agent into a workspace it does not
    // belong to. The id-based path (checkFromId) loads the agent without a
    // workspace filter, so this is the barrier that keeps a stray workspace id
    // from waking another workspace's agent.
    if (workspaceId != null && agent.workspaceId != workspaceId) {
      return const AgentReadinessResult(
        AgentReadiness.wrongWorkspace,
        reason: 'Agent belongs to a different workspace',
      );
    }
    final adapterId = agent.adapterId;
    if (adapterId == null || adapterId.isEmpty) {
      return const AgentReadinessResult(
        AgentReadiness.noAdapter,
        reason: 'Agent has no runtime adapter configured',
      );
    }
    return const AgentReadinessResult(AgentReadiness.ready);
  }

  /// Looks up an agent by [agentId] and checks its readiness.
  Future<AgentReadinessResult> checkFromId(
    String agentId, {
    required String? workspaceId,
  }) async {
    final agent = await _agentRepo.getById(agentId);
    if (agent == null) {
      return const AgentReadinessResult(
        AgentReadiness.noAdapter,
        reason: 'Agent not found',
      );
    }
    return check(agent, workspaceId: workspaceId);
  }
}
