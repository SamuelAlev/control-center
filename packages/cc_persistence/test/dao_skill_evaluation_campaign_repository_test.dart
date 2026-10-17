import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/evals_mapper.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

final _time = DateTime.utc(2026, 10, 11, 8, 0);

SkillEvaluationCampaign _campaign({
  String id = 'campaign-1',
  String workspaceId = 'ws-1',
  String skillKey = 'workspace:review',
}) => SkillEvaluationCampaign(
  id: id,
  workspaceId: workspaceId,
  skillKey: skillKey,
  skillSlug: 'review',
  skillHash: 'hash-1',
  corpusId: 'corpus-1',
  providerId: 'provider-1',
  modelId: 'model-1',
  configurationHash: 'config-1',
  comparison: SkillEvaluationComparison.absent,
  status: SkillEvaluationCampaignStatus.queued,
  repetitions: 3,
  budgetMicros: 900000,
  plannedAttempts: 6,
  completedAttempts: 0,
  createdAt: _time,
  actor: const UserPrincipal('user-1'),
  triggeredBy: 'manual',
  configuration: {
    'policy': {'kind': 'deny'},
    'ambient': <String>[],
  },
);

SkillEvaluationAttemptRecord _attempt({
  String id = 'attempt-1',
  String workspaceId = 'ws-1',
  String campaignId = 'campaign-1',
}) => SkillEvaluationAttemptRecord(
  id: id,
  workspaceId: workspaceId,
  campaignId: campaignId,
  taskId: 'task-1',
  armId: 'treatment',
  repetition: 0,
  ordinal: 0,
  evidence: {
    'events': [
      {'type': 'skill_load', 'observed': true},
    ],
  },
  createdAt: _time.add(const Duration(minutes: 1)),
);

SkillEvaluationPolicy _policy({
  String workspaceId = 'ws-1',
  bool enabled = true,
}) => SkillEvaluationPolicy(
  workspaceId: workspaceId,
  skillKey: 'workspace:review',
  enabled: enabled,
  actor: const UserPrincipal('user-1'),
  configuration: {'corpusId': 'corpus-1', 'budgetMicros': 900000},
  updatedAt: _time,
);

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoEvalsRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    repo = DaoEvalsRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test(
    'lifecycle/index/watch and partial report preserve revision and unknown cost',
    () async {
      final queued = _campaign();
      expect(await repo.watchSkillCampaign('ws-1', queued.id).first, isNull);
      final listChange = repo
          .watchSkillCampaigns('ws-1')
          .firstWhere((campaigns) => campaigns.isNotEmpty);
      await repo.upsertSkillCampaign(queued);
      expect(await listChange, [queued]);
      final running = queued.copyWith(
        status: SkillEvaluationCampaignStatus.running,
        startedAt: _time.add(const Duration(seconds: 1)),
        completedAttempts: 1,
        report: {
          'summary': {'complete': false, 'costMicros': null},
        },
      );
      final change = repo
          .watchSkillCampaign('ws-1', queued.id)
          .firstWhere(
            (campaign) =>
                campaign?.status == SkillEvaluationCampaignStatus.running,
          );
      await repo.upsertSkillCampaign(running);
      expect(await change, running);
      final cancelled = running.copyWith(
        status: SkillEvaluationCampaignStatus.cancelled,
        finishedAt: _time.add(const Duration(seconds: 4)),
        staleReason: 'revision_changed',
      );
      await repo.upsertSkillCampaign(cancelled);
      expect(await repo.skillCampaignById('ws-1', queued.id), cancelled);
      expect(
        (await repo.skillCampaigns('ws-1', skillKey: queued.skillKey)).single,
        cancelled,
      );
      expect(cancelled.spentMicros, isNull);
      expect(
        await repo.skillCampaigns('ws-1', skillKey: 'workspace:other'),
        isEmpty,
      );
      expect(await repo.skillCampaigns('ws-1', limit: 0), isEmpty);
    },
  );
  test('terminal campaigns cannot restart or lose progress', () async {
    final queued = _campaign();
    await repo.upsertSkillCampaign(queued);
    final running = queued.copyWith(
      status: SkillEvaluationCampaignStatus.running,
      completedAttempts: 2,
    );
    await repo.upsertSkillCampaign(running);
    await expectLater(repo.upsertSkillCampaign(queued), throwsStateError);
    final finished = running.copyWith(
      status: SkillEvaluationCampaignStatus.completed,
    );
    await repo.upsertSkillCampaign(finished);
    await expectLater(
      repo.upsertSkillCampaign(
        finished.copyWith(status: SkillEvaluationCampaignStatus.running),
      ),
      throwsStateError,
    );
    expect(await repo.skillCampaignById('ws-1', queued.id), finished);
  });

  test(
    'attempt ownership cannot be forged or reparented; scoped reads exclude other campaigns',
    () async {
      await repo.upsertSkillCampaign(_campaign());
      await repo.upsertSkillCampaign(_campaign(id: 'campaign-2'));
      await repo.upsertSkillCampaign(_campaign(workspaceId: 'ws-2'));
      await repo.upsertSkillAttempt(_attempt());
      expect(await repo.skillAttempts('ws-1', 'campaign-1'), [_attempt()]);
      expect(
        await repo.skillAttemptById('ws-1', 'campaign-1', 'attempt-1'),
        _attempt(),
      );
      expect(
        await repo.skillAttemptById('ws-1', 'campaign-2', 'attempt-1'),
        isNull,
      );
      expect(
        await repo.skillAttemptById('ws-2', 'campaign-1', 'attempt-1'),
        isNull,
      );
      await expectLater(
        repo.upsertSkillAttempt(_attempt(campaignId: 'campaign-2')),
        throwsStateError,
      );
      await expectLater(
        repo.upsertSkillAttempt(_attempt(id: 'missing', campaignId: 'none')),
        throwsStateError,
      );
      final richer = SkillEvaluationAttemptRecord.fromJson({
        ..._attempt().toJson(),
        'evidence': {
          'events': [
            {'type': 'verifier', 'passed': false},
          ],
        },
      });
      await repo.upsertSkillAttempt(richer);
      expect(
        await repo.skillAttemptById('ws-1', 'campaign-1', 'attempt-1'),
        richer,
      );
      final changedTask = SkillEvaluationAttemptRecord.fromJson({
        ..._attempt().toJson(),
        'taskId': 'different-task',
      });
      await expectLater(repo.upsertSkillAttempt(changedTask), throwsStateError);
      // Two database files can use the same attempt id, without leaking either row.
      final other = _attempt(workspaceId: 'ws-2');
      await repo.upsertSkillAttempt(other);
      expect(await repo.skillAttempts('ws-2', 'campaign-1'), [other]);
      final dao = dbs.of('ws-1').evalsDao;
      await expectLater(
        dao.upsertSkillAttempt(
          const EvalsMapper().skillAttemptToCompanion(other),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'campaign id cannot move to another skill or workspace; policy is scoped opt-in',
    () async {
      final campaign = _campaign();
      await repo.upsertSkillCampaign(campaign);
      await expectLater(
        repo.upsertSkillCampaign(_campaign(skillKey: 'workspace:other')),
        throwsStateError,
      );
      final changedConfiguration = SkillEvaluationCampaign.fromJson({
        ...campaign.toJson(),
        'configuration': {
          'policy': {'kind': 'allow'},
        },
      });
      await expectLater(
        repo.upsertSkillCampaign(changedConfiguration),
        throwsStateError,
      );
      expect(await repo.skillCampaignById('ws-1', campaign.id), campaign);
      expect(await repo.skillCampaignById('ws-2', campaign.id), isNull);
      expect(await repo.watchSkillCampaign('ws-2', campaign.id).first, isNull);
      expect(await repo.watchSkillCampaigns('ws-2').first, isEmpty);
      final dao = dbs.of('ws-1').evalsDao;
      await expectLater(
        dao.upsertSkillCampaign(
          const EvalsMapper().skillCampaignToCompanion(
            _campaign(workspaceId: 'ws-2', id: 'foreign'),
          ),
        ),
        throwsStateError,
      );

      expect(await repo.skillPolicy('ws-1', 'workspace:review'), isNull);
      await repo.upsertSkillPolicy(_policy());
      await repo.upsertSkillPolicy(
        _policy(workspaceId: 'ws-2', enabled: false),
      );
      expect(await repo.enabledSkillPolicies('ws-1'), [_policy()]);
      expect(await repo.enabledSkillPolicies('ws-2'), isEmpty);
      expect(
        await repo.skillPolicy('ws-2', 'workspace:review'),
        _policy(workspaceId: 'ws-2', enabled: false),
      );
      await repo.upsertSkillPolicy(_policy(enabled: false));
      expect(await repo.enabledSkillPolicies('ws-1'), isEmpty);
      expect(
        () => dao.upsertSkillPolicy(
          const EvalsMapper().skillPolicyToCompanion(
            _policy(workspaceId: 'ws-2'),
          ),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'on-disk workspace database reopens campaign, attempt and policy',
    () async {
      final dir = await Directory.systemTemp.createTemp('skill_evals_reopen_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/workspace.db');
      const mapper = EvalsMapper();
      final first = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws-1',
      );
      final completed = _campaign().copyWith(
        status: SkillEvaluationCampaignStatus.completed,
        completedAttempts: 6,
        spentMicros: 54321,
        report: {
          'regressions': [
            {'task': 'task-1', 'delta': -1},
          ],
        },
        finishedAt: _time.add(const Duration(minutes: 4)),
      );
      await first.evalsDao.upsertSkillCampaign(
        mapper.skillCampaignToCompanion(completed),
      );
      await first.evalsDao.upsertSkillAttempt(
        mapper.skillAttemptToCompanion(_attempt()),
      );
      await first.evalsDao.upsertSkillPolicy(
        mapper.skillPolicyToCompanion(_policy()),
      );
      await first.close();

      final second = WorkspaceDatabase.forTesting(
        NativeDatabase(file),
        workspaceId: 'ws-1',
      );
      addTearDown(second.close);
      final row = await second.evalsDao.skillCampaignById('ws-1', 'campaign-1');
      expect(mapper.skillCampaignFromRow(row!), completed);
      expect(
        mapper.skillAttemptFromRow(
          (await second.evalsDao.skillAttempts('ws-1', 'campaign-1')).single,
        ),
        _attempt(),
      );
      expect(
        mapper.skillPolicyFromRow(
          (await second.evalsDao.skillPolicy('ws-1', 'workspace:review'))!,
        ),
        _policy(),
      );
    },
  );
}
