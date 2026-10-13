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
    // The action policy's hook on Claude's own `Bash` tool. It still runs
    // under `--dangerously-skip-permissions` (a PreToolUse deny wins in every
    // permission mode), which is what lets "ask first" reach a runner whose
    // own prompt gate is off.
    final hookSettings = AgentRunLease.claudeHookSettings(_gatewayLease);
    final permissionMode = _claudePermissionMode(mode);
    _claudeMcpExpected = mcpConfigPath != null;

    // Capability-resolve FIRST: one effective-resume decision then governs the
    // argv, the stdin prompt, the diagnostics and the accounting baseline. An
    // older `claude` without `--resume` (or without `--effort`) must never be
    // handed a flag it will reject — and must never be sent a delta prompt with
    // no session to attach it to.
    final capabilities = await ClaudeCliBackend.detectCapabilities(claudePath);
    _claudeCapabilities = capabilities;
    if (capabilities.version == null) {
      // Actionable, not cosmetic: without a version the adapter refuses to
      // treat the persisted baseline as restorable, so a resumed turn reports
      // its own spend instead of a delta against totals this build may not
      // restore (which would silently swallow spend).
      addEvent(
        DebugEvent(
          content:
              '[claude] could not read the claude version (`--version` probe '
              'failed or produced nothing) — session cost totals are NOT '
              'assumed to be restored on resume.',
        ),
      );
    }

    // Everything a resumed session would silently inherit from the OLD
    // process — model, effort, permission surface, the Control Center mode, the
    // standing brief it was given, the MCP config, the appended system prompt.
    // Fingerprinted into the scope key, so a change FORKS to a fresh native
    // session (with the full prompt) rather than resuming under a policy that
    // no longer applies: the model would otherwise keep the previous mode's
    // deliverable contract and never see the new standing instructions.
    final policy = _claudePolicyFingerprint(
      permissionMode: permissionMode,
      mcpConfigPath: mcpConfigPath,
      settingsJson: hookSettings,
    );
    if (claudeResumeReset) {
      await _clearClaudeRecord(policy);
    }
    final resumeRecord = await _loadClaudeRecord(policy);
    final parts = promptParts;
    // A stored session is reachable only when the CLI can be asked for it, the
    // preparation produced a delta, and the record carries a conversation
    // cursor a delta can be built from. An EMPTY cursor means the previous run
    // never established continuity (it did not exit cleanly), so this dispatch
    // starts FRESH with the full prompt rather than fabricating a safe-looking
    // delta that would drop whatever the session never saw.
    final resumeCandidate =
        resumeRecord != null &&
            parts != null &&
            capabilities.supportsResume &&
            resumeRecord.conversationRevision.isNotEmpty
        ? resumeRecord
        : null;
    final delta = resumeCandidate != null && parts != null
        ? parts.deltaPromptFor(_deliveredContextOf(resumeCandidate))
        : null;
    // An untracked context forces a fresh session even when a record exists.
    final activeResumeRecord = delta != null ? resumeCandidate : null;
    if (parts != null && resumeRecord != null && !capabilities.supportsResume) {
      addEvent(
        DebugEvent(
          content:
              '[claude] this claude build does not support --resume; sending '
              'the full prompt instead of continuing the stored session.',
        ),
      );
    }
    _claudeResumeRecord = activeResumeRecord;
    _claudeResumeId = activeResumeRecord?.sessionId;
    _claudeDeltaPrompt = delta;
    // The ledger continues from the resumed session's persisted baseline ONLY
    // when the CLI will actually restore those totals: Claude makes them
    // durable on a normal exit alone, and versions before 2.1.277 never restore
    // them. Otherwise the figures a resumed call reports are its own, and
    // deltaing them against an old baseline would swallow the difference.
    _claudeLedger = ClaudeAccountingLedger(
      baseline:
          activeResumeRecord != null && activeResumeRecord.cliRestoresTotals
          ? ClaudeAccountingBaseline(
              cumulativeCostUsd: activeResumeRecord.cumulativeCostUsd,
              modelUsage: activeResumeRecord.modelUsage,
              mainUsageSinceModels: activeResumeRecord.mainUsageSinceModels,
              turns: activeResumeRecord.turns,
              restoredByCli: true,
            )
          : null,
    );
    // This dispatch's own attribution, independent of the native session's
    // cumulative counters so a reset or an account switch cannot erase earlier
    // attempts from the run's reported spend.
    _claudeDispatchTotals = ClaudeDispatchTotals();
    _claudeInit = null;
    _claudeNativeSessionId = _claudeResumeId;
    if (activeResumeRecord != null && parts != null) {
      addEvent(
        DebugEvent(
          content:
              '[claude] resuming native session ${activeResumeRecord.sessionId} for this '
              'conversation — sending only the new turn'
              '${parts.hasUndeliveredContext(_deliveredContextOf(activeResumeRecord)) ? ' plus the context that changed while parked' : ''}.',
        ),
      );
    }

    final claudeFlags = ClaudeCliBackend.buildClaudeArgs(
      modelId: modelId,
      permissionMode: permissionMode,
      mcpConfigPath: mcpConfigPath,
      settingsJson: hookSettings,
      effortLevel: effortLevel,
      capabilities: capabilities,
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

    // Preflight the claude invocation (NOT the prompt — it's free-form text
    // that could contain shell operators). The agent's own Bash commands are
    // checked by Claude's own permission layer. `--resume` only adds a session
    // id, so the base flag set is what the policy is asked about.
    final baseArgv = <String>[
      claudePath,
      ...claudeFlags,
      ...adapterArgsOverride,
    ];
    if (!await _preflightCommand(baseArgv)) {
      return;
    }

    // Opt-in MCP discovery-cache policy. Only trusted when a record for this
    // exact scope + policy already exists — i.e. this tool surface has run
    // here before — so a changed MCP config or permission posture never
    // reuses a cached tool list that no longer describes it.
    final discoveryEnv = deps.claudeMcpDiscoveryCache.envFor(
      trustCache: resumeRecord != null,
    );

    final mergedEnv = _mergedEnv(
      scopedEnv: scoped.environment,
      backendEnv: discoveryEnv,
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
    // A zero exit alone is not a completed turn: Claude can exit before
    // sending a result, in which case the prompt has no proven delivery.
    var completedTurn = false;
    var i = 0;
    while (i < attempts.length && !_cancelSource.isCancelled) {
      final attempt = attempts[i];
      ClaudeTerminalError? terminal;
      completedTurn = false;
      var producedOutput = false;
      // Claude Code's own auto-compactions in this attempt.
      var compactions = 0;

      _claudeToolNames.clear();
      _claudeParser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onText: (delta) {
            producedOutput = true;
            _noteClaudeModelDelta(useful: true);
            addEvent(TextEvent(content: delta));
          },
          onThinking: (delta) {
            _noteClaudeModelDelta();
            addEvent(ThinkingEvent(content: delta));
          },
          onToolCall: (tu) {
            producedOutput = true;
            // A tool call IS the useful work for a tool-first run (the stage's
            // own definition), so it closes `firstUsefulText` too.
            _noteClaudeModelDelta(useful: true);
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
                images: tr.images,
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
          // Startup metadata: the serving model, the live tool surface, MCP
          // status/errors and protocol capabilities — and the native session
          // id a later turn resumes.
          onInit: _onClaudeInit,
          onConversationReset: _onClaudeConversationReset,
          onApiRetry: (retry) => addEvent(
            DebugEvent(
              content:
                  '[claude] retrying request'
                  '${retry.errorStatus == null ? '' : ' after HTTP ${retry.errorStatus}'}'
                  ' (attempt ${retry.attempt}'
                  '${retry.maxRetries == null ? '' : '/${retry.maxRetries}'}'
                  '${retry.error == null ? '' : ', ${retry.error}'}'
                  '${retry.retryDelayMs == null ? '' : ', waiting ${retry.retryDelayMs}ms'})',
            ),
          ),
          // NOT gated on `producedOutput` — usage is accounting, not output, and
          // an attempt that spent tokens and then failed over to the next
          // account must still be counted.
          onUsage: _onClaudeResultUsage,
          // Held, not emitted: a capacity failure we are about to retry is not
          // something to show as an error, and the decision needs the exit code
          // that has not arrived yet.
          onTerminalError: (e) => terminal = e,
          onResult: () {
            completedTurn = _onClaudeTurnEnded(failed: terminal != null);
          },
        ),
      );

      // Closed by `_closeClaudeStdin`, at the turn's result or after exec.
      // ignore: close_sinks
      final stdin = _openClaudeStdin(
        // Resuming sends the DELTA (new per-turn context, the message, and the
        // conversation window again if it changed while parked); a fresh
        // attempt — first attempt with no stored session, or a failover after
        // one failed — sends the full prompt. A delta without `--resume` would
        // silently drop the standing brief and the conversation, so the two
        // always move together.
        i == 0 && _claudeResumeId != null
            ? _claudeDeltaPrompt ?? prompt
            : prompt,
      );
      if (!steeringAnnounced) {
        steeringAnnounced = true;
        onHarnessStarted?.call();
      }
      _pumpClaudeSteering();

      addEvent(DebugEvent(content: '[claude] launching claude -p…'));
      _sawProcessStderr = false;
      _claudeSawFirstStdout = false;
      _claudeSawFirstModelDelta = false;
      _claudeSawFirstUseful = false;
      _claudeAttemptStartedAt = DateTime.now();
      // `--resume` belongs to ONE account's config directory. A failover
      // attempt runs on a different account with a different store of
      // sessions, so it starts fresh rather than pointing at a session that
      // does not exist there.
      final attemptArgv = <String>[
        claudePath,
        ...(i == 0 && _claudeResumeId != null
            ? ClaudeCliBackend.buildClaudeArgs(
                modelId: modelId,
                permissionMode: permissionMode,
                mcpConfigPath: mcpConfigPath,
                settingsJson: hookSettings,
                effortLevel: effortLevel,
                resumeSessionId: _claudeResumeId,
                capabilities: capabilities,
              )
            : claudeFlags),
        ...adapterArgsOverride,
      ];
      try {
        exitCode = await deps.sandbox.exec(
          handle,
          attemptArgv,
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
      if (_cancelSource.isCancelled) {
        break;
      }

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
        // The next attempt runs on a DIFFERENT account: a different config
        // directory with its own store of sessions and its own running totals.
        // Nothing carries over — no resume (the id belongs to the failed
        // account) and no cost baseline (deltas against the previous account's
        // totals would be meaningless). Whatever the failed attempt already
        // reported stays on the run as its own additive events.
        //
        // The scope record is NOT written while we are on another account:
        // its key names the FIRST account's directory, so persisting this
        // session there would make a later run resume an id that directory
        // does not hold. The record keeps the last state that account actually
        // produced.
        _claudeResumeId = null;
        _claudeNativeSessionId = null;
        _claudePersistDisabled = true;
        _claudeLedger = ClaudeAccountingLedger();
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
          // Attempt 0 is the scope's own account again, so the resume id and
          // the accounting baseline must be restored TOGETHER from the record
          // this scope loaded — a failover in between left both describing the
          // other account, and deltaing this account's figures against them (or
          // persisting them under this scope) would corrupt the lineage.
          final record = _claudeResumeRecord;
          final parts0 = promptParts;
          final restoredDelta =
              record != null &&
                  parts0 != null &&
                  capabilities.supportsResume &&
                  record.conversationRevision.isNotEmpty
              ? parts0.deltaPromptFor(_deliveredContextOf(record))
              : null;
          // An untracked window cannot be sent as a delta on this retry either.
          final restoredRecord = restoredDelta != null ? record : null;
          _claudeResumeId = restoredRecord?.sessionId;
          _claudeDeltaPrompt = restoredDelta;
          _claudeNativeSessionId = _claudeResumeId;
          _claudeLedger = ClaudeAccountingLedger(
            baseline: restoredRecord != null && restoredRecord.cliRestoresTotals
                ? ClaudeAccountingBaseline(
                    cumulativeCostUsd: restoredRecord.cumulativeCostUsd,
                    modelUsage: restoredRecord.modelUsage,
                    mainUsageSinceModels: restoredRecord.mainUsageSinceModels,
                    turns: restoredRecord.turns,
                    restoredByCli: true,
                  )
                : null,
          );
          _claudePersistDisabled = false;
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
    // `terminate()` owns the stop notice, run log and terminal event. In
    // particular, its SIGTERM is not a Claude failure or an account retry.
    if (_cancelSource.isCancelled) {
      return;
    }
    // Land the final accounting baseline + native session id, so the next
    // ordinary follow-up turn resumes this session instead of rebuilding it.
    // Cancellation keeps the last result's baseline so the session can resume.
    await _persistClaudeRecord(normalExit: exitCode == 0 && completedTurn);
    await _closeClaudeSubagents();
    if (_cancelSource.isCancelled) {
      return;
    }
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

  /// Opens the stdin lane for one `claude -p` attempt: [firstMessage] as the
  /// first stream-json user message, then everything this run already steered
  /// (a failover attempt replays the turn as the operator last shaped it).
  ///
  /// [firstMessage] is the DELTA prompt when this attempt resumes a native
  /// session and the FULL prompt otherwise — never the delta without
  /// `--resume`, which would drop the standing brief and the conversation.
  StreamController<String> _openClaudeStdin(String firstMessage) {
    final stdin = StreamController<String>()
      ..add(_claudeUserLine(firstMessage));
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
  /// failover and sign-in handling need the exit. Returns true only when this
  /// was the successful FINAL turn, so an interrupted queued turn cannot
  /// advance the persisted delivery cursor.
  bool _onClaudeTurnEnded({required bool failed}) {
    final stdin = _claudeStdin;
    if (stdin == null) {
      return false;
    }
    if (!failed) {
      final pending = [
        ..._steering.drainSteering(),
        ..._steering.drainAside(),
        ..._steering.drainFollowUp(),
      ];
      if (pending.isNotEmpty) {
        _writeClaudeSteering(stdin, pending);
        return false;
      }
    }
    _closeClaudeStdin();
    return !failed;
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
      workingDirectory: agentDirHostPath,
      blobStore: deps.blobStore,
      mediaRenderer: deps.mediaRenderer,
    );
  }

  /// The launch-policy fingerprint: everything a resumed session would
  /// silently inherit from the process that created it.
  ///
  /// It is part of the scope key, so a change to any of these FORKS (starts a
  /// fresh native session) instead of resuming under a policy that no longer
  /// applies. The MCP config is hashed by CONTENT, not path: the derived
  /// `<cwd>/.mcp.json` path is per-session, and a path-keyed fingerprint would
  /// make every run look like a different policy.
  String _claudePolicyFingerprint({
    required String? permissionMode,
    required String? mcpConfigPath,
    required String? settingsJson,
  }) {
    var mcp = '';
    if (mcpConfigPath != null && mcpConfigPath.isNotEmpty) {
      try {
        mcp = File(mcpConfigPath).readAsStringSync();
      } on Object {
        mcp = mcpConfigPath;
      }
    }
    final hasControlCenterMcp =
        mcpConfigPath != null && mcpConfigPath.isNotEmpty;
    final canonical = [
      'model=${modelId ?? ''}',
      'effort=${effortLevel ?? ''}',
      'permission=${permissionMode ?? ''}',
      // The Control Center mode itself, not only the permission mode it maps
      // to: plan, review and orchestrate all collapse to Claude's `plan`, so
      // switching between them would otherwise keep the same scope while the
      // standing brief's deliverable contract changed under the model.
      'mode=${mode.name}',
      // The standing brief the session was given. A resumed session keeps the
      // old one, so any change here forks rather than continuing under
      // instructions the model no longer holds.
      'standing=${promptParts?.standingRevision ?? ''}',
      // Native sessions retain both the original environment and its credit
      // instructions. A preference/profile change must start a fresh session.
      'git=${jsonEncode(_gitIdentityEnv)}',
      'mcp=${sha256.convert(utf8.encode(mcp))}',
      'settings=${sha256.convert(utf8.encode(settingsJson ?? ''))}',
      'append=${ClaudeCliBackend.appendedSystemPrompt(hasControlCenterMcp: hasControlCenterMcp)}',
      if (hasControlCenterMcp)
        'disallowed=${ClaudeCliBackend.nativeChecklistTools}',
    ].join('\u0000');
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  /// The scope this run's native session belongs to, or null when the run has
  /// no workspace to scope it by (nothing can be persisted then).
  ClaudeNativeSessionScope? _claudeScope(String policyFingerprint) {
    final ws = workspaceId;
    if (ws == null || ws.isEmpty) {
      return null;
    }
    final dir = claudeConfigDir;
    return ClaudeNativeSessionScope(
      workspaceId: ws,
      conversationId: conversationId ?? '',
      agentId: agentId ?? '',
      // The FIRST account's config dir: it is the one the first attempt signs
      // in as, and the one whose directory holds the session transcript.
      accountId: dir ?? (claudeAccounts.firstOrNull?.configDir ?? ''),
      workdir: agentDirHostPath,
      policyFingerprint: policyFingerprint,
    );
  }

  /// Loads the persisted native session for this run's scope + [policy], or
  /// null when there is none to resume (no store, no workspace, no record, or
  /// a record whose scope no longer matches — the last of which cannot happen,
  /// since the scope IS the key).
  Future<ClaudeNativeSessionRecord?> _loadClaudeRecord(String policy) async {
    final store = deps.claudeSessionStore;
    final scope = _claudeScope(policy);
    if (store == null || scope == null) {
      _claudeScopeKey = scope?.storageKey;
      _claudePolicyKey = policy;
      return null;
    }
    _claudeScopeKey = scope.storageKey;
    _claudePolicyKey = policy;
    try {
      final record = await store.load(
        workspaceId: scope.workspaceId,
        storageKey: scope.storageKey,
      );
      if (record == null || record.sessionId.isEmpty) {
        return null;
      }
      if (record.policyFingerprint != policy) {
        // Belt and braces: the key already includes the policy, so this only
        // fires if a record was hand-edited. Resuming a mismatched policy is
        // exactly what must not happen.
        return null;
      }
      return record;
    } on Object catch (e) {
      CcInfraLog.warning(
        'claude-session: load failed for ${scope.storageKey}: $e',
      );
      return null;
    }
  }

  /// Drops the persisted record for this run's scope (explicit reset/fork).
  /// [policy] must be the run's real policy fingerprint, or the scope key would
  /// name a different record and the clear would silently miss.
  Future<void> _clearClaudeRecord(String policy) async {
    final store = deps.claudeSessionStore;
    final scope = _claudeScope(policy);
    if (store == null || scope == null) {
      return;
    }
    try {
      await store.clear(
        workspaceId: scope.workspaceId,
        storageKey: scope.storageKey,
      );
      addEvent(
        DebugEvent(
          content: '[claude] dropped the stored native session for this scope',
        ),
      );
    } on Object catch (e) {
      CcInfraLog.warning('claude-session: clear failed: $e');
    }
  }

  /// Persists the native session id, the delivered-conversation cursor and the
  /// accounting baseline for this scope.
  ///
  /// [normalExit] is whether the CLI process finished cleanly. Only then does
  /// Claude make the session's cost totals durable (and only on 2.1.277+ do
  /// resumed calls restore them), so only then is the baseline recorded as
  /// restorable — and only then is the conversation cursor advanced. An
  /// interrupted run keeps the previous cursor, so the next resume re-delivers
  /// context rather than assuming the model read it.
  ///
  /// Called on `system/init` (so an interrupted run still leaves a resumable
  /// id), on every result, and at the end of the run. A no-op when there is no
  /// store, no workspace, no native id, or no ledger yet.
  Future<void> _persistClaudeRecord({required bool normalExit}) async {
    // A failover attempt runs on another account whose session ids do not live
    // in this scope's directory; writing there would make a later resume point
    // at a session that directory does not hold.
    if (_claudePersistDisabled) {
      return;
    }
    final store = deps.claudeSessionStore;
    final storeKey = _claudeScopeKey;
    final policy = _claudePolicyKey;
    final sessionId = _claudeNativeSessionId;
    final ws = workspaceId;
    if (store == null ||
        storeKey == null ||
        policy == null ||
        sessionId == null ||
        sessionId.isEmpty ||
        ws == null ||
        ws.isEmpty) {
      return;
    }
    final ledger = _claudeLedger;
    final previous = _claudeResumeRecord;
    final now = DateTime.now().toUtc();
    final baseline = ledger?.baseline;
    final record = ClaudeNativeSessionRecord(
      storageKey: storeKey,
      sessionId: sessionId,
      policyFingerprint: policy,
      createdAt: previous != null && previous.sessionId == sessionId
          ? previous.createdAt
          : now,
      lastUsedAt: now,
      // Empty means "cursor unknown": a later resume must NOT build a delta
      // from it.
      conversationRevision: normalExit
          ? (promptParts?.conversationRevision ?? '')
          : (previous?.conversationRevision ?? ''),
      // Only a clean exit advances the cursor: an interrupted run may never
      // have been read, so the next resume re-delivers what changed. The lists
      // are BOUNDED (most recent window) — a cursor, not a log.
      deliveredConversationKeys: ClaudeNativeSessionRecord.bound(
        normalExit
            ? (promptParts?.deliveredConversationKeysFor() ?? const [])
            : (previous?.deliveredConversationKeys ?? const []),
      ),
      deliveredSectionKeys: ClaudeNativeSessionRecord.bound(
        normalExit
            ? (promptParts?.deliveredSectionKeysFor() ?? const [])
            : (previous?.deliveredSectionKeys ?? const []),
      ),
      // THIS session's own output is proven by the run id that produced it, so
      // a later turn can skip self-authored messages it already holds — and can
      // tell them apart from another session's output for the same agent.
      producedRunIds: ClaudeNativeSessionRecord.bound([
        ...?previous?.producedRunIds,
        if (normalExit && runLogId != null && runLogId!.isNotEmpty) runLogId!,
      ]),
      cliRestoresTotals: normalExit && _claudeCliRestoresTotals,
      turns: baseline?.turns ?? previous?.turns ?? 0,
      cumulativeCostUsd:
          baseline?.cumulativeCostUsd ?? previous?.cumulativeCostUsd ?? 0,
      modelUsage: baseline?.modelUsage ?? previous?.modelUsage ?? const {},
      mainUsageSinceModels:
          baseline?.mainUsageSinceModels ??
          previous?.mainUsageSinceModels ??
          const ClaudeModelUsageSnapshot(),
    );
    try {
      await store.save(workspaceId: ws, record: record);
      _claudeResumeRecord = record;
    } on Object catch (e) {
      CcInfraLog.warning('claude-session: save failed for $storeKey: $e');
    }
  }

  /// What [record] has already been delivered, for a delta decision.
  DeliveredPromptContext _deliveredContextOf(
    ClaudeNativeSessionRecord record,
  ) => DeliveredPromptContext(
    revision: record.conversationRevision,
    conversationKeys: record.deliveredConversationKeys,
    sectionKeys: record.deliveredSectionKeys,
    producedRunIds: record.producedRunIds,
  );

  /// Whether the resolved CLI restores a session's saved cost totals into a
  /// resumed call. Read from the SAME probe that resolved the other
  /// capabilities, so an older build is not credited with durability it does
  /// not have.
  bool get _claudeCliRestoresTotals =>
      _claudeCapabilities?.restoresSessionTotals ?? false;

  /// Startup metadata arrived. Records the native session id, reports what the
  /// CLI actually resolved (model, tool surface, MCP errors, capabilities) and
  /// the startup time — measured separately from model latency, and NEVER
  /// presented as provider TTFB, which the CLI hides.
  void _onClaudeInit(ClaudeInitMetadata init) {
    _claudeInit = init;
    final sessionId = init.sessionId;
    if (sessionId != null) {
      if (_claudeResumeId != null && _claudeResumeId != sessionId) {
        addEvent(
          DebugEvent(
            content:
                '[claude] resumed session ${_claudeResumeId!} continued as '
                '$sessionId',
          ),
        );
      }
      _claudeNativeSessionId = sessionId;
    }

    final started = _claudeAttemptStartedAt;
    final startupMs = started == null
        ? null
        : DateTime.now().difference(started).inMilliseconds;
    if (sessionId != null) {
      // A stable, machine-parseable line: the paired resume-vs-reconstruction
      // experiment reads run → native session id and whether this run resumed
      // from data, not from a narrative.
      addEvent(
        DebugEvent(
          content:
              '[claude] native-session: id=$sessionId '
              'resumed=${_claudeResumeId != null}',
        ),
      );
    }
    final mcp = init.mcpServers.isEmpty
        ? 'none'
        : init.mcpServers.map((s) => '${s.name}=${s.status}').join(', ');
    addEvent(
      DebugEvent(
        content:
            '[claude] session init: model=${init.model ?? modelId ?? 'unknown'}'
            '${init.claudeCodeVersion == null ? '' : ', cli=${init.claudeCodeVersion}'}'
            ', tools=${init.tools.length}'
            ', mcp[$mcp]'
            '${startupMs == null ? '' : ', startup ${startupMs}ms (incl. MCP discovery/connect)'}'
            '${_claudeResumeId == null ? '' : ', resumed=${_claudeResumeId!}'}',
      ),
    );
    if (!init.hasControlCenterTools && init.tools.isNotEmpty) {
      // Losing the `mcp__*` surface is the difference between an agent that can
      // call `complete_ticket` / `submit_output` and one that cannot, so when
      // this run passed an MCP config on purpose it is reported as an ERROR (a
      // turn that also answered still shows it as failure only if it produced
      // no text). Without that expectation it is a diagnostic.
      const content =
          '[claude] no mcp__* tools in this session — the control-center tool '
          'surface did not connect.';
      addEvent(
        _claudeMcpExpected
            ? ErrorEvent(content: content)
            : DebugEvent(content: content),
      );
    }
    for (final error in init.mcpServerErrors) {
      addEvent(
        DebugEvent(
          content:
              '[claude] MCP server "${error.name}" skipped'
              '${error.type == null ? '' : ' (${error.type})'}'
              '${error.message == null ? '' : ': ${error.message}'}',
        ),
      );
    }
    for (final failed in init.failedMcpServers) {
      addEvent(
        DebugEvent(
          content:
              '[claude] MCP server "${failed.name}" is ${failed.status} — its '
              'tools are unavailable this run.',
        ),
      );
    }
    for (final error in init.pluginErrors) {
      addEvent(DebugEvent(content: '[claude] plugin error: $error'));
    }
    if (init.capabilities.isNotEmpty) {
      addEvent(
        DebugEvent(
          content: '[claude] capabilities: ${init.capabilities.join(', ')}',
        ),
      );
    }

    // Persist the id immediately: an interrupted run must still leave the
    // conversation a resumable native session.
    unawaited(_persistClaudeRecord(normalExit: false));
  }

  /// The conversation was cleared: the CLI restarted its cumulative totals, so
  /// the ledger's baseline no longer describes anything. A reset may also mint
  /// a new native session id, which is what later turns resume.
  void _onClaudeConversationReset(String? sessionId) {
    _claudeLedger?.reset();
    if (sessionId != null && sessionId.isNotEmpty) {
      _claudeNativeSessionId = sessionId;
      unawaited(_persistClaudeRecord(normalExit: false));
    }
    addEvent(
      DebugEvent(
        content:
            '[claude] conversation reset — cumulative cost and model usage '
            'restarted.',
      ),
    );
  }

  /// One `result` came back. Folds it into the ledger and emits the two
  /// accounting events that keep the run honest:
  ///
  /// * an ADDITIVE per-turn delta (main-loop tokens + the cost this turn
  ///   added), which is what a live meter sums; and
  /// * an ABSOLUTE whole-run snapshot (`UsageScope.runCumulative`) taken from
  ///   the CLI's own cumulative `total_cost_usd` / `modelUsage`, which REPLACES
  ///   the accumulator's totals rather than adding to them — the fix for the
  ///   double-counting that summing `total_cost_usd` across queued turns (or
  ///   across a resume) produces.
  void _onClaudeResultUsage(ClaudeUsage usage) {
    final ledger = _claudeLedger ??= ClaudeAccountingLedger();
    final turn = ledger.record(usage);
    // Fold this turn's delta into the DISPATCH's own totals: the run-level
    // snapshot is built from these, so an earlier dispatch's spend (restored
    // into the native session's counters) never inflates this run and a reset
    // or account failover never erases what this run already spent.
    _claudeDispatchTotals.add(turn);
    // The CLI's OWN model, from `system/init` — the id it actually serves,
    // which can differ from the requested `--model`.
    final servingModel = _claudeInit?.model ?? modelId;
    final provider = _claudeProvider;
    // Locally priced API usage is an ESTIMATE; only an established subscription
    // lane is `subscription`. An `ANTHROPIC_API_KEY` takes precedence over
    // subscription login in `-p` mode, so metered runs must not be reported as
    // flat-fee usage.
    // Missing amounts stay nullable; unknown provenance uses the domain's
    // conservative estimate basis rather than claiming a reported figure.
    final basis = _claudeDispatchTotals.costUnavailable
        ? CostBasis.estimated
        : _claudeCostBasis();
    // Lineage, so the resume-vs-reconstruction experiment scores from data:
    // which native session produced this usage, and whether it was resumed.
    final nativeSessionId = _claudeNativeSessionId;
    final resumed = _claudeResumeId != null;

    addEvent(
      UsageEvent(
        purpose: domain_purpose.LlmCallPurpose.main,
        provider: provider,
        modelId: servingModel,
        scope: UsageScope.turn,
        nativeSessionId: nativeSessionId,
        resumedNativeSession: resumed,
        usage: RunUsage(
          inputTokens: turn.inputTokens,
          outputTokens: turn.outputTokens,
          cachedReadTokens: turn.cacheReadTokens,
          cachedWriteTokens: turn.cacheWriteTokens,
          // The legacy cents axis carries the DELTA only; the run total rides
          // the cumulative event below as micros, so a host that still sums
          // cents never double counts.
          estimatedCostCents: turn.costDeltaCents,
          costMicros: turn.costDeltaMicros,
          costBasis: basis,
        ),
        durationMs: usage.durationMs,
      ),
    );

    final totals = _claudeDispatchTotals;
    // Every result carries reconciled observed counters: whole-tree model
    // deltas when available, known main-loop usage otherwise. Missing model
    // counters are credited once if a later full snapshot fills the gap.
    if (totals.hasTokenData) {
      addEvent(
        UsageEvent(
          purpose: domain_purpose.LlmCallPurpose.main,
          provider: provider,
          modelId: servingModel,
          scope: UsageScope.runCumulative,
          nativeSessionId: nativeSessionId,
          resumedNativeSession: resumed,
          usage: RunUsage(
            inputTokens: totals.inputTokens,
            outputTokens: totals.outputTokens,
            cachedReadTokens: totals.cacheReadTokens,
            cachedWriteTokens: totals.cacheWriteTokens,
            estimatedCostCents: 0,
            costMicros: totals.costMicros,
            costBasis: basis,
          ),
        ),
      );
    }

    // A `/clear` mints a new session id on the result; keep the record's id
    // current so the next turn resumes the LATEST session.
    final resultSessionId = usage.sessionId;
    if (resultSessionId != null && resultSessionId.isNotEmpty) {
      _claudeNativeSessionId = resultSessionId;
    }
    unawaited(_persistClaudeRecord(normalExit: false));
  }

  /// Whether this run's spend is flat-fee subscription usage or a locally
  /// priced API estimate.
  ///
  /// `ANTHROPIC_API_KEY` in the effective environment takes precedence over a
  /// subscription login in `-p` mode (the CLI's own documented precedence), and
  /// `system/init` reports where the credential came from. Only the clearly
  /// subscription lanes count as `subscription`; everything else is the CLI's
  /// client-side ESTIMATE, which is also all `total_cost_usd` ever is.
  CostBasis _claudeCostBasis() {
    final source = _claudeInit?.apiKeySource?.toLowerCase();
    final hasApiKey =
        (callerEnv['ANTHROPIC_API_KEY']?.isNotEmpty ?? false) ||
        (adapterEnvOverride['ANTHROPIC_API_KEY']?.isNotEmpty ?? false) ||
        (Platform.environment['ANTHROPIC_API_KEY']?.isNotEmpty ?? false);
    if (hasApiKey) {
      return CostBasis.estimated;
    }
    switch (source) {
      case 'api_key':
      case 'api-key':
      case 'apitoken':
      case 'bedrock':
      case 'vertex':
        return CostBasis.estimated;
      default:
        // `oauth`, `claude.ai`, `keychain`, `none`, or unreported: the run is
        // on the subscription lane (or the CLI did not say, and the adapter's
        // own credential check already established a subscription directory).
        return CostBasis.subscription;
    }
  }

  /// Emits the model-latency stage events the adapter can actually observe,
  /// once each, and nothing it cannot: the CLI hides the provider request, so
  /// there is no truthful "requestSent" or provider TTFB to report.
  void _noteClaudeModelDelta({bool useful = false}) {
    if (!_claudeSawFirstModelDelta) {
      _claudeSawFirstModelDelta = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstModelDelta,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.adapter,
          provider: _claudeProvider,
          modelId: _claudeInit?.model ?? modelId,
        ),
      );
    }
    if (useful && !_claudeSawFirstUseful) {
      _claudeSawFirstUseful = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstUsefulText,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.adapter,
          provider: _claudeProvider,
          modelId: _claudeInit?.model ?? modelId,
        ),
      );
    }
  }

  /// The first structured stdout line of the current attempt — the transport
  /// boundary the adapter can see. Called from the shared sandbox-event
  /// forwarder, which is also where the line is parsed.
  void _noteClaudeFirstStdout() {
    if (!_claudeSawFirstStdout) {
      _claudeSawFirstStdout = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstResponseByte,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.transport,
          provider: _claudeProvider,
          modelId: _claudeInit?.model ?? modelId,
        ),
      );
    }
  }

  /// Milliseconds from the RUN's shared start to now.
  ///
  /// Measured against [runStartedAt] — the same instant the run log persists as
  /// `startedAt` — not against this adapter's entry, so a launch that waited on
  /// a directory lock still reports its real distance from the run's beginning.
  int _claudeOffsetMs() =>
      DateTime.now().difference(runStartedAt).inMilliseconds;

  int? _claudeAttemptDurationMs() {
    final start = _claudeAttemptStartedAt;
    return start == null
        ? null
        : DateTime.now().difference(start).inMilliseconds;
  }

  /// The provider name stamped on this run's usage events.
  String get _claudeProvider => 'anthropic';

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
    return File('$dir/.credentials.json').existsSync();
  }

  /// [base] re-pointed at ONE account of a multi-account run.
  Map<String, String> _envForClaudeAccount(
    Map<String, String> base,
    String configDir,
  ) {
    if (configDir.isEmpty) {
      return base;
    }
    return {...base, 'CLAUDE_CONFIG_DIR': configDir};
  }
}
