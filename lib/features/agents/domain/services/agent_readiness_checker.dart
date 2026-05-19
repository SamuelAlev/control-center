import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';

enum AgentReadiness {
  ready,
  archived,
  noAdapter,
  cliNotFound,
  sandboxUnavailable,
  atCapacity,
  wrongWorkspace,
}

class AgentReadinessResult {
  const AgentReadinessResult(this.readiness, {this.reason});
  final AgentReadiness readiness;
  final String? reason;
  bool get isReady => readiness == AgentReadiness.ready;
}

/// Checks whether an agent is ready for dispatch.
class AgentReadinessChecker {
  AgentReadinessChecker({required AgentRepository agentRepository})
      : _agentRepo = agentRepository;

  final AgentRepository _agentRepo;

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
