part of 'dispatch_session.dart';

/// The run's side of the action policy: its network posture and its
/// registration with the agent run gateway (pushes, Claude Code's hook).
extension _DispatchSessionGateway on DispatchSession {
  /// Registers this run with the gateway. Without a gateway or a workspace the
  /// run has no lease — and so no push path, which fails closed.
  Future<void> _openGatewayLease({String? repoOwner, String? repoName}) async {
    final gateway = deps.agentRunGateway;
    final ws = workspaceId;
    if (gateway == null || ws == null || ws.isEmpty) {
      return;
    }
    _gatewayLease = await gateway.open(
      AgentRunGrant(
        workspaceId: ws,
        conversationId: conversationId ?? dispatchId,
        agentId: agentId,
        spaceId: spaceId,
        mode: mode,
        actingUserId: requestedByUserId,
        runId: dispatchId,
        repoOwner: repoOwner,
        repoName: repoName,
      ),
    );
  }

  /// Resolves the "network egress" rule for this run: only a deny takes the
  /// sandbox's network away. Without a guard (tests, minimal hosts) or a
  /// workspace there is no rule to read, and the network stays on.
  Future<bool> _resolveNetworkEnabled() async {
    final guard = deps.actionGuard;
    final ws = workspaceId;
    if (guard == null || ws == null || ws.isEmpty) {
      return true;
    }
    try {
      final resolution = await guard.resolve(
        workspaceId: ws,
        classes: const {ActionClass.networkEgress},
        spaceId: spaceId,
        agentId: agentId,
        mode: mode,
      );
      return resolution.decision != ActionDecision.deny;
    } on Object catch (e) {
      CcInfraLog.warning(
        'dispatch $dispatchId: network-egress rule resolution failed, '
        'keeping the network on: $e',
      );
      return true;
    }
  }

  /// Revokes the run's scoped credential and closes its gateway lease (which
  /// revokes any write token the gateway minted for its pushes). Idempotent.
  Future<void> _releaseRunCredentials() async {
    final cred = credHandle;
    credHandle = null;
    if (cred != null) {
      await deps.broker.revoke(cred);
    }
    final lease = _gatewayLease;
    _gatewayLease = null;
    await deps.agentRunGateway?.close(lease);
  }
}
