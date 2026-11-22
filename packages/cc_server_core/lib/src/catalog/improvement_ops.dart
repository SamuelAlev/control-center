import 'package:cc_domain/cc_domain.dart'
    show
        AppException,
        ImprovementRefusedException,
        RepoOpKind,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/learning/improvement_adoption_service.dart';
import 'package:cc_server_core/src/learning/improvement_evaluation.dart';

/// The `improvements` pack: the proposals an improvement review wrote and a
/// person's decisions on them (plan section 13, "Adoption").
///
/// - `improvements.watchForWorkspace` and `improvements.get`: a member who
///   may read the proposal's space.
/// - `improvements.accept`, `.reject`, `.rollback`, `.startCampaign`: the
///   same, and a workspace admin for a workspace-scoped policy and every
///   skill change ([ImprovementAdoptionService.needsAdmin]).
///
/// A proposal id is looked up in the caller's workspace; one of another
/// workspace is a [WorkspaceMismatchException]. Refusals carry their
/// `data.kind` (`ImprovementRefusedException`).
///
/// A pack the catalog spreads, so `remote_rpc_catalog.dart` does not grow.
/// Empty when the host wires no proposals.
({List<RepoOp> ops, List<WatchQuery> watches}) buildImprovementOps({
  required ImprovementProposalRepository? proposals,
  required ImprovementAdoptionService? adoption,
  required Future<void> Function(
    String workspaceId,
    String userId,
    String spaceId,
  )
  requireSpace,
}) {
  if (proposals == null || adoption == null) {
    return (ops: const [], watches: const []);
  }

  Future<bool> canRead(String ws, String userId, String? spaceId) async {
    if (spaceId == null) {
      return false;
    }
    try {
      await requireSpace(ws, userId, spaceId);
      return true;
    } on AppException {
      return false;
    }
  }

  /// The proposal named by `proposal_id`, readable by the caller; [write]
  /// also applies the admin rule.
  Future<ImprovementProposal> gated(
    RepoOpContext ctx, {
    required bool write,
  }) async {
    final ws = ctx.workspaceId!;
    final id = ctx.args['proposal_id'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('Missing proposal_id');
    }
    final proposal = await proposals.getById(ws, id);
    if (proposal == null || proposal.workspaceId != ws) {
      throw const WorkspaceMismatchException(
        'Proposal not found in this workspace',
      );
    }
    final spaceId = proposal.spaceId;
    if (spaceId == null) {
      throw const WorkspaceMismatchException(
        'Proposal not found in this workspace',
      );
    }
    await requireSpace(ws, ctx.userId, spaceId);
    if (write &&
        ImprovementAdoptionService.needsAdmin(proposal) &&
        !(ctx.role?.isAdmin ?? false)) {
      throw const ImprovementRefusedException(
        'Only a workspace admin decides a workspace policy or a skill change',
        kind: ImprovementRefusedException.adminRequiredKind,
      );
    }
    return proposal;
  }

  /// [p] as a client sees it, with a campaign that ended meanwhile
  /// recorded first ([ImprovementAdoptionService.refreshCampaign]).
  Future<Map<String, dynamic>> wire(ImprovementProposal p) async {
    final fresh = await adoption.refreshCampaign(p);
    return improvementProposalToWire(
      fresh,
      evaluation: await adoption.evaluationOf(fresh),
    );
  }

  RepoOpHandler decide(
    Future<ImprovementProposal> Function(
      ImprovementProposal proposal,
      RepoOpContext ctx,
    )
    act,
  ) =>
      (ctx) async => {
        'proposal': await wire(await act(await gated(ctx, write: true), ctx)),
      };

  return (
    ops: [
      RepoOp(
        name: 'improvements.get',
        kind: RepoOpKind.read,
        requiredArgs: const ['proposal_id'],
        minRole: WorkspaceRole.member,
        handler: (ctx) async => {
          'proposal': await wire(await gated(ctx, write: false)),
        },
      ),
      RepoOp(
        name: 'improvements.accept',
        kind: RepoOpKind.mutate,
        requiredArgs: const ['proposal_id'],
        minRole: WorkspaceRole.member,
        handler: decide((p, ctx) => adoption.accept(p, userId: ctx.userId)),
      ),
      RepoOp(
        name: 'improvements.reject',
        kind: RepoOpKind.mutate,
        requiredArgs: const ['proposal_id'],
        minRole: WorkspaceRole.member,
        handler: decide((p, ctx) => adoption.reject(p, userId: ctx.userId)),
      ),
      RepoOp(
        name: 'improvements.rollback',
        kind: RepoOpKind.mutate,
        requiredArgs: const ['proposal_id'],
        minRole: WorkspaceRole.member,
        handler: decide((p, ctx) => adoption.rollback(p, userId: ctx.userId)),
      ),
      RepoOp(
        name: 'improvements.startCampaign',
        kind: RepoOpKind.mutate,
        requiredArgs: const [
          'proposal_id',
          'corpus_id',
          'provider_id',
          'model_id',
          'repetitions',
          'budget_micros',
        ],
        minRole: WorkspaceRole.member,
        actionClasses: const {
          ActionClass.processSpawn,
          ActionClass.networkEgress,
        },
        timeout: const Duration(seconds: 60),
        handler: (ctx) async {
          final proposal = await gated(ctx, write: true);
          final args = ctx.args;
          return {
            'proposal': await wire(
              await adoption.startCampaign(
                proposal,
                actor: ctx.principal,
                settings: {
                  'corpus_id': args['corpus_id'],
                  'provider_id': args['provider_id'],
                  'model_id': args['model_id'],
                  'repetitions': args['repetitions'],
                  'budget_micros': args['budget_micros'],
                  'adapter': ?args['adapter'],
                },
              ),
            ),
          };
        },
      ),
    ],
    watches: [
      WatchQuery(
        name: 'improvements.watchForWorkspace',
        minRole: WorkspaceRole.member,
        handler: (ctx) {
          final ws = ctx.workspaceId!;
          final status = ImprovementStatusWire.tryParse(
            ctx.args['status'] as String?,
          );
          return adoption
              .watchForWorkspace(ws)
              .asyncMap(
                (list) async => {
                  'proposals': [
                    for (final p in list)
                      if (p.workspaceId == ws &&
                          (status == null || p.status == status) &&
                          await canRead(ws, ctx.userId, p.spaceId))
                        await wire(p),
                  ],
                },
              );
        },
      ),
    ],
  );
}

/// A proposal as a client sees it. Timestamps are ISO 8601 UTC; enum fields
/// are their wire names; absent optional fields are omitted. A skill change
/// whose campaign ended (`campaign_state` `passed` or `failed`) carries
/// `evaluation` ([ImprovementEvaluation.toWire]): `paired_runs`,
/// `candidate_solved`, `baseline_solved`, `verdict`, `regressions` (the
/// per-task quality losses and cost regressions, and the change's runs that
/// hit a harness error), `coverage_complete` and `plan_violations`.
Map<String, dynamic> improvementProposalToWire(
  ImprovementProposal p, {
  required ImprovementEvaluation? evaluation,
}) => {
  'id': p.id,
  'workspace_id': p.workspaceId,
  'agent_id': p.agentId,
  'space_id': ?p.spaceId,
  'conversation_id': ?p.conversationId,
  'goal_id': ?p.goalId,
  'review_run_id': ?p.reviewRunId,
  'kind': p.kind.wire,
  'scope': p.scope.wire,
  'scope_ref_id': ?p.scopeRefId,
  'operation': p.operation.wire,
  'target_ref': ?p.targetRef,
  'change': p.change,
  'evidence': p.evidence.toJson(),
  'expected': p.expected,
  'status': p.status.wire,
  'before_text': ?p.beforeText,
  'after_text': ?p.afterText,
  'applied_ref': ?p.appliedRef,
  'candidate_revision_id': ?p.candidateRevisionId,
  'campaign_id': ?p.campaignId,
  'campaign_state': p.campaignState.wire,
  'decided_by_user_id': ?p.decidedByUserId,
  'decided_at': ?p.decidedAt?.toUtc().toIso8601String(),
  'created_at': p.createdAt.toUtc().toIso8601String(),
  'expires_at': p.expiresAt.toUtc().toIso8601String(),
  'needs_admin': ImprovementAdoptionService.needsAdmin(p),
  'evaluation': ?evaluation?.toWire(),
};
