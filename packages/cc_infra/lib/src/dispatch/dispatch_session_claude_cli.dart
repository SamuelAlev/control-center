part of 'dispatch_session.dart';

/// The prompt of a run that only compacts its native session.
///
/// Slash commands never reach a dispatch from a person: the messaging layer
/// handles `/compact` itself. So on the Claude lane this exact prompt can only
/// come from `ClaudeIdleCompactor`.
const kClaudeIdleCompactionPrompt = '/compact';

/// One stream-json user message, as `claude -p --input-format stream-json`
/// reads it from stdin.
String _claudeUserLine(String text) =>
    '${jsonEncode({
      'type': 'user',
      'message': {'role': 'user', 'content': text},
    })}\n';

/// What a turn that lost its sign-in mid-way is resumed with once a human has
/// signed in again. The resumed session already holds the request and the work
/// done on it; the failed call left no answer behind, so this only has to say
/// why the turn paused. Model-facing, so never localized.
const kClaudeContinueAfterSignInPrompt =
    'Your previous request failed because the Claude sign-in expired. '
    'It has been renewed. Continue the task from where you left off; '
    'do not repeat work that is already done.';

/// A Claude Code failure as the transcript records it: the sentence, plus the
/// structured code a client branches on (a sign-in prompt for an expired
/// credential) instead of pattern-matching the sentence.
ErrorEvent _claudeErrorEvent(String detail, {bool auth = false}) => ErrorEvent(
  content: detail,
  code: auth ? ErrorSegment.authenticationErrorCode : null,
  source: ErrorSegment.claudeCodeSource,
);

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
    required String sandboxSessionId,
    required String wsId,
  }) async {
    final claudePath = await resolveBinary('claude');
    if (claudePath == null) {
      addEvent(
        ErrorEvent(
          content:
              '[claude] "claude" not found on PATH. Install Claude Code: '
              'https://docs.anthropic.com/en/docs/claude-code',
        ),
      );
      _finish(exitCode: 127);
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
      if (spent.reason == RunCredentialReason.planSpent) {
        _markEndReason(
          RunEndReason.usageLimit,
          limitResetsAt: spent.earliestReset,
        );
      }
      addEvent(ErrorEvent(content: claudeRefusalDetail(spent)));
      _finish(exitCode: 126);
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
        addEvent(_claudeErrorEvent(detail, auth: true));
        _finish(exitCode: 126);
        return;
      }
    }

    // Capability-resolve FIRST: one effective-resume decision then governs the
    // argv, the stdin prompt, the diagnostics and the accounting baseline. An
    // older `claude` without `--resume` (or without `--effort`) must never be
    // handed a flag it will reject — and must never be sent a delta prompt with
    // no session to attach it to.
    final capabilities = await ClaudeCliBackend.detectCapabilities(claudePath);
    _claude.capabilities = capabilities;
    final compactOnly = _claudeCompactOnly;
    final startedIn = conversationId;
    if (workspaceId != null && startedIn != null) {
      deps.claudeIdleCompactor?.runStarted(workspaceId!, startedIn);
    }
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

    // Point `claude` at the Control Center MCP server explicitly, so the agent
    // reliably gets the `mcp__*` tool surface (incl. `submit_output`, which
    // writes a pipeline run's structured output so the step resume listener can
    // harvest it). The server's token and this run's secret go over stdin where
    // the CLI can take them that way, so they never land in a file the agent can
    // read. Otherwise the derived client config (`<cwd>/.mcp.json`, written
    // per-session from the live `mcp_config.json` posture) is the ONE config
    // `--strict-mcp-config` loads. No resolver → no MCP at all.
    final mcpServers = capabilities.supportsMcpSetServers
        ? await _resolveMcpServers()
        : null;
    var mcpConfigPath = mcpServers == null
        ? await _resolveMcpConfigPath()
        : null;
    if (mcpServers != null) {
      _removeStaleMcpConfig();
    }
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
    final hookSettings = AgentRunLease.claudeHookSettings(
      _gatewayLease,
      readOnly: readOnly,
    );
    final permissionMode = _claudePermissionMode(mode);
    _claude.mcpExpected = mcpConfigPath != null || mcpServers != null;

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
      mcpServers: mcpServers,
      settingsJson: hookSettings,
      // Whether this server runs scripts, which shapes the MCP `tools/list`
      // this session is handed.
      hasRepl: deps.codeExecutions?.availability.isAvailable ?? false,
    );
    // A fresh run starts a new native session and leaves the conversation's
    // stored one untouched (neither cleared nor resumed nor replaced), so the
    // next ordinary run resumes it as before.
    if (claudeResumeReset && !freshHistory) {
      await _clearClaudeRecord(policy);
    }
    final resumeRecord = freshHistory ? null : await _loadClaudeRecord(policy);
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
    // A compaction carries no context, so it only needs the session itself.
    final activeResumeRecord = delta != null || compactOnly
        ? resumeCandidate
        : null;
    if (compactOnly && activeResumeRecord == null) {
      // The session moved on or never existed: starting a fresh one to compact
      // would spend a turn on nothing.
      addEvent(
        DebugEvent(content: '[claude] no native session left to compact'),
      );
      _finish(exitCode: 0);
      return;
    }
    if (parts != null && resumeRecord != null && !capabilities.supportsResume) {
      addEvent(
        DebugEvent(
          content:
              '[claude] this claude build does not support --resume; sending '
              'the full prompt instead of continuing the stored session.',
        ),
      );
    }
    _claude.resumeRecord = activeResumeRecord;
    _claude.resumeId = activeResumeRecord?.sessionId;
    _claude.deltaPrompt = delta;
    // The ledger continues from the resumed session's persisted baseline ONLY
    // when the CLI will actually restore those totals: Claude makes them
    // durable on a normal exit alone, and versions before 2.1.277 never restore
    // them. Otherwise the figures a resumed call reports are its own, and
    // deltaing them against an old baseline would swallow the difference.
    _claude.ledger = ClaudeAccountingLedger(
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
    _claude.dispatchTotals = ClaudeDispatchTotals();
    _claude.unreported = ClaudeUnreportedUsage();
    _claude.init = null;
    _claude.nativeSessionId = _claude.resumeId;
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

    final autoCompactWindow = deps.claudeSessionSettings
        ?.call()
        .autoCompactWindow;
    final claudeFlags = ClaudeCliBackend.buildClaudeArgs(
      modelId: modelId,
      permissionMode: permissionMode,
      mcpConfigPath: mcpConfigPath,
      mcpOverStdin: mcpServers != null,
      settingsJson: hookSettings,
      autoCompactWindow: autoCompactWindow,
      effortLevel: effortLevel,
      capabilities: capabilities,
    );

    final handle = await _launchSandbox(sandboxSessionId, wsId);
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

    final mergedEnv = {
      ..._mergedEnv(backendEnv: discoveryEnv),
      ...ClaudeCliBackend.autoMemoryOffEnv,
    };

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

    // The window the meter measures against: the agent's own setting, else
    // the one the CLI reports for this `--model` id. Read off the critical
    // path — the first usage report lands after the first model response, by
    // which time the (cached, usually) catalog read is long done; until then
    // the window is simply unreported rather than guessed.
    var modelWindow = contextWindowTokens;
    final windowOf = deps.claudeContextWindowOf;
    if (modelWindow == null && windowOf != null) {
      unawaited(
        windowOf(modelId).then(
          (w) => modelWindow = w,
          onError: (Object e) {
            CcInfraLog.warning(
              'dispatch $dispatchId: could not read the Claude Code '
              'context window: $e',
            );
            return null;
          },
        ),
      );
    }

    var exitCode = 0;
    // Whether the attempt that ended the loop already explained itself, so the
    // trailing exit-code line does not repeat it. See [_sawProcessStderr].
    var explained = false;
    // How many times a dead sign-in has already parked this run. Bounded so a
    // credential that 401s again after a login cannot relaunch forever.
    var reauthParks = 0;
    // The native session a turn that died on its sign-in MID-WAY continues on
    // after a fresh login. Set only for the one attempt that follows the park.
    String? continueSessionId;
    // Whether ANY attempt of this turn produced output. A continued attempt
    // starts with nothing of its own, yet the turn behind it did work, so a
    // second failure must never send it back to the replay-the-prompt paths.
    var turnProducedOutput = false;
    _claude.subagents = _openClaudeSubagents();
    _claude.steered.clear();
    _steering.onEnqueued = _scheduleClaudeSteeringPump;
    var steeringAnnounced = false;
    // A zero exit alone is not a completed turn: Claude can exit before
    // sending a result, in which case the prompt has no proven delivery.
    var completedTurn = false;
    var i = 0;
    while (i < attempts.length && !_cancelSource.isCancelled) {
      final attempt = attempts[i];
      ClaudeTerminalError? terminal;
      ClaudeRateLimitInfo? blockedBy;
      completedTurn = false;
      var producedOutput = false;
      // Claude Code's own auto-compactions in this attempt.
      var compactions = 0;

      _claude.toolNames.clear();
      _claude.parser = ClaudeStreamJsonParser(
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
            _claude.toolNames[tu.id] = tu.name;
            _claude.subagents?.noteSpawnCall(tu);
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
                toolName: _claude.toolNames.remove(tr.id),
                isError: tr.isError,
                images: tr.images,
              ),
            );
            final subagents = _claude.subagents;
            if (subagents != null) {
              unawaited(subagents.complete(tr));
            }
          },
          // A subagent's own work becomes its child run's transcript, not
          // rows in this turn.
          onSubagent: (event) {
            producedOutput = true;
            _claude.subagents?.onEvent(event);
          },
          onBackgroundTask: _onClaudeBackgroundTask,
          // Occupancy, not spend: the size of the newest main-thread call,
          // measured against the agent's configured window, else the one the
          // `--model` id runs with. A setting the model cannot honour is
          // shown as set — the run, not the meter, is where it fails.
          onCallUsage: (u) {
            _claude.contextTokens = u.contextTokens;
            addEvent(
              ContextWindowEvent(
                contextTokens: u.contextTokens,
                windowTokens: modelWindow,
                compactions: compactions,
              ),
            );
            _onClaudeCallUsage(u);
          },
          // Spend only: a subagent's calls run in their own window.
          onSubagentCallUsage: _onClaudeCallUsage,
          onCompactBoundary: (preTokens) {
            compactions++;
            _noteClaudeCompacted();
            if (compactOnly) {
              // The run's whole output: without it the conversation shows an
              // empty reply from an agent nobody spoke to.
              addEvent(
                TextEvent(
                  content:
                      'Compacted this conversation'
                      '${preTokens == null ? '' : ' from $preTokens tokens'} '
                      'before its prompt cache expired.',
                ),
              );
            }
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
          onUsage: (usage) {
            _claude.cacheTtl = usage.cacheTtl ?? _claude.cacheTtl;
            _onClaudeResultUsage(usage);
          },
          // Held, not emitted: a capacity failure we are about to retry is not
          // something to show as an error, and the decision needs the exit code
          // that has not arrived yet.
          onTerminalError: (e) {
            final limit = blockedBy;
            terminal = limit == null ? e : e.blockedBy(limit);
          },
          onControlResponse: _onClaudeControlResponse,
          onRateLimit: (info) {
            blockedBy = info.blocked ? info : null;
            _onClaudeRateLimit(info, attempt);
          },
          onResult: () {
            completedTurn = _onClaudeTurnEnded(failed: terminal != null);
          },
        ),
      );

      // A turn that already worked and then lost its sign-in continues in the
      // session that holds that work, on the account it ran on; it is never
      // replayed from the top. See the auth branch below.
      final continuing = continueSessionId;
      continueSessionId = null;
      if (continuing != null) {
        _claude.resumeId = continuing;
      }
      // Closed by `_closeClaudeStdin`, at the turn's result or after exec.
      // ignore: close_sinks
      final stdin = _openClaudeStdin(
        // Resuming sends the DELTA (new per-turn context, the message, and the
        // conversation window again if it changed while parked); a fresh
        // attempt — first attempt with no stored session, or a failover after
        // one failed — sends the full prompt. A delta without `--resume` would
        // silently drop the standing brief and the conversation, so the two
        // always move together.
        compactOnly
            ? kClaudeIdleCompactionPrompt
            : continuing != null
            ? kClaudeContinueAfterSignInPrompt
            : i == 0 && _claude.resumeId != null
            ? _claude.deltaPrompt ?? prompt
            : prompt,
        mcpServers: mcpServers,
      );
      if (!steeringAnnounced) {
        steeringAnnounced = true;
        onHarnessStarted?.call();
      }
      _pumpClaudeSteering();

      addEvent(DebugEvent(content: '[claude] launching claude -p…'));
      _sawProcessStderr = false;
      _claude.sawFirstStdout = false;
      _claude.sawFirstModelDelta = false;
      _claude.sawFirstUseful = false;
      _claude.attemptStartedAt = DateTime.now();
      // `--resume` belongs to ONE account's config directory. A failover
      // attempt runs on a different account with a different store of
      // sessions, so it starts fresh rather than pointing at a session that
      // does not exist there.
      final attemptArgv = <String>[
        claudePath,
        ...((continuing != null || i == 0) && _claude.resumeId != null
            ? ClaudeCliBackend.buildClaudeArgs(
                modelId: modelId,
                permissionMode: permissionMode,
                mcpConfigPath: mcpConfigPath,
                mcpOverStdin: mcpServers != null,
                settingsJson: hookSettings,
                autoCompactWindow: autoCompactWindow,
                effortLevel: effortLevel,
                resumeSessionId: _claude.resumeId,
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
      // The adapter emits every line before `exec` returns, but the event
      // stream delivers them asynchronously: yield until what is queued has
      // been parsed. Nulling the parser first turned a late `result` line into
      // raw transcript text, or lost the turn's final usage.
      await _drainSandboxEvents();
      _claude.parser = null;
      if (_cancelSource.isCancelled) {
        // A stop already settled the run with the cumulative report that
        // includes the calls no `result` reported (`_failRun`), and may have
        // ended its stream: nothing more is emitted from here.
        break;
      }
      // Calls this process streamed that no `result` will report now: it died
      // mid-turn. Counted at their streamed size before anything moves to
      // another account or ends the run.
      _foldClaudeUnreportedUsage();

      final failure = terminal;
      final hasNext = i + 1 < attempts.length;
      turnProducedOutput = turnProducedOutput || producedOutput;
      // Is this failure about the ACCOUNT rather than the run? Two shapes
      // qualify — a spent plan and a credential that no longer authenticates —
      // and only those retry. Any other terminal error (a bad model id, a
      // rejected MCP config) would fail identically on every account, and a
      // turn that already streamed work would be duplicated by a re-run rather
      // than continued.
      final accountFailure =
          failure != null && (failure.isCapacity || failure.isAuth);
      // A compaction is an optimisation for one session on one account. It
      // never moves to another account or stops to ask anyone to sign in.
      if (accountFailure && !turnProducedOutput && hasNext && !compactOnly) {
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
        _claude.resumeId = null;
        _claude.nativeSessionId = null;
        _claude.persistDisabled = true;
        _claude.ledger = ClaudeAccountingLedger();
        continue;
      }
      // The last account's sign-in is dead and the turn has said nothing.
      // Park for a human to sign in again and re-run this same prompt, rather
      // than finishing as a blank bubble the operator cannot act on.
      if (failure != null &&
          failure.isAuth &&
          !turnProducedOutput &&
          reauthParks < 2 &&
          !compactOnly) {
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
          final record = _claude.resumeRecord;
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
          _claude.resumeId = restoredRecord?.sessionId;
          _claude.deltaPrompt = restoredDelta;
          _claude.nativeSessionId = _claude.resumeId;
          _claude.ledger = ClaudeAccountingLedger(
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
          _claude.persistDisabled = false;
          continue;
        }
        addEvent(_claudeErrorEvent(detail, auth: true));
        explained = true;
        break;
      }
      // The sign-in died AFTER the turn did work. Re-running the prompt would
      // redo (and duplicate) that work, so park for a login on the account it
      // ran on and then CONTINUE the native session that holds it — what a
      // person does in Claude Code itself: sign in again, then "continue".
      final sessionToContinue = _claude.nativeSessionId;
      if (failure != null &&
          failure.isAuth &&
          turnProducedOutput &&
          reauthParks < 2 &&
          capabilities.supportsResume &&
          sessionToContinue != null &&
          sessionToContinue.isNotEmpty) {
        if (attempt.accountId.isNotEmpty) {
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        final detail = redactSecrets('[claude] ${failure.message}');
        if (await _gateOnExpiredClaudeSignIn(
          detail: detail,
          midTurn: attempt,
        )) {
          reauthParks++;
          explained = false;
          continueSessionId = sessionToContinue;
          continue;
        }
        addEvent(_claudeErrorEvent(detail, auth: true));
        explained = true;
        break;
      }
      if (failure != null) {
        if (accountFailure && attempt.accountId.isNotEmpty) {
          // Last account, or the turn had already produced work: record the
          // failure anyway so the NEXT dispatch starts somewhere usable.
          await _reportClaudeAccountFailure(attempt.accountId, failure);
        }
        // The plan ran out and no account is left to carry the run: it ends
        // on a usage limit, with the CLI's reset time when it reported one.
        if (failure.isCapacity && !compactOnly) {
          _markEndReason(
            RunEndReason.usageLimit,
            limitResetsAt: failure.resetsAt,
          );
        }
        final detail = redactSecrets('[claude] ${failure.message}');
        addEvent(
          compactOnly
              ? DebugEvent(content: detail)
              : _claudeErrorEvent(detail, auth: failure.isAuth),
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
    if (exitCode == 0 && completedTurn && !compactOnly) {
      _reportClaudeTurnSettled();
    }
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
    // The terminal write must be the row's last cost write.
    await _claude.costWrites;
    _finish(exitCode: exitCode);
  }

  /// The turn's `result`. Anything still queued — follow-ups included — starts
  /// the next turn on this same process, context intact. Otherwise stdin
  /// closes and the process exits; a failed turn always closes, since the
  /// failover and sign-in handling need the exit. Returns true only when this
  /// was the successful FINAL turn, so an interrupted queued turn cannot
  /// advance the persisted delivery cursor.
  bool _onClaudeTurnEnded({required bool failed}) {
    final stdin = _claude.stdin;
    if (stdin == null) {
      return false;
    }
    // A stopped run takes nothing more: queued work must not start a turn on
    // the process that is being shut down.
    if (_cancelSource.isCancelled) {
      _closeClaudeStdin();
      return false;
    }
    // The run reached its cost cap on this turn: nothing queued starts
    // another turn. What is queued stays queued and converts at run end.
    if (_costCapReached) {
      _closeClaudeStdin();
      return !failed;
    }
    if (!failed) {
      final pending = [
        ..._steering.drainSteering(),
        ..._steering.drainAside(),
        ..._steering.drainFollowUp(),
      ];
      if (pending.isNotEmpty) {
        // Near the cap, the next turn starts with the wrap-up note.
        final wrapUp = _takeCostWrapUp();
        if (wrapUp != null) {
          stdin.add(_claudeUserLine(wrapUp));
        }
        _writeClaudeSteering(stdin, pending);
        return false;
      }
      if (_holdClaudeForBackground()) {
        return true;
      }
    }
    _closeClaudeStdin();
    return !failed;
  }

  /// Closes any Claude subagent still open: its parent process is gone, so
  /// its spawn call will never return.
  Future<void> _closeClaudeSubagents() async {
    final subagents = _claude.subagents;
    _claude.subagents = null;
    await subagents?.closeAll(endReason: _endReason ?? RunEndReason.error);
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
    required Map<String, Object?>? mcpServers,
    required String? settingsJson,
    required bool hasRepl,
  }) {
    var mcp = '';
    if (mcpServers != null) {
      // The shape of the file, so moving between the two forks no session.
      mcp = AgentRunLease.withoutRunSecret(
        jsonEncode({'mcpServers': mcpServers}),
      );
    } else if (mcpConfigPath != null && mcpConfigPath.isNotEmpty) {
      try {
        mcp = AgentRunLease.withoutRunSecret(
          File(mcpConfigPath).readAsStringSync(),
        );
      } on Object {
        mcp = mcpConfigPath;
      }
    }
    final hasControlCenterMcp =
        mcpServers != null ||
        (mcpConfigPath != null && mcpConfigPath.isNotEmpty);
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
      'git=${jsonEncode(_run.identity.gitEnv)}',
      'mcp=${sha256.convert(utf8.encode(mcp))}',
      'settings=${sha256.convert(utf8.encode(settingsJson ?? ''))}',
      // `repl` shapes the Control Center MCP `tools/list` (`repl`, and most
      // tools moved behind it). A resumed session keeps the tool list it
      // fetched, so a change forks, and a fork withholds trust in Claude
      // Code's MCP discovery cache (no record under the new fingerprint), so
      // a list fetched without `repl` is never reused with it.
      'repl=$hasRepl',
      'append=${ClaudeCliBackend.appendedSystemPrompt(hasControlCenterMcp: hasControlCenterMcp)}',
      if (hasControlCenterMcp)
        'disallowed=${ClaudeCliBackend.replacedNativeTools}',
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
      _claude.scopeKey = scope?.storageKey;
      _claude.policyKey = policy;
      return null;
    }
    _claude.scopeKey = scope.storageKey;
    _claude.policyKey = policy;
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
    if (_claude.persistDisabled) {
      return;
    }
    final store = deps.claudeSessionStore;
    final storeKey = _claude.scopeKey;
    final policy = _claude.policyKey;
    final sessionId = _claude.nativeSessionId;
    final ws = workspaceId;
    if (freshHistory ||
        store == null ||
        storeKey == null ||
        policy == null ||
        sessionId == null ||
        sessionId.isEmpty ||
        ws == null ||
        ws.isEmpty) {
      return;
    }
    final ledger = _claude.ledger;
    final previous = _claude.resumeRecord;
    final now = DateTime.now().toUtc();
    final baseline = ledger?.baseline;
    // A compaction sent the session nothing, so whatever arrived in the
    // conversation since its last turn is still owed to the next one.
    final delivered = normalExit && !_claudeCompactOnly;
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
      conversationRevision: delivered
          ? (promptParts?.conversationRevision ?? '')
          : (previous?.conversationRevision ?? ''),
      // Only a clean exit advances the cursor: an interrupted run may never
      // have been read, so the next resume re-delivers what changed. The lists
      // are BOUNDED (most recent window) — a cursor, not a log.
      deliveredConversationKeys: ClaudeNativeSessionRecord.bound(
        delivered
            ? (promptParts?.deliveredConversationKeysFor() ?? const [])
            : (previous?.deliveredConversationKeys ?? const []),
      ),
      deliveredSectionKeys: ClaudeNativeSessionRecord.bound(
        delivered
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
      _claude.resumeRecord = record;
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
      _claude.capabilities?.restoresSessionTotals ?? false;

  /// Startup metadata arrived. Records the native session id, reports what the
  /// CLI actually resolved (model, tool surface, MCP errors, capabilities) and
  /// the startup time — measured separately from model latency, and NEVER
  /// presented as provider TTFB, which the CLI hides.
  void _onClaudeInit(ClaudeInitMetadata init) {
    _claude.init = init;
    final sessionId = init.sessionId;
    if (sessionId != null) {
      if (_claude.resumeId != null && _claude.resumeId != sessionId) {
        addEvent(
          DebugEvent(
            content:
                '[claude] resumed session ${_claude.resumeId!} continued as '
                '$sessionId',
          ),
        );
      }
      _claude.nativeSessionId = sessionId;
    }

    final started = _claude.attemptStartedAt;
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
              'resumed=${_claude.resumeId != null}',
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
            '${_claude.resumeId == null ? '' : ', resumed=${_claude.resumeId!}'}',
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
        _claude.mcpExpected
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
    _claude.ledger?.reset();
    if (sessionId != null && sessionId.isNotEmpty) {
      _claude.nativeSessionId = sessionId;
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
    final ledger = _claude.ledger ??= ClaudeAccountingLedger();
    final turn = ledger.record(usage);
    // Fold this turn's delta into the DISPATCH's own totals: the run-level
    // snapshot is built from these, so an earlier dispatch's spend (restored
    // into the native session's counters) never inflates this run and a reset
    // or account failover never erases what this run already spent.
    _claude.dispatchTotals.add(turn);
    // A result with token counters reported every call streamed so far,
    // replacing their estimates (main-loop-only counters too: the ledger
    // reconciles the rest when whole-tree counters return). One with a cost
    // and no counters reported their spend but not their tokens. One that
    // reported nothing (a crashed, zeroed result) leaves them estimated, to be
    // counted when the process ends without a better report.
    final countersReported =
        usage.inputTokens > 0 ||
        usage.outputTokens > 0 ||
        usage.cacheReadTokens > 0 ||
        usage.cacheWriteTokens > 0 ||
        usage.modelUsage.isNotEmpty;
    if (countersReported) {
      _claude.unreported.settle();
    } else if (usage.costReported && usage.costUsd > 0) {
      _claude.unreported.dropEstimates();
    }
    // The CLI's OWN model, from `system/init` — the id it actually serves,
    // which can differ from the requested `--model`.
    final servingModel = _claude.init?.model ?? modelId;
    final provider = _claudeProvider;
    // Locally priced API usage is an ESTIMATE; only an established subscription
    // lane is `subscription`. An `ANTHROPIC_API_KEY` takes precedence over
    // subscription login in `-p` mode, so metered runs must not be reported as
    // flat-fee usage.
    // Missing amounts stay nullable; unknown provenance uses the domain's
    // conservative estimate basis rather than claiming a reported figure.
    final basis = _claude.dispatchTotals.costUnavailable
        ? CostBasis.estimated
        : _claudeCostBasis();
    // Lineage, so the resume-vs-reconstruction experiment scores from data:
    // which native session produced this usage, and whether it was resumed.
    final nativeSessionId = _claude.nativeSessionId;
    final resumed = _claude.resumeId != null;

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
          // The DELTA only; the run total rides the cumulative event below.
          costMicros: turn.costDeltaMicros,
          costBasis: basis,
        ),
        durationMs: usage.durationMs,
      ),
    );

    // Every result carries reconciled observed counters: whole-tree model
    // deltas when available, known main-loop usage otherwise. Missing model
    // counters are credited once if a later full snapshot fills the gap.
    _emitClaudeRunCumulative();

    // A `/clear` mints a new session id on the result; keep the record's id
    // current so the next turn resumes the LATEST session.
    final resultSessionId = usage.sessionId;
    if (resultSessionId != null && resultSessionId.isNotEmpty) {
      _claude.nativeSessionId = resultSessionId;
    }
    unawaited(_persistClaudeRecord(normalExit: false));
    // The reported spend replaced the in-turn estimate
    // (`_observeClaudeRunningCost`). At the cap the run ends with this turn
    // (`_onClaudeTurnEnded` starts no queued turn) and settles as `budget`.
    _observeRunCost(
      _claude.dispatchTotals.costMicros + _claude.unreported.pricedMicros,
    );
  }

  /// One streamed report of a model call, main thread or subagent: its spend
  /// joins the run's until the turn's `result` reports it. The run's
  /// cumulative report and its row move with it, and the cost cap is checked
  /// on it.
  void _onClaudeCallUsage(ClaudeCallUsage call) {
    if (!_claude.unreported.record(call, _claudeCallPriceMicros)) {
      return;
    }
    _emitClaudeRunCumulative();
    _observeClaudeRunningCost();
  }

  /// [call]'s estimated cost at its serving model's catalog price, in
  /// micro-dollars, or null when the catalog has no price for it.
  int? _claudeCallPriceMicros(ClaudeCallUsage call) {
    final model = call.model ?? _claude.init?.model ?? modelId;
    final price = model == null
        ? null
        : deps.modelResolver
              ?.call(model.contains('/') ? model : 'anthropic/$model')
              ?.cost;
    if (price == null || !price.isKnown) {
      return null;
    }
    return price.estimateMicros(
      inputTokens: call.inputTokens,
      cacheReadTokens: call.cacheReadTokens,
      cacheWriteTokens: call.cacheWriteTokens,
      outputTokens: call.outputTokens,
    );
  }

  /// Counts, for good, the calls the process streamed that no `result` will
  /// report: it ended (or crashed) mid-turn. They join the dispatch's totals
  /// at their streamed size and estimated price, so a later attempt's reports
  /// (a failover) build on them rather than dropping them.
  void _foldClaudeUnreportedUsage() {
    final pending = _claude.unreported;
    if (pending.isEmpty) {
      return;
    }
    final calls = pending.calls;
    _claude.dispatchTotals.addUnreported(pending);
    pending.settle();
    addEvent(
      DebugEvent(
        content:
            '[claude] $calls model call${calls == 1 ? '' : 's'} ended without '
            'a result; counted at their streamed usage (cost estimated)',
      ),
    );
    _emitClaudeRunCumulative();
  }

  /// Emits the run's spend so far as one ABSOLUTE `runCumulative` report, and
  /// writes it to the run's row: what the turns' results reported, plus every
  /// streamed call no result has reported yet. A later report replaces it,
  /// so the in-turn part stays provisional until the turn's `result` lands;
  /// if the run is stopped first, `_failRun` settles it with this figure.
  void _emitClaudeRunCumulative() {
    final totals = _claude.dispatchTotals;
    final pending = _claude.unreported;
    if (!totals.hasTokenData && pending.isEmpty) {
      return;
    }
    // Locally priced API usage is an ESTIMATE; only an established
    // subscription lane is `subscription`. A call no price was found for
    // makes the figure an estimate whatever the lane.
    final basis = totals.costUnavailable || pending.hasUnpriced
        ? CostBasis.estimated
        : _claudeCostBasis();
    final usage = RunUsage(
      inputTokens: totals.inputTokens + pending.inputTokens,
      outputTokens: totals.outputTokens + pending.outputTokens,
      cachedReadTokens: totals.cacheReadTokens + pending.cacheReadTokens,
      cachedWriteTokens: totals.cacheWriteTokens + pending.cacheWriteTokens,
      costMicros: totals.costMicros + pending.pricedMicros,
      costBasis: basis,
    );
    addEvent(
      UsageEvent(
        purpose: domain_purpose.LlmCallPurpose.main,
        provider: _claudeProvider,
        // The CLI's OWN model, from `system/init`.
        modelId: _claude.init?.model ?? modelId,
        scope: UsageScope.runCumulative,
        nativeSessionId: _claude.nativeSessionId,
        resumedNativeSession: _claude.resumeId != null,
        usage: usage,
      ),
    );
    _writeClaudeRunCost();
  }

  /// Writes the run's spend so far to its row, after any write in flight.
  ///
  /// The row otherwise holds no cost until the run ends, so a running run
  /// showed nothing until its turn finished. Writes coalesce: a queued write
  /// reads the latest cumulative report when it runs. `_runClaudeCli` and
  /// `_abortRun` await [ClaudeRunState.costWrites] before the terminal
  /// event, so the terminal write lands last.
  void _writeClaudeRunCost() {
    final repo = deps.runLogRepo;
    final id = runLogId;
    final ws = workspaceId;
    if (repo == null || id == null || ws == null || ws.isEmpty) {
      return;
    }
    if (_claude.costWriteQueued) {
      return;
    }
    _claude.costWriteQueued = true;
    _claude.costWrites = _claude.costWrites.then((_) async {
      _claude.costWriteQueued = false;
      final cost = _runEnd.usage.total;
      if (cost == null) {
        return;
      }
      try {
        await repo.updateCost(ws, id, cost);
      } on Object catch (e) {
        CcInfraLog.warning(
          'dispatch $dispatchId: could not write the run\'s spend: $e',
        );
      }
    });
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
    final source = _claude.init?.apiKeySource?.toLowerCase();
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
    if (!_claude.sawFirstModelDelta) {
      _claude.sawFirstModelDelta = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstModelDelta,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.adapter,
          provider: _claudeProvider,
          modelId: _claude.init?.model ?? modelId,
        ),
      );
    }
    if (useful && !_claude.sawFirstUseful) {
      _claude.sawFirstUseful = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstUsefulText,
          offsetMs: _claudeOffsetMs(),
          durationMs: _claudeAttemptDurationMs(),
          source: RunTimingSource.adapter,
          provider: _claudeProvider,
          modelId: _claude.init?.model ?? modelId,
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
    final start = _claude.attemptStartedAt;
    return start == null
        ? null
        : DateTime.now().difference(start).inMilliseconds;
  }

  /// The provider name stamped on this run's usage events.
  String get _claudeProvider => 'anthropic';

  /// Records an account's failure for later dispatches. Never throws: the
  /// record is a hint for the NEXT run's account choice, and a store that
  /// fails to write it must not abort the failover THIS run is in the middle
  /// of (the rate-limit path always swallowed it; these sites did not).
  Future<void> _reportClaudeAccountFailure(
    String accountId,
    ClaudeTerminalError failure,
  ) async {
    if (failure.isCapacity) {
      await _reportClaudeAccountExhausted(accountId, failure.resetsAt);
      return;
    }
    try {
      await onClaudeAccountAuthFailed?.call(
        accountId: accountId,
        reason: redactSecrets(failure.message),
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'dispatch $dispatchId: recording the sign-in failure of Claude '
        'account $accountId failed',
        e,
        st,
      );
    }
  }

  /// Records that [accountId] hit its plan limit. Never throws.
  Future<void> _reportClaudeAccountExhausted(
    String accountId,
    DateTime? resetsAt,
  ) async {
    try {
      await onClaudeAccountExhausted?.call(
        accountId: accountId,
        resetsAt: resetsAt,
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'dispatch $dispatchId: recording the plan limit of Claude account '
        '$accountId failed',
        e,
        st,
      );
    }
  }
}
