import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show skillEvaluationCorpora, skillEvaluationCorpusMetadata;
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';

/// Paid execution and evidence are explicit workspace surfaces. The shared
/// dispatcher checks registration and membership before these handlers; service
/// authorization also covers background work and per-repository evidence.
List<RepoOp> buildSkillEvaluationOps(SkillEvaluationService service) => [
  RepoOp(
    name: 'evals.skillCorpora',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id'],
    handler: (ctx) async {
      await service.authorize(ctx.workspaceId!, ctx.principal, write: false);
      return {
        'corpora': [
          for (final corpus in skillEvaluationCorpora)
            skillEvaluationCorpusMetadata(corpus),
        ],
        'capabilities': await service.capability(),
      };
    },
  ),
  RepoOp(
    name: 'evals.startSkillCampaign',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.member,
    actionClasses: const {ActionClass.processSpawn, ActionClass.networkEgress},
    requiredArgs: const [
      'workspace_id',
      'skill_slug',
      'corpus_id',
      'provider_id',
      'model_id',
      'comparison',
      'repetitions',
      'budget_micros',
    ],
    timeout: const Duration(seconds: 60),
    handler: (ctx) async => {
      'campaign': (await service.launch(
        workspaceId: ctx.workspaceId!,
        actor: ctx.principal,
        settings: SkillEvaluationSettings.fromJson(ctx.args),
      )).toJson(),
    },
  ),
  RepoOp(
    name: 'evals.cancelCampaign',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.member,
    requiredArgs: const ['workspace_id', 'campaign_id'],
    // Effect-free control message: cancels existing work, starts no process.
    handler: (ctx) async => {
      'campaign': (await service.cancel(
        ctx.workspaceId!,
        ctx.principal,
        ctx.args['campaign_id'] as String,
      )).toJson(),
    },
  ),
  RepoOp(
    name: 'evals.getAttempt',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id', 'campaign_id', 'attempt_id'],
    handler: (ctx) async => {
      'attempt': (await service.attempt(
        ctx.workspaceId!,
        ctx.principal,
        ctx.args['campaign_id'] as String,
        ctx.args['attempt_id'] as String,
      )).toJson(),
    },
  ),
  RepoOp(
    name: 'evals.listAttempts',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id', 'campaign_id'],
    handler: (ctx) async => {
      'attempts': [
        for (final attempt in await service.attempts(
          ctx.workspaceId!,
          ctx.principal,
          ctx.args['campaign_id'] as String,
        ))
          attempt.toJson(),
      ],
    },
  ),
  RepoOp(
    name: 'evals.exportCampaign',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id', 'campaign_id'],
    handler: (ctx) => service.export(
      ctx.workspaceId!,
      ctx.principal,
      ctx.args['campaign_id'] as String,
    ),
  ),
  RepoOp(
    name: 'evals.skillPolicy',
    kind: RepoOpKind.read,
    requiredArgs: const ['workspace_id', 'skill_key'],
    handler: (ctx) async => {
      'policy': (await service.policy(
        ctx.workspaceId!,
        ctx.principal,
        ctx.args['skill_key'] as String,
      ))?.toJson(),
    },
  ),
  RepoOp(
    name: 'evals.setSkillPolicy',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.admin,
    requiredArgs: const [
      'workspace_id',
      'skill_key',
      'enabled',
      'configuration',
    ],
    // Changes only the opt-in record. It does not launch or approve a run.
    handler: (ctx) async => {
      'policy': (await service.setPolicy(
        ctx.workspaceId!,
        ctx.principal,
        ctx.args['skill_key'] as String,
        ctx.args['enabled'] as bool,
        (ctx.args['configuration'] as Map).cast<String, dynamic>(),
      )).toJson(),
    },
  ),
];

/// Streams campaign updates through the same per-workspace and per-repository
/// authorization enforced by [SkillEvaluationService].
List<WatchQuery> buildSkillEvaluationWatchQueries(
  SkillEvaluationService service,
) => [
  WatchQuery(
    name: 'evals.watchCampaign',
    handler: (ctx) => service
        .watchOne(
          ctx.workspaceId!,
          UserPrincipal(ctx.userId),
          ctx.args['campaign_id'] as String,
        )
        .map((campaign) => {'campaign': campaign?.toJson()}),
  ),
  WatchQuery(
    name: 'evals.watchCampaignsForSkill',
    handler: (ctx) => service
        .watch(
          ctx.workspaceId!,
          UserPrincipal(ctx.userId),
          skillKey: ctx.args['skill_key'] as String?,
        )
        .map(
          (campaigns) => {
            'campaigns': [for (final campaign in campaigns) campaign.toJson()],
          },
        ),
  ),
];
