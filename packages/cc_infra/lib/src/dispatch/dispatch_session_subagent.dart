part of 'dispatch_session.dart';

String _stripFrontmatter(String md) {
  final t = md.trimLeft();
  if (t.startsWith('---')) {
    final end = t.indexOf('\n---', 3);
    if (end != -1) {
      final nl = t.indexOf('\n', end + 1);
      return nl == -1 ? '' : t.substring(nl + 1).trim();
    }
  }
  return md.trim();
}

extension _DispatchSessionSubagent on DispatchSession {
  Future<void> _updateSubagentCost({
    required String runId,
    required RunCost cost,
    required AgentRunLogRepository? repo,
  }) async {
    final ws = workspaceId;
    if (repo == null || ws == null || ws.isEmpty) {
      return;
    }
    try {
      final row = await repo.getById(ws, runId);
      if (row != null) {
        await repo.upsert(row.copyWith(cost: cost));
      }
    } catch (_) {
      // Progress telemetry, not the run's result — never fail a run over it.
    }
  }

  Future<SubagentResult> _spawnSubagent(
    SubagentSpawnRequest req, {
    required int depth,
    required SubagentType? parentType,
    required String? parentRunId,
    required AgentCapabilities baseCaps,
    required Map<String, String> env,
    required LlmProviderPort parentProvider,
    required String parentProviderId,
    required String baseSystemPrompt,
    required ToolApprovalCallback? approval,
  }) async {
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

    final childRegistry = _buildHarnessRegistry(
      mode: subProfile.surface.maxTier == ToolApprovalTier.exec
          ? Mode.chat
          : Mode.plan,
      caps: baseCaps,
      env: env,
    );

    var childProvider = parentProvider;
    var childProviderId = parentProviderId;
    String? childModel;
    final override = req.modelOverride;
    if (override != null && override.isNotEmpty) {
      try {
        final factory = deps.harnessProviderFactory;
        final parsed = factory.parseModel(override);
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
              baseCaps: baseCaps,
              env: env,
              parentProvider: childProvider,
              parentProviderId: childProviderId,
              baseSystemPrompt: baseSystemPrompt,
              approval: approval,
            ),
          ),
        ),
      );
    }
    final childAdmitted = custom != null
        ? custom.filterTools(childRegistry.toolsFor(subProfile.surface))
        : subProfile.filterTools(childRegistry.toolsFor(subProfile.surface));
    final childPartition = materializeHarnessToolSurface(
      registry: HarnessToolRegistry.of(childAdmitted),
      surface: const ToolSurfaceSpec.unrestricted(),
      residency: DispatchSession._childResidency(enabled: deps.toolDeferralEnabled),
    );
    final childTools = childPartition.resident;
    final childDeferredTools = childPartition.deferred;

    final childAgentId = agentId ?? 'subagent';
    final startedAt = DateTime.now();
    final repo = deps.runLogRepo;

    final ws = workspaceId;
    final recording = (ws != null && ws.isNotEmpty)
        ? deps.runTranscriptRecorder?.begin(
            runId: childRunId,
            workspaceId: ws,
            startedAt: startedAt,
          )
        : null;

    if (repo != null) {
      try {
        await repo.upsert(
          AgentRunLog(
            id: childRunId,
            agentId: childAgentId,
            workspaceId: workspaceId,
            conversationId: conversationId,
            startedAt: startedAt,
            status: RunStatus.running,
            summary: req.label,
            adapter: 'harness',
            modelId: childModel ?? childProviderId,
            role: AgentRunRole.sub,
            parentRunId: parentRunId,
            spawnToolCallId: req.spawnToolCallId,
          ),
        );
      } catch (e) {
        CcInfraLog.warning(
          'Failed to write subagent start run-log for "${req.label}": $e',
        );
      }
    }

    addEvent(
      DebugEvent(
        content:
            '[harness] subagent "${req.label}" (${req.type.name}) started.',
      ),
    );

    final costCalc = HarnessCostCalculator(
      (pid, m) => deps.modelResolver?.call('$pid/$m')?.cost,
    );
    final childModelInfo = childModel == null
        ? null
        : deps.modelResolver?.call('$childProviderId/$childModel');
    final childGeneration =
        childCredential?.generation ?? const ProviderGenerationDefaults();
    final config = AgentLoopConfig(
      systemPrompt: subProfile.buildSystemPrompt(
        baseSystemPrompt,
        canSpawn: canSpawn,
      ),
      model: childModel,
      maxTurns: subProfile.maxTurns,
      maxTokens: childGeneration.maxTokens ?? defaultHarnessMaxTokens,
      temperature: childGeneration.temperature,
      topP: childGeneration.topP,
      topK: childGeneration.topK,
      effort: _resolveHarnessEffort(childModelInfo),
      toolTimeout: const Duration(minutes: 30),
      approvalCallback: approval,
      autoApprove: false,
      maxParallelToolCalls: 2,
      pauseGate: _pauseGate,
      contextWindow: childModelInfo?.limits.context ?? 128000,
      compactor: DefaultHarnessCompactor(
        summarizer: LlmHarnessSummarizer(childProvider),
      ),
    );
    final childContext = HarnessToolContext(
      workingDirectory: agentDirHostPath,
      sharedRoots: _workspaceSharedRoots(),
      agentId: childAgentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      spaceId: spaceId,
    );

    final buf = StringBuffer();
    var lastText = '';
    var inputTokens = 0;
    var outputTokens = 0;
    var thoughtTokens = 0;
    var cachedRead = 0;
    var cachedWrite = 0;
    var costCents = 0;
    var isError = false;

    RunCost costSoFar({DateTime? completedAt}) => RunCost(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      thoughtTokens: thoughtTokens,
      cachedReadTokens: cachedRead,
      cachedWriteTokens: cachedWrite,
      estimatedCostCents: costCents,
      durationMs: (completedAt ?? DateTime.now())
          .difference(startedAt)
          .inMilliseconds,
    );

    final pilotKey =
        '${subProfile.type.name}|$childProviderId|'
        '${childModel ?? childProvider.defaultModel}';
    final existingPilot = _subagentPilots[pilotKey];
    Completer<void>? ownedPilot;
    if (existingPilot == null) {
      ownedPilot = Completer<void>();
      _subagentPilots[pilotKey] = ownedPilot;
    } else {
      await existingPilot.future
          .timeout(DispatchSession._subagentPilotWait)
          .catchError((Object _) {});
    }
    void releasePilot() {
      if (ownedPilot != null && !ownedPilot.isCompleted) {
        ownedPilot.complete();
      }
      if (identical(_subagentPilots[pilotKey], ownedPilot)) {
        _subagentPilots.remove(pilotKey);
      }
    }

    try {
      await for (final event in deps.agentLoop.run(
        history: <HarnessMessage>[],
        userMessage: req.description,
        tools: childTools,
        deferredTools: childDeferredTools,
        provider: childProvider,
        context: childContext,
        config: config,
        cancel: _cancelSource.token,
      )) {
        releasePilot();
        switch (event) {
          case LoopTextDelta(:final text):
            buf.write(text);
            recording?.add(TextEvent(content: text));
          case LoopThinkingDelta(:final thinking):
            recording?.add(ThinkingEvent(content: thinking));
          case LoopTurnComplete(:final message):
            final text = message.textContent;
            if (text.trim().isNotEmpty) {
              lastText = text;
            }
          case LoopUsage(:final usage):
            final rc = costCalc.cost(
              providerId: childProviderId,
              modelId: childModel ?? childProvider.defaultModel,
              usage: usage,
            );
            inputTokens += usage.inputTokens;
            outputTokens += usage.outputTokens;
            thoughtTokens += usage.thoughtTokens;
            cachedRead += usage.cacheReadTokens;
            cachedWrite += usage.cacheWriteTokens;
            costCents += rc.estimatedCostCents;
            unawaited(
              _updateSubagentCost(
                runId: childRunId,
                cost: costSoFar(),
                repo: repo,
              ),
            );
          case LoopToolCallStart(
            :final toolName,
            :final toolUseId,
            :final args,
          ):
            recording?.add(
              ToolCallEvent(
                toolName: toolName,
                toolCallId: toolUseId,
                inputs: args,
              ),
            );
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}": $toolName',
              ),
            );
          case LoopToolCallResult(
            :final toolName,
            :final toolUseId,
            :final result,
          ):
            recording?.add(
              ToolResultEvent(
                toolCallId: toolUseId,
                outputs: result.content,
                toolName: toolName,
                isError: result.isError,
                images: await _externalizeToolImages(result.images),
              ),
            );
          case LoopError(:final message):
            isError = true;
            recording?.add(ErrorEvent(content: message, source: 'harness'));
            addEvent(
              DebugEvent(
                content: '[harness] subagent "${req.label}" error: $message',
              ),
            );
          default:
            break;
        }
      }
    } on Object catch (e) {
      isError = true;
      recording?.add(ErrorEvent(content: '[harness] $e', source: 'harness'));
      addEvent(
        DebugEvent(content: '[harness] subagent "${req.label}" crashed: $e'),
      );
    } finally {
      releasePilot();
    }

    await recording?.finish(
      isError ? TurnOutcome.failed : TurnOutcome.completed,
    );

    final finalText = lastText.trim().isNotEmpty
        ? lastText.trim()
        : buf.toString().trim();
    final completedAt = DateTime.now();
    final cost = costSoFar(completedAt: completedAt);

    final runLogWorkspaceId = workspaceId;
    if (repo != null &&
        runLogWorkspaceId != null &&
        runLogWorkspaceId.isNotEmpty) {
      try {
        final existing = await repo.getById(runLogWorkspaceId, childRunId);
        final base =
            existing ??
            AgentRunLog(
              id: childRunId,
              agentId: childAgentId,
              workspaceId: workspaceId,
              conversationId: conversationId,
              startedAt: startedAt,
              status: RunStatus.running,
              role: AgentRunRole.sub,
              parentRunId: parentRunId,
              spawnToolCallId: req.spawnToolCallId,
            );
        await repo.upsert(
          base.copyWith(
            status: isError ? RunStatus.error : RunStatus.completed,
            completedAt: completedAt,
            summary: finalText.isEmpty ? req.label : _clip(finalText, 2000),
            cost: cost,
          ),
        );
      } catch (e) {
        CcInfraLog.warning(
          'Failed to write subagent completion run-log for "${req.label}": $e',
        );
      }
    }

    if (repo != null &&
        runLogWorkspaceId != null &&
        runLogWorkspaceId.isNotEmpty &&
        parentRunId != null &&
        costCents > 0) {
      try {
        final parent = await repo.getById(runLogWorkspaceId, parentRunId);
        if (parent != null) {
          await repo.upsert(
            parent.copyWith(childCostCents: parent.childCostCents + costCents),
          );
        }
      } catch (_) {}
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
      case 'goal':
        final ws = workspaceId;
        final conv = conversationId;
        final goalText = (body ?? '').trim();
        if (deps.todoRepo != null &&
            ws != null &&
            ws.isNotEmpty &&
            conv != null &&
            conv.isNotEmpty &&
            goalText.isNotEmpty) {
          try {
            await deps.todoRepo!.setGoal(ws, conv, goalText);
          } on Object catch (e) {
            CcInfraLog.warning('Failed to set conversation goal: $e');
          }
        }
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive:
              'The user invoked /goal. Treat the request as a goal to '
              'accomplish end-to-end: keep working across tool calls until it '
              'is achieved, then report what you did. Do not stop after a '
              'single step. The goal is DURABLE: the supervisor keeps the '
              'objective alive across segments and server restarts until you '
              'declare completion with the complete_goal MCP tool, passing a '
              'summary of what was achieved. There is no turn limit: the run '
              'is bounded by its cost budget and a repetition guard steers '
              'you if you start looping, so spend turns on real progress. '
              'Checkpoint relentlessly (commit work, write notes and memory, '
              'update tickets) because every segment starts from durable '
              'state. Decompose large goals into tickets or plan nodes '
              'instead of one monolithic run.\n\n'
              '$goalCompletionAudit',
          notice: 'goal mode',
        );
      case 'vibe':
        _vibeRoster = VibeRoster();
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive: vibeDirectorPrompt,
          notice: 'vibe mode',
        );
      case 'loop':
        return (
          mode: null,
          userTextOverride: body,
          maxTurns: null,
          directive:
              'The user invoked /loop. Work the task iteratively: after '
              'each pass, re-evaluate and continue refining until it is fully '
              'complete. Do not stop early. There is no turn limit — the run '
              'is bounded by its cost budget and a repetition guard steers '
              'you if you start cycling without progress. When it is fully '
              'complete, declare completion with the complete_goal MCP tool, '
              'passing a summary of what was achieved.\n\n'
              '$goalCompletionAudit',
          notice: 'loop mode',
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

  ReasoningEffort? _resolveHarnessEffort(ModelInfo? info) {
    final requested =
        ReasoningEffort.fromId(effortLevel) ?? ReasoningEffort.medium;
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
