part of 'agent_run_gateway.dart';

/// The gateway's Claude Code PreToolUse hook: each `Bash` command, and each of
/// Claude Code's own file and web tools, is put to the action policy before
/// it runs.
extension _ToolHooks on AgentRunGateway {
  Future<void> _preToolUse(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final body = await AgentRunGateway._readCapped(
      request,
      AgentRunGateway._maxHookBodyBytes,
    );
    final decoded = body == null
        ? null
        : AgentRunGateway._tryJson(utf8.decode(body));
    final input = decoded is Map ? decoded['tool_input'] : null;
    if (decoded is Map && input is Map && decoded['tool_name'] != 'Bash') {
      return _nativeToolDecision(
        request,
        grant,
        secret,
        _NativeToolAction.of(decoded['tool_name'], input, grant),
      );
    }
    final command = input is Map ? input['command'] : null;
    if (decoded is! Map ||
        decoded['tool_name'] != 'Bash' ||
        command is! String ||
        command.trim().isEmpty) {
      return _hookDecision(
        request,
        allowed: false,
        reason: 'Control Center: invalid Bash permission request.',
      );
    }

    // The transcript labels a Bash row with its `description`; Claude Code
    // leaves it optional. Refused before the policy check so a call that will
    // be retried never raises an approval. See
    // `ClaudeCliBackend.bashDescriptionInstruction`.
    final description = input is Map ? input['description'] : null;
    if (description is! String || description.trim().isEmpty) {
      return _hookDecision(
        request,
        allowed: false,
        reason:
            'Missing argument: description. Retry with a clear, concise '
            '5-10 word description of what this command does.',
      );
    }

    final classes = const ShellActionClassifier().classify(command);
    // The run's token cannot open a pull request, and one the bot opened
    // would be approvable by the person who asked for it. Refused before any
    // approval is raised, with directions to the server-side tool.
    if (classes.contains(ActionClass.prCreate)) {
      return _hookDecision(
        request,
        allowed: false,
        reason: kAgentShellPrCreateRefusal,
      );
    }
    // The run's token only reads: a `gh` write would fail on GitHub after
    // an approval was asked for nothing. Refused with directions instead.
    if (classes.contains(ActionClass.prPublish) ||
        classes.contains(ActionClass.vendorSyncWrite)) {
      return _hookDecision(
        request,
        allowed: false,
        reason: kAgentShellGitHubWriteRefusal,
      );
    }
    // Named branches let branch rules (and branch-scoped standing approvals)
    // decide here instead of asking about an unknown destination.
    final pushRefs = classes.contains(ActionClass.gitPush)
        ? ShellActionClassifier.pushRefs(command)
        : null;
    // `processSpawn` is deliberately NOT declared: Claude Code's plan mode is
    // read-only by its own rules and still runs `git diff`, and the read-only
    // mode profiles deny `processSpawn` wholesale. What the command DOES is
    // what the operator's rules are about.
    final verdict = await _askWithDeadline(
      secret,
      (withdrawn) async => _guard.check(
        workspaceId: grant.workspaceId,
        classes: classes,
        command: command,
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: 'bash: $command',
        approvalRationale: description,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runId,
        request: ActionRequest(
          classes: classes,
          command: command,
          refs: pushRefs ?? const [],
        ),
        autonomy: await AgentRunGateway._autonomyOf(grant),
        withdrawn: withdrawn,
      ),
    );
    if (verdict.allowed &&
        verdict.prompted &&
        classes.contains(ActionClass.gitPush)) {
      _shellPushApprovals[secret] = _ShellPushApproval(
        refs: pushRefs,
        until: DateTime.now().add(AgentRunGateway.shellPushApprovalWindow),
      );
    }
    if (verdict.allowed &&
        verdict.prompted &&
        classes.contains(ActionClass.gitCommit)) {
      _shellCommitApprovals[secret] = _now().add(
        AgentRunGateway.shellPushApprovalWindow,
      );
    }
    return _hookDecision(
      request,
      allowed: verdict.allowed,
      reason: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  /// The policy's answer for one of Claude Code's own file or web tools. Null
  /// [action] is a request this hook cannot read, which is refused.
  Future<void> _nativeToolDecision(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
    _NativeToolAction? action,
  ) async {
    if (action == null) {
      return _hookDecision(
        request,
        allowed: false,
        reason: 'Control Center: invalid tool permission request.',
      );
    }
    final refusal = action.refusal;
    if (refusal != null) {
      return _hookDecision(request, allowed: false, reason: refusal);
    }
    final verdict = await _askWithDeadline(
      secret,
      (withdrawn) async => _guard.check(
        workspaceId: grant.workspaceId,
        classes: action.request.classes,
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: action.summary,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runId,
        request: action.request,
        autonomy: await AgentRunGateway._autonomyOf(grant),
        withdrawn: withdrawn,
      ),
    );
    return _hookDecision(
      request,
      allowed: verdict.allowed,
      reason: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  /// Runs one policy check that may wait on a human, bounded by
  /// [AgentRunGateway.hookDecisionDeadline]. At the deadline — or when the run's lease closes
  /// first — the approval is WITHDRAWN, not just abandoned: it used to stay on
  /// the operator's screen, answerable, after the hook had already denied.
  Future<GuardVerdict> _askWithDeadline(
    String secret,
    Future<GuardVerdict> Function(Future<void> withdrawn) ask, {
    Duration deadline = AgentRunGateway.hookDecisionDeadline,
  }) async {
    final withdraw = Completer<void>();
    final pending = _pendingAsks.putIfAbsent(secret, () => {})..add(withdraw);
    try {
      return await ask(withdraw.future).timeout(
        deadline,
        onTimeout: () =>
            const GuardVerdict.deny('Nobody answered the approval in time.'),
      );
    } finally {
      if (!withdraw.isCompleted) {
        withdraw.complete();
      }
      pending.remove(withdraw);
      if (pending.isEmpty && identical(_pendingAsks[secret], pending)) {
        _pendingAsks.remove(secret);
      }
    }
  }

  /// Only the exact `allow` response lets the command hook exit successfully.
  Future<void> _hookDecision(
    HttpRequest request, {
    required bool allowed,
    required String reason,
  }) async {
    return AgentRunGateway._plain(
      request,
      HttpStatus.ok,
      allowed ? 'allow' : reason,
    );
  }
}
