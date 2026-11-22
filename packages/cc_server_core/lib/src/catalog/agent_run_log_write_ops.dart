import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/run_settlement.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, SessionCapability;
import 'package:cc_infra/cc_infra.dart' show ProcessDetectionService;

/// A person's stop: one run (`agent_run_log.stop`) or every live run of one
/// agent (`agents.killProcesses`), the one client write on a run log.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// The handlers source `ctx.workspaceId!` (the bound session) and verify
/// the run belongs to it before acting.
///
/// A stop follows the run's space ([requireRunLog], the gate of
/// `agent_run_log.get`): a run in a space the caller may not read answers
/// exactly like a missing one, and `agents.killProcesses` leaves it running
/// and out of its count. A stop is recorded as a person's, which moves the
/// goal, pipeline step or steering queue the run belongs to.
///
/// There is no other write here: no row, cost, descendant cost or runtime
/// classification a client sends. Those are the server's own record, written
/// where the run runs, because the settlement moves goals, pipeline steps,
/// team leaders and steering queues. A run ends only where it runs: the
/// session that ran it, the reaper, or a person's stop ([settleKilledRun]),
/// whose end reason and cost are the server's, never the caller's.
///
/// Both are host work (the process lives in the server's process table),
/// hence `fullClient`-only, and absent when the host wires no process
/// detector: a client then cannot offer the action.
List<RepoOp> buildAgentRunLogWriteOps(
  AgentRunLogRepository agentRunLogRepository, {
  required AgentRepository agentRepository,
  required ProcessDetectionService? processDetection,
  required DomainEventBus? eventBus,
  required Future<void> Function(
    String workspaceId,
    String userId,
    AgentRunLog log,
  )
  requireRunLog,
}) {
  /// Whether [userId] may read [run] (its space, or none).
  Future<bool> readable(
    String workspaceId,
    String userId,
    AgentRunLog run,
  ) async {
    try {
      await requireRunLog(workspaceId, userId, run);
      return true;
    } on AppException {
      return false;
    }
  }

  // RepoOpDispatcher verifies registered/non-deleted workspace and member
  // role before these handlers run. Verify run ownership and the run's space
  // as well: a run ID is not by itself an authorization boundary.
  Future<AgentRunLog> requireOwnedRun(
    String workspaceId,
    String userId,
    String runId,
  ) async {
    const missing = NotFoundException('Agent run log not found');
    final run = await agentRunLogRepository.getById(workspaceId, runId);
    if (run == null) {
      throw missing;
    }
    if (run.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Agent run log belongs to a different workspace',
      );
    }
    // A run in a space the caller may not read is not theirs to know of.
    if (!await readable(workspaceId, userId, run)) {
      throw missing;
    }
    return run;
  }

  final processes = processDetection;
  if (processes == null) {
    return const [];
  }
  return [
    // Stops one run's process and settles it as stopped by a person. A run
    // that is not live, or has no process, answers `not_found`; the
    // settlement is conditional, so a run that finished meanwhile keeps its
    // own outcome.
    RepoOp(
      name: 'agent_run_log.stop',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id'],
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final run = await requireOwnedRun(
          workspaceId,
          ctx.userId,
          ctx.args['run_id'] as String,
        );
        final pid = run.pid;
        if (!run.isRunning || pid == null) {
          throw const NotFoundException('No live agent run to stop');
        }
        await processes.stopRun(
          pid,
          mayStop: (runWorkspace) async => runWorkspace == workspaceId,
        );
        await settleKilledRun(
          agentRunLogRepository,
          eventBus,
          run,
          DateTime.now(),
        );
        return {'stopped': true};
      },
    ),
    // Stops every OS process of one agent's live runs that the caller may
    // read and settles them killed. A thin client that killed pids locally
    // either no-op'd (remote server) or killed an unrelated recycled pid on
    // its own machine, hence host work.
    RepoOp(
      name: 'agents.killProcesses',
      kind: RepoOpKind.mutate,
      requiredArgs: ['agent_id'],
      requiredCapability: SessionCapability.fullClient,
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final agentId = ctx.args['agent_id'] as String;
        final agent = await agentRepository.getById(workspaceId, agentId);
        if (agent == null) {
          throw const NotFoundException('Agent not found');
        }
        if (agent.workspaceId != workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent belongs to a different workspace',
          );
        }
        final logs = await agentRunLogRepository
            .watchByAgent(workspaceId, agentId)
            .first;
        final killedPids = <int>{};
        final now = DateTime.now();
        for (final log in logs) {
          final pid = log.pid;
          if (!log.isRunning ||
              pid == null ||
              !await readable(workspaceId, ctx.userId, log)) {
            continue;
          }
          await processes.stopRun(
            pid,
            mayStop: (runWorkspace) async => runWorkspace == workspaceId,
          );
          killedPids.add(pid);
          await settleKilledRun(agentRunLogRepository, eventBus, log, now);
        }
        // No second pass by name: detection lists only runs with a recorded
        // pid, all covered above, and a name match reached other agents'
        // runs in every workspace.
        return {'killed': killedPids.length};
      },
    ),
  ];
}

/// Ends [log], a run a person stopped (`agent_run_log.stop`,
/// `agents.killProcesses`), through the
/// conditional terminal write every run end shares: a run that finished
/// meanwhile keeps its outcome, and the run settles once, with the cost its
/// row has recorded.
Future<void> settleKilledRun(
  AgentRunLogRepository runLogs,
  DomainEventBus? eventBus,
  AgentRunLog log,
  DateTime at,
) => RunSettlement(runLogs: runLogs, eventBus: eventBus).settle(
  log.copyWith(
    status: RunStatus.error,
    completedAt: at,
    summary: 'Killed by user',
  ),
  endReason: RunEndReason.stoppedByUser,
  writeCost: false,
);
