part of 'dispatch_session.dart';

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
  /// [AgentProcessEvent]s; the prompt is fed via stdin. `claude -p` draws
  /// from the same Claude Code subscription quota as interactive mode.
  Future<void> _runClaudeCli({
    required AgentCapabilities caps,
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
          'CLAUDE_CONFIG_DIR set to that directory.';
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
    );

    final handle = await onResolveHandle(
      sessionId: sandboxSessionId,
      spec: SandboxSpec(
        sessionId: sandboxSessionId,
        workspaceId: wsId,
        agentId: agentId,
        bindMounts: _bindMounts(),
        guestWorkdir: agentDirHostPath,
        networkEnabled: caps.canAccessNetwork,
        mode: mode,
        capabilities: caps,
        protectedPaths: await _protectedPaths(),
        runnerStateDirs: _runnerStateDirs,
        execGrantRoots: await _resolveExecGrantRoots(wsId),
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
      caps: caps,
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
    var i = 0;
    while (i < attempts.length) {
      final attempt = attempts[i];
      ClaudeTerminalError? terminal;
      var producedOutput = false;

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
            addEvent(
              ToolCallEvent(
                toolName: tu.name,
                toolCallId: tu.id,
                inputs: tu.input as Map<String, dynamic>?,
              ),
            );
          },
          onToolResult: (tr) => addEvent(
            ToolResultEvent(
              toolCallId: tr.id,
              outputs: tr.outputs,
              toolName: _claudeToolNames.remove(tr.id),
              isError: tr.isError,
            ),
          ),
          // `claude` prices itself, so this path does NOT go through
          // [HarnessCostCalculator]: the CLI already knows which model served
          // (including the auxiliary calls it makes on its own) and reports the
          // total, where a models.dev lookup would have to guess. Deliberately
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
        ),
      );

      addEvent(DebugEvent(content: '[claude] launching claude -p…'));
      _sawProcessStderr = false;
      exitCode = await deps.sandbox.exec(
        handle,
        argv,
        env: {
          ...mergedEnv,
          if (attempt.configDir.isNotEmpty)
            'CLAUDE_CONFIG_DIR': attempt.configDir,
        },
        onPid: (forkedPid) {
          _onPidAvailable(forkedPid);
          addEvent(
            DebugEvent(content: '[claude] claude running (pid $forkedPid)'),
          );
        },
        stdinInput: prompt,
      );
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
