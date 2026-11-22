part of 'agent_run_gateway.dart';

/// The server owner's `stop` and `preCompact` hook scripts, as the gateway
/// runs them for a Claude Code run ([AgentRunGrant.claudeTurnHooks]).
abstract interface class ClaudeTurnHookScripts {
  /// Whether a `stop` script is configured.
  bool get hasStop;

  /// Whether a `preCompact` script is configured.
  bool get hasPreCompact;

  /// Runs the `stop` script with [event] on stdin. Returns the text that
  /// keeps the turn going (the script exited 2 with it on stdout, within the
  /// run's block limit), or null to let the turn end.
  Future<String?> stop(Map<String, Object?> event);

  /// Runs the `preCompact` script with [event] on stdin. Returns its stdout
  /// for the compaction's instructions, or null.
  Future<String?> preCompact(Map<String, Object?> event);
}

/// The gateway's Claude Code PreToolUse hook: each `Bash` command, and each of
/// Claude Code's own file and web tools, is put to the action policy before
/// it runs.
extension _ToolHooks on AgentRunGateway {
  /// Logs that [route] refused the run [secret] names because its backend
  /// does not use that route: once per run and route, not per request, since
  /// a process that keeps trying would otherwise flood the log.
  void _logRouteRefusal(String secret, AgentRunGrant grant, String route) {
    if (!_routeRefusalsLogged.putIfAbsent(secret, () => {}).add(route)) {
      return;
    }
    CcInfraLog.warning(
      'agent gateway: $route refused run ${grant.runId} of workspace '
      '${grant.workspaceId}: its agent does not use that route, so its '
      'secret opens nothing there',
    );
  }

  Future<void> _preToolUse(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    // Only a run whose Claude Code has the hook installed asks here. Any
    // other run's secret, which every process of that run can read, is
    // refused as one that names no run, like on `/mcp`.
    if (!grant.claudeHook) {
      _logRouteRefusal(secret, grant, AgentRunGateway.hookPath);
      return AgentRunGateway._plain(
        request,
        HttpStatus.unauthorized,
        'Unknown agent run.',
      );
    }
    final body = await AgentRunGateway._readCapped(
      request,
      AgentRunGateway._maxHookBodyBytes,
    );
    final decoded = body == null
        ? null
        : AgentRunGateway._tryJson(utf8.decode(body));
    final input = decoded is Map ? decoded['tool_input'] : null;
    // A read-only run's hook sees every tool; only reads pass, as they
    // would unhooked (an MCP tool meets the profile at the MCP dispatcher).
    final toolName = decoded is Map ? decoded['tool_name'] : null;
    if (grant.readOnly) {
      final admitted =
          toolName is String && ReadOnlyRunProfile.admitsClaudeTool(toolName);
      return _hookDecision(
        request,
        allowed: admitted,
        reason: admitted ? '' : ReadOnlyRunProfile.refusal('$toolName'),
      );
    }
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
    final actionRequest = ActionRequest(
      classes: classes,
      command: command,
      refs: pushRefs ?? const [],
    );
    final verdict = await _askWithinScripts(
      grant,
      secret,
      classes: classes,
      request: actionRequest,
      summary: 'bash: $command',
      command: command,
      onPersonWait: _callWaitOf(secret, request),
      ask: (withdrawn, onPersonWait, beforeCard, autonomy) => _guard.check(
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
        runId: grant.runLogId,
        request: actionRequest,
        autonomy: autonomy,
        withdrawn: withdrawn,
        onPersonWait: onPersonWait,
        beforeCard: beforeCard,
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
    final verdict = await _askWithinScripts(
      grant,
      secret,
      classes: action.request.classes,
      request: action.request,
      summary: action.summary,
      onPersonWait: _callWaitOf(secret, request),
      ask: (withdrawn, onPersonWait, beforeCard, autonomy) => _guard.check(
        workspaceId: grant.workspaceId,
        classes: action.request.classes,
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: action.summary,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runLogId,
        request: action.request,
        autonomy: autonomy,
        withdrawn: withdrawn,
        onPersonWait: onPersonWait,
        beforeCard: beforeCard,
      ),
    );
    return _hookDecision(
      request,
      allowed: verdict.allowed,
      reason: 'Control Center policy: ${verdict.reason ?? 'denied'}',
    );
  }

  /// What [_askWithDeadline] answers when its deadline passes first: a card
  /// nobody answered, which no script's budget records as declined.
  static const GuardVerdict _unanswered = GuardVerdict.deny(
    'Nobody answered the approval in time.',
  );

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
      return await ask(
        withdraw.future,
      ).timeout(deadline, onTimeout: () => _unanswered);
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
  /// Claude Code's `Stop` hook: the owner's `stop` script decides whether
  /// the turn may end. Answers `end`, or `block` and the script's text on
  /// the next lines (the client prints it to stderr and exits 2, which Claude
  /// Code reads as "continue with this"). Anything that goes wrong ends the
  /// turn: a broken stop hook must not hold a run open.
  Future<void> _stopHook(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final scripts = grant.claudeTurnHooks;
    if (!grant.claudeHook || scripts == null) {
      _logRouteRefusal(secret, grant, AgentRunGateway.stopHookPath);
      return AgentRunGateway._plain(
        request,
        HttpStatus.unauthorized,
        'Unknown agent run.',
      );
    }
    final input = await _hookInput(request);
    final last = input?['last_assistant_message'];
    String? text;
    try {
      // Claude Code says whether this stop follows a continuation the hook
      // caused; the script reads it as the harness lane's script does.
      final active = input?['stop_hook_active'];
      text = await scripts.stop({
        'event': 'stop',
        'last_message': last is String ? last : '',
        'stop_hook_active': active is bool && active,
      });
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: stop hook failed: $e');
      text = null;
    }
    return AgentRunGateway._plain(
      request,
      HttpStatus.ok,
      text == null ? 'end' : 'block\n$text',
    );
  }

  /// Claude Code's `PreCompact` hook: the owner's `preCompact` script's
  /// stdout is answered as the body, which the client prints on stdout for
  /// Claude Code to add to the compaction's instructions. Never a refusal:
  /// exit 2 from a `PreCompact` hook would block the compaction.
  Future<void> _preCompactHook(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final scripts = grant.claudeTurnHooks;
    if (!grant.claudeHook || scripts == null) {
      _logRouteRefusal(secret, grant, AgentRunGateway.preCompactHookPath);
      return AgentRunGateway._plain(
        request,
        HttpStatus.unauthorized,
        'Unknown agent run.',
      );
    }
    final input = await _hookInput(request);
    final trigger = input?['trigger'];
    String? text;
    try {
      text = await scripts.preCompact({
        'event': 'pre_compact',
        if (trigger is String) 'trigger': trigger,
      });
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: preCompact hook failed: $e');
      text = null;
    }
    return AgentRunGateway._plain(request, HttpStatus.ok, text ?? '');
  }

  /// The JSON object Claude Code sent a hook on stdin, or null.
  Future<Map<Object?, Object?>?> _hookInput(HttpRequest request) async {
    final body = await AgentRunGateway._readCapped(
      request,
      AgentRunGateway._maxHookBodyBytes,
    );
    final decoded = body == null
        ? null
        : AgentRunGateway._tryJson(utf8.decode(body, allowMalformed: true));
    return decoded is Map ? decoded : null;
  }

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
