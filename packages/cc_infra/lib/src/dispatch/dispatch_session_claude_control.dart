part of 'dispatch_session.dart';

/// One stream-json `control_request` line for stdin.
String _claudeControlLine(String requestId, Map<String, Object?> request) =>
    '${jsonEncode({'type': 'control_request', 'request_id': requestId, 'request': request})}\n';

/// How long a turn waits for `mcp_set_servers` to be answered. Past it the turn
/// starts anyway, and `_onClaudeInit` reports the tools it did not get.
const _claudeMcpAnswerTimeout = Duration(seconds: 90);

/// How long a stopped turn gets to close itself before it is killed.
const _claudeInterruptGrace = Duration(seconds: 3);

/// Talking to a running `claude` beyond its messages: the MCP servers it starts
/// with, stopping it, and what it reports about its plan and its session.
extension _ClaudeControlMethods on DispatchSession {
  /// Whether this run is the idle compaction of a session rather than a turn.
  /// See [kClaudeIdleCompactionPrompt].
  bool get _claudeCompactOnly =>
      (promptParts?.userText ?? prompt).trim() == kClaudeIdleCompactionPrompt;

  /// The MCP servers to hand `claude` over stdin, or null when no resolver is
  /// wired. Same scope and credentials as [_resolveMcpConfigPath].
  Future<Map<String, Object?>?> _resolveMcpServers() async {
    final resolver = deps.mcpServersResolver;
    if (resolver == null) {
      return null;
    }
    return resolver(
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      spaceId: spaceId,
      runToken: _gatewayLease?.secret,
    );
  }

  /// Removes a config an earlier run left in this overlay. Its bearer token
  /// would otherwise stay readable to an agent that no longer needs the file.
  void _removeStaleMcpConfig() {
    try {
      final file = File('$agentDirHostPath/.mcp.json');
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Object catch (e) {
      CcInfraLog.warning('dispatch $dispatchId: stale MCP config kept: $e');
    }
  }

  /// Opens the stdin lane for one `claude -p` attempt: [firstMessage] as the
  /// first stream-json user message, then everything this run already steered
  /// (a failover attempt replays the turn as the operator last shaped it).
  ///
  /// [firstMessage] is the DELTA prompt when this attempt resumes a native
  /// session and the FULL prompt otherwise — never the delta without
  /// `--resume`, which would drop the standing brief and the conversation.
  ///
  /// With [mcpServers], the servers go first and the prompt waits for the CLI's
  /// answer: a turn that started before they connected would run without the
  /// `mcp__*` tools, and the tool list is fixed when the turn starts.
  StreamController<String> _openClaudeStdin(
    String firstMessage, {
    Map<String, Object?>? mcpServers,
  }) {
    final stdin = StreamController<String>();
    _claudeStdin = stdin;
    final lines = [
      _claudeUserLine(firstMessage),
      for (final text in _claudeSteered) _claudeUserLine(text),
    ];
    if (mcpServers == null) {
      lines.forEach(stdin.add);
      return stdin;
    }
    _claudeHeldLines = lines;
    final id = 'cc-mcp-${_claudeControlRequests++}';
    _claudeMcpRequestId = id;
    stdin.add(
      _claudeControlLine(id, {
        'subtype': 'mcp_set_servers',
        'servers': mcpServers,
      }),
    );
    _claudeMcpAnswerTimer = Timer(_claudeMcpAnswerTimeout, () {
      addEvent(
        DebugEvent(
          content:
              '[claude] no answer to the MCP server setup after '
              '${_claudeMcpAnswerTimeout.inSeconds}s — starting the turn',
        ),
      );
      _releaseClaudeHeldLines();
    });
    return stdin;
  }

  /// The CLI answered a control request this run sent.
  void _onClaudeControlResponse(ClaudeControlResponse response) {
    if (response.requestId != _claudeMcpRequestId) {
      return;
    }
    final errors = response.body['errors'];
    final failures = [
      if (!response.success) response.error ?? 'refused',
      if (errors is Map)
        for (final MapEntry(:key, :value) in errors.entries) '$key: $value',
    ];
    if (failures.isNotEmpty) {
      // Reported properly by `_onClaudeInit`, which sees the tools go missing.
      addEvent(
        DebugEvent(
          content: redactSecrets(
            '[claude] MCP server setup failed: ${failures.join('; ')}',
          ),
        ),
      );
    }
    _releaseClaudeHeldLines();
  }

  /// Starts the turn held back by [_openClaudeStdin], then anything steered
  /// while it waited.
  void _releaseClaudeHeldLines() {
    final stdin = _claudeStdin;
    final lines = _claudeHeldLines;
    _claudeMcpAnswerTimer?.cancel();
    _claudeMcpAnswerTimer = null;
    _claudeMcpRequestId = null;
    _claudeHeldLines = null;
    if (stdin == null || lines == null) {
      return;
    }
    lines.forEach(stdin.add);
    _pumpClaudeSteering();
  }

  /// Asks the turn in flight to stop, and waits a moment for it to.
  ///
  /// A signal loses whatever the turn has not reported. Interrupted, the CLI
  /// closes the turn with a `result` that still carries what it spent, and it
  /// stops its own tools before anything is killed.
  Future<void> _interruptClaudeTurn() async {
    final stdin = _claudeStdin;
    if (stdin == null || _claudeInit == null || _claudeHeldLines != null) {
      return;
    }
    final closed = Completer<void>();
    _claudeStdinClosed = closed;
    stdin.add(
      _claudeControlLine('cc-interrupt-${_claudeControlRequests++}', const {
        'subtype': 'interrupt',
      }),
    );
    await closed.future.timeout(_claudeInterruptGrace, onTimeout: () {});
  }

  /// Takes the closing `result` of a turn that is being stopped, and nothing
  /// else: everything before it is output of a run that has already ended.
  void _readInterruptedClaudeResult(String line) {
    final Object? frame;
    try {
      frame = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (frame is Map<String, dynamic> && frame['type'] == 'result') {
      _claudeParser?.process(frame);
    }
  }

  /// Closes the open stdin lane, which lets `claude` exit once it has answered
  /// what it was already sent. Steering from here on stays queued.
  void _closeClaudeStdin() {
    final stdin = _claudeStdin;
    _claudeStdin = null;
    _claudeMcpAnswerTimer?.cancel();
    _claudeMcpAnswerTimer = null;
    _claudeMcpRequestId = null;
    _claudeHeldLines = null;
    if (stdin != null) {
      unawaited(stdin.close());
    }
    final closed = _claudeStdinClosed;
    _claudeStdinClosed = null;
    if (closed != null && !closed.isCompleted) {
      closed.complete();
    }
  }

  /// Drains on the next microtask rather than inside the push: the steering
  /// queue service pushes several rows in a row (reorder, run-start flush),
  /// and queue surgery mid-push would interleave with it.
  void _scheduleClaudeSteeringPump() {
    if (_claudeSteeringPumpScheduled) {
      return;
    }
    _claudeSteeringPumpScheduled = true;
    scheduleMicrotask(() {
      _claudeSteeringPumpScheduled = false;
      _pumpClaudeSteering();
    });
  }

  /// Writes the steering and aside lanes to the open stdin. Claude Code
  /// injects a user message that arrives mid-turn at its next tool boundary.
  /// Follow-ups wait for [_onClaudeTurnEnded]: they are for once the agent
  /// would otherwise stop.
  void _pumpClaudeSteering() {
    final stdin = _claudeStdin;
    if (stdin == null || _claudeHeldLines != null) {
      return;
    }
    _writeClaudeSteering(stdin, [
      ..._steering.drainSteering(),
      ..._steering.drainAside(),
    ]);
  }

  void _writeClaudeSteering(
    StreamController<String> stdin,
    List<SteeringMessage> messages,
  ) {
    if (messages.isEmpty) {
      return;
    }
    for (final message in messages) {
      _claudeSteered.add(message.content);
      stdin.add(_claudeUserLine(message.content));
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] steered the running turn with ${messages.length} '
            'queued message${messages.length == 1 ? '' : 's'}',
      ),
    );
  }

  /// Tells the idle compactor this session is at rest. A failover ran on an
  /// account this scope cannot resume, so there is nothing to compact.
  void _reportClaudeTurnSettled() {
    final ws = workspaceId;
    final space = spaceId;
    final conversation = conversationId;
    final agent = agentId;
    if (_claudePersistDisabled ||
        ws == null ||
        space == null ||
        conversation == null ||
        agent == null) {
      return;
    }
    deps.claudeIdleCompactor?.turnSettled(
      ClaudeSettledTurn(
        workspaceId: ws,
        spaceId: space,
        conversationId: conversation,
        agentId: agent,
        contextTokens: _claudeContextTokens,
        cacheTtl: _claudeCacheTtl,
        requestedByUserId: requestedByUserId,
      ),
    );
  }

  /// A limit report from the running CLI. Tells the rest of the server what
  /// this account has left the moment the CLI knows it, instead of when a
  /// failed turn or the next usage poll gets round to saying so.
  void _onClaudeRateLimit(
    ClaudeRateLimitInfo info,
    ({String accountId, String configDir}) attempt,
  ) {
    if (attempt.configDir.isNotEmpty) {
      deps.onClaudeUsageWindows?.call(attempt.configDir, info.usageWindows);
    }
    if (!info.blocked && !info.warning) {
      return;
    }
    if (!_claudeLimitCrossings.add('${info.status}:${info.crossingKey}')) {
      return;
    }
    final limit = info.rateLimitType ?? 'plan';
    final reset = info.resetsAt;
    final until = reset == null ? '' : ' until ${reset.toIso8601String()}';
    if (!info.blocked) {
      final used = info.windows[info.rateLimitType]?.usedFraction;
      final percent = used == null ? '' : ' at ${(used * 100).round()}%';
      addEvent(
        DebugEvent(
          content:
              '[claude] ${attempt.accountId} is nearing its $limit '
              'limit$percent',
        ),
      );
      return;
    }
    addEvent(
      DebugEvent(
        content: '[claude] ${attempt.accountId} reached its $limit limit$until',
      ),
    );
    // Now, not when this turn fails: another dispatch may be choosing an
    // account this moment, and the failure is still a round trip away.
    if (attempt.accountId.isNotEmpty) {
      unawaited(
        Future.sync(
          () => onClaudeAccountExhausted?.call(
            accountId: attempt.accountId,
            resetsAt: reset,
          ),
        ).catchError((Object _) {}),
      );
    }
  }
}
