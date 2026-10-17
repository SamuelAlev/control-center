part of 'dispatch_session.dart';

/// Transcript-metadata key under which the built-in harness persists the
/// delivered-context cursor (a host concern the loop never interprets).
const _promptCursorMetadataKey = 'cc.promptCursor';

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

extension _DispatchSessionHarness on DispatchSession {
  Future<void> _runHarness({
    required ScopedCredentials scoped,
    required String wsId,
  }) async {
    _harnessActive = true;
    // The moment a harness loop becomes drainable: the steering queue service
    // wires this session's drain notifications and flushes any
    // persisted-but-undelivered steering rows into the run here (a queued row
    // written while the session was between transports, or before this
    // dispatch existed, has no other delivery path).
    onHarnessStarted?.call();
    for (final note in scoped.notes) {
      addEvent(DebugEvent(content: '[harness] $note'));
    }

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
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
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
        addEvent(ErrorEvent(content: e.toString(), source: 'harness'));
        unawaited(_closeRunLog(exitCode: 126));
        addEvent(DoneEvent());
        _completeRun();
        return;
      } on Object catch (e) {
        addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
        unawaited(_closeRunLog(exitCode: 127));
        addEvent(DoneEvent());
        _completeRun();
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
    final provider = accounting.observe(built, providerId: providerId);

    // 1b. Slash commands: /plan, /goal, /loop change how the run behaves;
    //     /skill:<name> (or /skill:<repo>:<name>) injects that skill's
    //     instructions; anything else is plain text.
    //
    //     Parsed from `userText` (the user's message verbatim), NOT `prompt`:
    //     a space dispatch layers `prompt` into `<context>…</context>\n\n…`,
    //     which has no leading slash, so parsing it made every built-in
    //     command silently inert on the path that matters most.
    final parsedCommand = parseSlashCommand(userText ?? prompt);
    var effectiveMode = mode;
    var effectivePrompt = prompt;
    // No turn ceiling anywhere: interactive and autonomous runs alike end
    // when the model stops, a budget bites, or a human stops them — the
    // doom-loop repetition guard is the bound on a spinning run, not an
    // arbitrary iteration count.
    int? commandMaxTurns;
    final commandDirectives = StringBuffer();
    if (parsedCommand.isCommand) {
      final applied = await _applySlashCommand(parsedCommand);
      effectiveMode = applied.mode ?? mode;
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
    final magic = detectMagicKeywords(userText ?? prompt);
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
    Future<ToolGateDecision> approval(
      HarnessTool tool,
      Map<String, dynamic> args,
    ) async {
      if (DispatchSession._harnessInteractionTools.contains(tool.name)) {
        return const ToolGateDecision.allow();
      }
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

      if (guard != null && tool.actionClasses.isNotEmpty) {
        final actionRequest = const ActionRequestExtractor().extract(
          args,
          classes: tool.actionClasses,
        );
        final resolution = await guard.resolve(
          workspaceId: wsId,
          classes: tool.actionClasses,
          spaceId: spaceId,
          agentId: agentId,
          mode: effectiveMode,
          request: actionRequest,
        );
        void auditOutcome(ActionDecision applied, {bool asked = false}) {
          guard.recordOutcome(
            workspaceId: wsId,
            resolution: resolution,
            applied: applied,
            classes: tool.actionClasses,
            agentId: agentId,
            spaceId: spaceId,
            actionSummary: tool.name,
            prompted: asked,
            onBehalfOfUserId: requestedByUserId,
            runId: runLogId,
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
        final copy = ActionApprovalCopy.describe(
          classes: tool.actionClasses,
          request: actionRequest,
        );
        final approved = await port.requestApproval(
          ConfirmationRequest(
            spaceId: spaceId ?? '',
            workspaceId: workspaceId,
            title: copy.title,
            detail: copy.detail,
            command: actionRequest.command,
            kind: tool.approvalTier == ToolApprovalTier.exec
                ? ConfirmationKind.command
                : ConfirmationKind.fileWrite,
          ),
        );
        auditOutcome(
          approved ? ActionDecision.allow : ActionDecision.deny,
          asked: true,
        );
        return approved
            ? const ToolGateDecision.allow()
            : const ToolGateDecision.deny(
                reason: 'the operator declined this action',
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
      final actionRequest = const ActionRequestExtractor().extract(
        args,
        classes: tool.actionClasses,
      );
      final copy = ActionApprovalCopy.describe(
        classes: tool.actionClasses,
        request: actionRequest,
      );
      final approved = await port.requestApproval(
        ConfirmationRequest(
          spaceId: spaceId ?? '',
          workspaceId: workspaceId,
          title: copy.title,
          detail: copy.detail,
          command: actionRequest.command,
          kind: tool.approvalTier == ToolApprovalTier.exec
              ? ConfirmationKind.command
              : ConfirmationKind.fileWrite,
        ),
      );
      return approved
          ? const ToolGateDecision.allow()
          : const ToolGateDecision.deny(
              reason: 'the operator declined this action',
            );
    }

    final harnessToolEnv = <String, String>{
      ...scoped.environment,
      ..._gitIdentityEnv,
    };
    // `bash` pushes through the gateway exactly like a CLI adapter's shell.
    final lease = _gatewayLease;
    if (lease != null) {
      harnessToolEnv.addAll(lease.environment(harnessToolEnv));
    }

    final runConfig = await HarnessRunConfig.load(
      [agentDirHostPath, agentConfigDir],
      hookTrustedBases: [agentConfigDir],
    );
    final sessionCostCapMicros =
        (costCapCents ?? defaultRunCostCapCents) * 10000;
    final bool Function()? budgetExceeded = switch (parsedCommand.command) {
      'goal' ||
      'loop' => () => accounting.subtreeCostMicros >= sessionCostCapMicros,
      _ => null,
    };

    // 2. Assemble tools.
    final registry = _buildHarnessRegistry(
      mode: effectiveMode,
      env: harnessToolEnv,
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
            approval: approval,
          ),
        ),
      ),
    );
    final surface = profile.toToolSurfaceSpec();
    final partition = materializeHarnessToolSurface(
      registry: registry,
      surface: surface,
      residency: profile.toToolResidencySpec(enabled: deps.toolDeferralEnabled),
    );
    var tools = partition.resident;
    var deferredTools = partition.deferred;

    final vibeRoster = _vibeRoster;
    final workerRuns = <Future<SubagentResult>>{};
    if (vibeRoster != null) {
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
            approval: approval,
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
        for (final tool in partition.resident)
          if (tool.approvalTier == ToolApprovalTier.read && tool.name != 'task')
            tool,
        ...vibeTools,
      ];
      deferredTools = const [];
    }

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
    );

    if (runConfig.droppedHookBase != null) {
      addEvent(
        DebugEvent(
          content:
              '[harness] ignoring shell hooks declared by '
              '${runConfig.droppedHookBase}/.agents/harness.json — hooks are '
              'only honored from your own agent config dir, never from a '
              "repository's working tree.",
        ),
      );
    }
    Advisor? advisor;
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
    final hooks = runConfig.hasHooks
        ? ShellAgentLoopHooks(
            cwd: agentDirHostPath,
            sessionStartScript: runConfig.hookSessionStart,
            preToolScript: runConfig.hookPreTool,
            postToolScript: runConfig.hookPostTool,
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
      toolTimeout: const Duration(minutes: 30),
      approvalCallback: approval,
      callLedger: accounting.ledger,
      tokenCalibration: deps.tokenCalibration,
      maxParallelToolCalls: runConfig.maxParallelToolCalls,
      overlapReadOnlyTools: runConfig.overlapReadOnlyTools,
      observationIngest: ToolObservationIngest(
        store: deps.toolOutputStore,
        retainMinTokens: runConfig.compaction.policy == CompactionPolicy.current
            ? 0
            : kToolOutputRetentionMinTokens,
      ),
      autoApprove: false,
      pauseGate: _pauseGate,
      contract: profile.toCompletionContract(),
      budget: const HarnessBudget(),
      externalBudgetExceeded: budgetExceeded,
      externalBudgetPressure: switch (parsedCommand.command) {
        'goal' || 'loop' =>
          () => accounting.subtreeCostMicros * 5 >= sessionCostCapMicros * 4,
        _ => null,
      },
      streamRules: runConfig.streamRules,
      advisor: advisor,
      advisorEveryTurns: runConfig.advisorEveryTurns,
      hooks: hooks,
      steering: _steering,
      contextWindow: window,
      compactor: SnapcompactCompactor(
        fallback: DefaultHarnessCompactor(
          summarizer: LlmHarnessSummarizer(provider),
          config: runConfig.compaction,
          calibration: deps.tokenCalibration,
          providerId: providerId,
          modelId: parsed.model ?? provider.defaultModel,
          economics: CompactionEconomics(
            cache: ProviderCacheEconomics.forProvider(providerId),
          ),
        ),
        modelId: qualifiedModel,
        readerHasVision: modelInfo?.supportsImageInput ?? false,
        providerId: providerId,
        // Seed the source the previous run left behind, so an image it
        // retained can still be recovered by this run's compactions.
        retainedSource: resumed?.retainedSnapshotSource,
        preferSnapshots: runConfig.snapshotCompaction,
        config: runConfig.compaction,
      ),
      transcriptStore: deps.transcriptStore,
      transcriptKey: _transcriptKey,
      initialCheckpoints: _resumedCheckpoints,
      initialSnapshotSource: resumed?.retainedSnapshotSource,
      transcriptMetadata: _promptCursorMetadata(resumed),
    );
    final context = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
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
        provider: provider,
        context: context,
        config: config,
        cancel: _cancelSource.token,
      )) {
        switch (event) {
          case LoopTextDelta(:final text):
            if (text.trim().isNotEmpty) {
              markUsefulWork();
            }
            addEvent(TextEvent(content: text));
          case LoopThinkingDelta(:final thinking):
            addEvent(ThinkingEvent(content: thinking));
          case LoopToolCallStart(
            :final toolName,
            :final toolUseId,
            :final args,
          ):
            markUsefulWork();
            addEvent(
              ToolCallEvent(
                toolName: toolName,
                toolCallId: toolUseId,
                inputs: args,
              ),
            );
          case LoopToolCallResult(
            :final toolName,
            :final toolUseId,
            :final result,
          ):
            addEvent(
              ToolResultEvent(
                toolCallId: toolUseId,
                outputs: result.content,
                toolName: toolName,
                isError: result.isError,
                images: await _toolImageRefs(toolName, result),
              ),
            );
          case LoopUsage():
            // The provider boundary owns usage, including retries and auxiliary
            // calls. Banking this compatibility event would count main twice.
            break;
          case LoopNotice(:final message):
            addEvent(DebugEvent(content: '[harness] $message'));
          case LoopToolsActivated(:final names, :final trigger):
            _activatedToolNames.addAll(names);
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
            if (summarized) {
              compactions++;
            }
            addEvent(
              DebugEvent(
                content:
                    '[harness] context '
                    '${summarized ? 'compacted' : 'pruned'}: '
                    '$messagesFolded messages folded, '
                    '$tokensBefore→$tokensAfter tokens.',
              ),
            );
          case LoopError(:final message, :final code):
            exitCode = 1;
            addEvent(
              ErrorEvent(content: message, code: code, source: 'harness'),
            );
          case LoopDone(:final reason, :final unmetContractId):
            if (reason == LoopDoneReason.budgetExhausted) {
              addEvent(
                DebugEvent(content: '[harness] stopped: budget exhausted.'),
              );
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
      _harnessActive = false;
      _pauseGate.resume();
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
      await accounting.flush();
      try {
        await _closeRunLog(exitCode: exitCode, error: runFailure);
      } on Object catch (error) {
        CcInfraLog.warning('Harness run-log close failed: $error');
      }
      addEvent(DoneEvent());
      _completeRun();
    }
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
          estimatedCostCents: ((record.costMicros ?? 0) / 10000).round(),
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
      _resumedCheckpoints = trimmed.checkpoints;
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
