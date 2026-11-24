part of 'dispatch_session.dart';

String _stripFrontmatter(String md) =>
    MarkdownFrontmatter.parse(md).body.trim();

/// The code mode paragraph of a subagent's system prompt: the tools only a
/// `repl` script can reach, and how to reach them. Null when the subagent
/// has no `repl` or no such tool (its `repl` description then says all
/// there is to say).
///
/// A subagent's prompt is its profile's own, not the mode capability block
/// a top-level run gets, so this is the one part of that block a child
/// needs: without it a child sees neither the script-only tools' names nor
/// that it must not call them directly. The wording follows the capability
/// block's script-tool paragraph.
String? _subagentScriptToolsNote({
  required bool hasRepl,
  required List<String> scriptToolNames,
}) {
  if (!hasRepl || scriptToolNames.isEmpty) {
    return null;
  }
  final buf = StringBuffer()
    ..writeln(
      '${scriptToolNames.length} more tools are callable from `repl`, as '
      '`await tools.<name>(args)` (or `tools["<name>"](args)`) inside a '
      'script. They are not loaded as tools of their own, so do not call '
      "them directly. In a script, `await describeTool(name)` returns a tool's "
      'declaration and `await searchTools(query)` finds the right one for a '
      'plain-language description.',
    )
    ..writeln();
  for (final entry in groupToolsByCategory(scriptToolNames).entries) {
    final grouped = [...entry.value]..sort();
    buf.writeln(
      '- ${entry.key.label}: ${grouped.map((n) => '`$n`').join(', ')}',
    );
  }
  return buf.toString().trim();
}

extension _DispatchSessionSubagent on DispatchSession {
  Future<SubagentResult> _spawnSubagent(
    SubagentSpawnRequest req, {
    required int depth,
    required SubagentType? parentType,
    required String? parentRunId,
    required Map<String, String> env,
    required LlmProviderPort parentProvider,
    required String parentProviderId,
    required HarnessRunAccounting parentAccounting,
    required HarnessRunConfig runConfig,
    bool Function()? budgetExceeded,
    required String baseSystemPrompt,
    // The run's approval decision, given the origins of the loop asking: one
    // implementation for every loop, each binding its own origins, so the
    // card of a script's call names that loop's script and no other.
    required Future<ToolGateDecision> Function(
      RunScriptOrigins origins,
      ToolApprovalRequest request,
    )
    approvalWith,
    // The run's refusal of a script's call too long to audit whole, asked
    // before a hook or a card in every loop.
    required NestedCallRefusal scriptRefusal,
    Advisor? parentAdvisor,
    AgentLoopHooks? parentHooks,
  }) async {
    final childCancel = req.context.cancel ?? _cancelSource.token;
    if (childCancel.isCancelled) {
      return const SubagentResult(
        text: 'Subagent cancelled before starting.',
        isError: true,
      );
    }
    if (depth > maxSubagentDepth) {
      return SubagentResult(
        text:
            'Refused: subagent nesting is capped at $maxSubagentDepth '
            'levels and this request would be level $depth.',
        isError: true,
      );
    }
    if (parentType != null &&
        !subagentProfileFor(parentType).admitsChildType(req.type)) {
      return SubagentResult(
        text:
            'Refused: a "${parentType.name}" subagent is read-only and may '
            'not spawn a "${req.type.name}" subagent, which would grant it '
            'write/exec tools its own surface denies. Use explore or plan.',
        isError: true,
      );
    }
    final custom = (await _subagentCatalog()).customFor(req.typeName);
    final subProfile = custom?.resolve() ?? subagentProfileFor(req.type);
    final childRunId =
        '${runLogId ?? 'run'}-sub-${_subagentSeq++}-${const Uuid().v4()}';
    final childAgentId = agentId ?? 'subagent';
    // The outputs this child stores: its scripts read only these, though
    // they share its parent's store scope.
    final childOutputs = RunOutputLedger();
    final startedAt = DateTime.now();
    final repo = deps.runLogRepo;
    final ws = parentAccounting.workspaceId;
    final recording = deps.runTranscriptRecorder?.begin(
      runId: childRunId,
      workspaceId: ws,
      startedAt: startedAt,
    );
    final readMedia = ReadMediaCapture(
      emit: (event) => recording?.add(event),
      workingDirectory: agentDirHostPath,
      workspaceId: ws,
      store: deps.blobStore,
      renderer: deps.mediaRenderer,
      agentId: childAgentId,
      spaceId: spaceId,
      conversationId: conversationId,
    );
    int? childWindow;
    late final HarnessRunAccounting childAccounting;
    childAccounting = HarnessRunAccounting(
      runId: childRunId,
      workspaceId: ws,
      conversationId: conversationId,
      runStartedAt: startedAt,
      parent: parentAccounting,
      repository: deps.llmCallRecordRepo,
      runLogRepository: repo,
      priceLookup: (pid, model) =>
          deps.modelResolver?.call('$pid/$model')?.cost,
      onCall: (record) => _emitHarnessProviderCall(
        record,
        accounting: childAccounting,
        emit: readMedia.add,
        contextWindow: childWindow,
      ),
    );

    // The parent's script setup: the same execution service and the same
    // teardown, so a stop ends a child's script too. The origins are the
    // child's own, under the run id its scripts are recorded under: its
    // approval cards, its questions and its commands resolve a nested call
    // here, never in a parent's or a sibling's registry, which may hold a
    // script under the same tool call id.
    final scripts = await _codeModeScripts();
    final scriptExecutions = scripts.executions;
    final childOrigins = RunScriptOrigins(runId: childRunId);
    Future<ToolGateDecision> childApproval(ToolApprovalRequest request) =>
        approvalWith(childOrigins, request);
    final childRegistry = _buildHarnessRegistry(
      mode: subProfile.surface.maxTier == ToolApprovalTier.exec
          ? Mode.chat
          : Mode.plan,
      env: env,
      personalMcpUserId: await _personalMcpUser(),
      scriptOrigins: childOrigins,
      replSlot: scriptExecutions != null,
    );

    var childProvider = parentProvider;
    var childProviderId = parentProviderId;
    String? childModel;
    final override = req.modelOverride;
    if (override != null && override.isNotEmpty) {
      try {
        final factory = deps.harnessProviderFactory;
        final parsed = factory.parseModel(
          override,
          defaultProvider: parentProviderId,
        );
        final cred = await _resolveHarnessCredential(parsed.providerId);
        childProvider = await _buildHarnessProvider(
          factory: factory,
          primaryProviderId: parsed.providerId,
          primaryModel: parsed.model,
          primaryCredential: cred,
          extraSpecs: const [],
        );
        childProviderId = parsed.providerId;
        childModel = parsed.model;
      } on Object catch (e) {
        addEvent(
          DebugEvent(
            content:
                '[harness] subagent "${req.label}" model override failed '
                '($e); using parent model.',
          ),
        );
        childProvider = parentProvider;
        childProviderId = parentProviderId;
        childModel = null;
      }
    }
    final childCredential = await _resolveHarnessCredential(childProviderId);
    childProvider = childAccounting.observe(
      childProvider,
      providerId: childProviderId,
    );

    final canSpawn = depth < maxSubagentDepth;
    if (canSpawn) {
      childRegistry.register(
        TaskTool(
          catalog: await _subagentCatalog(),
          _ClosureSubagentSpawner(
            (r) => _spawnSubagent(
              r,
              depth: depth + 1,
              parentType: subProfile.type,
              parentRunId: childRunId,
              env: env,
              parentProvider: childProvider,
              parentProviderId: childProviderId,
              parentAccounting: childAccounting,
              runConfig: runConfig,
              budgetExceeded: budgetExceeded,
              baseSystemPrompt: baseSystemPrompt,
              approvalWith: approvalWith,
              scriptRefusal: scriptRefusal,
              parentAdvisor: parentAdvisor,
              parentHooks: parentHooks,
            ),
          ),
        ),
      );
    }
    final childAdmitted = custom != null
        ? custom.filterTools(childRegistry.toolsFor(subProfile.surface))
        : subProfile.filterTools(childRegistry.toolsFor(subProfile.surface));
    // The parent's script setup, not one of the child's own: sibling
    // children then build the same surface and share one cache prefix, and a
    // subagent cannot get a script tool its parent did not get.
    final childSurface = materializeHarnessToolSurface(
      registry: HarnessToolRegistry.of(childAdmitted),
      surface: const ToolSurfaceSpec.unrestricted(),
      residency: DispatchSession._childResidency(
        enabled: deps.toolDeferralEnabled,
      ),
    );
    var childTools = childSurface.resident;
    final childDeferredTools = childSurface.deferred;
    var childScriptTools = childSurface.scriptOnly;
    final childModelId = childModel ?? childProvider.defaultModel;
    final childModelInfo = deps.modelResolver?.call(
      '$childProviderId/$childModelId',
    );
    childWindow = childModelInfo?.limits.context ?? 128000;
    final childEffort = _resolveHarnessEffort(
      childModelInfo,
      override: req.effortOverride,
    );

    var childHasRunLogRow = false;
    if (repo != null) {
      try {
        await repo.upsert(
          AgentRunLog(
            id: childRunId,
            agentId: childAgentId,
            workspaceId: ws,
            spaceId: spaceId,
            conversationId: conversationId,
            startedAt: startedAt,
            status: RunStatus.running,
            summary: req.label,
            adapter: 'harness',
            modelId:
                '$childProviderId/${childModel ?? childProvider.defaultModel}',
            effort: childEffort?.name ?? 'default',
            taskFamily: subProfile.type.name,
            role: AgentRunRole.sub,
            parentRunId: parentRunId,
            spawnToolCallId: req.spawnToolCallId,
          ),
        );
        childHasRunLogRow = true;
      } catch (e) {
        CcInfraLog.warning(
          'Failed to write subagent start run-log for "${req.label}": $e',
        );
      }
    }

    // The child's own `repl`. Its scripts run under the child's run id, so
    // the service's one-script-per-run admission never makes a parent's
    // script and a child's script wait on each other, and their records
    // hang off the child's run-log row. A child whose row could not be
    // written gets no `repl` (its scripts could not be recorded) and calls
    // its tools directly. The agent is the parent's real one, never the
    // placeholder the child's tool context carries; the full output lands
    // where that context's `read_output` reads.
    if (scriptExecutions != null &&
        !childHasRunLogRow &&
        childTools.any((t) => t.name == ReplToolDescription.toolName)) {
      childTools = withoutReplTool(
        resident: childTools,
        scriptOnly: childScriptTools,
      );
      childScriptTools = const [];
    } else if (scriptExecutions != null) {
      childTools = bindReplTool(
        resident: childTools,
        scriptOnly: childScriptTools,
        binding: ReplBinding(
          executions: scriptExecutions.forLoop(childOrigins),
          run: _subagentReplRun(ws, childRunId, childAgentId, childOutputs),
          limits: scripts.limits,
          fullOutputSink: childOutputs.recording(_replOutputSink(childAgentId)),
        ),
      );
    }
    // The child's own background commands name their follow-ups in the
    // forms the child calls them in.
    backgroundCommandsOf([
      ...childTools,
      ...childDeferredTools,
      ...childScriptTools,
    ])?.bindCallForms(
      toolFormsOver(
        callable: [
          for (final t in [...childTools, ...childDeferredTools]) t.name,
        ],
        scriptOnly: [for (final t in childScriptTools) t.name],
      ),
    );
    final scriptToolsNote = _subagentScriptToolsNote(
      hasRepl: childTools.any(
        (tool) => tool.name == ReplToolDescription.toolName,
      ),
      scriptToolNames: [for (final tool in childScriptTools) tool.name],
    );

    addEvent(
      DebugEvent(
        content:
            '[harness] subagent "${req.label}" (${req.type.name}) started.',
      ),
    );

    final childGeneration =
        childCredential?.generation ?? const ProviderGenerationDefaults();
    final config = AgentLoopConfig(
      systemPrompt: [
        subProfile.buildSystemPrompt(baseSystemPrompt, canSpawn: canSpawn),
        ?scriptToolsNote,
      ].join('\n\n'),
      model: childModel,
      purpose: LlmCallPurpose.subagent,
      maxTurns: subProfile.maxTurns,
      maxTokens: childGeneration.maxTokens ?? defaultHarnessMaxTokens,
      temperature: childGeneration.temperature,
      topP: childGeneration.topP,
      topK: childGeneration.topK,
      effort: childEffort,
      tools: LoopToolConfig(
        overlapReadOnlyTools: runConfig.overlapReadOnlyTools,
        observationIngest: ToolObservationIngest(
          store: childOutputs.over(_outputs),
          retainMinTokens:
              runConfig.compaction.policy == CompactionPolicy.current
              ? 0
              : kToolOutputRetentionMinTokens,
        ),
        toolTimeout: const Duration(minutes: 30),
        approvalCallback: childApproval,
        nestedCallRefusal: scriptRefusal,
        autoApprove: false,
        maxParallelToolCalls: runConfig.maxParallelToolCalls < 2
            ? runConfig.maxParallelToolCalls
            : 2,
      ),
      guards: LoopGuardConfig(
        callLedger: childAccounting.ledger,
        externalBudgetExceeded: budgetExceeded,
      ),
      compaction: LoopCompactionConfig(
        tokenCalibration: deps.tokenCalibration,
        contextWindow: childWindow,
        compactor: buildHarnessCompactor(
          summaryProvider: childProvider,
          providerId: childProviderId,
          modelId: childModelId,
          config: runConfig.compaction,
          calibration: deps.tokenCalibration,
          purpose: LlmCallPurpose.subagent,
          readerHasVision: childModelInfo?.supportsImageInput ?? false,
          preferSnapshots: runConfig.snapshotCompaction,
        ),
      ),
      steering: LoopSteeringConfig(
        pauseGate: _harness.pauseGate,
        // What the parent run is subject to, the nested run is too: the user's
        // pre-tool veto gates every call made on their behalf (a subagent was a
        // trivial bypass), the advisor reviews the child's own transcript from
        // a fresh cursor, and steering sent while the parent is blocked on this
        // call reaches the child without being taken from the parent. The
        // parent's completion contract is NOT inherited: its deliverable verbs
        // (submit_plan, ...) are the parent's to call, and most child surfaces
        // cannot reach them, so the child would always end `contractUnmet`.
        hooks: parentHooks == null ? null : NestedRunHooks(parentHooks),
        advisor: parentAdvisor == null
            ? null
            : AdvisorPanel.freshFor(parentAdvisor),
        advisorEveryTurns: runConfig.advisorEveryTurns,
        queue: _steering.nestedView(),
      ),
    );
    final childContext = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      readOnlyRoots: _readOnlyRoots,
      agentId: childAgentId,
      workspaceId: ws,
      conversationId: conversationId,
      spaceId: spaceId,
    );

    final buf = StringBuffer();
    var lastText = '';
    var isError = false;
    final nestedRows = NestedCallRows();

    final pilotKey =
        '${subProfile.type.name}|$childProviderId|'
        '${childModel ?? childProvider.defaultModel}';
    final releasePilot = await _subagentPilots.enter(
      pilotKey,
      abandoned: childCancel.whenCancelled,
    );

    try {
      await for (final event in deps.agentLoop.run(
        history: <HarnessMessage>[],
        userMessage: req.description,
        tools: childTools,
        deferredTools: childDeferredTools,
        scriptTools: childScriptTools,
        provider: childProvider,
        context: childContext,
        config: config,
        cancel: childCancel,
      )) {
        releasePilot();
        final transcriptEvent = await harnessTranscriptEvent(
          event,
          imageRefs: _toolImageRefs,
        );
        // A script's calls are kept bounded, as on the parent's stream.
        final kept = transcriptEvent == null
            ? null
            : nestedRows.bound(transcriptEvent);
        if (kept != null) {
          readMedia.add(kept);
        }
        switch (event) {
          case LoopTextDelta(:final text):
            buf.write(text);
          case LoopThinkingDelta():
            break;
          case LoopTurnDiscarded(:final text):
            // The abandoned attempt's text is withdrawn from the recording
            // (above) and from the fallback answer buffer alike.
            final kept = buf.length - text.length;
            final current = buf.toString();
            buf
              ..clear()
              ..write(kept <= 0 ? '' : current.substring(0, kept));
          case LoopTurnComplete(:final message):
            final text = message.textContent;
            if (text.trim().isNotEmpty) {
              lastText = text;
            }
          case LoopUsage():
            // Already recorded at each physical provider-call boundary.
            break;
          case LoopToolCallStart(:final toolName):
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}": $toolName',
              ),
            );
          case LoopToolCallResult():
            break;
          case LoopError(:final message):
            isError = true;
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}" error: $message',
              ),
            );
          case LoopDone(:final reason):
            if (reason != LoopDoneReason.completed) {
              isError = true;
              readMedia.add(
                ErrorEvent(
                  content: 'Subagent stopped: ${reason.name}.',
                  source: 'harness',
                ),
              );
            }
          case LoopPark(:final parked, :final reason):
            // A subagent waiting on its own background command is not silent
            // either: the session's watchdog skips while it is parked.
            _noteLoopPark(childRunId, parked: parked);
            addEvent(
              DebugEvent(
                content: parked
                    ? '[harness] subagent "${req.label}" waiting for $reason '
                          'to finish.'
                    : '[harness] subagent "${req.label}" done waiting for '
                          '$reason.',
              ),
            );
          default:
            break;
        }
      }
    } on Object catch (e) {
      isError = true;
      readMedia.add(ErrorEvent(content: '[harness] $e', source: 'harness'));
      addEvent(
        DebugEvent(content: '[harness] subagent "${req.label}" crashed: $e'),
      );
    } finally {
      _noteLoopPark(childRunId, parked: false);
      releasePilot();
      await childAccounting.flush();
    }

    await readMedia.drained;
    await recording?.finish(
      isError ? TurnOutcome.failed : TurnOutcome.completed,
    );

    final finalText = lastText.trim().isNotEmpty
        ? lastText.trim()
        : buf.toString().trim();
    final completedAt = DateTime.now();
    final cost = childAccounting.cost(
      durationMs: completedAt.difference(startedAt).inMilliseconds,
    );

    final runLogWorkspaceId = ws;
    if (repo != null) {
      try {
        final existing = await repo.getById(runLogWorkspaceId, childRunId);
        final base =
            existing ??
            AgentRunLog(
              id: childRunId,
              agentId: childAgentId,
              workspaceId: ws,
              spaceId: spaceId,
              conversationId: conversationId,
              startedAt: startedAt,
              status: RunStatus.running,
              role: AgentRunRole.sub,
              parentRunId: parentRunId,
              spawnToolCallId: req.spawnToolCallId,
            );
        // The terminal write every run end shares, with an end reason: the
        // parent's when it cut the child short. A child announces nothing.
        await RunSettlement(runLogs: repo, eventBus: null).settle(
          base.copyWith(
            status: isError ? RunStatus.error : RunStatus.completed,
            completedAt: completedAt,
            summary: finalText.isEmpty ? req.label : _clip(finalText, 2000),
            cost: cost,
          ),
          endReason: isError
              ? _endReason ?? RunEndReason.error
              : RunEndReason.completed,
        );
      } catch (e) {
        CcInfraLog.warning(
          'Failed to write subagent completion run-log for "${req.label}": $e',
        );
      }
    }

    addEvent(
      DebugEvent(
        content:
            '[harness] subagent "${req.label}" '
            '${isError ? 'failed' : 'done'}.',
      ),
    );

    return SubagentResult(
      text: finalText.isEmpty
          ? (isError
                ? 'Subagent failed with no output.'
                : 'Subagent finished with no output.')
          : finalText,
      isError: isError,
      childRunId: childRunId,
    );
  }

  String _spliceUserText(String? replacement) {
    if (replacement == null) {
      return prompt;
    }
    final raw = userText;
    if (raw == null || raw.isEmpty) {
      return replacement;
    }
    if (!prompt.endsWith(raw)) {
      return prompt == raw ? replacement : prompt;
    }
    return prompt.substring(0, prompt.length - raw.length) + replacement;
  }

  Future<
    ({
      Mode? mode,
      String? userTextOverride,
      int? maxTurns,
      String? directive,
      String? notice,
    })
  >
  _applySlashCommand(ParsedSlashCommand cmd) async {
    final name = cmd.command!;
    final String? body = cmd.args.isEmpty ? null : cmd.args;
    switch (name) {
      case 'plan':
        return (
          mode: Mode.plan,
          userTextOverride: body,
          maxTurns: null,
          directive: null,
          notice: 'plan mode',
        );
      case 'vibe':
        // A settled worker's result reaches the director's aside lane, tagged
        // as not a person's words (`vibe:<id>`).
        _vibeRoster = VibeRoster(
          onSettled: (worker) => _steering.pushAside(
            vibeSettledNotice(worker, nonce: newWakeDataNonce()),
            source: 'vibe:${worker.id}',
          ),
        );
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive: vibeDirectorPrompt,
          notice: 'vibe mode',
        );
      default:
        final command = await _loadUserCommand(name);
        if (command != null) {
          return (
            mode: null,
            userTextOverride: command.render(cmd.args),
            maxTurns: null,
            directive: null,
            notice: 'command: $name',
          );
        }
        final skillName = skillNameFor(name);
        final skill = skillName == null
            ? null
            : await _loadSkillBody(skillName);
        if (skill != null) {
          return (
            mode: null,
            userTextOverride: body ?? 'Apply the "$skillName" skill.',
            maxTurns: null,
            directive:
                'The user invoked the "$skillName" skill. Follow these '
                'instructions:\n\n$skill',
            notice: 'skill: $skillName',
          );
        }
        return (
          mode: null,
          userTextOverride: null,
          maxTurns: null,
          directive: null,
          notice: null,
        );
    }
  }

  Future<SubagentCatalog> _subagentCatalog() async {
    final cached = _catalogMemo;
    if (cached != null) {
      return cached;
    }
    try {
      final agents = await const HarnessAgentScanner().scan([
        agentDirHostPath,
        agentConfigDir,
      ]);
      return _catalogMemo = SubagentCatalog(custom: agents);
    } on Object catch (e) {
      CcInfraLog.warning('Failed to scan agent definitions: $e');
      return _catalogMemo = const SubagentCatalog();
    }
  }

  Future<HarnessCommandInfo?> _loadUserCommand(String name) async {
    try {
      final commands = await const HarnessCommandScanner().scan([
        agentDirHostPath,
        agentConfigDir,
      ]);
      for (final command in commands) {
        if (command.name == name.toLowerCase()) {
          return command;
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('Failed to scan slash commands: $e');
    }
    return null;
  }

  Future<String?> _loadSkillBody(String name) async {
    try {
      final catalog = _repoProjector?.catalog;
      if (catalog != null) {
        // A bare name that two repos ship must not fall through to the
        // overlay scan: both copies are linked there, and the scanner keeps
        // whichever it sees first.
        if (await catalog.isAmbiguous(name)) {
          CcInfraLog.warning(
            'DispatchSession: skill "$name" is shipped by more than one '
            'repo; invoke it as <repo>:$name',
          );
          return null;
        }
        final entry = await catalog.resolve(name);
        if (entry != null) {
          return _stripFrontmatter(await File(entry.path).readAsString());
        }
      }
      final skills = await const HarnessSkillScanner().scan([
        agentConfigDir,
        agentDirHostPath,
      ], permittedLinkRoots: _permittedLinkRoots());
      for (final s in skills) {
        if (s.name == name) {
          return _stripFrontmatter(await File(s.path).readAsString());
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('DispatchSession: skill load failed: $e');
    }
    return null;
  }

  ReasoningEffort? _resolveHarnessEffort(ModelInfo? info, {String? override}) {
    final requested =
        ReasoningEffort.fromId(override ?? effortLevel) ??
        ReasoningEffort.medium;
    if (info == null) {
      return requested;
    }
    final thinking = info.thinking;
    if (thinking == null) {
      return null;
    }
    return thinking.resolve(requested);
  }
}

/// A [SubagentSpawner] backed by a closure, so the `task` tool can spawn a
/// subagent without the tool holding a reference to the whole dispatch session.
/// Adapts a closure to [VibeWorkerRunner], so the roster tools stay free of
/// the dispatch layer exactly as `task` does.
class _ClosureVibeRunner implements VibeWorkerRunner {
  _ClosureVibeRunner(this._run);

  final Future<SubagentResult> Function(
    VibeWorker worker,
    String brief,
    HarnessToolContext context,
    SubagentType type,
    String? modelOverride,
  )
  _run;

  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) => _run(worker, brief, context, type, modelOverride);
}

class _ClosureSubagentSpawner implements SubagentSpawner {
  _ClosureSubagentSpawner(this._run);

  final Future<SubagentResult> Function(SubagentSpawnRequest request) _run;

  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) => _run(request);
}
