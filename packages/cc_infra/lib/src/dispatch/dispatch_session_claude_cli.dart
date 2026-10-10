part of 'dispatch_session.dart';

/// One stream-json user message, as `claude -p --input-format stream-json`
/// reads it from stdin.
String _claudeUserLine(String text) =>
    '${jsonEncode({
      'type': 'user',
      'message': {'role': 'user', 'content': text},
    })}\n';

String? _claudePermissionMode(Mode mode) {
  switch (mode) {
    case Mode.plan:
    case Mode.review:
    case Mode.orchestrate:
      return 'plan';
    case Mode.chat:
      return null;
  }
}

extension _ClaudeCliMethods on DispatchSession {
  /// Runs Claude Code directly via `claude -p --output-format stream-json`,
  /// spawned inside the OS sandbox exactly like a structured-CLI adapter
  /// (Pi). Stdout NDJSON is parsed by [ClaudeStreamJsonParser] into
  /// [AgentProcessEvent]s. Stdin is a stream-json lane: the prompt first,
  /// then queued steering as it arrives, closed at the turn's `result`.
  /// `claude -p` draws from the same Claude Code subscription quota as
  /// interactive mode.
  Future<void> _runClaudeCli({
    required ScopedCredentials scoped,
    required String sandboxSessionId,
    required String wsId,
  }) async {
    for (final note in scoped.notes) {
      addEvent(DebugEvent(content: '[claude] $note'));
    }

    final claudePath = await resolveBinary('claude');
    if (claudePath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[claude] "claude" not found on PATH. Install Claude Code: '
              'https://docs.anthropic.com/en/docs/claude-code',
        ),
      );
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    final spent = claudeAccountsSpent;
    if (spent != null) {
      // Refuse before spawning. Claude would reach the same conclusion and
      // charge a turn for it; the useful part is the time, not the failure.
      //
      // Reaching here means the credential gate is off, was declined, or ran
      // out of patience — the gate itself runs one layer up, in
      // `AgentDispatchService`, where the account plan can still be re-resolved
      // before the sandbox profile is built from it. This is the terminal
      // report, and it shares its sentence with what the gate showed.
      addEvent(ErrorEvent(content: claudeRefusalDetail(spent)));
      unawaited(_closeRunLog(exitCode: 126));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

    if (!_claudeAccountHasCredential()) {
      // Fail here rather than let the CLI do it. Spawned logged-out, `claude
      // -p` prints `Not logged in · Please run /login` on stdout and exits 0 —
      // so the turn "succeeds", the sentence lands in the transcript looking
      // like something the agent said, and the operator is told to run a slash
      // command in a CLI they never opened. Naming the account and where to
      // sign it in is the whole difference.
      final detail =
          '[claude] this Claude Code account is signed out '
          '($claudeConfigDir). Sign in from Settings → Adapters → '
          'Claude Code, or run `claude auth login` with '
          'CLAUDE_CONFIG_DIR set to that directory, or give it a long-lived '
          'token from `claude setup-token`.';
      // Signed-out is the one Claude verdict this session can gate itself: the
      // account is already resolved, so its directory is in the sandbox's
      // writable set and a `claude auth login` into that SAME directory lands
      // somewhere the run can already read. Nothing has to be re-resolved, so
      // nothing about the profile can be stale. The spent case above is the
      // opposite — no account was resolved at all — which is why it is gated
      // one layer up instead.
      if (!await _gateOnClaudeSignIn(detail: detail)) {
        addEvent(ErrorEvent(content: detail));
        unawaited(_closeRunLog(exitCode: 126));
        addEvent(DoneEvent());
        _completeRun();
        return;
      }
    }

    // Point `claude` at the Control Center MCP server explicitly. The derived
    // client config (`<cwd>/.mcp.json`, written per-session from the live
    // `mcp_config.json` posture) is the ONE config `--strict-mcp-config` loads,
    // so the agent reliably gets the `mcp__*` tool surface (incl.
    // `submit_output`, which writes a pipeline run's structured output so the
    // step resume listener can harvest it). Null resolver → no `--mcp-config`.
    var mcpConfigPath = await _resolveMcpConfigPath();
    // `--strict-mcp-config` makes `claude` treat a missing/unreadable config
    // file as FATAL: it exits 1 before emitting any stream event ("nothing
    // visible, then exited with code 1"). If the resolver handed back a path
    // that isn't actually on disk, drop the MCP flags and run without the CC
    // tool surface (degraded, like Pi) rather than killing the whole turn.
    if (mcpConfigPath != null && !File(mcpConfigPath).existsSync()) {
      addEvent(
        DebugEvent(
          content:
              '[claude] MCP config not found at $mcpConfigPath — running '
              'without the control-center tools.',
        ),
      );
      mcpConfigPath = null;
    }
    final claudeFlags = ClaudeCliBackend.buildClaudeArgs(
      modelId: modelId,
      permissionMode: _claudePermissionMode(mode),
      mcpConfigPath: mcpConfigPath,
      // The action policy's hook on Claude's own `Bash` tool. It still runs
      // under `--dangerously-skip-permissions` (a PreToolUse deny wins in
      // every permission mode), which is what lets "ask first" reach a
      // runner whose own prompt gate is off.
      settingsJson: _gatewayLease?.claudeHookSettings(),
    );

    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: SandboxSpec(
        sessionId: sandboxSessionId,
        workspaceId: wsId,
        agentId: agentId,
        bindMounts: _bindMounts(),
        guestWorkdir: agentDirHostPath,
        networkEnabled: _networkEnabled,
        mode: mode,
        protectedPaths: await _protectedPaths(),
        runnerStateDirs: _runnerStateDirs,
        execGrantRoots: await _resolveExecGrantRoots(wsId),
        loopbackPorts: _gatewayLoopbackPorts,
      ),
      emit: addEvent,
    );

    if (handle.state == SandboxState.error) {
      // Destroy before throwing: the handle is already registered in the
      // adapter's map, and the throw skips the cooldown scheduling that would
      // otherwise clean it up — so an error-state handle (plus its broadcast
      // controller) was retained until a same-session re-dispatch.
      try {
        await deps.sandbox.destroy(handle);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: destroy after launch '
          'failure also failed: $e',
        );
      }
      throw StateError('sandbox launch failed: ${handle.error}');
    }

    _activeHandle = handle;
    eventsSub = deps.sandbox.events(handle).listen(_forwardSandboxEvent);

    final argv = <String>[claudePath, ...claudeFlags, ...adapterArgsOverride];

    // Preflight the claude invocation (NOT the prompt — it's free-form text
    // that could contain shell operators). The agent's own Bash commands are
    // checked by Claude's own permission layer.
    if (!await _preflightCommand(argv)) {
      return;
    }

    final mergedEnv = _mergedEnv(
      scopedEnv: scoped.environment,
      backendEnv: const {},
    );

    // One attempt per attached account, best first. A `claude -p` process owns
    // its own credential, so there is no swapping it mid-stream the way the
    // harness does — a plan that runs out can only be answered by running the
    // turn again on the next account. That is what lets a `/goal` carry on
    // across a usage limit instead of stopping at one.
    final attempts = claudeAccounts.isEmpty
        ? <({String accountId, String configDir})>[
            (accountId: '', configDir: claudeConfigDir ?? ''),
          ]
        : claudeAccounts;

    var exitCode = 0;
    // Whether the attempt that ended the loop already explained itself, so the
    // trailing exit-code line does not repeat it. See [_sawProcessStderr].
    var explained = false;
    // How many times a dead sign-in has already parked this run. Bounded so a
    // credential that 401s again after a login cannot relaunch forever.
    var reauthParks = 0;
    _claudeSubagents = _openClaudeSubagents();
    _claudeSteered.clear();
    _steering.onEnqueued = _scheduleClaudeSteeringPump;
    var steeringAnnounced = false;
    var i = 0;
    while (i < attempts.length) {
      final attempt = attempts[i];
      ClaudeTerminalError? terminal;
      var producedOutput = false;
      // Claude Code's own auto-compactions in this attempt.
      var compactions = 0;

      _claudeToolNames.clear();
      _claudeParser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onText: (delta) {
            producedOutput = true;
            addEvent(TextEvent(content: delta));
          },
          onThinking: (delta) => addEvent(ThinkingEvent(content: delta)),
          onToolCall: (tu) {
            producedOutput = true;
            _claudeToolNames[tu.id] = tu.name;
            _claudeSubagents?.noteSpawnCall(tu);
            addEvent(
              ToolCallEvent(
                toolName: tu.name,
                toolCallId: tu.id,
                inputs: tu.input as Map<String, dynamic>?,
              ),
            );
          },
          onToolResult: (tr) {
            addEvent(
              ToolResultEvent(
                toolCallId: tr.id,
                outputs: tr.outputs,
                toolName: _claudeToolNames.remove(tr.id),
                isError: tr.isError,
              ),
            );
            final subagents = _claudeSubagents;
            if (subagents != null) {
              unawaited(subagents.complete(tr));
            }
          },
          // A subagent's own work becomes its child run's transcript, not
          // rows in this turn.
          onSubagent: (event) {
            producedOutput = true;
            _claudeSubagents?.onEvent(event);
          },
          // `claude` prices itself, so this path does NOT go through
          // [HarnessCostCalculator]: the CLI already knows which model served
          // (including the auxiliary calls it makes on its own) and reports the
          // total, where a models.dev lookup would have to guess. Deliberately
          // Occupancy, not spend: the size of the newest main-thread call,
          // measured against the agent's configured window, else the one the
          // `--model` id runs with. A setting the model cannot honour is
          // shown as set — the run, not the meter, is where it fails.
          onCallUsage: (u) => addEvent(
            ContextWindowEvent(
              contextTokens: u.contextTokens,
              windowTokens:
                  contextWindowTokens ??
                  AcpModelsService.claudeCodeContextWindow(modelId),
              compactions: compactions,
            ),
          ),
          onCompactBoundary: (preTokens) {
            compactions++;
            addEvent(
              DebugEvent(
                content:
                    '[claude] auto-compacted its context'
                    '${preTokens == null ? '' : ' from $preTokens tokens'}',
              ),
            );
          },
          // NOT gated on `producedOutput` — usage is accounting, not output, and
          // an attempt that spent tokens and then failed over to the next
          // account must still be counted. The accumulator downstream sums
          // per-attempt events, which is what makes that add up.
          onUsage: (u) => addEvent(
            UsageEvent(
              usage: RunUsage(
                inputTokens: u.inputTokens,
                outputTokens: u.outputTokens,
                cachedReadTokens: u.cacheReadTokens,
                cachedWriteTokens: u.cacheWriteTokens,
                estimatedCostCents: u.costCents,
              ),
              durationMs: u.durationMs,
            ),
          ),
          // Held, not emitted: a capacity failure we are about to retry is not
          // something to show as an error, and the decision needs the exit code
          // that has not arrived yet.
          onTerminalError: (e) => terminal = e,
          onResult: () => _onClaudeTurnEnded(failed: terminal != null),
        ),
      );

      // Closed by `_closeClaudeStdin`, at the turn's result or after exec.
      // ignore: close_sinks
      final stdin = _openClaudeStdin();
      if (!steeringAnnounced) {
        steeringAnnounced = true;
        onHarnessStarted?.call();
      }
      _pumpClaudeSteering();

      addEvent(DebugEvent(content: '[claude] launching claude -p…'));
      _sawProcessStderr = false;
      try {
        exitCode = await deps.sandbox.exec(
          handle,
          argv,
          env: _envForClaudeAccount(mergedEnv, attempt.configDir),
          onPid: (forkedPid) {
            _onPidAvailable(forkedPid);
            addEvent(
              DebugEvent(content: '[claude] claude running (pid $forkedPid)'),
            );
          },
          stdinStream: stdin.stream,
        );
      } finally {
        _closeClaudeStdin();
      }
      _claudeParser = null;

      final failure = terminal;
      final hasNext = i + 1 < attempts.length;
      // Is this failure about the ACCOUNT rather than the run? Two shapes
      // qualify — a spent plan and a credential that no longer authenticates —
      // and only those retry. Any other terminal error (a bad model id, a
      // rejected MCP config) would fail identically on every account, and a
      // turn that already streamed work would be duplicated by a re-run rather
      // than continued.
      final accountFailure =
          failure != null && (failure.isCapacity || failure.isAuth);
      if (accountFailure && !producedOutput && hasNext) {
        if (attempt.accountId.isNotEmpty) {
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        final next = attempts[i + 1];
        // Same shape as the harness's `[harness] provider fallback X → Y`,
        // deliberately: one vocabulary for "the run moved to another
        // credential", whichever transport moved it.
        addEvent(
          DebugEvent(
            content:
                '[claude] account fallback ${attempt.accountId} → '
                '${next.accountId} '
                '(${failure.isCapacity ? 'out of plan headroom' : 'credential expired'})',
          ),
        );
        i++;
        continue;
      }
      // The last account's sign-in is dead and the turn has said nothing.
      // Park for a human to sign in again and re-run this same prompt, rather
      // than finishing as a blank bubble the operator cannot act on.
      if (failure != null &&
          failure.isAuth &&
          !producedOutput &&
          reauthParks < 2) {
        if (attempt.accountId.isNotEmpty) {
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        final detail = redactSecrets('[claude] ${failure.message}');
        if (await _gateOnExpiredClaudeSignIn(detail: detail)) {
          reauthParks++;
          i = 0;
          explained = false;
          continue;
        }
        addEvent(ErrorEvent(content: detail));
        explained = true;
        break;
      }
      if (failure != null) {
        if (accountFailure && attempt.accountId.isNotEmpty) {
          // Last account, or the turn had already produced work: record the
          // failure anyway so the NEXT dispatch starts somewhere usable.
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        addEvent(
          ErrorEvent(content: redactSecrets('[claude] ${failure.message}')),
        );
        explained = true;
      }
      break;
    }

    // What is still queued now converts to a follow-up message at run end.
    _steering.onEnqueued = null;
    await _closeClaudeSubagents();
    unawaited(_closeRunLog(exitCode: exitCode));

    if (exitCode == 127) {
      addEvent(
        ErrorEvent(
          content:
              '[claude] "claude" not found on PATH. Install Claude Code: '
              'https://docs.anthropic.com/en/docs/claude-code',
        ),
      );
    } else if (exitCode != 0) {
      final content = '[claude] claude exited with code $exitCode';
      addEvent(
        explained || _sawProcessStderr
            ? DebugEvent(content: content)
            : ErrorEvent(content: content),
      );
    } else {
      addEvent(DebugEvent(content: '[claude] claude exited cleanly (code 0)'));
    }
    addEvent(DoneEvent());
    _completeRun();
  }

  /// Opens the stdin lane for one `claude -p` attempt: the prompt as the first
  /// stream-json user message, then everything this run already steered (a
  /// failover attempt replays the turn as the operator last shaped it).
  StreamController<String> _openClaudeStdin() {
    final stdin = StreamController<String>()..add(_claudeUserLine(prompt));
    for (final text in _claudeSteered) {
      stdin.add(_claudeUserLine(text));
    }
    _claudeStdin = stdin;
    return stdin;
  }

  /// Closes the open stdin lane, which lets `claude` exit once it has answered
  /// what it was already sent. Steering from here on stays queued.
  void _closeClaudeStdin() {
    final stdin = _claudeStdin;
    _claudeStdin = null;
    if (stdin != null) {
      unawaited(stdin.close());
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
    if (stdin == null) {
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

  /// The turn's `result`. Anything still queued — follow-ups included — starts
  /// the next turn on this same process, context intact. Otherwise stdin
  /// closes and the process exits; a failed turn always closes, since the
  /// failover and sign-in handling need the exit.
  void _onClaudeTurnEnded({required bool failed}) {
    final stdin = _claudeStdin;
    if (stdin == null) {
      return;
    }
    if (!failed) {
      final pending = [
        ..._steering.drainSteering(),
        ..._steering.drainAside(),
        ..._steering.drainFollowUp(),
      ];
      if (pending.isNotEmpty) {
        _writeClaudeSteering(stdin, pending);
        return;
      }
    }
    _closeClaudeStdin();
  }

  /// Child-run recording for the subagents this run spawns. Null when the run
  /// has no run log or workspace to hang them from.
  ClaudeSubagentRuns? _openClaudeSubagents() {
    final parentRunId = runLogId;
    final ws = workspaceId;
    if (parentRunId == null ||
        parentRunId.isEmpty ||
        ws == null ||
        ws.isEmpty) {
      return null;
    }
    return ClaudeSubagentRuns(
      parentRunId: parentRunId,
      workspaceId: ws,
      agentId: agentId ?? 'subagent',
      spaceId: spaceId,
      conversationId: conversationId,
      modelId: modelId,
      repo: deps.runLogRepo,
      recorder: deps.runTranscriptRecorder,
    );
  }

  Future<void> _reportClaudeAccountFailure(
    String accountId,
    ClaudeTerminalError failure,
  ) async {
    if (failure.isCapacity) {
      await onClaudeAccountExhausted?.call(
        accountId: accountId,
        resetsAt: failure.resetsAt,
      );
      return;
    }
    await onClaudeAccountAuthFailed?.call(
      accountId: accountId,
      reason: redactSecrets(failure.message),
    );
  }
}

/// Which Claude Code account a run signs in as, and parking the run on the
/// credential gate until that account has a usable sign-in.
extension _ClaudeAccountCredentials on DispatchSession {
  /// Parks this run until this account's directory holds a credential again,
  /// and reports whether it does.
  ///
  /// False when no gate is wired, when the operator cancels, or when the wait
  /// times out — every one of which falls through to the failure the run had
  /// before the gate existed.
  Future<bool> _gateOnClaudeSignIn({required String detail}) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return false;
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] waiting for a sign-in on $claudeConfigDir — '
            'the run continues as soon as one lands.',
      ),
    );
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.signedOut,
        detail: detail,
        runLogId: runLogId,
        accountIds: [for (final a in claudeAccounts) a.accountId],
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // The credential lands as a FILE in the account directory — written
      // directly by the CLI off macOS or by an in-sandbox refresh, and mirrored
      // there from the Keychain otherwise. The mirror has to be re-run for the
      // Keychain case; without it the probe would watch a file that a
      // successful `claude auth login` never touches.
      recheck: () async {
        final sync = deps.syncClaudeCredential;
        final accountId = claudeAccounts.firstOrNull?.accountId;
        if (sync != null && accountId != null) {
          await sync(accountId);
        }
        return _claudeAccountHasCredential();
      },
    );
    return outcome == RunCredentialOutcome.resolved;
  }

  /// Parks this run until a Claude Code account that just 401'd has a newer
  /// credential, and reports whether one landed.
  ///
  /// Distinct from [_gateOnClaudeSignIn]: that one fires before spawn, when
  /// the directory is empty. This one fires after `claude -p` has already
  /// proved the credential on disk no longer authenticates — an access token
  /// the CLI could not renew, which still looks signed-in to the pre-spawn
  /// probe. The same prompt is re-run when a human signs in; cancelling or
  /// timing out falls through to the error the turn already has.
  ///
  /// False when no gate is wired, when the operator cancels, when the wait
  /// times out, or when the gate says "resolved" without the credential file
  /// actually changing — that last one is what stops a poll from relaunching
  /// `claude` against the same dead token.
  Future<bool> _gateOnExpiredClaudeSignIn({required String detail}) async {
    final gate = deps.credentialGate;
    if (gate == null) {
      return false;
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] waiting for a fresh sign-in — '
            'the same prompt continues as soon as one lands.',
      ),
    );
    final before = _claudeCredentialBlobs();
    final outcome = await gate.awaitCredentials(
      RunCredentialBlockRequest(
        lane: RunCredentialLane.claudeCode,
        reason: RunCredentialReason.credentialExpired,
        detail: detail,
        runLogId: runLogId,
        accountIds: [
          for (final a in claudeAccounts)
            if (a.accountId.isNotEmpty) a.accountId,
        ],
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        agentName: agentName,
      ),
      // Re-mirror first. On macOS the login lands in the Keychain and the
      // file the sandbox can read is only a copy; without the sync the probe
      // watches a file `claude auth login` never touches.
      recheck: () => _claudeCredentialsRenewed(before),
    );
    if (outcome != RunCredentialOutcome.resolved) {
      return false;
    }
    return _claudeCredentialsRenewed(before);
  }

  /// `.credentials.json` contents for every account dir this run can see.
  ///
  /// A missing file is stored as null so a login that creates one counts as
  /// a change, and a sign-out that deletes one does not have to.
  Map<String, String?> _claudeCredentialBlobs() {
    final dirs = <String>{
      if (claudeConfigDir != null && claudeConfigDir!.isNotEmpty)
        claudeConfigDir!,
      for (final a in claudeAccounts)
        if (a.configDir.isNotEmpty) a.configDir,
    };
    return {for (final dir in dirs) dir: _readClaudeCredential(dir)};
  }

  /// Whether any account dir now holds a different credential than [before].
  ///
  /// Content, not mtime: a failed refresh and the Keychain mirror can both
  /// rewrite the file without a human signing in, and a 1-second filesystem
  /// timestamp cannot tell that apart from a real login. A new sign-in
  /// replaces the blob.
  Future<bool> _claudeCredentialsRenewed(Map<String, String?> before) async {
    final sync = deps.syncClaudeCredential;
    if (sync != null) {
      for (final account in claudeAccounts) {
        if (account.accountId.isEmpty) {
          continue;
        }
        await sync(account.accountId);
      }
    }
    for (final entry in _claudeCredentialBlobs().entries) {
      final current = entry.value;
      if (current != null &&
          current.isNotEmpty &&
          current != before[entry.key]) {
        return true;
      }
    }
    return false;
  }

  String? _readClaudeCredential(String dir) {
    try {
      final file = File('$dir/.credentials.json');
      if (!file.existsSync()) {
        return null;
      }
      return file.readAsStringSync();
    } on Object {
      return null;
    }
  }

  /// Whether the Claude Code account this run will use has something to
  /// authenticate with.
  ///
  /// Only answerable when Control Center owns the config dir; with none set the
  /// CLI resolves its own credential (a keychain item, `~/.claude`) and this
  /// returns true rather than guessing. A token in the environment counts:
  /// `CLAUDE_CODE_OAUTH_TOKEN` and `ANTHROPIC_API_KEY` both authenticate the
  /// CLI without any file in the config dir, so treating an empty dir as
  /// signed-out would refuse a run that would have worked.
  bool _claudeAccountHasCredential() {
    final dir = claudeConfigDir;
    if (dir == null || dir.isEmpty) {
      return true;
    }
    for (final key in const ['CLAUDE_CODE_OAUTH_TOKEN', 'ANTHROPIC_API_KEY']) {
      final fromCaller = callerEnv[key] ?? adapterEnvOverride[key];
      if (fromCaller != null && fromCaller.isNotEmpty) {
        return true;
      }
      final fromHost = Platform.environment[key];
      if (fromHost != null && fromHost.isNotEmpty) {
        return true;
      }
    }
    return File('$dir/.credentials.json').existsSync() ||
        readClaudeLongLivedToken(dir) != null;
  }

  /// [base] re-pointed at ONE account of a multi-account run.
  ///
  /// The token has to move with the config dir. [_mergedEnv] exported the
  /// FIRST account's token, and a failover attempt on an account without one
  /// would otherwise sign in as the account it is failing over from — exactly
  /// the plan that just ran out.
  Map<String, String> _envForClaudeAccount(
    Map<String, String> base,
    String configDir,
  ) {
    if (configDir.isEmpty) {
      return base;
    }
    final env = {...base, 'CLAUDE_CONFIG_DIR': configDir};
    final token = readClaudeLongLivedToken(configDir);
    final first = claudeConfigDir;
    final inherited = first == null || first.isEmpty
        ? null
        : readClaudeLongLivedToken(first);
    if (token != null) {
      env[claudeLongLivedTokenEnvKey] = token;
    } else if (inherited != null &&
        env[claudeLongLivedTokenEnvKey] == inherited) {
      env.remove(claudeLongLivedTokenEnvKey);
    }
    return env;
  }
}
