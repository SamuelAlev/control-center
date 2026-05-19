import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/evals/domain/services/eval_runner.dart';
import 'package:cc_domain/features/evals/domain/services/reliability_score.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_scorecard.dart';
import 'package:cc_host/cc_host.dart';
import 'package:uuid/uuid.dart';

/// Serializes an [EvalSuite] to the wire.
Map<String, dynamic> evalSuiteToWire(EvalSuite s) => {
  'id': s.id,
  'name': s.name,
  'description': s.description,
  'taskJson': s.taskJson,
  'gradersJson': s.gradersJson,
  'fixtureRef': s.fixtureRef,
  'fixtureSha': s.fixtureSha,
  'defaultBatchSize': s.defaultBatchSize,
  'isStarter': s.isStarter,
  'createdAt': s.createdAt.toIso8601String(),
  'updatedAt': s.updatedAt.toIso8601String(),
};

/// Serializes an [EvalRun] to the wire.
Map<String, dynamic> evalRunToWire(EvalRun r) => {
  'id': r.id,
  'suiteId': r.suiteId,
  'configHash': r.configHash,
  'batchSize': r.batchSize,
  'scorecardJson': r.scorecardJson,
  'passRate': r.passRate,
  'status': r.status,
  'costCents': r.costCents,
  'triggeredBy': r.triggeredBy,
  'jobId': r.jobId,
  'createdAt': r.createdAt.toIso8601String(),
  'startedAt': r.startedAt?.toIso8601String(),
  'finishedAt': r.finishedAt?.toIso8601String(),
};

/// Serializes a [SessionRecording] to the wire.
Map<String, dynamic> recordingToWire(SessionRecording rec) => {
  'id': rec.id,
  'runLogId': rec.runLogId,
  'agentId': rec.agentId,
  'conversationId': rec.conversationId,
  'configHash': rec.configHash,
  'hashVersion': rec.hashVersion,
  'eventCount': rec.eventCount,
  'title': rec.title,
  'createdAt': rec.createdAt.toIso8601String(),
};

/// Serializes a [GoldenSession] to the wire.
Map<String, dynamic> goldenToWire(GoldenSession g) => {
  'id': g.id,
  'agentId': g.agentId,
  'recordingId': g.recordingId,
  'mode': g.mode,
  'name': g.name,
  'enabled': g.enabled,
  'lastStatus': g.lastStatus,
  'lastScorecardJson': g.lastScorecardJson,
  'blessedBy': g.blessedBy,
  'blessedAt': g.blessedAt.toIso8601String(),
};

/// Serializes an [AgentConfigVersion] to the wire.
Map<String, dynamic> configVersionToWire(AgentConfigVersion v) => {
  'id': v.id,
  'agentId': v.agentId,
  'configHash': v.configHash,
  'hashVersion': v.hashVersion,
  'status': v.status,
  'scorecardJson': v.scorecardJson,
  'promotedBy': v.promotedBy,
  'promotedAt': v.promotedAt?.toIso8601String(),
  'createdAt': v.createdAt.toIso8601String(),
};

/// Builds the eval RPC ops (PRD 21). `runSuite` executes a batch via the
/// injected runner factory, which the runtime constructs with a dispatch-backed
/// task executor; when none is wired the op returns a clear error, never a fake
/// pass.
List<RepoOp> buildEvalsOps({
  required EvalsRepository repository,
  EvalRunner Function()? runnerFactory,
}) {
  const uuid = Uuid();
  return [
    RepoOp(
      name: 'evals.upsertSuite',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['name'],
      handler: (ctx) async {
        final ws = ctx.workspaceId!;
        final id = ctx.args['id'] as String? ?? uuid.v4();
        final existing = await repository.suiteById(ws, id);
        final now = DateTime.now();
        await repository.upsertSuite(
          EvalSuite(
            id: id,
            workspaceId: ws,
            name: ctx.args['name'] as String,
            description: ctx.args['description'] as String? ?? '',
            taskJson: _jsonArg(ctx.args['task']) ?? '{}',
            gradersJson: _jsonArg(ctx.args['graders']) ?? '[]',
            fixtureRef: ctx.args['fixture_ref'] as String?,
            defaultBatchSize:
                (ctx.args['default_batch_size'] as num?)?.toInt() ?? 1,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
        return {'id': id};
      },
    ),
    RepoOp(
      name: 'evals.deleteSuite',
      kind: RepoOpKind.destructive,
      requiredArgs: const ['suite_id'],
      handler: (ctx) async {
        await repository.deleteSuite(
          ctx.workspaceId!,
          ctx.args['suite_id'] as String,
        );
        return {'ok': true};
      },
    ),
    RepoOp(
      name: 'evals.runSuite',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['suite_id'],
      handler: (ctx) async {
        final ws = ctx.workspaceId!;
        final suite = await repository.suiteById(
          ws,
          ctx.args['suite_id'] as String,
        );
        if (suite == null) {
          throw const NotFoundException('Eval suite not found');
        }
        if (runnerFactory == null) {
          throw const ValidationException(
            'Eval execution is not available on this server (no dispatch-'
            'backed task executor wired).',
          );
        }
        final scorecard = await runnerFactory().runSuite(
          suite: suite,
          configHash: ctx.args['config_hash'] as String? ?? 'live',
          batchSize: (ctx.args['batch_size'] as num?)?.toInt(),
          triggeredBy: ctx.args['triggered_by'] as String? ?? 'manual',
        );
        return {'scorecard': scorecard.toJson()};
      },
    ),
    RepoOp(
      name: 'evals.blessGolden',
      kind: RepoOpKind.mutate,
      requiredArgs: const ['agent_id', 'recording_id'],
      handler: (ctx) async {
        final id = uuid.v4();
        await repository.upsertGolden(
          GoldenSession(
            id: id,
            workspaceId: ctx.workspaceId!,
            agentId: ctx.args['agent_id'] as String,
            recordingId: ctx.args['recording_id'] as String,
            mode: ctx.args['mode'] as String? ?? 'deterministic',
            name: ctx.args['name'] as String? ?? '',
            // Blessing a golden is an act of judgement: the human who did it
            // is the caller's authenticated identity, never a client arg.
            blessedBy: ctx.userId,
            blessedAt: DateTime.now(),
          ),
        );
        return {'id': id};
      },
    ),
    RepoOp(
      name: 'evals.reliability',
      kind: RepoOpKind.read,
      requiredArgs: const ['agent_id'],
      handler: (ctx) async {
        final score = await _reliabilityForAgent(
          repository,
          ctx.workspaceId!,
          ctx.args['agent_id'] as String,
        );
        return {
          'reliability': {
            'score': score.score,
            'recommended': score.recommended.wire,
            'rationale': score.rationale,
          },
        };
      },
    ),
  ];
}

/// The eval reactive queries (PRD 21).
List<WatchQuery> buildEvalsWatchQueries({required EvalsRepository repository}) {
  return [
    WatchQuery(
      name: 'evals.watchSuites',
      handler: (ctx) => repository
          .watchSuites(ctx.workspaceId!)
          .map((suites) => {'suites': suites.map(evalSuiteToWire).toList()}),
    ),
    WatchQuery(
      name: 'evals.watchRunsForSuite',
      handler: (ctx) => repository
          .watchRunsForSuite(
            ctx.workspaceId!,
            ctx.args['suite_id'] as String? ?? '',
          )
          .map((runs) => {'runs': runs.map(evalRunToWire).toList()}),
    ),
    WatchQuery(
      name: 'evals.watchRecordings',
      handler: (ctx) => repository
          .watchRecordings(ctx.workspaceId!)
          .map((recs) => {'recordings': recs.map(recordingToWire).toList()}),
    ),
    WatchQuery(
      name: 'evals.watchGoldens',
      handler: (ctx) => repository
          .watchGoldens(ctx.workspaceId!)
          .map((goldens) => {'goldens': goldens.map(goldenToWire).toList()}),
    ),
  ];
}

/// Assembles reliability evidence from the agent's eval runs (production
/// signals can be layered in by the runtime; eval runs are the always-present
/// source). Weighted pass-rate over graded runs.
Future<ReliabilityScore> _reliabilityForAgent(
  EvalsRepository repo,
  String workspaceId,
  String agentId,
) async {
  final versions = await repo.configVersionsForAgent(workspaceId, agentId);
  var gradedRuns = 0;
  var weightedPass = 0.0;
  for (final v in versions) {
    // Reliability is computed from the agent's config versions' scorecards.
    final scJson = v.scorecardJson;
    if (scJson == null || scJson.isEmpty) {
      continue;
    }
    try {
      final sc = EvalScorecard.fromJson(
        jsonDecode(scJson) as Map<String, dynamic>,
      );
      gradedRuns += sc.batchSize;
      weightedPass += sc.passRate * sc.batchSize;
    } on Object {
      // Skip unparseable scorecards.
    }
  }
  final passRate = gradedRuns == 0 ? 0.0 : weightedPass / gradedRuns;
  return ReliabilityScore.compute(
    ReliabilityEvidence(gradedRuns: gradedRuns, gradedPassRate: passRate),
  );
}

String? _jsonArg(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return jsonEncode(value);
}
