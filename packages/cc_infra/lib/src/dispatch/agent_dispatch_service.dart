import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/services/slugify.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/isolation/path_lock_manager.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
import 'package:cc_domain/features/observability/domain/doom_loop_detector.dart';
import 'package:cc_domain/features/observability/domain/subagent_cost_propagator.dart';
import 'package:cc_infra/cc_infra.dart'
    show WorkspaceFilesystemService, HireAgentUseCase;
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// Result of a successful agent dispatch.
class AgentDispatchResult {
  /// Creates a dispatch result.
  AgentDispatchResult({
    required this.stream,
    required this.dispatchId,
    required this.runLog,
    this.agent,
  });

  /// Stream of events emitted by the agent process.
  final Stream<AgentProcessEvent> stream;

  /// Unique identifier for this dispatch.
  final String dispatchId;

  /// Run log tracking the agent's execution.
  final AgentRunLog runLog;

  /// The agent that was dispatched, if resolved.
  final Agent? agent;
}

/// Orchestrates agent dispatch: prompt building, workspace provisioning, and process spawning.
class AgentDispatchService {
  /// Creates an agent dispatch service.
  AgentDispatchService({
    required AgentDispatchPort agentDispatch,
    required DispatchAgentUseCase dispatchUseCase,
    AgentRunLogRepository? runLogRepo,
    RepoWorkspaceProvisionerPort? repoProvisioner,
    AgentRegistry? registry,
    WorkspaceFilesystemPort? filesystemPort,
    PathLockManager? pathLock,
    DomainEventBus? eventBus,
    this.adapterLaunchOverrides,
  }) : _agentDispatch = agentDispatch,
       _dispatchUseCase = dispatchUseCase,
       _runLogRepo = runLogRepo,
       _repoProvisioner = repoProvisioner,
       _registry = registry,
       _filesystemPort = filesystemPort,
       _pathLock = pathLock,
       _eventBus = eventBus;

  final AgentDispatchPort _agentDispatch;
  final DispatchAgentUseCase _dispatchUseCase;
  final AgentRunLogRepository? _runLogRepo;

  /// Optional filesystem port used to heal the dispatched agent's global skill
  /// links (`syncAgentSkillLinks`) before provisioning, so the per-agent
  /// overlay's `.agents` symlink resolves the current skill set. Null skips the
  /// heal (skills are expected to already be synced from hire/update).
  final WorkspaceFilesystemPort? _filesystemPort;

  /// Process-global registry that tracks every live agent and its work-aware
  /// activity. Optional: when null, dispatch behaves exactly as before (the
  /// roster is simply not populated). Injected with the process-global instance
  /// at the composition root.
  final AgentRegistry? _registry;

  /// Resolver for per-adapter argv + env overrides (YOLO flags, API keys).
  ///
  /// Wired by the server from the INSTALL-wide settings store: argv is handed
  /// to a process on this host and env overrides are host credentials, so they
  /// bound what any agent on this machine may do regardless of which workspace
  /// asked. Null leaves both empty.
  ///
  /// This went unwired for a long time — the only production construction site
  /// omitted it — which meant per-adapter args and env edited in settings had
  /// no effect on how agents launched. Keep it wired.
  final Future<({List<String> args, Map<String, String> env})> Function(
    String adapterId,
  )?
  adapterLaunchOverrides;

  /// Provisions/reuses the per-conversation working root with isolated repo
  /// worktrees and returns it as the agent's working directory. Optional —
  /// when null, the passed [dispatch] working directory is used unchanged.
  final RepoWorkspaceProvisionerPort? _repoProvisioner;

  /// Serializes dispatches that share a working directory: a run requesting a
  /// path already owned by another in-flight run is parked until it frees,
  /// surfacing as a `waiting_local_directory` task state. Null disables the
  /// feature (dispatches never park on a path).
  final PathLockManager? _pathLock;

  /// Event bus used to publish the `waiting_local_directory` task state when a
  /// dispatch parks on a held path. Null skips the signal.
  final DomainEventBus? _eventBus;

  /// Maps a live run log id to the dispatch id of its in-flight process, so a
  /// specific run can be stopped without cross-killing other concurrent
  /// dispatches. Entries are added on [dispatch] and removed when the run
  /// completes, fails, or is stopped.
  final Map<String, String> _runToDispatch = {};

  final _uuid = const Uuid();

  /// Serializes subagent → parent cost rollups so concurrent child completions
  /// can't lose a read-modify-write update of the parent's `childCostCents`.
  /// Reads/writes go through the run-log repo (the propagator stays pure).
  ///
  /// One propagator per workspace: the store hooks bind the workspace that
  /// selects the run log's database, and per-parent locking stays correct
  /// because a parent run id only ever exists inside one workspace.
  final Map<String, SubagentCostPropagator> _costPropagators = {};

  SubagentCostPropagator _costPropagatorFor(String workspaceId) =>
      _costPropagators.putIfAbsent(
        workspaceId,
        () => SubagentCostPropagator(
          readChildCostCents: (parentRunId) async =>
              (await _runLogRepo?.getById(
                workspaceId,
                parentRunId,
              ))?.childCostCents ??
              0,
          writeChildCostCents: (parentRunId, value) async {
            final parent = await _runLogRepo?.getById(workspaceId, parentRunId);
            if (parent != null) {
              await _runLogRepo?.upsert(parent.copyWith(childCostCents: value));
            }
          },
        ),
      );

  /// Dispatches an agent to process a prompt, returning a stream of events and metadata.
  ///
  /// [workspaceId] owns the run: it scopes the run log, the conversation
  /// worktree and the live-agent roster entry. A run cannot be recorded without
  /// it, so it is required rather than resolved.
  ///
  /// [requestedByUserId] is the human on whose behalf the run executes; it is
  /// threaded to the dispatch port so the run's git commits carry an honest
  /// co-author trailer and per-user credentials apply. Null attributes the run
  /// to the server owner.
  Future<AgentDispatchResult> dispatch({
    required String agentId,
    required String prompt,
    required String workingDirectory,
    required String workspaceId,
    String? adapterId,
    String? conversationId,
    String? channelId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? requestedByUserId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
    AgentRunRole role = AgentRunRole.main,
    String? parentAgentId,
    int? costCapCents,
  }) async {
    // Prepare the dispatch (resolve agent + build prompt) FIRST so we can derive
    // the per-agent slug and heal its skills before provisioning the
    // conversation overlay cwd. `workingDirectory` here is the agent's global
    // dir (the fallback / symlink-target source); the resolved cwd is computed
    // below and threaded into the actual process spawn.
    final prepared = await _dispatchUseCase.execute(
      workspaceId: workspaceId,
      agentId: agentId,
      prompt: prompt,
      channelId: channelId,
      conversationId: conversationId,
      adapterId: adapterId,
      wakeContext: wakeContext,
      mentionContext: mentionContext,
    );

    final agent = prepared.agent;
    final agentSlug = _slugFor(agent, agentId);

    // Heal the global agent dir's skill links so the per-agent overlay's
    // `.agents` symlink resolves the current skill set. Best-effort: a failure
    // is logged and never blocks dispatch (skills are normally synced at
    // hire/update time).
    final fs = _filesystemPort;
    if (fs != null && agent != null && workspaceId.isNotEmpty) {
      try {
        await fs.syncAgentSkillLinks(
          workspaceId,
          agentSlug,
          agent.skills.toList(),
        );
      } catch (e, st) {
        CcInfraLog.warning(
          'AgentDispatchService: skill heal failed for $agentSlug: $e\n$st',
        );
      }
    }

    // Resolve the per-agent overlay cwd (AGENTS.md + .agents + repos symlinks)
    // with isolated CoW worktrees. Reuses any worktree pre-provisioned for a
    // ticket; degrades to [workingDirectory] (the agent dir) when unavailable.
    final resolvedWorkingDirectory = await _resolveWorkingDirectory(
      workspaceId: workspaceId,
      channelId: channelId ?? conversationId,
      ticketId: ticketId,
      agentSlug: agentSlug,
      agentConfigDir: workingDirectory,
      fallback: workingDirectory,
    );

    final runLogId = _uuid.v4();
    final startedAt = DateTime.now();

    // Park this run when another in-flight run owns the same working directory:
    // the path lock serializes same-path dispatches and surfaces the wait as a
    // `waiting_local_directory` task state. Released when the run's event stream
    // ends. No-op (acquires instantly) when the feature is off or the path is
    // free — the common case, since worktrees are per-conversation isolated.
    PathLockHandle? pathLockHandle;
    final pathLock = _pathLock;
    if (pathLock != null) {
      pathLockHandle = await pathLock.acquire(
        resolvedWorkingDirectory,
        runLogId,
        onWait: (holder) => _eventBus?.publish(
          TaskWaitingLocalDirectory(
            taskId: runLogId,
            seq: 0,
            lockedPath: resolvedWorkingDirectory,
            holderTaskId: holder,
            workspaceId: workspaceId,
            agentId: agentId,
            occurredAt: DateTime.now(),
          ),
        ),
      );
    }

    // Resolve per-adapter argv + env overrides (YOLO flags, API keys) from the
    // app-layer resolver when wired; otherwise both stay empty.
    final overrides =
        prepared.resolvedAdapterId == null || adapterLaunchOverrides == null
        ? const (args: <String>[], env: <String, String>{})
        : await adapterLaunchOverrides!(prepared.resolvedAdapterId!);
    final handle = _agentDispatch.start(
      cliName: prepared.cliName,
      prompt: prepared.effectivePrompt,
      // The user's message verbatim, so built-in slash commands are recognized
      // (the layered prompt starts with `<context>`, never a slash).
      userText: prepared.rawUserText,
      workingDirectory: resolvedWorkingDirectory,
      // The agent's global config dir (AGENTS.md + .agents source) is mounted
      // read-only alongside the writable cwd so the overlay symlinks resolve.
      agentConfigDir: workingDirectory,
      modelId: prepared.agent?.modelId,
      agentId: agentId,
      agentName: prepared.agent?.name,
      workspaceId: workspaceId,
      conversationId: prepared.effectiveConversationId,
      runLogId: runLogId,
      ticketId: ticketId,
      requestedByUserId: requestedByUserId,
      wakeContext: wakeContext,
      mode: prepared.mode,
      silenceTimeoutMinutes: prepared.agent?.silenceTimeoutMinutes,
      effortLevel: prepared.agent?.effort,
      adapterArgsOverride: overrides.args,
      adapterEnvOverride: overrides.env,
      costCapCents: costCapCents,
    );
    final runLog = AgentRunLog(
      id: runLogId,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: prepared.effectiveConversationId,
      ticketId: ticketId,
      startedAt: startedAt,
      status: RunStatus.pending,
      adapter: prepared.resolvedAdapterId,
      modelId: prepared.agent?.modelId,
      pipelineRunId: pipelineRunId,
      pipelineStepRunId: pipelineStepId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
      role: role,
    );
    await _runLogRepo?.upsert(runLog);

    _runToDispatch[runLogId] = handle.dispatchId;

    // Track the agent in the process-global registry so the work-aware roster
    // can show who is alive and what they are doing. Only workspace-scoped
    // dispatches join the roster (workspace is the isolation boundary); a
    // workspace-less one-shot run is not part of any workspace's roster.
    final trackedRegistry = (_registry != null && workspaceId.isNotEmpty)
        ? _registry
        : null;
    if (trackedRegistry != null) {
      trackedRegistry.register(
        RegisterAgentInput(
          id: agentId,
          displayName: prepared.agent?.name ?? agentId,
          workspaceId: workspaceId,
          conversationId: prepared.effectiveConversationId,
          dispatchId: handle.dispatchId,
          // Mirror the run's role into the live roster so the Agent Hub shows
          // main vs sub vs advisor. Names align across the two enums.
          kind: AgentKind.values.byName(role.name),
          parentId: parentAgentId,
        ),
      );
    }

    // Per-dispatch repeating-tool-call guard (PRD 06 #3). Detects the agent
    // calling the same tool with identical args N times in a row and flags the
    // run as looping so it surfaces in observability (and, with the harness,
    // can be steered/aborted before it burns unbounded tokens).
    final doomLoop = DoomLoopDetector();
    // Latch so the loop side effects (roster notice + the looping-liveness DB
    // write) fire exactly once per dispatch, not on every subsequent identical
    // tool call once the streak is past threshold.
    var loopMarked = false;

    return AgentDispatchResult(
      // Tap the event stream to keep the roster live: tool calls become the
      // agent's current activity, and the terminal DoneEvent flips it to idle.
      // The same tap feeds the doom-loop detector. `.map` preserves the
      // stream's single-subscription / broadcast nature and only runs while the
      // consumer is listening, so it adds no overhead to an unconsumed stream.
      stream: _withLockRelease(
        handle.events.map((event) {
          if (trackedRegistry != null) {
            _updateRegistryFromEvent(trackedRegistry, agentId, event);
          }
          if (!loopMarked) {
            final loopingTool = _recordDoomLoop(doomLoop, event);
            if (loopingTool != null) {
              loopMarked = true;
              trackedRegistry?.setActivity(agentId, 'doom loop: $loopingTool');
              unawaited(_markLooping(workspaceId, runLogId));
            }
          }
          return event;
        }),
        pathLockHandle,
      ),
      dispatchId: handle.dispatchId,
      runLog: runLog,
      agent: prepared.agent,
    );
  }

  /// Releases [handle] (the working-directory path lock) when [source]
  /// completes, so the next dispatch parked on the same path can proceed.
  /// Returns [source] unchanged when there is no lock to release.
  Stream<AgentProcessEvent> _withLockRelease(
    Stream<AgentProcessEvent> source,
    PathLockHandle? handle,
  ) {
    if (handle == null) {
      return source;
    }
    return source.transform(
      StreamTransformer<AgentProcessEvent, AgentProcessEvent>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) =>
            sink.addError(error, stackTrace),
        handleDone: (sink) {
          handle.release();
          sink.close();
        },
      ),
    );
  }

  /// Feeds a tool call to [doomLoop] and returns the tool name when this call
  /// crosses into a detected repeating-call loop, or null otherwise (including
  /// for non-tool events). The caller latches so the response fires once.
  String? _recordDoomLoop(DoomLoopDetector doomLoop, AgentProcessEvent event) {
    if (event is! ToolCallEvent) {
      return null;
    }
    final decision = doomLoop.record(
      ToolCallSignature.from(event.toolName, event.inputs),
    );
    return decision == DoomLoopDecision.detected ? event.toolName : null;
  }

  /// Marks [runLogId] as looping (idempotent — only the first transition writes).
  Future<void> _markLooping(String workspaceId, String runLogId) async {
    final run = await _runLogRepo?.getById(workspaceId, runLogId);
    if (run != null && run.liveness != RunLiveness.looping) {
      await _runLogRepo?.upsert(run.copyWith(liveness: RunLiveness.looping));
    }
  }

  /// Reflects a single dispatch event into the registry: a tool call sets the
  /// agent's current activity (normalized by the registry), and the terminal
  /// [DoneEvent] marks the agent idle. Other events are roster-irrelevant.
  void _updateRegistryFromEvent(
    AgentRegistry registry,
    String agentId,
    AgentProcessEvent event,
  ) {
    switch (event) {
      case ToolCallEvent(:final toolName):
        if (toolName.isNotEmpty) {
          registry.setActivity(agentId, toolName);
        }
      case DoneEvent():
        registry.setStatus(agentId, AgentStatus.idle);
      default:
        break;
    }
  }

  /// Derives the per-agent slug used to key the conversation overlay cwd. The
  /// slug mirrors [WorkspaceFilesystemService.agentDir] / [HireAgentUseCase]:
  /// `slugify(agent.name)`; falls back to the agent id (or `oneshot`) when no
  /// agent was resolved.
  static String _slugFor(Agent? agent, String agentId) {
    if (agent != null && agent.name.isNotEmpty) {
      final slug = slugify(agent.name);
      if (slug.isNotEmpty) {
        return slug;
      }
    }
    return agentId.isNotEmpty ? agentId : 'oneshot';
  }

  /// Resolves the agent's working directory to the per-agent conversation
  /// overlay (sharing the conversation's isolated repo worktrees), or returns
  /// [fallback] (the agent dir) when no provisioner is wired / there is no
  /// conversation+workspace context.
  ///
  /// [agentSlug] keys the overlay (`agents/<slug>/`); [agentConfigDir] is the
  /// agent's global dir — the symlink-target source for the overlay's AGENTS.md
  /// + `.agents`.
  Future<String> _resolveWorkingDirectory({
    required String workspaceId,
    required String? channelId,
    required String? ticketId,
    required String agentSlug,
    String? agentConfigDir,
    required String fallback,
  }) async {
    final provisioner = _repoProvisioner;
    if (provisioner == null ||
        workspaceId.isEmpty ||
        channelId == null ||
        channelId.isEmpty) {
      return fallback;
    }
    return provisioner.ensureConversationWorkspace(
      workspaceId: workspaceId,
      channelId: channelId,
      agentSlug: agentSlug,
      fallbackDir: fallback,
      agentConfigDir: agentConfigDir,
      ticketId: ticketId,
    );
  }

  /// Marks [runLog] completed (idempotent) and forgets its dispatch mapping.
  ///
  /// The workspace comes from [AgentRunLog.workspaceId] — the run owns it. A run
  /// log with no workspace was never persisted (the repository rejects it), so
  /// there is no row to complete and only the roster is updated.
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {
    _runToDispatch.remove(runLog.id);
    // The run is over: the agent stays in the roster but goes idle. Idempotent
    // with the DoneEvent tap (setStatus no-ops when already idle).
    _registry?.setStatus(runLog.agentId, AgentStatus.idle);
    final workspaceId = runLog.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return;
    }
    final existing = await _runLogRepo?.getById(workspaceId, runLog.id);
    if (existing == null || existing.completedAt != null) {
      return;
    }
    // Complete from the freshly-read row, not the stale dispatch-time [runLog]:
    // a subagent may have rolled cost into this run's `childCostCents` while it
    // was in flight, and the dispatch-time object still carries 0. Writing from
    // `existing` preserves that propagated rollup (and any other server-side
    // field) instead of clobbering it back to its dispatch-time default.
    // A run already marked `silentRun` ended without its declared deliverable,
    // and that summary is the honest one — do not overwrite it with the model's
    // last chatter. `liveness`/`errorFamily` survive automatically (copyWith
    // preserves what it does not name).
    final unmetDeliverable = existing.errorFamily == RunErrorFamily.silentRun;
    final completedAt = DateTime.now();
    await _runLogRepo?.upsert(
      existing.copyWith(
        completedAt: completedAt,
        status: RunStatus.completed,
        summary: unmetDeliverable ? existing.summary : summary,
        cost: _timed(cost, existing.startedAt, completedAt),
      ),
    );
    await _propagateCostToParent(
      workspaceId,
      runLog.agentId,
      cost?.estimatedCostCents ?? 0,
    );
  }

  /// Stamps [cost] with the run's wall-clock duration when nothing upstream
  /// measured one.
  ///
  /// A subagent times itself (`DispatchSession._spawnSubagent` — it has no
  /// process for the reaper to time), but a TOP-LEVEL run's duration can only
  /// come from `UsageEvent.durationMs`, and the built-in harness emits usage
  /// without it. Left alone, every main run persists `durationMs: null` and its
  /// activity header reads "—". Measured here, at the one place that already
  /// knows both ends of the run, so it holds for every adapter.
  RunCost? _timed(RunCost? cost, DateTime startedAt, DateTime completedAt) {
    final elapsed = completedAt.difference(startedAt).inMilliseconds;
    if (cost == null) {
      return RunCost(durationMs: elapsed);
    }
    // A real per-turn measurement is more precise than wall clock — keep it.
    if (cost.durationMs != null && cost.durationMs != 0) {
      return cost;
    }
    return RunCost(
      inputTokens: cost.inputTokens,
      outputTokens: cost.outputTokens,
      thoughtTokens: cost.thoughtTokens,
      cachedReadTokens: cost.cachedReadTokens,
      cachedWriteTokens: cost.cachedWriteTokens,
      estimatedCostCents: cost.estimatedCostCents,
      durationMs: elapsed,
      timeToFirstTokenMs: cost.timeToFirstTokenMs,
    );
  }

  /// Rolls this run's spend up into its spawning parent's run, if any: looks up
  /// the parent agent in the registry, finds the parent's active run, and adds
  /// [amountCents] to its `childCostCents` via the concurrency-safe propagator
  /// (so parallel subagent completions sum without lost updates). A no-op when
  /// there is no parent, no active parent run, or nothing to add.
  ///
  /// The parent run is looked up inside [workspaceId] — the child's own
  /// workspace. A spawning parent always shares it: a subagent cannot cross the
  /// isolation boundary.
  Future<void> _propagateCostToParent(
    String workspaceId,
    String agentId,
    int amountCents,
  ) async {
    if (amountCents <= 0) {
      return;
    }
    final parentId = _registry?.get(agentId)?.parentId;
    if (parentId == null) {
      return;
    }
    final parentRun = await _runLogRepo?.activeRunForAgent(
      workspaceId,
      parentId,
    );
    if (parentRun == null) {
      return;
    }
    await _costPropagatorFor(workspaceId).propagate(parentRun.id, amountCents);
  }

  /// Marks [runLog] failed (idempotent) and forgets its dispatch mapping.
  ///
  /// Workspace-sourced from [AgentRunLog.workspaceId], like [completeRun].
  Future<void> failRun(AgentRunLog runLog, String error) async {
    _runToDispatch.remove(runLog.id);
    // The run ended (in error): the agent goes idle but stays registered so it
    // can be re-dispatched. A hard kill maps to `aborted`, not here.
    _registry?.setStatus(runLog.agentId, AgentStatus.idle);
    final workspaceId = runLog.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return;
    }
    final existing = await _runLogRepo?.getById(workspaceId, runLog.id);
    if (existing != null && existing.completedAt == null) {
      // Fail from the freshly-read row (preserves any propagated childCostCents
      // and other server-side fields), not the stale dispatch-time object.
      final completedAt = DateTime.now();
      await _runLogRepo?.upsert(
        existing.copyWith(
          completedAt: completedAt,
          status: RunStatus.error,
          summary: error,
          // A run that died after 20 minutes is a different diagnosis from one
          // that died on the first turn, so a failure gets timed too.
          cost: _timed(existing.cost, existing.startedAt, completedAt),
        ),
      );
    }
  }

  /// Delivers a mid-run steering [message] to the in-flight dispatch backing
  /// [runLogId] (built-in harness only). Returns true when a live run received
  /// it; false when the run has no active dispatch (finished, or an external-CLI
  /// transport with no steering channel).
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async {
    final dispatchId = _runToDispatch[runLogId];
    if (dispatchId == null) {
      return false;
    }
    return _agentDispatch.steerDispatch(
      dispatchId,
      message,
      followUp: followUp,
    );
  }

  /// Pauses the run's built-in harness loop at its next clean turn boundary
  /// (take-over, PRD 16 §8). Returns true when a pausable run accepted it.
  Future<bool> pauseRun(String runLogId) async {
    final dispatchId = _runToDispatch[runLogId];
    if (dispatchId == null) {
      return false;
    }
    return _agentDispatch.pauseDispatch(dispatchId);
  }

  /// Releases a paused run (hand-back). Returns true when a live dispatch
  /// received it.
  Future<bool> resumeRun(String runLogId) async {
    final dispatchId = _runToDispatch[runLogId];
    if (dispatchId == null) {
      return false;
    }
    return _agentDispatch.resumeDispatch(dispatchId);
  }

  /// Stops the in-flight process backing the run identified by [runLogId] within
  /// [workspaceId].
  ///
  /// Terminates only that dispatch (other concurrent runs are unaffected) and
  /// closes the run log if the terminate path did not already stamp it. Safe to
  /// call for an already-finished run — it becomes a no-op. A run id belonging
  /// to another workspace resolves to no row, so the close is skipped.
  Future<void> stopRun(String workspaceId, String runLogId) async {
    final dispatchId = _runToDispatch.remove(runLogId);
    if (dispatchId != null) {
      await _agentDispatch.stopDispatch(dispatchId);
    }
    final existing = await _runLogRepo?.getById(workspaceId, runLogId);
    if (existing != null && existing.completedAt == null) {
      // The run was stopped: the agent goes idle (still registered and
      // re-dispatchable). The id comes from the run log so the registry stays
      // in sync even when only the run id is known.
      _registry?.setStatus(existing.agentId, AgentStatus.idle);
      await _runLogRepo?.upsert(
        existing.copyWith(
          completedAt: DateTime.now(),
          status: RunStatus.error,
          summary: 'Stopped by user',
        ),
      );
    }
  }
}
