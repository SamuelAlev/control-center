part of 'agent_run_gateway.dart';

/// The call-token side of [AgentRunLease]: what a command's environment
/// gains so the gateway can tell which command a request comes from.
extension _LeaseCallTokens on AgentRunLease {
  /// `git -c` pairs that make the run's git name the command it runs in
  /// ([AgentRunLease.callTokenHeader]) on every request it sends the gateway, beside the
  /// secret [AgentRunLease.gitConfig] sends. Git sends every value of a multi-valued
  /// `extraHeader`, and only to the gateway.
  List<(String, String)> _callGitConfig(String token) => [
    (_gatewayHeaderKey, '${AgentRunLease.callTokenHeader}: $token'),
  ];

  /// What a command's environment [env] gains for the call token [token]:
  /// the variable the agent run client reads and [_callGitConfig] appended
  /// to the `GIT_CONFIG_*` entries [env] already carries.
  Map<String, String> _callEnvironment(String token, Map<String, String> env) {
    final out = <String, String>{AgentRunLease.callTokenEnvKey: token};
    var count = int.tryParse(env['GIT_CONFIG_COUNT'] ?? '') ?? 0;
    for (final (key, value) in _callGitConfig(token)) {
      out['GIT_CONFIG_KEY_$count'] = key;
      out['GIT_CONFIG_VALUE_$count'] = value;
      count++;
    }
    out['GIT_CONFIG_COUNT'] = '$count';
    return out;
  }
}

/// The gateway's registrations of the run's commands ([AgentRunLease.register]).
extension _GatewayCallWaits on AgentRunGateway {
  /// Registers [listener] under a fresh call token on [lease]'s run. See
  /// [AgentRunLease.register].
  CommandWait _registerCallWait(
    AgentRunLease lease,
    PersonWaitListener listener,
    Map<String, String> env,
    void Function(bool approved) decided,
  ) {
    final secret = lease.secret;
    if (!_grants.containsKey(secret)) {
      return CommandWait(environment: const {}, release: () {});
    }
    final bytes = List<int>.generate(
      32,
      (_) => AgentRunGateway._random.nextInt(256),
    );
    final token = base64Url.encode(bytes).replaceAll('=', '');
    final wait = _CallWait(listener, decided);
    _callWaits.putIfAbsent(secret, () => {})[token] = wait;
    return CommandWait(
      environment: lease._callEnvironment(token, env),
      release: () {
        wait.release();
        final waits = _callWaits[secret];
        if (waits != null && identical(waits[token], wait)) {
          waits.remove(token);
          if (waits.isEmpty) {
            _callWaits.remove(secret);
          }
        }
      },
    );
  }

  /// The person-wait listener of the command [request] says it comes from,
  /// when that command is still registered on this run ([secret], already
  /// authenticated). Null for no call token, more than one, an unknown one
  /// or one registered on another run: the request is then decided exactly
  /// as it would be without one, and nobody's clock stops.
  PersonWaitListener? _callWaitOf(String secret, HttpRequest request) {
    final tokens = request.headers[AgentRunLease.callTokenHeader];
    if (tokens == null || tokens.length != 1) {
      return null;
    }
    return _callWaits[secret]?[tokens.single]?.report;
  }

  /// Where the decision about [request] goes: the [CommandWaitRelay.register]
  /// `decided` callback of the command it names, under the same rule as
  /// [_callWaitOf]. Null when it names none that is registered.
  void Function(bool approved)? _callDecidedOf(
    String secret,
    HttpRequest request,
  ) {
    final tokens = request.headers[AgentRunLease.callTokenHeader];
    if (tokens == null || tokens.length != 1) {
      return null;
    }
    return _callWaits[secret]?[tokens.single]?.decided;
  }

  /// Holds [approvals] on [secret]'s run until the returned call. See
  /// [AgentRunLease.holdScriptApprovals]. A run that is not registered (its
  /// lease closed) holds nothing.
  void Function() _holdScriptApprovals(
    String secret,
    ScriptApprovalBudget approvals,
  ) {
    if (!_grants.containsKey(secret)) {
      return () {};
    }
    final held = _scriptApprovals.putIfAbsent(secret, () => []);
    held.add(approvals);
    var released = false;
    return () {
      if (released) {
        return;
      }
      released = true;
      final now = _scriptApprovals[secret];
      if (now == null || !identical(now, held)) {
        return;
      }
      now.remove(approvals);
      if (now.isEmpty) {
        _scriptApprovals.remove(secret);
      }
    };
  }

  /// [ask] (one policy check a hook or the signer is waiting on) bounded by
  /// [deadline] like every hook ask (`_askWithDeadline`), and within the
  /// budgets of [grant]'s scripts in flight ([_checkWithinScripts]). A card
  /// whose deadline passed was not answered, so no budget records it as
  /// declined.
  Future<GuardVerdict> _askWithinScripts(
    AgentRunGrant grant,
    String secret, {
    required Set<ActionClass> classes,
    required ActionRequest request,
    required String summary,
    required Future<GuardVerdict> Function(
      Future<void> withdrawn,
      PersonWaitListener? onPersonWait,
      String? Function()? beforeCard,
      AutonomyLevel? autonomy,
    )
    ask,
    String? command,
    PersonWaitListener? onPersonWait,
    void Function(bool approved)? onDecided,
    Duration deadline = AgentRunGateway.hookDecisionDeadline,
  }) async {
    final autonomy = await AgentRunGateway._autonomyOf(grant);
    return _checkWithinScripts(
      grant,
      secret,
      classes: classes,
      request: request,
      summary: summary,
      command: command,
      autonomy: autonomy,
      onPersonWait: onPersonWait,
      onDecided: onDecided,
      unanswered: (verdict) => identical(verdict, _ToolHooks._unanswered),
      check: (onPersonWait, beforeCard) => _askWithDeadline(
        secret,
        (withdrawn) => ask(withdrawn, onPersonWait, beforeCard, autonomy),
        deadline: deadline,
      ),
    );
  }

  /// The policy's answer to one push of [grant]'s run, asked within its
  /// scripts' budgets ([_checkWithinScripts]). [summary] names every pushed
  /// ref, so it is what runs (`executed`): the audit row digests all of it.
  Future<GuardVerdict> _pushVerdict(
    AgentRunGrant grant,
    String secret,
    HttpRequest request,
    ActionRequest pushRequest,
    String summary,
  ) async {
    final autonomy = await AgentRunGateway._autonomyOf(grant);
    return _checkWithinScripts(
      grant,
      secret,
      classes: const {ActionClass.gitPush},
      request: pushRequest,
      summary: summary,
      autonomy: autonomy,
      onPersonWait: _callWaitOf(secret, request),
      onDecided: _callDecidedOf(secret, request),
      check: (onPersonWait, beforeCard) => _guard.check(
        workspaceId: grant.workspaceId,
        classes: const {ActionClass.gitPush},
        spaceId: grant.spaceId,
        conversationId: grant.conversationId,
        agentId: grant.agentId,
        mode: grant.mode,
        actionSummary: summary,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runLogId,
        request: pushRequest,
        autonomy: autonomy,
        onPersonWait: onPersonWait,
        beforeCard: beforeCard,
        executed: summary,
      ),
      executed: summary,
    );
  }

  /// Runs one policy [check] for [grant]'s run that may ask a person, within
  /// the budgets of the run's scripts in flight ([_holdScriptApprovals]):
  /// while one is held, a card counts against each, and a call that would
  /// ask once one of them refuses is denied without asking and audited as
  /// that denial. Every card the gateway raises goes through here, whatever
  /// the request says about the command it comes from. [executed] is what
  /// [check] is handed as what runs, so a denial recorded here digests it.
  Future<GuardVerdict> _checkWithinScripts(
    AgentRunGrant grant,
    String secret, {
    required Set<ActionClass> classes,
    required ActionRequest request,
    required String summary,
    required Future<GuardVerdict> Function(
      PersonWaitListener? onPersonWait,
      String? Function()? beforeCard,
    )
    check,
    String? command,
    String? executed,
    AutonomyLevel? autonomy,
    PersonWaitListener? onPersonWait,
    void Function(bool approved)? onDecided,
    bool Function(GuardVerdict verdict)? unanswered,
  }) => checkWithinScriptApprovals(
    guard: _guard,
    approvals: [...?_scriptApprovals[secret]],
    workspaceId: grant.workspaceId,
    classes: classes,
    request: request,
    actionSummary: summary,
    check: check,
    command: command,
    executed: executed,
    spaceId: grant.spaceId,
    agentId: grant.agentId,
    mode: grant.mode,
    autonomy: autonomy,
    onBehalfOfUserId: grant.actingUserId,
    runId: grant.runLogId,
    onPersonWait: onPersonWait,
    onDecided: onDecided,
    unanswered: unanswered,
  );
}

/// One command's registration for the waits the gateway holds on a person
/// while it runs ([AgentRunLease.register]).
///
/// The listener hears one `true` when the first of the command's asks
/// starts and one `false` when the last ends, so concurrent asks (two
/// pushes) do not end each other's wait. Once released it hears nothing
/// more: a release during an ask ends that wait there, and the ask's own
/// end later finds the registration gone.
final class _CallWait {
  _CallWait(this._listener, this._decided);

  final PersonWaitListener _listener;
  final void Function(bool approved) _decided;
  int _depth = 0;
  bool _live = true;

  /// What `ActionGuardService.check` is handed as its `onPersonWait`.
  void report(bool waiting) {
    if (!_live) {
      return;
    }
    if (waiting) {
      _depth++;
      if (_depth == 1) {
        _tell(true);
      }
      return;
    }
    if (_depth == 0) {
      return;
    }
    _depth--;
    if (_depth == 0) {
      _tell(false);
    }
  }

  /// What the gateway decided about a request of the command, while it is
  /// registered ([CommandWaitRelay.register]).
  void decided(bool approved) {
    if (!_live) {
      return;
    }
    try {
      _decided(approved);
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: a decision listener failed: $e');
    }
  }

  /// Ends the registration, closing a wait that is still open.
  void release() {
    if (!_live) {
      return;
    }
    _live = false;
    if (_depth > 0) {
      _depth = 0;
      _tell(false);
    }
  }

  /// A listener only stops clocks: its failure must not fail the request,
  /// the command or the lease's close.
  void _tell(bool waiting) {
    try {
      _listener(waiting);
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: a person-wait listener failed: $e');
    }
  }
}
