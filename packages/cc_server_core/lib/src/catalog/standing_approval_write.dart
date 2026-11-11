part of '../remote_rpc_catalog.dart';

/// Writes the standing approval an approved "Approve for 8 hours" answer asks
/// for: a real policy rule that is narrow (the constraint generalized from the
/// approved call), scoped (space, agent or workspace) and self-revoking (an
/// explicit TTL), so "yes, for the next few hours" never rewrites permanent
/// policy.
///
/// [request] is the server's own record of the card and decides what may be
/// written; [remember] is the client's wish and only chooses among that.
Future<void> _writeStandingApproval({
  required ConfirmationRequest request,
  required Map<Object?, Object?> remember,
  required String workspaceId,
  required String responderId,
  required WorkspaceMembershipRepository? members,
  required ActionPolicyRepository repository,
}) async {
  // Only what the card offered: a rule without a constraint would cover its
  // whole class, so one is written only for a commit
  // (`standsWithoutConstraint`), whatever the client sends.
  final constraint = ActionConstraint.decode(request.constraintJson);
  final classes = request.actionClasses;
  if (request.rememberChoice == null ||
      (constraint == null &&
          !ActionGuardService.standsWithoutConstraint(classes))) {
    return;
  }
  final scopeWire = remember['scope'] as String?;
  final requestedTtl = (remember['ttl_seconds'] as num?)?.toInt();
  // Answering a prompt is a MEMBER-level act; writing workspace policy is an
  // ADMIN one (`action_policy.upsert` is admin-gated). A standing approval
  // must not be a way around that, so a non-admin's remember is confined to
  // the space (or the agent) the prompt came from, and workspace scope needs
  // the same role the policy editor does.
  final responderRole = members == null
      ? null
      : (await members.getMember(workspaceId, responderId))?.role;
  final mayWriteWorkspaceScope = responderRole?.isAdmin ?? false;
  final spaceId = request.spaceId;
  final agentId = request.agentId ?? '';
  final (scopeType, scopeId) = switch (scopeWire) {
    'space' when spaceId.isNotEmpty => (ActionScopeType.space, spaceId),
    'agent' when agentId.isNotEmpty => (ActionScopeType.agent, agentId),
    'workspace' when mayWriteWorkspaceScope => (ActionScopeType.workspace, ''),
    // Narrow rather than refuse: the answer already stands, and the narrowest
    // scope that exists is what the responder is entitled to. With neither a
    // space nor an agent to pin it to, an unprivileged remember writes
    // nothing at all.
    _ when spaceId.isNotEmpty => (ActionScopeType.space, spaceId),
    _ when agentId.isNotEmpty => (ActionScopeType.agent, agentId),
    _ when mayWriteWorkspaceScope => (ActionScopeType.workspace, ''),
    _ => (ActionScopeType.workspace, unscopedRemember),
  };
  if (classes.isEmpty || scopeId == unscopedRemember) {
    return;
  }
  // A standing approval is time-boxed BY DEFINITION. An unbounded ttl would
  // let one click become permanent policy, which is the admin-gated act this
  // path must not become.
  final ttl = Duration(
    seconds: (requestedTtl ?? defaultRememberTtlSeconds).clamp(
      60,
      maxRememberTtlSeconds,
    ),
  );
  final now = DateTime.now();
  for (final wire in classes) {
    final cls = ActionClass.fromWire(wire);
    if (cls == null) {
      continue;
    }
    await repository.upsertRule(
      ActionPolicyRule(
        id: const Uuid().v4(),
        workspaceId: workspaceId,
        scopeType: scopeType,
        scopeId: scopeId,
        actionClass: cls,
        decision: ActionDecision.allow,
        provenance: 'remembered',
        createdBy: responderId,
        constraint: constraint,
        expiresAt: now.add(ttl),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
  await _pruneExpiredStandingApprovals(repository, workspaceId, now);
}

/// Deletes [workspaceId]'s standing approvals that expired by [now].
///
/// Enforcement already ignores them; this keeps the store from collecting
/// every one ever given. Housekeeping only, so a failure is logged and never
/// fails the answer that triggered it.
Future<void> _pruneExpiredStandingApprovals(
  ActionPolicyRepository repository,
  String workspaceId,
  DateTime now,
) async {
  try {
    for (final rule in await repository.rules(workspaceId)) {
      if (rule.provenance == 'remembered' && rule.isExpiredAt(now)) {
        await repository.deleteRule(workspaceId, rule.id);
      }
    }
  } on Object catch (e, st) {
    CcHostLog.error(
      'confirmation.respond: pruning expired standing approvals in '
      '$workspaceId failed: $e',
      e,
      st,
    );
  }
}
