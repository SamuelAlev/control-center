part of 'dispatch_session.dart';

/// The harness side of account pools: ordering a provider's stored keys by
/// the scope's pool, and parking a run the pool refuses on the credential gate.
extension _DispatchSessionAccountPool on DispatchSession {
  /// Orders [stored] according to the workspace's pool for [providerId].
  ///
  /// Returns the list unchanged when no resolver is wired or the pool is
  /// unconfigured — which is what keeps every existing install on the exact
  /// chain it had before pools existed. The resolver is the ONLY thing that
  /// knows about workspaces, strategies and cooldowns; this layer just spends
  /// the order it is given.
  Future<List<ProviderCredential>> _orderRotation(
    String providerId,
    List<ProviderCredential> stored,
  ) async {
    final resolve = onResolveHarnessRotation;
    // Consulted even for ONE stored key: a pool naming only removed keys must
    // refuse, not quietly run on whatever key is left.
    if (resolve == null || stored.isEmpty) {
      return stored;
    }
    final answer = await resolve(
      workspaceId: workspaceId,
      agentId: agentId,
      providerId: providerId,
      credentialIds: [for (final c in stored) c.credentialId],
    );
    final refusal = answer.refusal;
    if (refusal != null) {
      throw _AccountPoolRefused(providerId, refusal);
    }
    final order = answer.order;
    if (order == null || order.isEmpty) {
      return stored;
    }
    final byId = {for (final c in stored) c.credentialId: c};
    return [
      for (final id in order)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Parks this run until [refused]'s pool stops refusing it, and reports
  /// whether it did.
  ///
  /// False when no gate is wired, when the operator cancels, or when the wait
  /// times out — each falls through to the refusal as the run's failure.
  Future<bool> _gateOnHarnessPool(_AccountPoolRefused refused) async {
    final gate = deps.credentialGate;
    final resolve = onResolveHarnessRotation;
    if (gate == null || resolve == null) {
      return false;
    }
    final detail = refused.toString();
    addEvent(DebugEvent(content: detail));
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.harness,
        reason: refused.refusal.reason,
        detail: detail,
        runLogId: runLogId,
        providerId: refused.providerId,
        accountIds: refused.refusal.accountIds,
        availableAt: refused.refusal.earliestReset,
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // Re-asking the pool IS the probe: an edit to it lands in workspace
      // settings, which only a fresh read observes.
      recheck: () async {
        final stored =
            await deps.harnessCredentialStore?.credentialsFor(
              refused.providerId,
            ) ??
            const <ProviderCredential>[];
        final answer = await resolve(
          workspaceId: workspaceId,
          agentId: agentId,
          providerId: refused.providerId,
          credentialIds: [for (final c in stored) c.credentialId],
        );
        return answer.refusal == null;
      },
    );
    return outcome == RunCredentialOutcome.resolved;
  }
}

/// Thrown out of harness provider assembly when the scope's account pool
/// refuses the run, so the session can park it on the credential gate instead
/// of building a provider on a credential the pool rules out.
class _AccountPoolRefused implements Exception {
  _AccountPoolRefused(this.providerId, this.refusal);

  final String providerId;
  final AccountPoolRefusal refusal;

  @override
  String toString() => harnessPoolRefusalDetail(providerId, refusal);
}
