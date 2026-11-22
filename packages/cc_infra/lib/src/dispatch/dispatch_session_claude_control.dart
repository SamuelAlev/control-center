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
  /// See [kClaudeIdleCompactionPrompt]. Read from [userText], which only a
  /// signed-in person's run carries: another agent's `/compact` is a message.
  bool get _claudeCompactOnly =>
      userText?.trim() == kClaudeIdleCompactionPrompt;

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
    _claude.stdin = stdin;
    // A task a late line of the last attempt reported is not this one's.
    _claude.backgroundTasks.clear();
    _claude.backgroundYielded = false;
    final lines = [
      _claudeUserLine(firstMessage),
      for (final text in _claude.steered) _claudeUserLine(text),
    ];
    if (mcpServers == null) {
      lines.forEach(stdin.add);
      return stdin;
    }
    _claude.heldLines = lines;
    final id = 'cc-mcp-${_claude.controlRequests++}';
    _claude.mcpRequestId = id;
    stdin.add(
      _claudeControlLine(id, {
        'subtype': 'mcp_set_servers',
        'servers': mcpServers,
      }),
    );
    _claude.mcpAnswerTimer = Timer(_claudeMcpAnswerTimeout, () {
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
    if (response.requestId != _claude.mcpRequestId) {
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
    // Closed by the Claude transport when its turn ends.
    // ignore: close_sinks
    final stdin = _claude.stdin;
    final lines = _claude.heldLines;
    _claude.mcpAnswerTimer?.cancel();
    _claude.mcpAnswerTimer = null;
    _claude.mcpRequestId = null;
    _claude.heldLines = null;
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
    // Closed by the Claude transport when its turn ends.
    // ignore: close_sinks
    final stdin = _claude.stdin;
    if (_claudeHeldIdle) {
      // No turn to interrupt: the wait on background tasks ends at once.
      _closeClaudeStdin();
      return;
    }
    if (stdin == null || _claude.init == null || _claude.heldLines != null) {
      return;
    }
    final closed = Completer<void>();
    _claude.stdinClosed = closed;
    stdin.add(
      _claudeControlLine('cc-interrupt-${_claude.controlRequests++}', const {
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
      _claude.parser?.process(frame);
    }
  }

  /// Closes the open stdin lane, which lets `claude` exit once it has answered
  /// what it was already sent. Steering from here on stays queued.
  void _closeClaudeStdin() {
    final stdin = _claude.stdin;
    _claude.stdin = null;
    _endClaudeBackgroundHold();
    _claude.backgroundTasks.clear();
    _claude.mcpAnswerTimer?.cancel();
    _claude.mcpAnswerTimer = null;
    _claude.mcpRequestId = null;
    _claude.heldLines = null;
    if (stdin != null) {
      unawaited(stdin.close());
    }
    final closed = _claude.stdinClosed;
    _claude.stdinClosed = null;
    if (closed != null && !closed.isCompleted) {
      closed.complete();
    }
  }

  /// Drains on the next microtask rather than inside the push: the steering
  /// queue service pushes several rows in a row (reorder, run-start flush),
  /// and queue surgery mid-push would interleave with it.
  void _scheduleClaudeSteeringPump() {
    if (_claude.steeringPumpScheduled) {
      return;
    }
    _claude.steeringPumpScheduled = true;
    scheduleMicrotask(() {
      _claude.steeringPumpScheduled = false;
      _pumpClaudeSteering();
    });
  }

  /// Writes the steering and aside lanes to the open stdin. Claude Code
  /// injects a user message that arrives mid-turn at its next tool boundary.
  /// Follow-ups wait for [_onClaudeTurnEnded]: they are for once the agent
  /// would otherwise stop.
  void _pumpClaudeSteering() {
    final stdin = _claude.stdin;
    if (stdin == null || _claude.heldLines != null) {
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
    // A turn begins: a wait on background tasks is no longer idle.
    _noteClaudeBackgroundTurn();
    // Steering is never a command, whoever pushed it (a person mid-run, a
    // wake, the server): Claude Code would run a slash-leading line as one.
    for (final message in messages) {
      final text = nonCommandTurnInput(message.content);
      _claude.steered.add(text);
      stdin.add(_claudeUserLine(text));
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
    if (_claude.persistDisabled ||
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
        contextTokens: _claude.contextTokens,
        cacheTtl: _claude.cacheTtl,
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
    if (!_claude.limitCrossings.add('${info.status}:${info.crossingKey}')) {
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
      unawaited(_reportClaudeAccountExhausted(attempt.accountId, reset));
    }
  }
}

/// The longest a turn keeps `claude`'s stdin open for its background Bash
/// tasks, from the turn's end: the default the built-in harness gives a
/// background command (`BackgroundCommandRegistry.defaultTimeoutSeconds`,
/// 600 s). The stream reports no task's own timeout, so this bound is the
/// only one; a task whose end the stream never reports costs at most this
/// much of an idle run, and nothing waits behind it (the run yields).
const _claudeBackgroundBound = Duration(
  seconds: BackgroundCommandRegistry.defaultTimeoutSeconds,
);

/// After the last background task ended, how long `claude` gets to start
/// its next turn by itself before stdin closes as at any turn end.
const _claudeBackgroundGrace = Duration(minutes: 1);

/// The park name the silence watchdog skips while a turn waits, idle, on
/// its background tasks.
const _claudeBackgroundPark = 'claude-background';

/// Background Bash tasks of the Claude Code lane (plan section 11, defect
/// 24): a turn that ends while one is live keeps stdin open, so the CLI can
/// continue when the task finishes.
///
/// - The wait is idle: the silence watchdog is paused only while nothing
///   happens; steering written to the CLI, or any line it prints (a new
///   turn), runs the watchdog again until that turn's result.
/// - It is bounded by [_claudeBackgroundBound] from the turn's end.
/// - It blocks nothing: the run reports itself held for background tasks
///   only (`BackgroundHoldView`), and the wake queue makes it yield when
///   work for this agent here waits; a person's stop ends it at once.
extension _ClaudeBackgroundTasks on DispatchSession {
  /// Routes one decoded stdout line to the Claude parser, when this run is
  /// a Claude Code run. False otherwise.
  bool _routeClaudeLine(Map<String, dynamic> json) {
    final parser = _claude.parser;
    if (parser == null) {
      return false;
    }
    // The first stdout byte of this attempt: the one transport boundary the
    // adapter can honestly time (the CLI hides the provider request).
    _noteClaudeFirstStdout();
    if (json['type'] != 'system') {
      // A turn's line (a task's lifecycle line or an init is not the CLI at
      // work): during a background wait, the CLI continued by itself.
      _noteClaudeBackgroundTurn();
    }
    parser.process(json);
    return true;
  }

  /// The first structured stdout line of the current attempt — the transport
  /// boundary the adapter can see. Called from [_routeClaudeLine].
  void _noteClaudeFirstStdout() {
    if (!_claude.sawFirstStdout) {
      _claude.sawFirstStdout = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstResponseByte,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.transport,
          provider: _claudeProvider,
          modelId: _claude.init?.model ?? modelId,
        ),
      );
    }
  }

  /// Whether this run is live only because its turn waits, idle, on its
  /// background tasks, or is yielding that wait.
  bool get _claudeHeldIdle =>
      _claude.backgroundYielded ||
      (_claude.backgroundIdleSince != null && !_claude.backgroundTurnActive);

  /// The stream's report of a background Bash task.
  void _onClaudeBackgroundTask(ClaudeBackgroundTaskEvent event) {
    switch (event) {
      case ClaudeBackgroundTaskStarted(:final taskId):
        _claude.backgroundTasks.add(taskId);
        addEvent(
          DebugEvent(content: '[claude] background task $taskId started'),
        );
      case ClaudeBackgroundTaskEnded(:final taskId, :final status):
        if (!_claude.backgroundTasks.remove(taskId)) {
          return;
        }
        addEvent(
          DebugEvent(
            content:
                '[claude] background task $taskId ended'
                '${status == null ? '' : ' ($status)'}',
          ),
        );
        if (_claude.backgroundTasks.isEmpty &&
            _claude.backgroundIdleSince != null) {
          _claude.backgroundEndedAt = clock.now();
        }
    }
  }

  /// At a successful turn's end with nothing queued: keeps stdin open while
  /// a background task is live. True when the turn now waits.
  bool _holdClaudeForBackground() {
    final live = _claude.backgroundTasks.length;
    if (live == 0 || _claude.stdin == null) {
      return false;
    }
    _claude.backgroundCheck?.cancel();
    _claude
      ..backgroundIdleSince = clock.now()
      ..backgroundTurnActive = false
      ..backgroundEndedAt = null;
    _noteLoopPark(_claudeBackgroundPark, parked: true);
    addEvent(
      DebugEvent(
        content:
            '[claude] waiting for $live background task(s) to finish before '
            'the turn ends (at most ${_claudeBackgroundBound.inMinutes} min).',
      ),
    );
    _claude.backgroundCheck = Timer.periodic(
      _parks.checkEvery,
      (_) => _checkClaudeBackgroundHold(),
    );
    return true;
  }

  /// A turn began during the wait (steering was written, or the CLI
  /// printed): the silence watchdog runs again until its result.
  void _noteClaudeBackgroundTurn() {
    if (_claude.backgroundIdleSince == null || _claude.backgroundTurnActive) {
      return;
    }
    _claude.backgroundTurnActive = true;
    _noteLoopPark(_claudeBackgroundPark, parked: false);
  }

  /// Ends the idle wait now, for work that waits for this agent here.
  void _yieldClaudeBackgroundHold() {
    if (!_claudeHeldIdle || _claude.backgroundYielded) {
      return;
    }
    _claude.backgroundYielded = true;
    addEvent(
      DebugEvent(
        content:
            '[claude] work is waiting for this agent: ending the wait for '
            'background tasks.',
      ),
    );
    _closeClaudeStdin();
  }

  void _checkClaudeBackgroundHold() {
    // Closed by `_closeClaudeStdin`.
    // ignore: close_sinks
    final stdin = _claude.stdin;
    final since = _claude.backgroundIdleSince;
    if (stdin == null || since == null) {
      _endClaudeBackgroundHold();
      return;
    }
    if (_cancelSource.isCancelled) {
      _closeClaudeStdin();
      return;
    }
    if (_claude.backgroundTurnActive) {
      // A turn runs: its result decides.
      return;
    }
    // Follow-ups wait for a turn's end; this one ended already.
    final followUps = _steering.drainFollowUp();
    if (followUps.isNotEmpty) {
      _writeClaudeSteering(stdin, followUps);
      return;
    }
    final now = clock.now();
    if (_claude.backgroundTasks.isNotEmpty) {
      if (now.difference(since) >= _claudeBackgroundBound) {
        addEvent(
          DebugEvent(
            content:
                '[claude] background tasks still running '
                '${_claudeBackgroundBound.inMinutes} min after the turn; '
                'ending the turn.',
          ),
        );
        _closeClaudeStdin();
      }
      return;
    }
    final ended = _claude.backgroundEndedAt ?? now;
    if (now.difference(ended) >= _claudeBackgroundGrace) {
      _closeClaudeStdin();
    }
  }

  /// Ends a turn's wait on its background tasks (none: a no-op).
  void _endClaudeBackgroundHold() {
    _claude.backgroundCheck?.cancel();
    _claude.backgroundCheck = null;
    if (_claude.backgroundIdleSince == null) {
      return;
    }
    final wasIdle = !_claude.backgroundTurnActive;
    _claude
      ..backgroundIdleSince = null
      ..backgroundEndedAt = null
      ..backgroundTurnActive = false;
    if (wasIdle) {
      _noteLoopPark(_claudeBackgroundPark, parked: false);
    }
  }
}
