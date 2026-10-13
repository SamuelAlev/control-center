import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;

import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// The partial `agent_run_log.*` writes a remote dispatch host makes while a
/// run is live: cost, descendant cost, runtime classification and the guarded
/// terminal write.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Every handler sources `ctx.workspaceId!` (the bound session) and verifies
/// the run belongs to it before writing.
List<RepoOp> buildAgentRunLogWriteOps(
  AgentRunLogRepository agentRunLogRepository,
) {
  // RepoOpDispatcher verifies registered/non-deleted workspace and member
  // role before these handlers run. Verify run ownership as well: a run ID is
  // not by itself an authorization boundary, even for partial writes.
  Future<AgentRunLog> requireOwnedRun(String workspaceId, String runId) async {
    final run = await agentRunLogRepository.getById(workspaceId, runId);
    if (run == null) {
      throw const NotFoundException('Agent run log not found');
    }
    if (run.workspaceId != workspaceId) {
      throw const WorkspaceMismatchException(
        'Agent run log belongs to a different workspace',
      );
    }
    return run;
  }

  return [
    RepoOp(
      name: 'agent_run_log.updateCost',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id', 'cost'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final runId = ctx.args['run_id'] as String;
        await requireOwnedRun(workspaceId, runId);
        final cost = runCostFromWire(
          (ctx.args['cost'] as Map).cast<String, dynamic>(),
        );
        await agentRunLogRepository.updateCost(workspaceId, runId, cost);
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'agent_run_log.addChildCostMicros',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id', 'amount_micros'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final runId = ctx.args['run_id'] as String;
        await requireOwnedRun(workspaceId, runId);
        final amount = ctx.args['amount_micros'];
        if (amount is! int || amount < 0) {
          throw const ValidationException(
            'Descendant cost increment must be a nonnegative integer',
          );
        }
        await agentRunLogRepository.addChildCostMicros(
          workspaceId,
          runId,
          amount,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'agent_run_log.updateRuntime',
      kind: RepoOpKind.mutate,
      requiredArgs: ['run_id'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final runId = ctx.args['run_id'] as String;
        await requireOwnedRun(workspaceId, runId);
        final markRunning = ctx.args['mark_running'];
        if (markRunning != null && markRunning is! bool) {
          throw const ValidationException('mark_running must be a boolean');
        }
        final liveness = ctx.args['liveness'];
        final errorFamily = ctx.args['error_family'];
        final parsedLiveness = liveness == null
            ? null
            : RunLiveness.values.asNameMap()[liveness];
        final parsedError = errorFamily == null
            ? null
            : RunErrorFamily.values.asNameMap()[errorFamily];
        if ((liveness != null && parsedLiveness == null) ||
            (errorFamily != null && parsedError == null)) {
          throw const ValidationException('Invalid run classification');
        }
        final rawLastOutput = ctx.args['last_output_at'];
        final lastOutput = rawLastOutput == null
            ? null
            : rawLastOutput is String
            ? DateTime.tryParse(rawLastOutput)
            : null;
        if (rawLastOutput != null && lastOutput == null) {
          throw const ValidationException('Invalid last_output_at timestamp');
        }
        return {
          'updated': await agentRunLogRepository.updateRuntime(
            workspaceId,
            runId,
            pid: (ctx.args['pid'] as num?)?.toInt(),
            markRunning: markRunning == true,
            logPath: ctx.args['log_path'] as String?,
            contextSnapshotJson: ctx.args['context_snapshot_json'] as String?,
            lastOutputAt: lastOutput,
            liveness: parsedLiveness,
            errorFamily: parsedError,
            summary: ctx.args['summary'] as String?,
            modelId: ctx.args['model_id'] as String?,
            effort: ctx.args['effort'] as String?,
            taskFamily: ctx.args['task_family'] as String?,
          ),
        };
      },
    ),
    RepoOp(
      name: 'agent_run_log.completeIfActive',
      kind: RepoOpKind.mutate,
      requiredArgs: ['log', 'write_cost'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final completed = agentRunLogFromWire(
          (ctx.args['log'] as Map).cast<String, dynamic>(),
        );
        if (completed.workspaceId != workspaceId) {
          throw const WorkspaceMismatchException(
            'Agent run log belongs to a different workspace',
          );
        }
        await requireOwnedRun(workspaceId, completed.id);
        if (completed.completedAt == null ||
            (completed.status != RunStatus.completed &&
                completed.status != RunStatus.error)) {
          throw const ValidationException(
            'Terminal write requires a completed/error status and timestamp',
          );
        }
        return {
          'completed': await agentRunLogRepository.completeIfActive(
            completed,
            writeCost: ctx.args['write_cost'] as bool,
          ),
        };
      },
    ),
  ];
}
