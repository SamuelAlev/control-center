import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:control_center/features/dispatch/domain/usecases/build_agent_prompt_use_case.dart';
import 'package:control_center/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
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
  })  : _agentDispatch = agentDispatch,
        _dispatchUseCase = dispatchUseCase,
        _runLogRepo = runLogRepo,
        _repoProvisioner = repoProvisioner;

  final AgentDispatchPort _agentDispatch;
  final DispatchAgentUseCase _dispatchUseCase;
  final AgentRunLogRepository? _runLogRepo;

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
    );
    await _runLogRepo?.upsert(runLog);

    _runToDispatch[runLogId] = handle.dispatchId;

    return AgentDispatchResult(
      stream: handle.events,
      dispatchId: handle.dispatchId,
      runLog: runLog,
      agent: prepared.agent,
    );
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
