import 'package:cc_domain/cc_domain.dart'
    show
        NotFoundException,
        OrchestrationCapRefusedException,
        RepoOpKind,
        ValidationException;
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/ports/orchestration_cap_store.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart'
    show kBudgetHoldStateKey;
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog, RepoOp, RepoOpContext;
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show pipelineRunToWire;

/// The highest cap a raise may set: 1,000 USD, in micro-dollars.
const int kOrchestrationCapCeilingMicros = 1000 * 1000000;

/// The kind of the system row a raise posts in the orchestration's space
/// (`metadata.kind`; clients localize it from `old_micros`, `new_micros` and
/// `user_id`).
const String kOrchestrationCapRaisedRow = 'orchestration_cap_raised';

/// The person a pipeline run acts for, or null for a bot run.
String? pipelineRunRequester(PipelineRun? run) {
  final requester = run?.triggerPayload?[kPipelineRequestedByKey];
  return requester is String && requester.isNotEmpty ? requester : null;
}

/// Who may raise the cap of an orchestration whose run acts for
/// [requester]: that person, or a workspace admin when the run has none.
/// The `can_raise_cap` a viewer is shown, and the rule the op enforces.
bool canRaiseOrchestrationCap({
  required String? requester,
  required String userId,
  required bool isAdmin,
}) => requester == null ? isAdmin : requester == userId;

/// [pipelineRunToWire] for the caller of [ctx] (a single-run read): a run
/// held at its orchestration's cap also carries `can_raise_cap`, whether
/// this viewer may raise it ([canRaiseOrchestrationCap]; the admin rule
/// counts only in the connection's own workspace).
Map<String, dynamic> pipelineRunToWireFor(
  RepoOpContext ctx,
  PipelineRun run, {
  bool withSnapshot = false,
}) => {
  ...pipelineRunToWire(run, withSnapshot: withSnapshot),
  if (run.state.containsKey(kBudgetHoldStateKey))
    'can_raise_cap': canRaiseOrchestrationCap(
      requester: pipelineRunRequester(run),
      userId: ctx.userId,
      isAdmin:
          run.workspaceId == ctx.workspaceId && (ctx.role?.isAdmin ?? false),
    ),
};

/// A `pipeline_run.*` watch frame (`{run}` or `{runs}` of
/// [pipelineRunToWire] maps) with `can_raise_cap` added to every held run,
/// for [userId]. [isAdminIn] is asked per frame (a role moves), once per
/// workspace and only when a held bot run needs it.
Future<Map<String, dynamic>> withCanRaiseCap(
  Map<String, dynamic> frame, {
  required String userId,
  required Future<bool> Function(String workspaceId) isAdminIn,
}) async {
  final admin = <String, bool>{};
  Future<Map<String, dynamic>> one(Map<String, dynamic> run) async {
    final state = run['state'];
    if (state is! Map || !state.containsKey(kBudgetHoldStateKey)) {
      return run;
    }
    final payload = run['trigger_payload'];
    final raw = payload is Map ? payload[kPipelineRequestedByKey] : null;
    final requester = raw is String && raw.isNotEmpty ? raw : null;
    final ws = run['workspace_id'] as String;
    return {
      ...run,
      'can_raise_cap': canRaiseOrchestrationCap(
        requester: requester,
        userId: userId,
        isAdmin: requester == null && (admin[ws] ??= await isAdminIn(ws)),
      ),
    };
  }

  final single = frame['run'];
  final list = frame['runs'];
  return {
    ...frame,
    if (single is Map<String, dynamic>) 'run': await one(single),
    if (list is List)
      'runs': [for (final r in list) await one(r as Map<String, dynamic>)],
  };
}

/// `orchestration.raiseCap {orchestration_id, max_cost_micros}`: the only
/// client write of an orchestration row's cap, and so the only way to lift a
/// budget hold (`OrchestrationBudgetGate` watches the row and resumes the
/// run). No client op writes the columns a cap is found through
/// (`pipeline_run_id`, `space_id`, `workspace_id`, `status`) or inserts a
/// row: the server's use cases are the only other writers.
///
/// - The orchestration is looked up in the caller's workspace (another
///   workspace's id is not found), then the space gate of its space
///   ([requireSpace]) and the write grant on every repository that space
///   exposes ([reposExposedBy]).
/// - Only the run's requester raises it; a workspace admin when the run has
///   none (`orchestration_not_yours`, [canRaiseOrchestrationCap]).
/// - The value is an integer above the current cap and above what the run
///   has spent, at most [kOrchestrationCapCeilingMicros]; a removal (null or
///   0) and a raise of an orchestration with no cap are refused
///   (`orchestration_cap_invalid`).
/// - The write is conditional on the cap read and touches that column only;
///   a raise that lost a race is refused with the stored value
///   (`orchestration_cap_changed`, `data.max_cost_micros`).
///
/// A raise posts a system row in the orchestration's space
/// ([kOrchestrationCapRaisedRow]) and returns `{orchestration_id,
/// old_micros, new_micros}`, which the audit trail keeps beside the args.
List<RepoOp> buildOrchestrationCapOps({
  required OrchestrationRepository orchestrations,
  required OrchestrationCapStore caps,
  required PipelineRunRepository runs,
  required MessagingRepository messages,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required Future<List<String>> Function(String workspaceId, String spaceId)
  reposExposedBy,
}) {
  Future<Orchestration> gated(RepoOpContext ctx) async {
    final ws = ctx.workspaceId!;
    final id = ctx.args['orchestration_id'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('orchestration_id is required');
    }
    final o = await orchestrations.getById(ws, id);
    if (o == null || o.workspaceId != ws) {
      throw NotFoundException('No orchestration $id in this workspace.');
    }
    final spaceId = o.spaceId;
    if (spaceId != null && spaceId.isNotEmpty) {
      await requireSpace(ws, ctx.userId, spaceId);
    }
    return o;
  }

  Future<List<String>> spaceRepos(RepoOpContext ctx) async {
    final spaceId = (await gated(ctx)).spaceId;
    return spaceId == null || spaceId.isEmpty
        ? const []
        : reposExposedBy(ctx.workspaceId!, spaceId);
  }

  Never invalid(String message, int? current) =>
      throw OrchestrationCapRefusedException(
        message,
        kind: OrchestrationCapRefusedException.invalidKind,
        currentMicros: current,
      );

  return [
    RepoOp(
      name: 'orchestration.raiseCap',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['orchestration_id', 'max_cost_micros'],
      minRole: WorkspaceRole.member,
      repoAccess: RepoGrantLevel.write,
      repoAccessVia: spaceRepos,
      handler: (ctx) async {
        final ws = ctx.workspaceId!;
        final o = await gated(ctx);
        final cap = o.maxCostMicros;
        final run = o.pipelineRunId == null
            ? null
            : await runs.getRun(o.pipelineRunId!);
        final ownRun = run != null && run.workspaceId == ws ? run : null;
        if (!canRaiseOrchestrationCap(
          requester: pipelineRunRequester(ownRun),
          userId: ctx.userId,
          isAdmin: ctx.role?.isAdmin ?? false,
        )) {
          throw OrchestrationCapRefusedException(
            "Only the person this orchestration's run acts for raises its "
            'cap; a workspace admin when it acts for no one.',
            kind: OrchestrationCapRefusedException.notYoursKind,
            currentMicros: cap,
          );
        }
        final raw = ctx.args['max_cost_micros'];
        final value = raw is int
            ? raw
            : raw is num && raw == raw.truncateToDouble() && raw.isFinite
            ? raw.toInt()
            : null;
        if (cap == null || cap <= 0) {
          invalid('This orchestration has no cap to raise.', cap);
        }
        if (value == null || value <= 0) {
          invalid('A cap that was set is never removed.', cap);
        }
        final spent = ownRun?.totalCostMicros ?? 0;
        if (value <= cap || value <= spent) {
          invalid(
            'The new cap must be above the current cap '
            '(${formatUsdMicros(cap)}) and what was spent '
            '(${formatUsdMicros(spent)}).',
            cap,
          );
        }
        if (value > kOrchestrationCapCeilingMicros) {
          invalid(
            'A cap is at most '
            '${formatUsdMicros(kOrchestrationCapCeilingMicros)}.',
            cap,
          );
        }
        if (!await caps.raiseCap(ws, o.id, from: cap, to: value)) {
          final fresh = await orchestrations.getById(ws, o.id);
          throw OrchestrationCapRefusedException(
            'The cap changed while this was being saved; it is now '
            '${fresh?.maxCostMicros == null ? 'unset' : formatUsdMicros(fresh!.maxCostMicros!)}.',
            kind: OrchestrationCapRefusedException.changedKind,
            currentMicros: fresh?.maxCostMicros,
          );
        }
        final spaceId = o.spaceId;
        if (spaceId != null && spaceId.isNotEmpty) {
          // The raise stands either way: a row that fails to post is logged,
          // never a refusal of a write that already landed.
          await messages
              .sendMessage(
                workspaceId: ws,
                spaceId: spaceId,
                content:
                    "This orchestration's cost cap was raised from "
                    '${formatUsdMicros(cap)} to ${formatUsdMicros(value)}.',
                senderId: 'system',
                senderType: 'system',
                messageType: 'system',
                metadata: {
                  'kind': kOrchestrationCapRaisedRow,
                  'orchestration_id': o.id,
                  'old_micros': cap,
                  'new_micros': value,
                  'user_id': ctx.userId,
                },
              )
              .then<void>(
                (_) {},
                onError: (Object e) => CcHostLog.warning(
                  'orchestration ${o.id}: cap raise row failed: $e',
                ),
              );
        }
        return {
          'orchestration_id': o.id,
          'old_micros': cap,
          'new_micros': value,
        };
      },
    ),
  ];
}
