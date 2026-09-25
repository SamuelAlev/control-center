part of 'dispatch_session.dart';

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
    required AgentCapabilities caps,
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

    final LlmProviderPort provider;
    try {
      provider = await _buildHarnessProvider(
        factory: factory,
        primaryProviderId: providerId,
        primaryModel: parsed.model,
        primaryCredential: credential,
        extraSpecs: modelSpecs.length > 1 ? modelSpecs.sublist(1) : const [],
      );
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
      unawaited(_closeRunLog(exitCode: 127));
      addEvent(DoneEvent());
      _completeRun();
      return;
    }

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
    final ToolApprovalCallback? approval = port == null
        ? null
        : (tool, args) async {
            if (DispatchSession._harnessInteractionTools.contains(tool.name)) {
              return const ToolGateDecision.allow();
            }
            if (profile.pinnedVerbs.contains(tool.name)) {
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
            if (autonomy == 'proposeOnly') {
              addEvent(
                DebugEvent(
                  content:
                      '[harness] "${tool.name}" denied: autonomy in this '
                      'space is propose-only.',
                ),
              );
              return const ToolGateDecision.deny(
                reason: 'this space\'s autonomy is set to propose-only',
                remediation:
                    'Propose the action in a message instead and let '
                    'the operator run it.',
              );
            }

            if (guard != null && tool.actionClasses.isNotEmpty) {
              final resolution = await guard.resolve(
                workspaceId: wsId,
                classes: tool.actionClasses,
                spaceId: spaceId,
                agentId: agentId,
                mode: effectiveMode,
                request: const ActionRequestExtractor().extract(
                  args,
                  classes: tool.actionClasses,
                ),
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
              );
              if (outcome == AutonomyOutcome.allow) {
                auditOutcome(ActionDecision.allow);
                return const ToolGateDecision.allow();
              }
              if (outcome == AutonomyOutcome.deny) {
                auditOutcome(ActionDecision.deny);
                return ToolGateDecision.deny(
                  reason: resolution.driving.reason,
                  remediation: DispatchSession._remediationFor(profile),
                );
              }
              final approved = await port.requestApproval(
                ConfirmationRequest(
                  spaceId: spaceId ?? '',
                  workspaceId: workspaceId,
                  title: 'Approve ${tool.name}',
                  detail:
                      '${resolution.driving.reason}'
                      '${DispatchSession._approvalArgsSummary(args)}',
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

            if (autonomy == 'actFreely') {
              return const ToolGateDecision.allow();
            }
            final approved = await port.requestApproval(
              ConfirmationRequest(
                spaceId: spaceId ?? '',
                workspaceId: workspaceId,
                title: 'Approve ${tool.name}',
                detail:
                    'An agent wants to run the "${tool.name}" tool.'
                    '${DispatchSession._approvalArgsSummary(args)}',
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
          };

    final harnessToolEnv = <String, String>{
      ..._gitIdentityEnv,
      ...scoped.environment,
    };

    // 2. Assemble tools.
    final registry = _buildHarnessRegistry(
      mode: effectiveMode,
      caps: caps,
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
            baseCaps: caps,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
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
    if (vibeRoster != null) {
      final vibeTools = buildVibeTools(
        roster: vibeRoster,
        runner: _ClosureVibeRunner((worker, brief, ctx, type, model) async {
          return _spawnSubagent(
            SubagentSpawnRequest(
              description: brief,
              label: 'vibe:${worker.label}',
              type: type,
              context: ctx,
              modelOverride: model,
            ),
            depth: 1,
            parentType: null,
            parentRunId: runLogId,
            baseCaps: caps,
            env: harnessToolEnv,
            parentProvider: provider,
            parentProviderId: providerId,
            baseSystemPrompt: baseSystem,
            approval: approval,
          );
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
    final costCalc = HarnessCostCalculator(
      (pid, m) => deps.modelResolver?.call('$pid/$m')?.cost,
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
    );

    final runConfig = await HarnessRunConfig.load(
      [agentDirHostPath, agentConfigDir],
      hookTrustedBases: [agentConfigDir],
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

      if (roster.advisors.isEmpty) {
        advisor = WatchdogAdvisor(
          provider,
          model: runConfig.advisorModel,
          attention: attentionFor(''),
          projectContext: watchdogContext.projectContext,
          extraInstructions: runConfig.advisorInstructions,
        );
      } else {
        advisor = AdvisorPanel([
          for (final entry in roster.advisors)
            WatchdogAdvisor(
              provider,
              model: entry.model ?? runConfig.advisorModel,
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
    final sessionCostCapCents = costCapCents ?? defaultRunCostCapCents;
    var runCostCents = 0;
    final config = AgentLoopConfig(
      systemPrompt: systemPrompt,
      model: parsed.model,
      maxTurns: commandMaxTurns,
      maxTokens: generation.maxTokens ?? defaultHarnessMaxTokens,
      temperature: generation.temperature,
      topP: generation.topP,
      topK: generation.topK,
      effort: _raiseEffort(
        _resolveHarnessEffort(modelInfo),
        magicKeywordEffort(magic),
      ),
      cacheKey: conversationId,
      toolTimeout: const Duration(minutes: 30),
      approvalCallback: approval,
      autoApprove: false,
      pauseGate: _pauseGate,
      contract: profile.toCompletionContract(),
      budget: const HarnessBudget(),
      externalBudgetExceeded: switch (parsedCommand.command) {
        'goal' || 'loop' => () => runCostCents >= sessionCostCapCents,
        _ => null,
      },
      externalBudgetPressure: switch (parsedCommand.command) {
        'goal' ||
        'loop' => () => runCostCents >= (sessionCostCapCents * 0.8).round(),
        _ => null,
      },
      streamRules: runConfig.streamRules,
      advisor: advisor,
      advisorEveryTurns: runConfig.advisorEveryTurns,
      hooks: hooks,
      steering: _steering,
      contextWindow: modelInfo?.limits.context ?? 128000,
      compactor: SnapcompactCompactor(
        fallback: DefaultHarnessCompactor(
          summarizer: LlmHarnessSummarizer(provider),
        ),
        modelId: qualifiedModel,
        readerHasVision: modelInfo?.supportsImageInput ?? false,
      ),
      transcriptStore: deps.transcriptStore,
      transcriptKey: _transcriptKey,
      initialCheckpoints: _resumedCheckpoints,
    );
    final context = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: spaceId,
    );

    final resumed = await _loadResumeTranscript();
    final history = <HarnessMessage>[...?resumed?.messages];
    final bareUserText = userText;
    final promptForRun =
        history.isEmpty || bareUserText == null || bareUserText.isEmpty
        ? effectivePrompt
        : bareUserText;

    var exitCode = 0;
    CompletionContract? contractUnmet;
    _markRunStarted();

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
            addEvent(TextEvent(content: text));
          case LoopThinkingDelta(:final thinking):
            addEvent(ThinkingEvent(content: thinking));
          case LoopToolCallStart(
            :final toolName,
            :final toolUseId,
            :final args,
          ):
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
                images: await _externalizeToolImages(result.images),
              ),
            );
          case LoopUsage(:final usage):
            final servedProvider = provider is FallbackProvider
                ? provider.lastServedProviderId
                : providerId;
            final servedModel = provider is FallbackProvider
                ? provider.lastServedModel
                : (parsed.model ?? provider.defaultModel);
            final rc = costCalc.cost(
              providerId: servedProvider,
              modelId: servedModel,
              usage: usage,
            );
            runCostCents += rc.estimatedCostCents;
            addEvent(
              UsageEvent(
                usage: RunUsage(
                  inputTokens: usage.inputTokens,
                  outputTokens: usage.outputTokens,
                  thoughtTokens: usage.thoughtTokens,
                  cachedReadTokens: usage.cacheReadTokens,
                  cachedWriteTokens: usage.cacheWriteTokens,
                  estimatedCostCents: rc.estimatedCostCents,
                ),
              ),
            );
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
      unawaited(_closeRunLog(exitCode: exitCode));
    } on Object catch (e) {
      addEvent(ErrorEvent(content: '[harness] $e', source: 'harness'));
      unawaited(_closeRunLog(exitCode: 1, error: e));
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
      addEvent(DoneEvent());
      _completeRun();
    }
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
