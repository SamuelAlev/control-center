import 'package:cc_domain/cc_domain.dart'
    show AppException, OrchestrationCapRefusedException, RepoOpKind;
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/save_orchestration_revision_use_case.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show
        OrchestrationActionFn,
        OrchestrationApproveFn,
        orchestrationRevisionToWire,
        orchestrationToWire;
import 'package:cc_server_core/src/catalog/orchestration_cap_ops.dart'
    show canRaiseOrchestrationCap, pipelineRunRequester;

/// The `orchestration.*` ops a client calls and their watches, each behind
/// the orchestration's space: an orchestration in a space the caller may not
/// read ([requireSpace]) is absent from their reads (a read answers null, a
/// list leaves it out, a watch emits null) and its moves and by-id lists
/// refuse with the space gate's own refusal. An orchestration with no space
/// is the workspace's, for every member.
///
/// The moves that start or widen work (approve, approveNodes, continueNode,
/// saveRevision) are mutations: they need the member role and the write
/// grant on every repository the orchestration's space exposes
/// ([reposExposedBy], `repoAccessVia`), the way `orchestration.raiseCap`
/// does; an orchestration with no space, or a space with no repositories,
/// asks no grant. Widening an approved orchestration's work (approveNodes,
/// continueNode) is also the person its run acts for, or a workspace admin
/// when it acts for no one: the work runs as them. Cancel is the brake and
/// stays open to anyone who may read the space.
///
/// The moves run on the host that owns the engine and are absent without it.
/// Every op is workspace-scoped (`ctx.workspaceId!`, never a client arg);
/// the use cases re-validate the orchestration belongs to that workspace.
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
({List<RepoOp> ops, List<WatchQuery> watches}) buildOrchestrationOps({
  required OrchestrationRepository orchestrations,
  required OrchestrationRevisionRepository? revisions,
  required PipelineRunRepository runs,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
  required Future<List<String>> Function(String workspaceId, String spaceId)
  reposExposedBy,
  required Future<bool> Function(String callerId, String workspaceId)
  callerSeesWorkspace,
  required OrchestrationApproveFn? approve,
  required Future<void> Function(
    String workspaceId,
    String orchestrationId,
    Set<String>? approvedNodeKeys, {
    String? approvedByUserId,
  })?
  approveScoped,
  required OrchestrationActionFn? cancel,
  required Future<void> Function(
    String workspaceId,
    String orchestrationId,
    Set<String> nodeKeys,
  )?
  approveNodes,
  required SaveOrchestrationRevisionUseCase? saveRevision,
  required Future<Map<String, dynamic>> Function(
    String workspaceId,
    String orchestrationId,
  )?
  divergenceMarkers,
  required Future<void> Function(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  )?
  continueNode,
}) {
  /// Whether [userId] may read [o] (its space, or none).
  Future<bool> readable(String userId, Orchestration o) async {
    final spaceId = o.spaceId;
    if (spaceId == null || spaceId.isEmpty) {
      return true;
    }
    try {
      await requireSpace(o.workspaceId, userId, spaceId);
      return true;
    } on AppException {
      return false;
    }
  }

  /// [o] when the caller may read it, else null.
  Future<Map<String, dynamic>?> visible(
    RepoOpContext ctx,
    Orchestration? o,
  ) async => o != null && await readable(ctx.userId, o)
      ? orchestrationToWire(o)
      : null;

  /// The orchestration named by [key], refused (the space gate's refusal)
  /// when it is in a space the caller may not read. A missing one is the
  /// use case's to refuse.
  Future<String> gated(RepoOpContext ctx, String key) async {
    final id = ctx.args[key] as String;
    final o = await orchestrations.getById(ctx.workspaceId!, id);
    final spaceId = o?.spaceId;
    if (spaceId != null && spaceId.isNotEmpty) {
      await requireSpace(ctx.workspaceId!, ctx.userId, spaceId);
    }
    return id;
  }

  /// The repositories a move on the orchestration named by
  /// `orchestration_id` needs the write grant on (`repoAccessVia`): those
  /// its space exposes, after the space gate; none for an orchestration with
  /// no space, or a missing one (the use case refuses it).
  Future<List<String>> spaceRepos(RepoOpContext ctx) async {
    final ws = ctx.workspaceId!;
    final o = await orchestrations.getById(
      ws,
      ctx.args['orchestration_id'] as String,
    );
    final spaceId = o?.spaceId;
    if (spaceId == null || spaceId.isEmpty) {
      return const [];
    }
    await requireSpace(ws, ctx.userId, spaceId);
    return reposExposedBy(ws, spaceId);
  }

  /// [gated], then refused (`orchestration_not_yours`) unless the caller is
  /// the person the orchestration's run acts for, or a workspace admin when
  /// it acts for no one: the rule of `orchestration.raiseCap`
  /// ([canRaiseOrchestrationCap]). Widened work runs as that person, on
  /// nodes they chose not to start. A run of another workspace, or none yet,
  /// acts for no one.
  Future<String> gatedToRunOwner(RepoOpContext ctx) async {
    final ws = ctx.workspaceId!;
    final id = await gated(ctx, 'orchestration_id');
    final o = await orchestrations.getById(ws, id);
    if (o == null) {
      return id;
    }
    final runId = o.pipelineRunId;
    final run = runId == null ? null : await runs.getRun(runId);
    if (!canRaiseOrchestrationCap(
      requester: pipelineRunRequester(
        run != null && run.workspaceId == ws ? run : null,
      ),
      userId: ctx.userId,
      isAdmin: ctx.role?.isAdmin ?? false,
    )) {
      throw OrchestrationCapRefusedException(
        "Only the person this orchestration's run acts for widens its work; "
        'a workspace admin when it acts for no one.',
        kind: OrchestrationCapRefusedException.notYoursKind,
        currentMicros: o.maxCostMicros,
      );
    }
    return id;
  }

  final approveOrch = approve;
  final cancelOrch = cancel;
  final revisionsRepo = revisions;
  return (
    ops: [
      if (approveOrch != null)
        RepoOp(
          name: 'orchestration.approve',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.member,
          repoAccess: RepoGrantLevel.write,
          repoAccessVia: spaceRepos,
          // Hires agents and starts the generated pipeline (bash included).
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: const ['orchestration_id'],
          handler: (ctx) async {
            final id = await gated(ctx, 'orchestration_id');
            // Optional subtree scope (PRD 17 §4): when `approved_node_keys`
            // is present (and the scoped path is wired), unlisted nodes
            // materialize behind suspended approval gates.
            final rawKeys = ctx.args['approved_node_keys'];
            final nodeKeys = rawKeys is List
                ? rawKeys.whereType<String>().toSet()
                : null;
            if (nodeKeys != null && approveScoped != null) {
              await approveScoped(
                ctx.workspaceId!,
                id,
                nodeKeys,
                approvedByUserId: ctx.userId,
              );
            } else {
              await approveOrch(
                ctx.workspaceId!,
                id,
                approvedByUserId: ctx.userId,
              );
            }
            return {'ok': true};
          },
        ),
      if (cancelOrch != null)
        RepoOp(
          name: 'orchestration.cancel',
          kind: RepoOpKind.mutate,
          requiredArgs: const ['orchestration_id'],
          handler: (ctx) async {
            await cancelOrch(
              ctx.workspaceId!,
              await gated(ctx, 'orchestration_id'),
            );
            return {'ok': true};
          },
        ),
      // Widens an executing partial approval: newly approved nodes'
      // suspended gates resume. The use case enforces dependency-closure.
      if (approveNodes != null)
        RepoOp(
          name: 'orchestration.approveNodes',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.member,
          repoAccess: RepoGrantLevel.write,
          repoAccessVia: spaceRepos,
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: const ['orchestration_id', 'node_keys'],
          handler: (ctx) async {
            await approveNodes(
              ctx.workspaceId!,
              await gatedToRunOwner(ctx),
              (ctx.args['node_keys'] as List).whereType<String>().toSet(),
            );
            return {'ok': true};
          },
        ),
      // Saves an operator-edited proposal as a new revision (validated;
      // optimistic-concurrency via `base_revision` — a stale edit is refused
      // with "the plan moved on", never silently clobbered).
      if (saveRevision != null)
        RepoOp(
          name: 'orchestration.saveRevision',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.member,
          repoAccess: RepoGrantLevel.write,
          repoAccessVia: spaceRepos,
          requiredArgs: const [
            'orchestration_id',
            'proposal_json',
            'base_revision',
          ],
          handler: (ctx) async {
            final updated = await saveRevision.save(
              workspaceId: ctx.workspaceId!,
              orchestrationId: await gated(ctx, 'orchestration_id'),
              proposal: OrchestrationProposal.fromJsonString(
                ctx.args['proposal_json'] as String,
              ),
              baseRevision: (ctx.args['base_revision'] as num).toInt(),
              authoredBy: ctx.userId,
            );
            return {'orchestration': orchestrationToWire(updated)};
          },
        ),
      // The append-only revision timeline (plan diff + rewind read surface).
      if (revisionsRepo != null)
        RepoOp(
          name: 'orchestration.revisions',
          kind: RepoOpKind.read,
          requiredArgs: const ['orchestration_id'],
          handler: (ctx) async {
            final list = await revisionsRepo.forOrchestration(
              ctx.workspaceId!,
              await gated(ctx, 'orchestration_id'),
            );
            return {
              'revisions': list.map(orchestrationRevisionToWire).toList(),
            };
          },
        ),
      // Plan-drift divergence markers for the Studio canvas (PRD 17 §6).
      if (divergenceMarkers != null)
        RepoOp(
          name: 'orchestration.divergence',
          kind: RepoOpKind.read,
          requiredArgs: const ['orchestration_id'],
          handler: (ctx) async => {
            'markers': await divergenceMarkers(
              ctx.workspaceId!,
              await gated(ctx, 'orchestration_id'),
            ),
          },
        ),
      // Resumes a node held by stop-and-ask drift policy.
      if (continueNode != null)
        RepoOp(
          name: 'orchestration.continueNode',
          kind: RepoOpKind.mutate,
          minRole: WorkspaceRole.member,
          repoAccess: RepoGrantLevel.write,
          repoAccessVia: spaceRepos,
          actionClasses: const {ActionClass.processSpawn},
          requiredArgs: const ['orchestration_id', 'node_key'],
          handler: (ctx) async {
            await continueNode(
              ctx.workspaceId!,
              await gatedToRunOwner(ctx),
              ctx.args['node_key'] as String,
            );
            return {'ok': true};
          },
        ),
      RepoOp(
        name: 'orchestration.getById',
        kind: RepoOpKind.read,
        requiredArgs: const ['id'],
        handler: (ctx) async => {
          'orchestration': await visible(
            ctx,
            await orchestrations.getById(
              ctx.workspaceId!,
              ctx.args['id'] as String,
            ),
          ),
        },
      ),
      RepoOp(
        name: 'orchestration.forParentTicket',
        kind: RepoOpKind.read,
        requiredArgs: const ['ticket_id'],
        handler: (ctx) async => {
          'orchestration': await visible(
            ctx,
            await orchestrations.forParentTicket(
              ctx.workspaceId!,
              ctx.args['ticket_id'] as String,
            ),
          ),
        },
      ),
      RepoOp(
        name: 'orchestration.forPipelineRun',
        kind: RepoOpKind.read,
        requiredArgs: const ['pipeline_run_id'],
        handler: (ctx) async => {
          'orchestration': await visible(
            ctx,
            await orchestrations.forPipelineRun(
              ctx.workspaceId!,
              ctx.args['pipeline_run_id'] as String,
            ),
          ),
        },
      ),
      // CROSS-WORKSPACE BY DESIGN: event routers receive only a pipeline run
      // id (events carry no workspaceId); the returned row carries its own
      // workspaceId (mirrors the documented
      // OrchestrationRepository.forPipelineRunAnyWorkspace exemption).
      RepoOp(
        name: 'orchestration.forPipelineRunAnyWorkspace',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: const ['pipeline_run_id'],
        handler: (ctx) async {
          final o = await orchestrations.forPipelineRunAnyWorkspace(
            ctx.args['pipeline_run_id'] as String,
          );
          final seen =
              o != null &&
              await callerSeesWorkspace(ctx.userId, o.workspaceId) &&
              await readable(ctx.userId, o);
          return {'orchestration': seen ? orchestrationToWire(o) : null};
        },
      ),
      // CROSS-WORKSPACE BY DESIGN: startup materialization-resume scans
      // approved orchestrations across all workspaces; each row carries its
      // own workspaceId (mirrors the documented
      // OrchestrationRepository.approvedNeedingMaterialization exemption).
      RepoOp(
        name: 'orchestration.approvedNeedingMaterialization',
        kind: RepoOpKind.read,
        workspaceScoped: false,
        requiredArgs: const [],
        handler: (ctx) async {
          final list = await orchestrations.approvedNeedingMaterialization();
          return {
            'orchestrations': [
              for (final o in list)
                if (await callerSeesWorkspace(ctx.userId, o.workspaceId) &&
                    await readable(ctx.userId, o))
                  orchestrationToWire(o),
            ],
          };
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'orchestration.watchForWorkspace',
        handler: (ctx) => orchestrations
            .watchForWorkspace(ctx.workspaceId!)
            .asyncMap(
              (list) async => {
                'orchestrations': [
                  for (final o in list)
                    if (await readable(ctx.userId, o)) orchestrationToWire(o),
                ],
              },
            ),
      ),
      WatchQuery(
        name: 'orchestration.watchById',
        handler: (ctx) => orchestrations
            .watchById(ctx.workspaceId!, ctx.args['id'] as String)
            .asyncMap(
              (o) async => {
                'orchestration': o != null && await readable(ctx.userId, o)
                    ? orchestrationToWire(o)
                    : null,
              },
            ),
      ),
      if (revisionsRepo != null)
        WatchQuery(
          name: 'orchestration.watchRevisions',
          handler: (ctx) async* {
            final id = ctx.args['orchestration_id'] as String;
            final o = await orchestrations.getById(ctx.workspaceId!, id);
            final spaceId = o?.spaceId;
            if (spaceId != null && spaceId.isNotEmpty) {
              await requireSpace(ctx.workspaceId!, ctx.userId, spaceId);
            }
            yield* revisionsRepo
                .watchForOrchestration(ctx.workspaceId!, id)
                .map(
                  (list) => {
                    'revisions': list.map(orchestrationRevisionToWire).toList(),
                  },
                );
          },
        ),
    ],
  );
}
