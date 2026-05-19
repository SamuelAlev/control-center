import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/mention_context.dart';
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
    this.adapterLaunchOverrides,
  })  : _agentDispatch = agentDispatch,
        _dispatchUseCase = dispatchUseCase,
        _runLogRepo = runLogRepo,
        _repoProvisioner = repoProvisioner,
        _registry = registry;

  final AgentDispatchPort _agentDispatch;
  final DispatchAgentUseCase _dispatchUseCase;
  final AgentRunLogRepository? _runLogRepo;

  /// Process-global registry that tracks every live agent and its work-aware
  /// activity. Optional: when null, dispatch behaves exactly as before (the
  /// roster is simply not populated). Injected with the process-global instance
  /// at the composition root.
  final AgentRegistry? _registry;

  /// Optional resolver for per-adapter argv + env overrides (e.g. YOLO flags,
  /// API keys). Injected by the app layer (which owns the secure store + prefs);
  /// null leaves both empty. The adapter id is the resolved adapter id.
  final Future<({List<String> args, Map<String, String> env})> Function(
    String adapterId,
  )? adapterLaunchOverrides;


  /// Provisions/reuses the per-conversation working root with isolated repo
  /// worktrees and returns it as the agent's working directory. Optional —
  /// when null, the passed [dispatch] working directory is used unchanged.
  final RepoWorkspaceProvisionerPort? _repoProvisioner;

  /// Maps a live run log id to the dispatch id of its in-flight process, so a
  /// specific run can be stopped without cross-killing other concurrent
  /// dispatches. Entries are added on [dispatch] and removed when the run
  /// completes, fails, or is stopped.
  final Map<String, String> _runToDispatch = {};

  final _uuid = const Uuid();

  /// Dispatches an agent to process a prompt, returning a stream of events and metadata.
  Future<AgentDispatchResult> dispatch({
    required String agentId,
    required String prompt,
    required String workingDirectory,
    String? adapterId,
    String? workspaceId,
    String? conversationId,
    String? channelId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
    WakeContext? wakeContext,
    MentionContext? mentionContext,
  }) async {
    // Resolve the per-conversation working root (AGENTS.md + .mcp.json +
    // repos/) with isolated CoW worktrees. Reuses any worktree pre-provisioned
    // for a ticket; degrades to [workingDirectory] when unavailable.
    final resolvedWorkingDirectory = await _resolveWorkingDirectory(
      workspaceId: workspaceId,
      channelId: channelId ?? conversationId,
      ticketId: ticketId,
      fallback: workingDirectory,
    );

    final prepared = await _dispatchUseCase.execute(
      agentId: agentId,
      prompt: prompt,
      channelId: channelId,
      conversationId: conversationId,
      adapterId: adapterId,
      workingDirectory: resolvedWorkingDirectory,
      wakeContext: wakeContext,
      mentionContext: mentionContext,
    );

    final runLogId = _uuid.v4();
    final startedAt = DateTime.now();

    // Resolve per-adapter argv + env overrides (YOLO flags, API keys) from the
    // app-layer resolver when wired; otherwise both stay empty.
    final overrides = prepared.resolvedAdapterId == null || adapterLaunchOverrides == null
        ? const (args: <String>[], env: <String, String>{})
        : await adapterLaunchOverrides!(prepared.resolvedAdapterId!);
    final handle = _agentDispatch.start(
      cliName: prepared.cliName,
      prompt: prepared.effectivePrompt,
      workingDirectory: resolvedWorkingDirectory,
      modelId: prepared.agent?.modelId,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: prepared.effectiveConversationId,
      runLogId: runLogId,
      ticketId: ticketId,
      wakeContext: wakeContext,
      mode: prepared.mode,
      silenceTimeoutMinutes: prepared.agent?.silenceTimeoutMinutes,
      effortLevel: prepared.agent?.effort,
      adapterArgsOverride: overrides.args,
      adapterEnvOverride: overrides.env,
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
      pipelineRunId: pipelineRunId,
      pipelineStepRunId: pipelineStepId,
      expectedOutputSchema: expectedOutputSchema,
      outputContractMode: outputContractMode,
    );
    await _runLogRepo?.upsert(runLog);

    _runToDispatch[runLogId] = handle.dispatchId;

    // Track the agent in the process-global registry so the work-aware roster
    // can show who is alive and what they are doing. Only workspace-scoped
    // dispatches join the roster (workspace is the isolation boundary); a
    // workspace-less one-shot run is not part of any workspace's roster.
    final wsId = workspaceId;
    final trackedRegistry = (_registry != null && wsId != null && wsId.isNotEmpty)
        ? _registry
        : null;
    if (trackedRegistry != null) {
      trackedRegistry.register(RegisterAgentInput(
        id: agentId,
        displayName: prepared.agent?.name ?? agentId,
        workspaceId: wsId!,
        conversationId: prepared.effectiveConversationId,
        dispatchId: handle.dispatchId,
      ));
    }

    return AgentDispatchResult(
      // Tap the event stream to keep the roster live: tool calls become the
      // agent's current activity, and the terminal DoneEvent flips it to idle.
      // `.map` preserves the stream's single-subscription / broadcast nature
      // and only runs while the consumer is listening, so it adds no overhead
      // to an unconsumed stream.
      stream: trackedRegistry != null
          ? handle.events.map((event) {
              _updateRegistryFromEvent(trackedRegistry, agentId, event);
              return event;
            })
          : handle.events,
      dispatchId: handle.dispatchId,
      runLog: runLog,
      agent: prepared.agent,
    );
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

  /// Resolves the agent's working directory to the per-conversation root with
  /// isolated repo worktrees, or returns [fallback] when no provisioner is
  /// wired / there is no conversation+workspace context.
  ///
  /// [fallback] (the agent dir) holds the agent's `AGENTS.md` + `.mcp.json`,
  /// which are linked into the conversation root so the agent keeps its config
  /// while its repos live under `repos/`.
  Future<String> _resolveWorkingDirectory({
    required String? workspaceId,
    required String? channelId,
    required String? ticketId,
    required String fallback,
  }) async {
    final provisioner = _repoProvisioner;
    if (provisioner == null ||
        workspaceId == null ||
        workspaceId.isEmpty ||
        channelId == null ||
        channelId.isEmpty) {
      return fallback;
    }
    return provisioner.ensureConversationWorkspace(
      workspaceId: workspaceId,
      channelId: channelId,
      fallbackDir: fallback,
      agentConfigDir: fallback,
      ticketId: ticketId,
    );
  }

  /// Marks [runLog] completed (idempotent) and forgets its dispatch mapping.
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {
    _runToDispatch.remove(runLog.id);
    // The run is over: the agent stays in the roster but goes idle. Idempotent
    // with the DoneEvent tap (setStatus no-ops when already idle).
    _registry?.setStatus(runLog.agentId, AgentStatus.idle);
    final existing = await _runLogRepo?.getById(runLog.id);
    if (existing == null || existing.completedAt != null) {
      return;
    }
    await _runLogRepo?.upsert(
      runLog.copyWith(
        completedAt: DateTime.now(),
        status: RunStatus.completed,
        summary: summary,
        cost: cost,
      ),
    );
  }

  /// Marks [runLog] failed (idempotent) and forgets its dispatch mapping.
  Future<void> failRun(AgentRunLog runLog, String error) async {
    _runToDispatch.remove(runLog.id);
    // The run ended (in error): the agent goes idle but stays registered so it
    // can be re-dispatched. A hard kill maps to `aborted`, not here.
    _registry?.setStatus(runLog.agentId, AgentStatus.idle);
    final existing = await _runLogRepo?.getById(runLog.id);
    if (existing != null && existing.completedAt == null) {
      await _runLogRepo?.upsert(
        runLog.copyWith(
          completedAt: DateTime.now(),
          status: RunStatus.error,
          summary: error,
        ),
      );
    }
  }

  /// Stops the in-flight process backing the run identified by [runLogId].
  ///
  /// Terminates only that dispatch (other concurrent runs are unaffected) and
  /// closes the run log if the terminate path did not already stamp it. Safe to
  /// call for an already-finished run — it becomes a no-op.
  Future<void> stopRun(String runLogId) async {
    final dispatchId = _runToDispatch.remove(runLogId);
    if (dispatchId != null) {
      await _agentDispatch.stopDispatch(dispatchId);
    }
    final existing = await _runLogRepo?.getById(runLogId);
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
