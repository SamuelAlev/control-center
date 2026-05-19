import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/services/run_liveness_classifier.dart';
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
import 'package:cc_infra/src/dispatch/claude_refusal_message.dart';
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

/// Orchestrates agent dispatch: prompt building, workspace provisioning and process spawning.
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
    this.resolveClaudeConfigDir,
    this.resolveHarnessRotation,
    this.onHarnessCredentialExhausted,
    this.credentialGate,
    this.onRunEnded,
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

  /// Resolves which Claude Code account directory a run signs in as.
  ///
  /// Returns that account's `CLAUDE_CONFIG_DIR`, or null when the install
  /// manages no accounts and the CLI should resolve its own credential.
  /// Server-scoped for the same reason as [adapterLaunchOverrides]: the
  /// directory is on THIS host.
  ///
  /// It takes the conversation rather than only an account id because the
  /// composer's pick is stored per conversation — resolving it here keeps
  /// every dispatch entry point (chat, tickets, pipelines, the goal
  /// supervisor) on the operator's choice without each one having to know the
  /// feature exists. An explicit `accountId` still wins, for a caller that
  /// genuinely means one specific login.
  ///
  /// `workingDirectory` is the resolved cwd of the run about to start. The
  /// resolver needs it because Claude Code's workspace-trust dialog is keyed by
  /// project path and is per config dir: without it, a dispatched run silently
  /// drops the project's `permissions.allow` entries.
  final Future<ClaudeAccountPlan?> Function({
    String? workspaceId,
    String? conversationId,
    String? agentId,
    String? accountId,
    String? workingDirectory,
  })?
  resolveClaudeConfigDir;

  /// Orders a harness provider's stored credentials for one run — the harness
  /// half of account pools. See `DispatchSession.onResolveHarnessRotation`.
  final Future<List<String>?> Function({
    String? workspaceId,
    String? agentId,
    required String providerId,
    required List<String> credentialIds,
  })?
  resolveHarnessRotation;

  /// Records a harness credential that ran out of quota.
  final Future<void> Function({
    required String providerId,
    required String credentialId,
  })?
  onHarnessCredentialExhausted;

  /// Parks a run whose Claude Code account cannot serve it — signed out, past
  /// repair, or out of plan headroom — instead of failing the turn, and lets it
  /// continue once a human fixes the credential.
  ///
  /// The Claude half of the gate lives HERE rather than in the session, and the
  /// reason is the sandbox: the profile's writable set is built from the
  /// resolved account directories before the process is spawned, so a run that
  /// parked inside the session and came back on a DIFFERENT account (or on the
  /// first account at all, having resolved none) would hold a directory its own
  /// sandbox denies. Re-resolving before the session exists is what makes the
  /// resumed run indistinguishable from one that never blocked. The harness
  /// half stays in the session, where its credential reaches the provider
  /// in-process and no profile has to agree.
  ///
  /// Null keeps the pre-gate behaviour exactly: the refusal is carried into the
  /// session and the turn fails with the message it always did.
  final RunCredentialGatePort? credentialGate;

  /// Notified (fire-and-forget, after the run log row is stamped terminal) when
  /// a run completes, fails or is stopped — the steering queue's
  /// "last run ended; convert what is still queued" trigger.
  ///
  /// Late-bound (a plain mutable field) because the steering queue service is
  /// constructed after this one and needs the dispatch service itself to reach
  /// live sessions — a constructor cycle otherwise.
  void Function(String workspaceId, String conversationId, String? spaceId)?
  onRunEnded;

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
  /// selects the run log's database and per-parent locking stays correct
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
    String? spaceId,
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
    String? claudeAccountId,
    List<String> promptImageRefs = const [],
    String? modelOverride,
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
      spaceId: spaceId,
      conversationId: conversationId,
      adapterId: adapterId,
      wakeContext: wakeContext,
      mentionContext: mentionContext,
    );

    final agent = prepared.agent;
    final agentSlug = agentSlugFor(agent, agentId);

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
      // The SPACE owns the copy-on-write worktree (its conversations share
      // it), and a conversation id can no longer stand in for it — a run with
      // no space simply falls back to the agent's own directory.
      spaceId: spaceId,
      ticketId: ticketId,
      agentSlug: agentSlug,
      agentConfigDir: workingDirectory,
      fallback: workingDirectory,
    );

    // Stopped while we were waiting for the clone. Refuse LOUDLY rather than
    // starting the agent in the fallback directory: the caller asked for a run
    // in a workspace that no longer exists, and silently running it somewhere
    // else is the failure this guard exists to prevent. Thrown before the run
    // log is written, so nothing terminal is left behind either.
    if (_spaceProvisioningStopped(workspaceId, spaceId)) {
      throw StateError(
        'Dispatch refused: preparation of space $spaceId was stopped',
      );
    }

    final runLogId = _uuid.v4();

    // Which Claude Code account this run signs in as. Resolved for EVERY
    // adapter, not only `claude-code`: an ACP agent that shells out to `claude`
    // needs the same directory readable and writable, and the dispatch session
    // ignores the value when nothing uses it.
    //
    // Resolved (and, when it refuses, gated) BEFORE the path lock on purpose. A
    // run parked on a credential can sit there for minutes, and holding the
    // working directory's lease for that whole time would park every other
    // dispatch into the same worktree behind a run that has not started.
    final claudePlan = await _resolveClaudeAccounts(
      workspaceId: workspaceId,
      conversationId: prepared.effectiveConversationId,
      agentId: agentId,
      accountId: claudeAccountId,
      spaceId: spaceId,
      agentName: prepared.agent?.name,
      runLogId: runLogId,
    );

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

    // Everything from here to the hand-off runs under the lock, so a throw in
    // between must give it back. Without this the lease leaked: the release is
    // wired to the event stream's `done`, and a dispatch that failed BEFORE
    // there was a stream (the account plan, the process spawn) left the path
    // held by a run that no longer existed. Every later dispatch into that same
    // working directory then parked forever — no process, no run log, and a
    // pipeline step suspended on a task that was never created. That is a wedge
    // only a server restart clears, and it is silent.
    try {
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
        // A retry-with-a-different-model overrides the agent's configured
        // one for this run only; the agent record is untouched.
        modelId: modelOverride ?? prepared.agent?.modelId,
        agentId: agentId,
        agentName: prepared.agent?.name,
        workspaceId: workspaceId,
        conversationId: prepared.effectiveConversationId,
        spaceId: spaceId,
        runLogId: runLogId,
        ticketId: ticketId,
        requestedByUserId: requestedByUserId,
        wakeContext: wakeContext,
        mode: prepared.mode,
        // Blob references for images the human attached to the triggering
        // message; the dispatch session resolves them per workspace.
        imagePaths: promptImageRefs.isEmpty ? null : promptImageRefs,
        silenceTimeoutMinutes: prepared.agent?.silenceTimeoutMinutes,
        effortLevel: prepared.agent?.effort,
        adapterArgsOverride: overrides.args,
        adapterEnvOverride: overrides.env,
        claudeConfigDir: claudePlan?.accounts.firstOrNull?.configDir,
        claudeAccounts: claudePlan?.accounts ?? const [],
        onClaudeAccountExhausted: claudePlan?.onExhausted,
        onClaudeAccountAuthFailed: claudePlan?.onAuthFailed,
        // Carried rather than thrown. A throw here happens BEFORE the run log
        // exists, so the operator would get an exception and an empty
        // conversation; routed through the session it reaches them as a failed
        // turn with a reason, and only on the transport it actually applies to.
        claudeAccountsSpent: claudePlan?.refusal,
        onResolveHarnessRotation: resolveHarnessRotation,
        onHarnessCredentialExhausted: onHarnessCredentialExhausted,
        costCapCents: costCapCents,
      );
      final runLog = AgentRunLog(
        id: runLogId,
        agentId: agentId,
        workspaceId: workspaceId,
        conversationId: prepared.effectiveConversationId,
        // The space the run belongs to. It used to be left null and read back
        // as `spaceId ?? conversationId`, which only worked while the two ids
        // were the same value.
        spaceId: spaceId,
        ticketId: ticketId,
        startedAt: startedAt,
        status: RunStatus.pending,
        adapter: prepared.resolvedAdapterId,
        modelId: prepared.agent?.modelId,
        pipelineRunId: pipelineRunId,
        pipelineStepId: pipelineStepId,
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
        // agent's current activity and the terminal DoneEvent flips it to idle.
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
                trackedRegistry?.setActivity(
                  agentId,
                  'doom loop: $loopingTool',
                );
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
    } on Object {
      pathLockHandle?.release();
      rethrow;
    }
  }

  /// Releases [handle] (the working-directory path lock) when [source] ends,
  /// so the next dispatch parked on the same path can proceed.
  ///
  /// "Ends" means done, error-then-done, OR the listener cancelling — and the
  /// last one is why this is a controller rather than a
  /// `StreamTransformer.fromHandlers`. That transformer has no cancel handler,
  /// so a run that was stopped, interrupted, or whose consumer went away closed
  /// its subscription without ever reaching `handleDone`: the path stayed held
  /// by a run that no longer existed, and every later dispatch into that
  /// working directory parked forever. Nothing surfaces that — no process, no
  /// run log, a pipeline step suspended on a task that was never created — and
  /// only a server restart clears it.
  ///
  /// [PathLockHandle.release] is idempotent, so releasing on whichever of the
  /// three arrives first is safe.
  Stream<AgentProcessEvent> _withLockRelease(
    Stream<AgentProcessEvent> source,
    PathLockHandle? handle,
  ) {
    if (handle == null) {
      return source;
    }
    late final StreamController<AgentProcessEvent> controller;
    StreamSubscription<AgentProcessEvent>? sub;
    controller = StreamController<AgentProcessEvent>(
      onListen: () {
        sub = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            handle.release();
            controller.close();
          },
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () {
        handle.release();
        return sub?.cancel();
      },
    );
    return controller.stream;
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
  /// agent's current activity (normalized by the registry) and the terminal
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

  /// Resolves this run's Claude Code accounts, parking the dispatch rather than
  /// letting it fail when none of them can serve it.
  ///
  /// The loop is what "continue with the discussion" means in practice: the
  /// plan is re-resolved from scratch after every unblock, so an operator who
  /// signed into a DIFFERENT account, or into the only one there was, gets a run
  /// that starts on what they just fixed. A single re-check would instead resume
  /// on the stale directory that had already refused.
  ///
  /// It re-parks (rather than giving up) when the fresh plan still refuses:
  /// pressing "retry" too early, or a second account expiring while the first
  /// was being fixed, is a reason to keep waiting, not to lose the turn. The
  /// registry's own deadline is what bounds the whole wait, so this cannot spin.
  ///
  /// Every exit that is not a usable plan returns the refusal untouched, which
  /// the session then reports exactly as it did before the gate existed.
  Future<ClaudeAccountPlan?> _resolveClaudeAccounts({
    required String workspaceId,
    required String? conversationId,
    required String? agentId,
    required String? accountId,
    required String? spaceId,
    required String? agentName,
    required String runLogId,
  }) async {
    final resolve = resolveClaudeConfigDir;
    if (resolve == null) {
      return null;
    }
    Future<ClaudeAccountPlan?> resolveOnce() => resolve(
      workspaceId: workspaceId,
      conversationId: conversationId,
      agentId: agentId,
      accountId: accountId,
    );

    var plan = await resolveOnce();
    final gate = credentialGate;
    if (gate == null) {
      return plan;
    }
    while (plan?.refusal != null) {
      final refusal = plan!.refusal!;
      final outcome = await gate.awaitCredentials(
        RunCredentialBlockRequest(
          lane: RunCredentialLane.claudeCode,
          reason: refusal.reason,
          detail: claudeRefusalDetail(refusal),
          runLogId: runLogId,
          accountIds: refusal.accountIds,
          availableAt: refusal.earliestReset,
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: conversationId,
          agentId: agentId,
          agentName: agentName,
        ),
        // Re-resolving IS the probe: it re-reads the registry, re-mirrors each
        // credential from the keychain and re-reads plan headroom, which is the
        // only way to observe a `claude auth login` that happened in a terminal
        // the server never saw.
        recheck: () async => (await resolveOnce())?.refusal == null,
      );
      if (outcome != RunCredentialOutcome.resolved) {
        return plan;
      }
      plan = await resolveOnce();
    }
    return plan;
  }

  /// Whether the space this dispatch is for had its workspace preparation
  /// STOPPED (the pipeline run that owned it was cancelled, or a human pressed
  /// stop in the space).
  ///
  /// Checked after the working directory resolves, because that is where a
  /// dispatch waits out a clone: a cancelled provision returns the agent's own
  /// global dir as its fallback, and starting the agent there would run the
  /// work somebody just stopped, against the wrong tree.
  bool _spaceProvisioningStopped(String workspaceId, String? spaceId) {
    final provisioner = _repoProvisioner;
    if (provisioner == null ||
        workspaceId.isEmpty ||
        spaceId == null ||
        spaceId.isEmpty) {
      return false;
    }
    return provisioner.isSpaceProvisioningCancelled(workspaceId, spaceId);
  }

  /// Resolves the agent's working directory to the per-agent overlay in the
  /// SPACE's root (sharing the space's isolated repo worktrees), or returns
  /// [fallback] (the agent dir) when no provisioner is wired / there is no
  /// space+workspace context.
  ///
  /// [agentSlug] keys the overlay (`agents/<slug>/`); [agentConfigDir] is the
  /// agent's global dir — the symlink-target source for the overlay's AGENTS.md
  /// + `.agents`.
  Future<String> _resolveWorkingDirectory({
    required String workspaceId,
    required String? spaceId,
    required String? ticketId,
    required String agentSlug,
    String? agentConfigDir,
    required String fallback,
  }) async {
    final provisioner = _repoProvisioner;
    if (provisioner == null ||
        workspaceId.isEmpty ||
        spaceId == null ||
        spaceId.isEmpty) {
      return fallback;
    }
    return provisioner.ensureSpaceWorkspace(
      workspaceId: workspaceId,
      spaceId: spaceId,
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
    // was in flight and the dispatch-time object still carries 0. Writing from
    // `existing` preserves that propagated rollup (and any other server-side
    // field) instead of clobbering it back to its dispatch-time default.
    // A run already marked `silentRun` ended without its declared deliverable,
    // and that summary is the honest one — do not overwrite it with the model's
    // last chatter. `liveness`/`errorFamily` survive automatically (copyWith
    // preserves what it does not name).
    final unmetDeliverable = existing.errorFamily == RunErrorFamily.silentRun;
    final completedAt = DateTime.now();
    final completed = existing.copyWith(
      completedAt: completedAt,
      status: RunStatus.completed,
      summary: unmetDeliverable ? existing.summary : summary,
      cost: _timed(cost, existing.startedAt, completedAt),
    );
    // Classify the FINISHED row. [RunLivenessClassifier] reads `status` and
    // `summary`, so it has to run after both are set — and it has to run at
    // all: it had no production call site, so `liveness_class` only ever held
    // what some other write happened to leave there, and every completed run
    // read back as `empty` however much it produced.
    //
    // A contract-unmet run keeps the verdict `_markContractUnmet` already
    // recorded, for the same reason it keeps its summary: that one was decided
    // against the deliverable, which the classifier cannot see.
    await _runLogRepo?.upsert(
      unmetDeliverable
          ? completed
          : completed.copyWith(
              liveness: const RunLivenessClassifier().classify(completed),
            ),
    );
    _notifyRunEnded(runLog);
    await _propagateCostToParent(
      workspaceId,
      runLog.agentId,
      cost?.estimatedCostCents ?? 0,
    );
  }

  /// Fires [onRunEnded] when the caller has just stamped a run terminal.
  ///
  /// Fire-and-forget on purpose: the steering-queue conversion it triggers
  /// reads the run log (which now shows the run completed) and must never sit
  /// on the run-completion path.
  void _notifyRunEnded(AgentRunLog runLog) {
    final hook = onRunEnded;
    final workspaceId = runLog.workspaceId;
    if (hook == null || workspaceId == null || workspaceId.isEmpty) {
      return;
    }
    scheduleMicrotask(
      () => hook(workspaceId, runLog.conversationId ?? '', runLog.spaceId),
    );
  }

  /// Stamps [cost] with the run's wall-clock duration when nothing upstream
  /// measured one.
  ///
  /// A subagent times itself (`DispatchSession._spawnSubagent` — it has no
  /// process for the reaper to time), but a TOP-LEVEL run's duration can only
  /// come from `UsageEvent.durationMs` and the built-in harness emits usage
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
  /// the parent agent in the registry, finds the parent's active run and adds
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
      final failed = existing.copyWith(
        completedAt: completedAt,
        status: RunStatus.error,
        summary: error,
        // A run that died after 20 minutes is a different diagnosis from one
        // that died on the first turn, so a failure gets timed too.
        cost: _timed(existing.cost, existing.startedAt, completedAt),
      );
      // Classified for the same reason as the completed path — and it is worth
      // more here, because this is where the classifier separates a process we
      // lost (`dead`) from one that reported it was blocked (`blocked`) from an
      // ordinary failure.
      await _runLogRepo?.upsert(
        failed.copyWith(
          liveness: const RunLivenessClassifier().classify(failed),
        ),
      );
      _notifyRunEnded(runLog);
    }
  }

  /// Delivers a mid-run steering [message] to the in-flight dispatch backing
  /// [runLogId] (built-in harness only). Returns true when a live run received
  /// it; false when the run has no active dispatch (finished, or an external-CLI
  /// transport with no steering space).
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
      _notifyRunEnded(existing);
    }
  }
}

/// Derives the per-agent slug used to key the conversation overlay cwd. The
/// slug mirrors [WorkspaceFilesystemService.agentDir] / [HireAgentUseCase]:
/// `slugify(agent.name)`; falls back to the agent id (or `oneshot`) when no
/// agent was resolved.
///
/// Top-level and public so the context-inspection path resolves the SAME
/// overlay key a dispatch would — a second slug rule would point the explorer
/// at a directory the run never reads.
String agentSlugFor(Agent? agent, String agentId) {
  if (agent != null && agent.name.isNotEmpty) {
    final slug = slugify(agent.name);
    if (slug.isNotEmpty) {
      return slug;
    }
  }
  return agentId.isNotEmpty ? agentId : 'oneshot';
}

/// The Claude Code accounts one dispatch may use, plus how to report a limit.
///
/// Built by the server (which owns the account directories) and handed to the
/// dispatch port, so the dispatch layer never has to know where credentials
/// live — only which ones this run may try, in order.
class ClaudeAccountPlan {
  /// Creates a [ClaudeAccountPlan].
  const ClaudeAccountPlan({
    required this.accounts,
    this.onExhausted,
    this.onAuthFailed,
    this.refusal,
  });

  /// The accounts to try, best first. The first is the one the run starts on.
  final List<({String accountId, String configDir})> accounts;

  /// Records an observed plan limit so later dispatches skip that account.
  final Future<void> Function({required String accountId, DateTime? resetsAt})?
  onExhausted;

  /// Records an observed authentication failure (an expired OAuth token, a
  /// directory that is no longer signed in) so later dispatches skip that
  /// account until a human signs it back in.
  final Future<void> Function({required String accountId, String? reason})?
  onAuthFailed;

  /// Set instead of [accounts] when every attached account is spent.
  final ClaudeAccountRefusal? refusal;
}
