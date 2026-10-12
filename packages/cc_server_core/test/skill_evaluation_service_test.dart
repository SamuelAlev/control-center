import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/paired_evaluation.dart';
import 'package:cc_domain/features/evals/domain/repositories/evals_repository.dart';
import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AdmittedSkillEvaluationSnapshot,
        EvaluationArtifacts,
        EvaluationRunResult,
        SkillEvaluationSnapshotStore,
        SkillPackageSnapshot;
import 'package:cc_server_core/src/evals/skill_evaluation_service.dart';
import 'package:test/test.dart';

const _workspace = 'workspace-one';
const _other = 'workspace-two';
final _actor = UserPrincipal('operator');
final _instant = DateTime.utc(2026, 1, 1);
const _corpus = 'cc-skill-serialization-trigger-pilot-v1';

typedef _Execution = Future<EvaluationRunResult> Function(SkillEvaluationJob);

class _Repository implements EvalsRepository {
  final campaigns = <String, SkillEvaluationCampaign>{};
  final attempts = <String, SkillEvaluationAttemptRecord>{};
  final policies = <String, SkillEvaluationPolicy>{};
  final _terminal = <String, Completer<void>>{};
  final reads = <String>[];
  final writes = <String>[];
  bool registered = true;
  Future<void> Function(SkillEvaluationPolicy)? beforePolicyWrite;

  String _key(String workspace, String id) => '$workspace\u0000$id';
  Future<void> settled(String id) {
    if (campaigns.values.any((row) => row.id == id && row.isTerminal)) {
      return Future<void>.value();
    }
    return _terminal.putIfAbsent(id, Completer<void>.new).future;
  }

  void _guard(String workspace) {
    if (!registered)
      throw StateError('Database for removed workspace was reopened');
    reads.add(workspace);
  }

  @override
  Future<void> upsertSkillCampaign(SkillEvaluationCampaign campaign) async {
    _guard(campaign.workspaceId);
    writes.add(campaign.id);
    campaigns[_key(campaign.workspaceId, campaign.id)] = campaign;
    if (campaign.isTerminal) {
      final done = _terminal.putIfAbsent(campaign.id, Completer<void>.new);
      if (!done.isCompleted) done.complete();
    }
  }

  @override
  Future<SkillEvaluationCampaign?> skillCampaignById(
    String workspaceId,
    String id,
  ) async {
    _guard(workspaceId);
    return campaigns[_key(workspaceId, id)];
  }

  @override
  Future<List<SkillEvaluationCampaign>> skillCampaigns(
    String workspaceId, {
    String? skillKey,
    int limit = 100,
  }) async {
    _guard(workspaceId);
    return campaigns.values
        .where(
          (row) =>
              row.workspaceId == workspaceId &&
              (skillKey == null || row.skillKey == skillKey),
        )
        .take(limit)
        .toList();
  }

  @override
  Stream<List<SkillEvaluationCampaign>> watchSkillCampaigns(
    String workspaceId, {
    String? skillKey,
  }) {
    _guard(workspaceId);
    return Stream.value(
      campaigns.values
          .where(
            (row) =>
                row.workspaceId == workspaceId &&
                (skillKey == null || row.skillKey == skillKey),
          )
          .toList(),
    );
  }

  @override
  Stream<SkillEvaluationCampaign?> watchSkillCampaign(
    String workspaceId,
    String id,
  ) {
    _guard(workspaceId);
    return Stream.value(campaigns[_key(workspaceId, id)]);
  }

  @override
  Future<void> upsertSkillAttempt(SkillEvaluationAttemptRecord attempt) async {
    _guard(attempt.workspaceId);
    attempts[_key(attempt.workspaceId, attempt.id)] = attempt;
  }

  @override
  Future<List<SkillEvaluationAttemptRecord>> skillAttempts(
    String workspaceId,
    String campaignId,
  ) async {
    _guard(workspaceId);
    return attempts.values
        .where(
          (row) =>
              row.workspaceId == workspaceId && row.campaignId == campaignId,
        )
        .toList();
  }

  @override
  Future<SkillEvaluationAttemptRecord?> skillAttemptById(
    String workspaceId,
    String campaignId,
    String id,
  ) async {
    _guard(workspaceId);
    final row = attempts[_key(workspaceId, id)];
    return row?.campaignId == campaignId ? row : null;
  }

  @override
  Future<void> upsertSkillPolicy(SkillEvaluationPolicy policy) async {
    _guard(policy.workspaceId);
    await beforePolicyWrite?.call(policy);
    policies[_key(policy.workspaceId, policy.skillKey)] = policy;
  }

  @override
  Future<SkillEvaluationPolicy?> skillPolicy(
    String workspaceId,
    String skillKey,
  ) async {
    _guard(workspaceId);
    return policies[_key(workspaceId, skillKey)];
  }

  @override
  Future<List<SkillEvaluationPolicy>> enabledSkillPolicies(
    String workspaceId,
  ) async {
    _guard(workspaceId);
    return policies.values
        .where((row) => row.workspaceId == workspaceId && row.enabled)
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshots implements SkillEvaluationSnapshotStore {
  final revisions = <String, String>{'candidate': 'A', 'ambient': 'X'};
  final captures = <String>[];
  Future<void> Function(String slug, int count)? beforeCapture;
  final counts = <String, int>{};

  @override
  Future<AdmittedSkillEvaluationSnapshot> capture({
    required String workspaceId,
    required String slug,
    String? repoId,
    String? skillPath,
  }) async {
    captures.add('$workspaceId:$slug');
    final count = counts.update(slug, (value) => value + 1, ifAbsent: () => 1);
    // Freeze the bytes before yielding: admission can overlap a later revision.
    final content = utf8.encode('---\nname: $slug\n---\n${revisions[slug]}');
    await beforeCapture?.call(slug, count);
    final files = <String, List<int>>{'SKILL.md': content};
    return AdmittedSkillEvaluationSnapshot(
      skillKey: repoId == null ? 'workspace:$slug' : 'repo:$repoId:$skillPath',
      skillPath: skillPath,
      package: SkillPackageSnapshot(
        slug: slug,
        files: files,
        packageHash: SkillPackageSnapshot.computeHash(files),
        origin: repoId == null ? 'workspace' : 'repository',
        repoId: repoId,
      ),
      scan: const SkillScanResult(
        verdict: SkillScanVerdict.pass,
        findings: [],
        manifest: SkillCapabilityManifest(),
        rulesVersion: 1,
      ),
    );
  }

  @override
  Future<AdmittedSkillEvaluationSnapshot?> previous({
    required String workspaceId,
    required String skillKey,
    required String hash,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  final repository = _Repository();
  final snapshots = _Snapshots();
  final bus = DomainEventBus();
  final authorized = <String>[];
  final models = <String>[];
  final rejectedModels = <String>{};
  final availableBackends = <String>{'builtin', 'claude-cli'};
  late final SkillEvaluationService service;
  bool registered = true;
  bool permit = true;
  _Execution execute = (job) async => _result(job);
  int nextId = 0;
  bool _closed = false;

  _Harness() {
    service = SkillEvaluationService(
      repository: repository,
      snapshots: snapshots,
      eventBus: bus,
      authorize: (workspaceId, actor, {required write, repoId}) async {
        authorized.add('$workspaceId:${repoId ?? '-'}');
        if (!permit ||
            workspaceId != _workspace ||
            !registered ||
            repoId == 'private')
          throw StateError('Access denied');
      },
      workspaceExists: (workspaceId) async =>
          registered && workspaceId == _workspace,
      registeredWorkspaceIds: () async => registered ? [_workspace] : [],
      capability: () async => {
        'available': true,
        'backends': availableBackends.toList(),
      },
      validateModel: (settings) async {
        models.add('${settings.providerId}:${settings.modelId}');
        if (rejectedModels.contains(settings.modelId))
          throw StateError('Model unavailable');
        return {'provider': settings.providerId, 'model': settings.modelId};
      },
      authorizeExecution: (workspaceId, actor, automatic) async {
        if (!registered || !permit) throw StateError('Execution denied');
      },
      execute: (job) => execute(job),
      now: () => _instant,
      newId: () => 'manual-${++nextId}',
    );
  }

  void revision(String slug) {
    final snapshot = snapshots.revisions[slug]!;
    final bytes = utf8.encode('---\nname: $slug\n---\n$snapshot');
    bus.publish(
      SkillUpdated(
        workspaceId: _workspace,
        slug: slug,
        origin: 'test',
        computedHash: SkillPackageSnapshot.computeHash({'SKILL.md': bytes}),
        occurredAt: _instant,
      ),
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await service.dispose();
    bus.dispose();
  }
}

SkillEvaluationSettings _settings({
  SkillEvaluationComparison comparison = SkillEvaluationComparison.absent,
  List<String> ambient = const [],
  String skillSlug = 'candidate',
  String modelId = 'vendor/model',
  String? repoId,
  String? skillPath,
}) => SkillEvaluationSettings(
  skillSlug: skillSlug,
  corpusId: _corpus,
  providerId: 'openrouter',
  modelId: modelId,
  comparison: comparison,
  repetitions: 1,
  budgetMicros: 1000000,
  ambientSkillSlugs: ambient,
  repoId: repoId,
  skillPath: skillPath,
);

SkillEvaluationCampaign _stored(
  String id,
  SkillEvaluationCampaignStatus status, {
  int? spent = 0,
  int completed = 0,
}) => SkillEvaluationCampaign(
  id: id,
  workspaceId: _workspace,
  skillKey: 'workspace:candidate',
  skillSlug: 'candidate',
  skillHash: 'hash-A',
  corpusId: _corpus,
  providerId: 'openrouter',
  modelId: 'vendor/model',
  configurationHash: 'config',
  comparison: SkillEvaluationComparison.absent,
  status: status,
  repetitions: 1,
  budgetMicros: 1000000,
  plannedAttempts: 2,
  completedAttempts: completed,
  spentMicros: spent,
  createdAt: _instant,
  actor: _actor,
  triggeredBy: 'manual',
  configuration: _settings().toJson(),
);

EvaluationAttempt _attempt(SkillEvaluationJob job, String id, {int? cost}) =>
    EvaluationAttempt(
      attemptId: id,
      taskId: job.corpus.tasks.first.id,
      taskKind: job.corpus.tasks.first.kind,
      armId: 'baseline',
      effective: const EvaluationEffectiveConfig(
        adapter: 'builtin',
        providerId: 'openrouter',
        modelId: 'vendor/model',
      ),
      stratum: CacheStratum.cold,
      repetition: 0,
      seed: 1,
      startedAtEpochMs: _instant.millisecondsSinceEpoch,
      cost: EvaluationCostRoles(billedMicros: cost),
      completed: true,
    );

EvaluationRunResult _result(SkillEvaluationJob job, {bool coverage = true}) =>
    EvaluationRunResult(
      report: EvaluationReport(
        manifest: EvaluationManifest(
          corpusId: job.corpus.id,
          corpusHash: job.corpus.corpusHash,
          adapter: 'builtin',
          providerId: 'openrouter',
          modelId: 'vendor/model',
        ),
        planId: job.campaign.id,
        seed: 1,
        executionMode: EvaluationExecutionMode.live,
        generatedAtEpochMs: _instant.millisecondsSinceEpoch,
        armSummaries: const [],
        taskOutcomes: const [],
        regressions: const [],
        verdicts: const [],
        caveats: const [],
        planViolations: const [],
        unknowns: const [],
        attempts: const [],
        expectedTrials: 2,
        expectedPairs: 1,
        coverageComplete: coverage,
      ),
      benchmark: BenchmarkRun(
        id: job.campaign.id,
        dataset: job.corpus.id,
        trials: const [],
        expectedTotal: 2,
        startedAt: _instant,
      ),
      artifacts: EvaluationArtifacts.forExisting('/unused'),
      trials: const [],
    );

void main() {
  test(
    'unavailable adapter is refused before model or skill admission',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      h.availableBackends.remove('claude-cli');
      await expectLater(
        h.service.launch(
          workspaceId: _workspace,
          actor: _actor,
          settings: SkillEvaluationSettings.fromJson({
            ..._settings().toJson(),
            'adapter': 'claude-cli',
          }),
        ),
        throwsStateError,
      );
      expect(h.models, isEmpty);
      expect(h.snapshots.captures, isEmpty);
      expect(h.repository.campaigns, isEmpty);
    },
  );

  test(
    'authorization refuses reads and launch before campaign or source exposure',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      h.permit = false;
      await expectLater(
        h.service.launch(
          workspaceId: _workspace,
          actor: _actor,
          settings: _settings(),
        ),
        throwsStateError,
      );
      await expectLater(
        h.service.get(_workspace, _actor, 'any'),
        throwsStateError,
      );
      await expectLater(
        h.service.attempts(_workspace, _actor, 'any'),
        throwsStateError,
      );
      await expectLater(
        h.service.export(_workspace, _actor, 'any'),
        throwsStateError,
      );
      await expectLater(
        h.service.watch(_workspace, _actor).first,
        throwsStateError,
      );
      expect(h.repository.reads, isEmpty);
      expect(h.snapshots.captures, isEmpty);
      expect(h.models, isEmpty);

      h.permit = true;
      await expectLater(
        h.service.launch(
          workspaceId: _workspace,
          actor: _actor,
          settings: _settings(
            repoId: 'private',
            skillPath: 'skills/candidate/SKILL.md',
          ),
        ),
        throwsStateError,
      );
      expect(h.snapshots.captures, isEmpty);
      h.repository.campaigns['$_workspace\u0000private-campaign'] =
          SkillEvaluationCampaign.fromJson({
            ..._stored(
              'private-campaign',
              SkillEvaluationCampaignStatus.completed,
            ).toJson(),
            'repoId': 'private',
            'skillKey': 'repo:private:skills/candidate/SKILL.md',
            'report': {'secret': 'repository'},
          });
      await expectLater(
        h.service.get(_workspace, _actor, 'private-campaign'),
        throwsStateError,
      );
      await expectLater(
        h.service.export(_workspace, _actor, 'private-campaign'),
        throwsStateError,
      );
      expect((await h.service.watch(_workspace, _actor).first), isEmpty);
      h.repository.campaigns['$_other\u0000foreign'] =
          SkillEvaluationCampaign.fromJson({
            ..._stored(
              'foreign',
              SkillEvaluationCampaignStatus.completed,
            ).toJson(),
            'workspaceId': _other,
            'report': {'secret': 'other'},
          });
      await expectLater(
        h.service.get(_workspace, _actor, 'foreign'),
        throwsStateError,
      );
      await expectLater(
        h.service.watchOne(_workspace, _actor, 'foreign').first,
        throwsStateError,
      );
      expect(h.repository.reads, everyElement(_workspace));
      h.registered = false;
      h.repository.registered = false;
      final readsBeforeRemoval = h.repository.reads.length;
      await expectLater(
        h.service.get(_workspace, _actor, 'foreign'),
        throwsStateError,
      );
      expect(h.repository.reads.length, readsBeforeRemoval);
    },
  );

  test(
    'restart interrupts paid work with unknown spend but queued work remains zero',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      for (final status in [
        SkillEvaluationCampaignStatus.queued,
        SkillEvaluationCampaignStatus.running,
        SkillEvaluationCampaignStatus.cancelling,
      ]) {
        final row = _stored(
          status.name,
          status,
          spent: status == SkillEvaluationCampaignStatus.queued ? 0 : 240,
          completed: status == SkillEvaluationCampaignStatus.queued ? 0 : 1,
        );
        await h.repository.upsertSkillCampaign(row);
      }
      await h.service.start();
      final rows = await h.repository.skillCampaigns(_workspace);
      for (final row in rows) {
        expect(row.status, SkillEvaluationCampaignStatus.interrupted);
        expect(row.finishedAt, isNotNull);
        expect(row.spentMicros, row.id == 'queued' ? 0 : isNull);
        expect(row.completedAttempts, row.id == 'queued' ? 0 : 1);
      }
    },
  );

  test(
    'queued cancellation never executes behind blocked run; active cancellation keeps attempts',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final entered = Completer<void>();
      final release = Completer<void>();
      final finished = Completer<void>();
      final executed = <String>[];
      h.execute = (job) async {
        executed.add(job.campaign.id);
        await job.onAttempt(_attempt(job, 'paid', cost: 20));
        entered.complete();
        await release.future;
        finished.complete();
        return _result(job);
      };
      final first = await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: _settings(),
      );
      await entered.future;
      final second = await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: _settings(),
      );
      expect(second.status, SkillEvaluationCampaignStatus.queued);
      expect(
        (await h.service.cancel(_workspace, _actor, second.id)).status,
        SkillEvaluationCampaignStatus.cancelled,
      );
      expect(
        (await h.service.cancel(_workspace, _actor, first.id)).status,
        SkillEvaluationCampaignStatus.cancelling,
      );
      release.complete();
      await finished.future;
      await h.repository.settled(first.id);
      await h.close();
      expect(executed, [first.id]);
      final active = await h.repository.skillCampaignById(_workspace, first.id);
      expect(active!.status, SkillEvaluationCampaignStatus.cancelled);
      expect(active.completedAttempts, 1);
      expect(active.spentMicros, 20);
      expect(
        (await h.repository.skillAttempts(_workspace, first.id)).single.id,
        'paid',
      );
      expect(active.report?['coverageComplete'], isNot(true));
      expect(
        (await h.repository.skillCampaignById(_workspace, second.id))!.report,
        isNull,
      );
    },
  );

  test(
    'policy saves never replay history; distinct revision runs once and disabling stops automatic work',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      await h.service.start();
      final settings = _settings();
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        true,
        settings.toJson(),
      );
      h.revision('candidate');
      await h.service.refreshRevisions();
      expect(h.repository.campaigns, isEmpty);
      h.snapshots.revisions['candidate'] = 'B';
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        true,
        settings.toJson(),
      );
      await h.service.refreshRevisions();
      expect(h.repository.campaigns, isEmpty);
      h.revision('candidate');
      await h.service.refreshRevisions();
      expect(h.repository.campaigns, isEmpty);

      final entered = Completer<void>();
      final release = Completer<void>();
      final executed = <String>[];
      h.execute = (job) async {
        executed.add(job.campaign.id);
        if (!entered.isCompleted) entered.complete();
        await release.future;
        return _result(job);
      };
      h.snapshots.revisions['candidate'] = 'C';
      h.revision('candidate');
      await h.service.refreshRevisions();
      await entered.future;
      final launched = h.repository.campaigns.values.single;
      expect(launched.skillHash, isNotEmpty);
      h.revision('candidate');
      await h.service.refreshRevisions();
      expect(h.repository.campaigns.length, 1);
      h.snapshots.revisions['candidate'] = 'D';
      h.revision('candidate');
      await h.service.refreshRevisions();
      final queued = h.repository.campaigns.values.singleWhere(
        (row) => row.id != launched.id,
      );
      expect(queued.status, SkillEvaluationCampaignStatus.queued);
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        false,
        settings.toJson(),
      );
      expect(
        await h.service
            .get(_workspace, _actor, launched.id)
            .then((row) => row.status),
        SkillEvaluationCampaignStatus.running,
      );
      release.complete();
      await h.repository.settled(launched.id);
      await h.repository.settled(queued.id);
      h.snapshots.revisions['candidate'] = 'E';
      h.revision('candidate');
      await h.service.refreshRevisions();
      await h.close();
      expect(
        (await h.repository.skillCampaignById(_workspace, launched.id))!.status,
        SkillEvaluationCampaignStatus.cancelled,
      );
      expect(
        (await h.repository.skillCampaignById(_workspace, queued.id))!.status,
        SkillEvaluationCampaignStatus.cancelled,
      );
      expect(executed, [launched.id]);
      expect(h.repository.campaigns.length, 2);
    },
  );

  test(
    'disable and reenable cannot revive an admission authorized by the old policy',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final settings = _settings();
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        true,
        settings.toJson(),
      );
      h.snapshots.revisions['candidate'] = 'B';
      final captured = Completer<void>();
      final release = Completer<void>();
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      h.snapshots.beforeCapture = (slug, count) async {
        if (!captured.isCompleted) {
          captured.complete();
          await release.future;
        }
      };
      var executions = 0;
      h.execute = (job) async {
        executions++;
        return _result(job);
      };
      final pending = h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: settings,
        automatic: true,
      );
      await captured.future;
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        false,
        settings.toJson(),
      );
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        true,
        settings.toJson(),
      );
      final rejected = expectLater(pending, throwsStateError);
      release.complete();
      await rejected;
      expect(executions, 0);
      expect(h.repository.campaigns, isEmpty);
      expect(h.repository.policies.values.single.enabled, true);
    },
  );

  test(
    'one invalid policy does not starve another sharing a changed ambient skill',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      h.snapshots.revisions['other'] = 'P';
      await h.service.start();
      final first = _settings(
        comparison: SkillEvaluationComparison.composition,
        ambient: ['ambient'],
        modelId: 'blocked/model',
      );
      final second = _settings(
        comparison: SkillEvaluationComparison.composition,
        ambient: ['ambient'],
        skillSlug: 'other',
      );
      await h.service.setPolicy(
        _workspace,
        _actor,
        first.skillKey,
        true,
        first.toJson(),
      );
      await h.service.setPolicy(
        _workspace,
        _actor,
        second.skillKey,
        true,
        second.toJson(),
      );
      await h.service.refreshRevisions();
      h.rejectedModels.add('blocked/model');
      h.snapshots.revisions['ambient'] = 'Y';
      h.revision('ambient');
      await h.service.refreshRevisions();
      final campaign = h.repository.campaigns.values.single;
      await h.repository.settled(campaign.id);
      expect(campaign.skillSlug, 'other');
      expect(
        (await h.repository.skillCampaignById(_workspace, campaign.id))!.status,
        SkillEvaluationCampaignStatus.completed,
      );
    },
  );

  test(
    'a delayed revision checkpoint cannot overwrite an explicit policy disable',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      await h.service.start();
      final settings = _settings();
      await h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        true,
        settings.toJson(),
      );
      await h.service.refreshRevisions();
      final entered = Completer<void>();
      final release = Completer<void>();
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      h.repository.beforePolicyWrite = (policy) async {
        if (policy.enabled && !entered.isCompleted) {
          entered.complete();
          await release.future;
        }
      };
      h.snapshots.revisions['candidate'] = 'B';
      h.revision('candidate');
      final refresh = h.service.refreshRevisions();
      await entered.future;
      final disabled = h.service.setPolicy(
        _workspace,
        _actor,
        settings.skillKey,
        false,
        settings.toJson(),
      );
      await Future<void>.delayed(Duration.zero);
      release.complete();
      await disabled;
      await refresh;
      expect(h.repository.policies.values.single.enabled, false);
    },
  );

  test(
    'composition ambient revision invalidates target and admission rechecks A after B race',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      await h.service.start();
      final settings = _settings(
        comparison: SkillEvaluationComparison.composition,
        ambient: ['ambient'],
      );
      final first = await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: settings,
      );
      h.snapshots.revisions['ambient'] = 'Y';
      h.revision('ambient');
      await h.service.refreshRevisions();
      expect(
        (await h.service.get(_workspace, _actor, first.id)).staleReason,
        isNotNull,
      );
      final captured = Completer<void>();
      final continueCapture = Completer<void>();
      h.snapshots.beforeCapture = (slug, count) async {
        if (slug == 'candidate' && !captured.isCompleted) {
          captured.complete();
          await continueCapture.future;
        }
      };
      final pending = h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: settings,
      );
      await captured.future;
      h.snapshots.revisions['candidate'] = 'B';
      h.revision('candidate');
      await h.service.refreshRevisions();
      continueCapture.complete();
      final admitted = await pending;
      expect(admitted.staleReason, isNotNull);
    },
  );

  test(
    'provider prefix is stripped once and the normalized model reaches admission',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      Map<String, dynamic> wire(String model) => {
        ..._settings().toJson(),
        'model_id': model,
      };
      expect(
        SkillEvaluationSettings.fromJson(
          wire('openrouter/vendor/model'),
        ).modelId,
        'vendor/model',
      );
      expect(
        SkillEvaluationSettings.fromJson(
          wire('openrouter/openrouter/vendor/model'),
        ).modelId,
        'openrouter/vendor/model',
      );
      expect(
        SkillEvaluationSettings.fromJson(wire('vendor/model')).modelId,
        'vendor/model',
      );
      final campaign = await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: SkillEvaluationSettings.fromJson(
          wire('openrouter/vendor/model'),
        ),
      );
      expect(campaign.modelId, 'vendor/model');
      expect(h.models, ['openrouter:vendor/model']);
    },
  );

  test(
    'unknown costs remain unknown and partial report cannot complete',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final recorded = Completer<void>();
      h.execute = (job) async {
        await job.onAttempt(_attempt(job, 'unpriced'));
        recorded.complete();
        return _result(job, coverage: false);
      };
      final row = await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: _settings(),
      );
      await recorded.future;
      await h.repository.settled(row.id);
      await h.close();
      final actual = (await h.repository.skillCampaignById(
        _workspace,
        row.id,
      ))!;
      expect(actual.completedAttempts, 1);
      expect(actual.spentMicros, isNull);
      expect(actual.status, SkillEvaluationCampaignStatus.failed);
      expect(actual.report?['coverageComplete'], false);
    },
  );

  test(
    'removed workspace never reopens repository after failed running work',
    () async {
      final h = _Harness();
      addTearDown(h.close);
      final entered = Completer<void>();
      final release = Completer<void>();
      h.execute = (job) async {
        entered.complete();
        await release.future;
        throw StateError('executor failed after deletion');
      };
      await h.service.launch(
        workspaceId: _workspace,
        actor: _actor,
        settings: _settings(),
      );
      await entered.future;
      final before = h.repository.reads.length;
      h.registered = false;
      h.repository.registered = false;
      release.complete();
      await h.close();
      expect(h.repository.reads.length, before);
    },
  );
}
