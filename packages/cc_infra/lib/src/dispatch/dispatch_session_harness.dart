part of 'dispatch_session.dart';

/// Transcript-metadata key under which the built-in harness persists the
/// delivered-context cursor (a host concern the loop never interprets).
const _promptCursorMetadataKey = 'cc.promptCursor';

/// Who wrote the message a harness run starts with, which decides whether a
/// compaction pins it: a signed-in person's own message ([userText]) and a
/// pipeline step's or an assignment's prompt are the run's request; a wake
/// frame and a peer's text are data, never pinned.
HarnessMessageOrigin harnessRequestOrigin(
  String? userText,
  WakeContext? wakeContext,
) => userText != null
    ? HarnessMessageOrigin.person
    : (wakeContext?.hasWakes ?? false)
    ? HarnessMessageOrigin.wake
    : switch (wakeContext?.wakeReason) {
        WakeReason.peerMessage ||
        WakeReason.peerReply ||
        WakeReason.childCompleted => HarnessMessageOrigin.peer,
        _ => HarnessMessageOrigin.person,
      };

ReasoningEffort? _raiseEffort(
  ReasoningEffort? configured,
  ReasoningEffort? requested,
) {
  if (requested == null) {
    return configured;
  }
  if (configured == null) {
    return requested;
  }
  return requested.index > configured.index ? requested : configured;
}

/// What a run's `repl` tools run scripts with: the session's view of the
/// execution service and the workspace's limits. `executions` is null when
/// the run gets no script tool, and `error` then says why: the server runs
/// no scripts, the run has no workspace, or the limits could not be read.
typedef _CodeModeScripts = ({
  RunCodeExecutions? executions,
  CodeModeLimits limits,
  String? error,
});

extension _DispatchSessionHarness on DispatchSession {
  /// Builds the base harness tool registry (built-in filesystem/command tools
  /// first, then bridged CC MCP tools) for a given [mode]/[env]. The
  /// `task` tool is NOT added here — the top-level run adds it explicitly and
  /// subagents deliberately omit it so nesting is capped at one level.
  ///
  /// [personalMcp] is [_personalMcpAllowed], asked by the caller right before.
  ///
  /// [scriptOrigins] are the origins of the loop the registry is for (the
  /// session's own for the top-level run, the child's for a subagent): where
  /// its `ask_user` and its command runner learn which script a nested call
  /// belongs to.
  ///
  /// [replSlot] gives the registry a `repl` slot, which the run binds to its
  /// own `ReplTool` once its surface is known (`bindReplTool`).
  HarnessToolRegistry _buildHarnessRegistry({
    required Mode mode,
    required Map<String, String> env,
    required bool personalMcp,
    required RunScriptOrigins scriptOrigins,
    bool replSlot = false,
  }) {
    final toolProcesses = _toolProcesses(mode);
    return buildHarnessToolRegistry(
      mode: mode,
      networkEnabled: _run.networkEnabled,
      loopbackPorts: _gatewayLoopbackPorts,
      environmentScope: _run.environment.scope,
      env: env,
      toolOutputStore: _outputs,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      sandboxManager: deps.sandboxManager,
      confirmationPort: deps.confirmationPort,
      // The SAME resolution the CLI profile uses, so both adapters get the
      // same scoped exec roots — and the tool's own cwd never enters into it.
      execGrantRootsResolver: () => _execGrants(workspaceId ?? ''),
      sandboxSpec: (id) => _sandboxSpec(id, workspaceId ?? '', mode: mode),
      // The operator's own `commandPrefix` rules reach the bash gate through
      // this — before it, they were stored, resolvable, editable in the
      // what-if probe, and never consulted at runtime.
      actionGuard: deps.actionGuard,
      fileSearch: deps.fileSearch,
      mcpRegistry: deps.mcpRegistry,
      includePersonalMcp: personalMcp,
      protectedPaths: _protectedPaths,
      // `ask_user` renders in this run's conversation within its space.
      // Both scopes must reach the tool so the answer returns to this run.
      agentQuestionPort: deps.agentQuestionPort,
      spaceId: spaceId,
      // The question names this run, so only this run's watchdog pauses, and
      // `bash`'s guard rows name it and the person it acts for.
      runLogId: runLogId,
      onBehalfOfUserId: requestedByUserId,
      // Diagnostics + navigation. The ledger is PER RUN (a new run should hear
      // the current state of the world once), while the supervisor is shared
      // (its cost is indexing).
      lspSupervisor: deps.lspSupervisor,
      diagnosticsLedger: _diagnosticsLedger,
      lspWorkingDirectory: agentDirHostPath,
      // Structural search + rewrite. Null when the grammars are not staged, in
      // which case the tools are not advertised at all.
      treeSitterParser: deps.astParsers?.parserIfReady,
      stagedEditStore: _stagedEdits,
      debugSupervisor: deps.debugSupervisor,
      evalKernelFor: deps.kernelLauncherFactory == null
          ? null
          : (language) => _kernelFor(language, hostProcesses: toolProcesses),
      toolProcesses: toolProcesses,
      debugProcesses: _debugProcesses(mode),
      lspProcesses: _lspProcesses(mode),
      harnessSandboxSessionId: _harnessSandboxSessionId,
      // A script's question and a script's command name the script's own
      // execution, and a push the gateway holds stops the calling tool's
      // clocks.
      scriptOrigins: scriptOrigins,
      callWaits: _gatewayLease,
      replSlot: replSlot,
    );
  }

  Future<void> _runHarness({required String wsId}) async {
    _harness.begin();
    // The moment a harness loop becomes drainable: the steering queue service
    // wires this session's drain notifications and flushes any
    // persisted-but-undelivered steering rows into the run here (a queued row
    // written while the session was between transports, or before this
    // dispatch existed, has no other delivery path).
    onHarnessStarted?.call();
    // 1. Resolve provider + model + credential. A modelId may carry a fallback
    //    chain: `primary/model|fallback/model|…`.
    final factory = deps.harnessProviderFactory;
    final modelSpecs = (modelId ?? '')
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final parsed = factory.parseModel(
      modelSpecs.isEmpty ? modelId : modelSpecs.first,
    );
    final providerId = parsed.providerId;
    var credential = await _resolveHarnessCredential(providerId);
    if (!DispatchSession._harnessAuthSatisfied(credential)) {
      final envHint =
          (EnvProviderCredentialStore.envKeys[providerId] ?? const <String>[])
              .join(' or ');
      final detail =
          '[harness] No credential for provider "$providerId". Connect '
          'an account in Settings → Providers'
          "${envHint.isEmpty ? '' : ' or set $envHint'}.";
      credential = await _gateOnHarnessCredential(
        providerId: providerId,
        detail: detail,
      );
      if (!DispatchSession._harnessAuthSatisfied(credential)) {
        addEvent(ErrorEvent(content: detail, source: 'harness'));
        _finish(exitCode: 127);
        return;
      }
    }

    LlmProviderPort? built;
    while (built == null) {
      try {
        built = await _buildHarnessProvider(
          factory: factory,
          primaryProviderId: providerId,
          primaryModel: parsed.model,
          primaryCredential: credential,
          extraSpecs: modelSpecs.length > 1 ? modelSpecs.sublist(1) : const [],
        );
      } on _AccountPoolRefused catch (e) {
        // The same hold the Claude Code lane applies to the same verdict: the
        // operator edits the pool, the gate sees the refusal lift, and the
        // provider is assembled again from the new pool.
        if (await _gateOnHarnessPool(e)) {
          continue;
        }
        if (e.refusal.reason == RunCredentialReason.planSpent) {
          _markEndReason(
            RunEndReason.usageLimit,
            limitResetsAt: e.refusal.earliestReset,
          );
        }
        addEvent(ErrorEvent(content: e.toString(), source: 'harness'));
        _finish(exitCode: 126);
        return;
      } on Object catch (e) {
        addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
        _finish(exitCode: 127);
        return;
      }
    }
    var compactions = 0;
    late final int window;
    late final HarnessRunAccounting accounting;
    accounting = HarnessRunAccounting(
      runId: runLogId ?? const Uuid().v4(),
      workspaceId: wsId,
      conversationId: conversationId,
      runStartedAt: runStartedAt,
      repository: runLogId == null ? null : deps.llmCallRecordRepo,
      runLogRepository: runLogId == null ? null : deps.runLogRepo,
      priceLookup: (pid, model) =>
          deps.modelResolver?.call('$pid/$model')?.cost,
      onCall: (record) => _emitHarnessProviderCall(
        record,
        accounting: accounting,
        emit: addEvent,
        contextWindow: window,
        compactions: compactions,
      ),
    );
    _runEnd.accounting = accounting;
    final provider = accounting.observe(built, providerId: providerId);

    // 1b. Slash commands: /plan and /vibe change how the run behaves;
    //     /skill:<name> (or /skill:<repo>:<name>) injects that skill's
    //     instructions; anything else is plain text.
    //
    //     Parsed from `userText` (the user's message verbatim), NOT `prompt`:
    //     a space dispatch layers `prompt` into `<context>…</context>\n\n…`,
    //     which has no leading slash, so parsing it made every built-in
    //     command silently inert on the path that matters most.
    // Null for every run that is not a signed-in person's message: a
    // peer's text or a wake's payload is never a command.
    final parsedCommand = parseSlashCommand(userText ?? '');
    // A read-only run has the review mode's capabilities whatever it was
    // started with (the adapter starts it so; this holds it here too).
    var effectiveMode = readOnly ? Mode.review : mode;
    var effectivePrompt = prompt;
    // No turn ceiling anywhere: interactive and autonomous runs alike end
    // when the model stops, a budget bites, or a human stops them — the
    // doom-loop repetition guard is the bound on a spinning run, not an
    // arbitrary iteration count.
    int? commandMaxTurns;
    final commandDirectives = StringBuffer();
    if (parsedCommand.isCommand) {
      final applied = await _applySlashCommand(parsedCommand);
      // A read-only run stays read-only whatever its text asks for.
      effectiveMode = readOnly ? Mode.review : applied.mode ?? mode;
      effectivePrompt = _spliceUserText(applied.userTextOverride);
      commandMaxTurns = applied.maxTurns;
      if (applied.directive != null) {
        commandDirectives.writeln(applied.directive);
      }
      if (applied.notice != null) {
        addEvent(DebugEvent(content: '[harness] ${applied.notice}'));
      }
    }

    // Magic keywords: a standalone lowercase word in the user's own prose that
    // attaches a hidden instruction to THIS turn.
    final magic = detectMagicKeywords(userText ?? '');
    if (magic.isNotEmpty) {
      commandDirectives.writeln(magicKeywordDirective(magic));
      addEvent(
        DebugEvent(content: '[harness] ${magic.map((k) => k.word).join(', ')}'),
      );
    }

    final baseSystem = await _harnessSystemPrompt(wsId);

    // 3. Approval gate (write/exec tools; bash self-guards via the policy).
    final port = deps.confirmationPort;
    final guard = deps.actionGuard;
    final profile = profileFor(effectiveMode);
    // A script's call whose summary the audit could not hold whole is
    // refused, and audited, before anything else: no pre-tool hook, no
    // policy, no card, no budget. Every loop of the run asks it
    // ([LoopToolConfig.nestedCallRefusal]).
    String? scriptRefusal(HarnessTool tool, Map<String, dynamic> args) {
      final executed = tool.executedContent(args);
      final summary = ActionGuardService.toolActionSummary(tool.name, executed);
      return guard == null
          ? ActionGuardService.scriptActionRefusal(summary)
          : guard.refuseScriptAction(
              workspaceId: wsId,
              classes: tool.actionClasses,
              actionSummary: summary,
              command: executed,
              spaceId: spaceId,
              agentId: agentId,
              onBehalfOfUserId: requestedByUserId,
              runId: runLogId,
            );
    }

    // One decision for every loop of the run; only the origins a script's
    // call is resolved against are the loop's own.
    Future<ToolGateDecision> approvalWith(
      RunScriptOrigins origins,
      ToolApprovalRequest request,
    ) async {
      final tool = request.tool;
      final args = request.args;
      final origin = request.origin;
      if (DispatchSession._harnessInteractionTools.contains(tool.name)) {
        return const ToolGateDecision.allow();
      }
      // What the call runs, audited whole under the tool's name and digested
      // (a script's that is too long never gets here: [scriptRefusal]).
      final executed = tool.executedContent(args);
      final summary = ActionGuardService.toolActionSummary(tool.name, executed);
      final parent = origin.parentToolUseId;
      String? autonomy;
      final resolveAutonomy = deps.autonomyResolver;
      final autonomyWorkspaceId = workspaceId;
      if (resolveAutonomy != null &&
          spaceId != null &&
          agentId != null &&
          autonomyWorkspaceId != null &&
          autonomyWorkspaceId.isNotEmpty) {
        autonomy = await resolveAutonomy(
          autonomyWorkspaceId,
          spaceId!,
          agentId!,
        );
      }

      // A script's call: what that script may still ask of a person. A direct call has no budget.
      final budget = parent == null || parent.isEmpty
          ? null
          : origins.approvalsOf(parent);
      // Asks a person, telling the gate exactly when one is asked. Null when
      // the card came down unanswered: nobody's answer, and no decline.
      var unanswered = false;
      Future<bool?> ask(ConfirmationPort port, ConfirmationRequest card) async {
        budget?.asking();
        request.onPersonWait(true);
        final bool approved;
        try {
          approved = await port.requestApproval(card);
        } finally {
          request.onPersonWait(false);
        }
        if (request.withdrawn.isCancelled || unanswered) {
          return null;
        }
        budget?.answered(approved: approved, unanswered: false);
        return approved;
      }

      const withdrawnReason = 'the call stopped waiting before anyone answered';
      const unansweredReason = kUnansweredCardReason;
      if (guard != null && tool.actionClasses.isNotEmpty) {
        final actionRequest = const ActionRequestExtractor().extract(
          args,
          classes: tool.actionClasses,
          tool: tool.name,
        );
        final resolution = await guard.resolve(
          workspaceId: wsId,
          classes: tool.actionClasses,
          spaceId: spaceId,
          agentId: agentId,
          mode: effectiveMode,
          request: actionRequest,
        );
        void auditOutcome(
          ActionDecision applied, {
          bool asked = false,
          String? budgetRefusal,
        }) {
          guard.recordOutcome(
            workspaceId: wsId,
            resolution: budgetRefusal == null
                ? resolution
                : scriptApprovalDenial(resolution, budgetRefusal),
            applied: applied,
            classes: tool.actionClasses,
            agentId: agentId,
            spaceId: spaceId,
            actionSummary: summary,
            prompted: asked,
            unanswered: unanswered || (asked && request.withdrawn.isCancelled),
            onBehalfOfUserId: requestedByUserId,
            runId: runLogId,
            command: executed,
          );
        }

        if (resolution.decision == ActionDecision.deny) {
          auditOutcome(ActionDecision.deny);
          addEvent(
            DebugEvent(
              content:
                  '[harness] "${tool.name}" denied by action '
                  'policy: ${resolution.driving.reason}',
            ),
          );
          return ToolGateDecision.deny(
            reason: resolution.driving.reason,
            remediation: DispatchSession._remediationFor(profile),
          );
        }
        final outcome = const AutonomyComposition().compose(
          decision: resolution.decision,
          autonomy: AutonomyLevel.tryFromWire(autonomy),
          isGated: !profile.pinnedVerbs.contains(tool.name),
        );
        if (outcome == AutonomyOutcome.allow) {
          auditOutcome(ActionDecision.allow);
          return const ToolGateDecision.allow();
        }
        if (outcome == AutonomyOutcome.deny) {
          auditOutcome(ActionDecision.deny);
          return ToolGateDecision.deny(
            reason: autonomy == 'proposeOnly'
                ? 'this space\'s autonomy is set to propose-only'
                : resolution.driving.reason,
            remediation: DispatchSession._remediationFor(profile),
          );
        }
        if (port == null) {
          auditOutcome(ActionDecision.deny);
          return const ToolGateDecision.deny(
            reason: 'approval is required but no approver is connected',
          );
        }
        // Nobody waits for this decision any more: raise no card for it.
        if (request.withdrawn.isCancelled) {
          return const ToolGateDecision.deny(reason: withdrawnReason);
        }
        // A script that already used its asks, or was declined once, is
        // refused without a card: a denial nobody was asked about.
        if (budget?.refusal case final refusal?) {
          auditOutcome(ActionDecision.deny, budgetRefusal: refusal);
          return ToolGateDecision.deny(reason: refusal);
        }
        // Policy asks here (the dial never asks on its own once policy
        // allows), and the resolution above already let a live standing
        // approval answer it.
        final approved = await ask(
          port,
          ActionGuardService.approvalRequest(
            resolution: resolution,
            classes: tool.actionClasses,
            request: actionRequest,
            spaceId: spaceId,
            conversationId: conversationId,
            workspaceId: workspaceId,
            agentId: agentId,
            actionSummary: tool.name,
            kind: tool.approvalTier == ToolApprovalTier.exec
                ? ConfirmationKind.command
                : ConfirmationKind.fileWrite,
            withdrawn: request.withdrawn.whenCancelled,
            origin: _scriptOriginOf(origin, origins),
            runId: runLogId,
            onUnanswered: () => unanswered = true,
          ),
        );
        if (approved == null) {
          // The card came down unanswered. Whatever the port said, no
          // person allowed this, and the call is not run.
          auditOutcome(ActionDecision.deny, asked: true);
          return const ToolGateDecision.deny(reason: unansweredReason);
        }
        auditOutcome(
          approved ? ActionDecision.allow : ActionDecision.deny,
          asked: true,
        );
        return approved
            ? const ToolGateDecision.allow(askedPerson: true)
            : const ToolGateDecision.deny(
                reason: 'the operator declined this action',
                askedPerson: true,
              );
      }

      if (profile.pinnedVerbs.contains(tool.name)) {
        return const ToolGateDecision.allow();
      }
      if (autonomy == 'proposeOnly') {
        return const ToolGateDecision.deny(
          reason: 'this space\'s autonomy is set to propose-only',
          remediation:
              'Propose the action in a message instead and let '
              'the operator run it.',
        );
      }
      if (autonomy == 'actFreely') {
        return const ToolGateDecision.allow();
      }
      if (port == null) {
        return const ToolGateDecision.deny(
          reason: 'approval is required but no approver is connected',
        );
      }
      if (request.withdrawn.isCancelled) {
        return const ToolGateDecision.deny(reason: withdrawnReason);
      }
      if (budget?.refusal case final refusal?) {
        return ToolGateDecision.deny(reason: refusal);
      }
      // No policy was consulted (no guard, or a tool with no effect
      // classes), so there is nothing a standing approval could rest on.
      final approved = await ask(
        port,
        ActionGuardService.approvalRequest(
          resolution: null,
          classes: tool.actionClasses,
          request: const ActionRequestExtractor().extract(
            args,
            classes: tool.actionClasses,
            tool: tool.name,
          ),
          spaceId: spaceId,
          conversationId: conversationId,
          workspaceId: workspaceId,
          agentId: agentId,
          actionSummary: tool.name,
          kind: tool.approvalTier == ToolApprovalTier.exec
              ? ConfirmationKind.command
              : ConfirmationKind.fileWrite,
          runId: runLogId,
          withdrawn: request.withdrawn.whenCancelled,
          origin: _scriptOriginOf(origin, origins),
          onUnanswered: () => unanswered = true,
        ),
      );
      if (approved == null) {
        return const ToolGateDecision.deny(reason: unansweredReason);
      }
      return approved
          ? const ToolGateDecision.allow(askedPerson: true)
          : const ToolGateDecision.deny(
              reason: 'the operator declined this action',
              askedPerson: true,
            );
    }

    // The top-level loop's binding; each subagent binds [approvalWith] to
    // its own origins.
    Future<ToolGateDecision> approval(ToolApprovalRequest request) =>
        approvalWith(scriptOrigins, request);

    final harnessToolEnv = <String, String>{..._run.identity.gitEnv};
    // `bash` pushes through the gateway exactly like a CLI adapter's shell.
    final lease = _gatewayLease;
    if (lease != null) {
      harnessToolEnv.addAll(_leaseEnvironment(lease, harnessToolEnv));
    }

    final hookFolder = _hookFolder;
    final runConfig = await HarnessRunConfig.load([
      agentDirHostPath,
      agentConfigDir,
    ], hookBase: hookFolder);
    // The run's cost cap, whatever started it: the loop stops at the cap and
    // is told to wrap up at [kRunCostWrapUpTenths] of it. No cap, no check.
    final sessionCostCapMicros = costCapMicros;
    final bool Function()? budgetExceeded = sessionCostCapMicros == null
        ? null
        : () => accounting.subtreeCostMicros >= sessionCostCapMicros;

    // Built further down; declared here so the subagent spawners (which run
    // only once the loop is going) hand them to every nested run.
    Advisor? advisor;
    AgentLoopHooks? hooks;

    // 2. Assemble tools. Whether the run has `repl` is decided once, here,
    //    for the run and every subagent it spawns: exactly when this server
    //    runs scripts.
    final scripts = await _codeModeScripts();
    final scriptExecutions = scripts.executions;
    final registry = _buildHarnessRegistry(
      mode: effectiveMode,
      env: harnessToolEnv,
      personalMcp: await _personalMcpAllowed(),
      scriptOrigins: scriptOrigins,
      replSlot: scriptExecutions != null,
    );

    final subagentCatalog = await _subagentCatalog();
    registry.register(
      TaskTool(
        catalog: subagentCatalog,
        _ClosureSubagentSpawner(
          (req) => _spawnSubagent(
            req,
            depth: 1,
            parentType: null,
            parentRunId: runLogId,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
            parentAccounting: accounting,
            runConfig: runConfig,
            budgetExceeded: budgetExceeded,
            baseSystemPrompt: baseSystem,
            approvalWith: approvalWith,
            scriptRefusal: scriptRefusal,
            parentAdvisor: advisor,
            parentHooks: hooks,
          ),
        ),
      ),
    );
    // A read-only run calls only what changes nothing, whatever its mode.
    final surface = readOnly
        ? ReadOnlyRunProfile.toolSurfaceOver(registry.tools)
        : profile.toToolSurfaceSpec();
    final toolSurface = materializeHarnessToolSurface(
      registry: registry,
      surface: surface,
      residency: profile.toToolResidencySpec(enabled: deps.toolDeferralEnabled),
    );
    var tools = toolSurface.resident;
    var deferredTools = toolSurface.deferred;
    var scriptTools = toolSurface.scriptOnly;

    final vibeRoster = _vibeRoster;
    final workerRuns = <Future<SubagentResult>>{};
    if (vibeRoster != null && !readOnly) {
      final vibeTools = buildVibeTools(
        roster: vibeRoster,
        runner: _ClosureVibeRunner((worker, brief, ctx, type, model) async {
          final run = _spawnSubagent(
            SubagentSpawnRequest(
              description: brief,
              label: 'vibe:${worker.label}',
              type: type,
              context: ctx.withCancel(
                CancellationToken.any([_cancelSource.token, worker.cancel]),
              ),
              modelOverride: model,
              spawnToolCallId: ctx.toolCallId,
            ),
            depth: 1,
            parentType: null,
            parentRunId: runLogId,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
            parentAccounting: accounting,
            runConfig: runConfig,
            budgetExceeded: budgetExceeded,
            baseSystemPrompt: baseSystem,
            approvalWith: approvalWith,
            scriptRefusal: scriptRefusal,
            parentAdvisor: advisor,
            parentHooks: hooks,
          );
          workerRuns.add(run);
          try {
            return await run;
          } finally {
            workerRuns.remove(run);
          }
        }),
      );
      tools = [
        for (final tool in toolSurface.resident)
          if (tool.approvalTier == ToolApprovalTier.read && tool.name != 'task')
            tool,
        ...vibeTools,
      ];
      deferredTools = const [];
      // The orchestrator keeps only read-tier residents, so a script there
      // can call only those: `repl` is read tier and stays, the script-only
      // list goes with the deferred one.
      scriptTools = const [];
    }
    // The run's own `repl`, built for exactly what the loop will admit for a
    // nested call. After the vibe narrowing, so a script there is told about
    // the read-tier tools it can actually reach.
    // A script is recorded under its run's row before it starts, so a run
    // without one (its row could not be written) gets no `repl`: its tools
    // are all called directly instead.
    if (scriptExecutions != null &&
        !hasRunLogRow &&
        tools.any((t) => t.name == ReplToolDescription.toolName)) {
      tools = withoutReplTool(resident: tools, scriptOnly: scriptTools);
      scriptTools = const [];
      addEvent(
        DebugEvent(
          content:
              '[harness] this run has no run log, so its scripts could not be '
              'recorded: it has no repl, and calls its tools directly.',
        ),
      );
    } else if (scriptExecutions != null) {
      tools = bindReplTool(
        resident: tools,
        scriptOnly: scriptTools,
        binding: ReplBinding(
          executions: scriptExecutions.forLoop(scriptOrigins),
          run: _replRun(wsId, codeModeRunId),
          limits: scripts.limits,
          fullOutputSink: _replOutputSink(agentId),
        ),
      );
    }

    _bindToolForms(tools, deferredTools, scriptTools);
    // 4. Run the loop, translating events to AgentProcessEvents.
    final qualifiedModel =
        '$providerId/${parsed.model ?? provider.defaultModel}';
    final modelInfo = deps.modelResolver?.call(qualifiedModel);
    final effectiveEffort = _raiseEffort(
      _resolveHarnessEffort(modelInfo),
      magicKeywordEffort(magic),
    );
    final capabilityBlock = buildCapabilityPreamble(
      profile,
      materializedToolNames: [for (final t in tools) t.name],
      deferredToolNames: [for (final t in deferredTools) t.name],
      hasRepl: tools.any((t) => t.name == ReplToolDescription.toolName),
      scriptToolNames: [for (final t in scriptTools) t.name],
    );
    final systemPrompt = [
      baseSystem,
      capabilityBlock,
      if (commandDirectives.isNotEmpty) commandDirectives.toString().trim(),
    ].where((part) => part.trim().isNotEmpty).join('\n\n');
    _recordRunComposition(
      toolNames: [for (final t in tools) t.name],
      deferredToolNames: [for (final t in deferredTools) t.name],
      mode: effectiveMode.name,
      model: qualifiedModel,
      adapter: 'cc-harness',
      systemPrompt: systemPrompt,
      toolSchemaTokens: estimateToolSchemaTokens(tools),
      effort: effectiveEffort?.name,
      scriptsUnavailable:
          tools.any((t) => t.name == ReplToolDescription.toolName)
          ? null
          : scripts.error ??
                'this run has no run log, so its scripts could not be '
                    'recorded',
      scriptToolNames: [for (final t in scriptTools) t.name],
    );

    _reportHookConfig(runConfig, hookFolder);
    if (runConfig.advisorEnabled) {
      final watchdogContext = await loadWatchdogContext(
        agentDirHostPath,
        agentConfigDir: agentConfigDir,
      );
      final roster = await const WatchdogRosterLoader().load(
        agentDirHostPath,
        agentConfigDir: agentConfigDir,
      );
      String attentionFor(String extra) {
        final parts = [
          if (watchdogContext.attention case final a? when a.isNotEmpty) a,
          if (roster.shared.isNotEmpty) roster.shared,
          if (extra.isNotEmpty) extra,
        ];
        return parts.join('\n\n');
      }

      final advisorProviders = <String, LlmProviderPort>{};
      Future<LlmProviderPort> providerForAdvisor(String? model) async {
        if (model == null || model.isEmpty) {
          return provider;
        }
        final cached = advisorProviders[model];
        if (cached != null) {
          return cached;
        }
        final factory = deps.harnessProviderFactory;
        final target = factory.parseModel(model, defaultProvider: providerId);
        final targetCredential = await _resolveHarnessCredential(
          target.providerId,
        );
        final targetProvider = await _buildHarnessProvider(
          factory: factory,
          primaryProviderId: target.providerId,
          primaryModel: target.model,
          primaryCredential: targetCredential,
          extraSpecs: const [],
        );
        return advisorProviders[model] = accounting.observe(
          targetProvider,
          providerId: target.providerId,
        );
      }

      if (roster.advisors.isEmpty) {
        advisor = WatchdogAdvisor(
          await providerForAdvisor(runConfig.advisorModel),
          attention: attentionFor(''),
          projectContext: watchdogContext.projectContext,
          extraInstructions: runConfig.advisorInstructions,
        );
      } else {
        advisor = AdvisorPanel([
          for (final entry in roster.advisors)
            WatchdogAdvisor(
              await providerForAdvisor(entry.model ?? runConfig.advisorModel),
              attention: attentionFor(entry.instructions),
              projectContext: watchdogContext.projectContext,
              extraInstructions: runConfig.advisorInstructions,
            ),
        ]);
        addEvent(
          DebugEvent(
            content:
                '[harness] advisor panel: '
                '${roster.advisors.map((a) => a.name).join(', ')}',
          ),
        );
      }
    }
    hooks = runConfig.hasHooks && hookFolder != null
        ? ShellAgentLoopHooks(
            cwd: agentDirHostPath,
            start: _hookProcesses(effectiveMode, hookFolder).start,
            sessionStartScript: runConfig.hookSessionStart,
            preToolScript: runConfig.hookPreTool,
            postToolScript: runConfig.hookPostTool,
            stopScript: runConfig.hookStop,
            preCompactScript: runConfig.hookPreCompact,
            denyTools: runConfig.preToolRefused,
            onWarning: (message) => CcInfraLog.warning('harness hooks: $message'),
          )
        : null;

    final generation =
        credential?.generation ?? const ProviderGenerationDefaults();
    // The model's window, capped by the agent's own setting: a context size
    // is an override down, never a promise the model cannot keep.
    final modelWindow = modelInfo?.limits.context ?? 128000;
    final override = contextWindowTokens;
    window = override != null && override > 0 && override < modelWindow
        ? override
        : modelWindow;
    // The resumed transcript is loaded FIRST: the config seeds its snapshot
    // source from it (so an image from the previous run can still be recovered)
    // and carries the delivered-context cursor whose update the loop persists
    // with every save.
    final resumed = await _loadResumeTranscript();

    final config = AgentLoopConfig(
      systemPrompt: systemPrompt,
      model: parsed.model,
      maxTurns: commandMaxTurns,
      maxTokens: generation.maxTokens ?? defaultHarnessMaxTokens,
      temperature: generation.temperature,
      topP: generation.topP,
      topK: generation.topK,
      effort: effectiveEffort,
      cacheKey: conversationId,
      tools: LoopToolConfig(
        toolTimeout: const Duration(minutes: 30),
        approvalCallback: approval,
        nestedCallRefusal: scriptRefusal,
        maxParallelToolCalls: runConfig.maxParallelToolCalls,
        overlapReadOnlyTools: runConfig.overlapReadOnlyTools,
        observationIngest: ToolObservationIngest(
          store: _outputs,
          retainMinTokens:
              runConfig.compaction.policy == CompactionPolicy.current
              ? 0
              : kToolOutputRetentionMinTokens,
        ),
        autoApprove: false,
      ),
      guards: LoopGuardConfig(
        callLedger: accounting.ledger,
        contract: profile.toCompletionContract(),
        externalBudgetExceeded: budgetExceeded,
        externalBudgetPressure: sessionCostCapMicros == null
            ? null
            : () =>
                  accounting.subtreeCostMicros * 10 >=
                  sessionCostCapMicros * kRunCostWrapUpTenths,
      ),
      compaction: LoopCompactionConfig(
        tokenCalibration: deps.tokenCalibration,
        contextWindow: window,
        compactor: buildHarnessCompactor(
          summaryProvider: provider,
          providerId: providerId,
          modelId: parsed.model ?? provider.defaultModel,
          config: runConfig.compaction,
          calibration: deps.tokenCalibration,
          readerHasVision: modelInfo?.supportsImageInput ?? false,
          // Seed the source the previous run left behind, so an image it
          // retained can still be recovered by this run's compactions.
          retainedSnapshotSource: resumed?.retainedSnapshotSource,
          preferSnapshots: runConfig.snapshotCompaction,
        ),
        inFlightLines: stillInFlightLines,
        clock: clock.now,
      ),
      steering: LoopSteeringConfig(
        pauseGate: _harness.pauseGate,
        streamRules: runConfig.streamRules,
        advisor: advisor,
        advisorEveryTurns: runConfig.advisorEveryTurns,
        hooks: hooks,
        // The owner's `stop` and `preCompact` scripts: the main run only (a
        // subagent's config sets none, so it never inherits them).
        // The server's would-stop handlers first, then the owner's.
        turnHooks: ServerTurnHooks.compose(
          deps.wouldStopHandlers,
          this,
          owner: hooks,
        ),
        queue: _steering,
        requestOrigin: harnessRequestOrigin(userText, wakeContext),
      ),
      transcript: LoopTranscriptConfig(
        store: deps.transcriptStore,
        key: _transcriptKey,
        initialCheckpoints: _harness.resumedCheckpoints,
        initialSnapshotSource: resumed?.retainedSnapshotSource,
        metadata: _promptCursorMetadata(resumed),
      ),
    );
    final context = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      readOnlyRoots: _readOnlyRoots,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: spaceId,
    );

    final history = <HarnessMessage>[...?resumed?.messages];
    // Fresh turns need the complete assembled context. A resumed turn uses a
    // delta only when its cursor is known and no slash command replaced the
    // input; otherwise append the full contextual input without losing history.
    final cursorMetadata = resumed?.metadata[_promptCursorMetadataKey];
    final standingUnchanged =
        cursorMetadata is Map &&
        cursorMetadata['standingRevision'] == promptParts?.standingRevision;
    final resumeDelta =
        history.isEmpty || effectivePrompt != prompt || !standingUnchanged
        ? null
        : promptParts?.deltaPromptFor(_deliveredPromptCursor(resumed));
    final promptForRun = resumeDelta ?? effectivePrompt;

    var exitCode = 0;
    Object? runFailure;
    CompletionContract? contractUnmet;
    _markRunStarted();
    addEvent(
      StageTimingEvent(
        stage: RunStage.runtimeReady,
        offsetMs: accounting.runOffsetMs + accounting.elapsedMs,
        source: RunTimingSource.harness,
      ),
    );
    var usefulWorkStarted = false;

    void markUsefulWork() {
      if (usefulWorkStarted) {
        return;
      }
      usefulWorkStarted = true;
      addEvent(
        StageTimingEvent(
          stage: RunStage.firstUsefulText,
          offsetMs: accounting.runOffsetMs + accounting.elapsedMs,
          source: RunTimingSource.harness,
        ),
      );
    }

    try {
      await for (final event in deps.agentLoop.run(
        history: history,
        userMessage: promptForRun,
        userImages: await _loadPromptImages(),
        tools: tools,
        deferredTools: deferredTools,
        scriptTools: scriptTools,
        provider: provider,
        context: context,
        config: config,
        cancel: _cancelSource.token,
      )) {
        if (event is LoopToolCallStart ||
            (event is LoopTextDelta && event.text.trim().isNotEmpty)) {
          markUsefulWork();
        }
        // Text, thinking, retractions, tool calls/results and errors map the
        // same way for every host; see harnessTranscriptEvent.
        final transcriptEvent = await harnessTranscriptEvent(
          event,
          imageRefs: _toolImageRefs,
        );
        if (transcriptEvent != null) {
          addEvent(transcriptEvent);
        }
        switch (event) {
          case LoopTextDelta() ||
              LoopThinkingDelta() ||
              LoopToolCallStart() ||
              LoopToolCallResult():
            break;
          case LoopTurnDiscarded(:final reason):
            // The retraction above drops the abandoned attempt's deltas, or
            // the retried answer would render after a half-written copy.
            addEvent(
              DebugEvent(
                content:
                    '[harness] discarded a partial model attempt '
                    '(${reason ?? 'retry'}).',
              ),
            );
          case LoopUsage():
            // The provider boundary owns usage, including retries and auxiliary
            // calls. Banking this compatibility event would count main twice.
            break;
          case LoopNotice(:final message):
            addEvent(DebugEvent(content: '[harness] $message'));
          case LoopToolsActivated(:final names, :final trigger):
            _harness.activatedToolNames.addAll(names);
            addEvent(
              DebugEvent(
                content:
                    '[harness] loaded ${names.length} deferred tool'
                    '${names.length == 1 ? '' : 's'} via $trigger: '
                    '${names.join(', ')}',
              ),
            );
          case LoopAdvisorNote(:final note, :final severity):
            addEvent(
              DebugEvent(
                content: '[harness] advisor (${severity.name}): $note',
              ),
            );
          case LoopCompaction(
            :final summarized,
            :final messagesFolded,
            :final tokensBefore,
            :final tokensAfter,
          ):
            // `summarized` is a MODEL-written summary only; a structural
            // digest still folds history, so it counts as a compaction too.
            if (summarized || messagesFolded > 0) {
              compactions++;
            }
            addEvent(
              DebugEvent(
                content:
                    '[harness] context '
                    '${summarized
                        ? 'compacted'
                        : messagesFolded > 0
                        ? 'folded'
                        : 'pruned'}: '
                    '$messagesFolded messages folded, '
                    '$tokensBefore→$tokensAfter tokens.',
              ),
            );
          case LoopError(:final message, :final code):
            exitCode = 1;
            // A spent balance or quota after the provider chain ran out of
            // credentials to fall back to: the run ended on a usage limit.
            if (LlmErrorKind.classify(code: code, message: message) ==
                LlmErrorKind.quota) {
              _markEndReason(RunEndReason.usageLimit);
            }
          case LoopDone(:final reason, :final unmetContractId):
            if (reason == LoopDoneReason.budgetExhausted) {
              _markEndReason(RunEndReason.budget);
              addEvent(
                DebugEvent(content: '[harness] stopped: budget exhausted.'),
              );
            } else if (reason == LoopDoneReason.error) {
              // The loop pairs every failure with a LoopError, which already
              // set this; keyed here too so a failure can never exit 0.
              exitCode = 1;
            } else if (reason == LoopDoneReason.providerOutputLost) {
              exitCode = 1;
              addEvent(
                DebugEvent(
                  content:
                      '[harness] stopped: the provider discarded this '
                      "turn's output (truncated mid-tool-call).",
                ),
              );
            }
            final unmet = unmetContractId == null
                ? null
                : profile.toCompletionContract();
            if (unmet != null) {
              contractUnmet = unmet;
              addEvent(TextEvent(content: '\n\n_${unmet.unmetSummary}_'));
              addEvent(
                DebugEvent(
                  content:
                      '[harness] completion contract "$unmetContractId" '
                      'unmet after ${reason.name}.',
                ),
              );
            }
          case LoopTurnComplete():
            break;
          case LoopCompacting(:final started):
            _noteCompacting(started: started);
          case LoopPark(:final parked, :final reason):
            _noteLoopPark('main', parked: parked);
            addEvent(
              DebugEvent(
                content: parked
                    ? '[harness] waiting for $reason to finish before the '
                          'turn ends (no model call meanwhile).'
                    : '[harness] done waiting for $reason.',
              ),
            );
        }
      }
      final unmetAtClose = contractUnmet;
      if (unmetAtClose != null) {
        await _markContractUnmet(unmetAtClose);
      }
    } on Object catch (e) {
      exitCode = 1;
      runFailure = e;
      addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
    } finally {
      _noteLoopPark('main', parked: false);
      _noteCompacting(started: false);
      _harness.end();
      for (final kernel in _kernels.values) {
        unawaited(kernel.dispose());
      }
      _kernels.clear();
      final killed = _vibeRoster?.killAll() ?? 0;
      if (killed > 0) {
        addEvent(
          TextEvent(content: '\n[vibe] stopped $killed worker(s) on exit.\n'),
        );
      }
      _vibeRoster = null;
      while (workerRuns.isNotEmpty) {
        try {
          await workerRuns.first;
        } on Object catch (error) {
          CcInfraLog.warning('Worker shutdown failed: $error');
        }
      }
      // A script still running (the loop ended under it, or threw) is
      // cancelled, and its runner is gone, before the run reports itself
      // finished.
      await _bestEffort('script teardown', _endScripts);
      await _retireOutputs();
      await accounting.flush();
      // Also after a stop already finished the run: a tool call still
      // unwinding then may have opened a session again.
      await _bestEffort('tool sandbox release', _releaseToolProcesses);
      _finish(exitCode: exitCode, error: runFailure);
      await _finishing;
    }
  }

  /// What this run's `repl` tools run scripts with, set up once and shared by
  /// its subagents (each binds its own loop's origins with
  /// [RunCodeExecutions.forLoop]), so one close ends every loop's scripts.
  /// No script tool when this server runs no scripts (no execution service,
  /// or a runner that failed its self-test) or the run has no workspace;
  /// none either when the workspace's limits cannot be read, because running
  /// under the built-in defaults could exceed limits a workspace admin
  /// lowered.
  Future<_CodeModeScripts> _codeModeScripts() =>
      _codeModeScriptsSetup ??= _openCodeModeScripts();

  Future<_CodeModeScripts> _openCodeModeScripts() async {
    final service = deps.codeExecutions;
    final ws = workspaceId;
    String? unavailable;
    if (service == null) {
      unavailable = 'this server runs no scripts';
    } else if (!service.availability.isAvailable) {
      // The runner's own reason can name a host path; the status page
      // gives the public one.
      unavailable = 'the script runner is unavailable on this server';
    } else if (ws == null || ws.isEmpty) {
      unavailable = 'the run has no workspace';
    }
    if (service == null || unavailable != null || ws == null) {
      return (
        executions: null,
        limits: CodeModeLimits.defaults,
        error: unavailable,
      );
    }
    final CodeModeLimits limits;
    try {
      limits = await deps.codeModeLimits?.call(ws) ?? CodeModeLimits.defaults;
    } on Object catch (e, st) {
      // Workspace members read both texts below; what the store threw can
      // name a host path, so it goes to the server log only.
      CcInfraLog.error('code mode limits could not be read', e, st);
      addEvent(
        DebugEvent(
          content:
              '[harness] code mode limits could not be read (the server log '
              'has the reason); the run has no script tool.',
        ),
      );
      return (
        executions: null,
        limits: CodeModeLimits.defaults,
        error:
            'code mode limits could not be read (the server log has the '
            'reason)',
      );
    }
    return (
      executions: _scripts ??= RunCodeExecutions(
        service,
        gateway: _gatewayLease,
      ),
      limits: limits,
      error: null,
    );
  }

  /// Where a `repl` result's full output goes when it is over its budget: the
  /// run's tool-output store, under the scope `read_output` reads with for a
  /// tool context whose agent is [contextAgentId]. Null without a store or a
  /// workspace.
  ReplFullOutputSink? _replOutputSink(String? contextAgentId) {
    final store = _outputs;
    final ws = workspaceId;
    if (store == null || ws == null || ws.isEmpty) {
      return null;
    }
    final scope = ToolOutputScope(
      workspaceId: ws,
      conversationId: conversationId,
      agentId: contextAgentId,
    );
    return (text) => store.put(
      ToolOutputWrite(
        scope: scope,
        toolName: ReplToolDescription.toolName,
        content: text,
      ),
    );
  }

  /// [id] when it names something, else null: a code execution records real
  /// ids or none.
  static String? _realId(String? id) => id == null || id.isEmpty ? null : id;

  /// The origin an approval card shows for a call a script made, or null for
  /// a call the model made directly. The execution is the one the script
  /// runs as, in [origins]: the origins of the loop that made the call.
  ScriptCallOrigin? _scriptOriginOf(
    ToolCallOrigin origin,
    RunScriptOrigins origins,
  ) {
    final parent = origin.parentToolUseId;
    if (parent == null || parent.isEmpty) {
      return null;
    }
    return origins.originOf(parent);
  }

  void _emitHarnessProviderCall(
    ProviderCallRecord record, {
    required HarnessRunAccounting accounting,
    required void Function(AgentProcessEvent) emit,
    int? contextWindow,
    int compactions = 0,
  }) {
    final usage = record.usage;
    emit(
      UsageEvent(
        usage: RunUsage(
          inputTokens: usage.inputTokens,
          outputTokens: usage.outputTokens,
          thoughtTokens: usage.thoughtTokens,
          cachedReadTokens: usage.cacheReadTokens,
          cachedWriteTokens: usage.cacheWriteTokens,
          costMicros: record.costMicros ?? 0,
          costBasis: CostBasis.fromWire(record.costBasis.wire),
        ),
        purpose: domain_purpose.LlmCallPurpose.fromWire(record.purpose.wire),
        provider: record.providerId,
        modelId: record.model,
        requestId: record.requestId,
        attempt: record.attempt,
      ),
    );
    if (record.purpose != LlmCallPurpose.main &&
        record.purpose != LlmCallPurpose.subagent) {
      return;
    }
    final requestOffset = accounting.runOffsetMs + record.startedAtMs;
    final requestIdentity = '${record.requestId}:${record.attempt}';
    if (record.requestSentMs case final sent?) {
      emit(
        StageTimingEvent(
          stage: RunStage.requestSent,
          offsetMs: requestOffset + sent,
          source: RunTimingSource.transport,
          provider: record.providerId,
          modelId: record.model,
          requestId: requestIdentity,
        ),
      );
    }
    if (record.transportFirstByteMs case final firstByte?) {
      emit(
        StageTimingEvent(
          stage: RunStage.firstResponseByte,
          offsetMs: requestOffset + firstByte,
          source: RunTimingSource.transport,
          provider: record.providerId,
          modelId: record.model,
          requestId: requestIdentity,
        ),
      );
    }
    if (record.firstModelEventMs case final firstDelta?) {
      emit(
        StageTimingEvent(
          stage: RunStage.firstModelDelta,
          offsetMs: requestOffset + firstDelta,
          source: RunTimingSource.provider,
          provider: record.providerId,
          modelId: record.model,
          requestId: requestIdentity,
        ),
      );
    }
    if (record.usageReported && contextWindow != null) {
      emit(
        ContextWindowEvent(
          contextTokens:
              usage.inputTokens +
              usage.cacheReadTokens +
              usage.cacheWriteTokens +
              usage.outputTokens,
          windowTokens: contextWindow,
          compactions: compactions,
        ),
      );
    }
  }

  /// The delivered-context cursor the resumed transcript records, or null when
  /// it recorded none (continuity was never established).
  DeliveredPromptContext? _deliveredPromptCursor(HarnessTranscript? t) {
    final raw = t?.metadata[_promptCursorMetadataKey];
    if (raw is! Map) {
      return null;
    }
    List<String> keys(String name) => raw[name] is List
        ? [
            for (final k in raw[name] as List)
              if (k is String) k,
          ]
        : const [];
    final revision = raw['revision'];
    if (revision is! String || revision.isEmpty) {
      return null;
    }
    return DeliveredPromptContext(
      revision: revision,
      conversationKeys: keys('conversationKeys'),
      sectionKeys: keys('sectionKeys'),
      producedRunIds: keys('producedRunIds'),
    );
  }

  /// The transcript metadata for this run: the previous metadata with the
  /// prompt cursor ADVANCED to what this run is about to deliver.
  ///
  /// Advanced at config time on purpose — the loop's first save happens at a
  /// turn boundary, so a run that dies before delivering anything leaves the
  /// stored cursor untouched.
  Map<String, Object?> _promptCursorMetadata(HarnessTranscript? t) {
    final parts = promptParts;
    if (parts == null) {
      return {...?t?.metadata};
    }
    return {
      ...?t?.metadata,
      _promptCursorMetadataKey: {
        'revision': parts.conversationRevision,
        'standingRevision': parts.standingRevision,
        'conversationKeys': ClaudeNativeSessionRecord.bound(
          parts.deliveredConversationKeysFor(),
        ),
        'sectionKeys': ClaudeNativeSessionRecord.bound(
          parts.deliveredSectionKeysFor(),
        ),
        'producedRunIds': ClaudeNativeSessionRecord.bound([
          ...?_deliveredPromptCursor(t)?.producedRunIds,
          if (runLogId != null && runLogId!.isNotEmpty) runLogId!,
        ]),
      },
    };
  }

  Future<HarnessTranscript?> _loadResumeTranscript() async {
    final store = deps.transcriptStore;
    final key = _transcriptKey;
    if (store == null || key == null) {
      return null;
    }
    try {
      final loaded = await store.load(key);
      if (loaded == null || loaded.messages.isEmpty) {
        return null;
      }
      final trimmed = trimTranscriptForResume(loaded);
      _harness.resumedCheckpoints = trimmed.checkpoints;
      return trimmed;
    } on Object catch (e) {
      CcInfraLog.warning('transcript resume failed: $e');
      return null;
    }
  }

  Future<List<HarnessImageBlock>> _loadPromptImages() async {
    final store = deps.blobStore;
    final ws = workspaceId;
    if (store == null || ws == null || ws.isEmpty || promptImageRefs.isEmpty) {
      return const [];
    }
    final blocks = <HarnessImageBlock>[];
    for (final ref in promptImageRefs) {
      final hash = blobHashOf(ref);
      if (hash == null) {
        continue;
      }
      try {
        final bytes = await store.read(ws, hash);
        if (bytes == null || bytes.isEmpty) {
          continue;
        }
        blocks.add(
          HarnessImageBlock(
            data: base64Encode(bytes),
            mediaType: await store.mediaTypeFor(ws, hash),
          ),
        );
      } on Object catch (e) {
        CcInfraLog.warning('Failed to load prompt image $ref: $e');
      }
    }
    return blocks;
  }

  Future<List<ToolImageRef>> _toolImageRefs(
    String toolName,
    HarnessToolResult result,
  ) async {
    final refs = renderMediaImageRefs(toolName, result.content);
    if (refs.isNotEmpty) {
      return refs;
    }
    return _externalizeToolImages(result.images);
  }

  Future<List<ToolImageRef>> _externalizeToolImages(
    List<HarnessImageBlock> images,
  ) async {
    final store = deps.blobStore;
    final ws = workspaceId;
    if (store == null || ws == null || ws.isEmpty || images.isEmpty) {
      return const [];
    }
    final refs = <ToolImageRef>[];
    for (final image in images) {
      try {
        final stored = await store.putBase64(
          ws,
          image.data,
          mediaType: image.mediaType,
          creatorId: agentId,
        );
        if (stored != null) {
          refs.add(
            ToolImageRef(
              ref: stored.ref,
              mediaType: stored.mediaType,
              bytes: stored.bytes,
            ),
          );
        }
      } on Object catch (e) {
        CcInfraLog.warning('Failed to store tool-result image: $e');
      }
    }
    return refs;
  }
}
