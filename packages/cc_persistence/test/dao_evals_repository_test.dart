import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoEvalsRepository] against the real Drift database. The repository
/// is a thin mapper+delegate layer over the evals DAO; these tests assert the
/// round-trip through the domain entities and the workspace-scoped reads,
/// including the watch streams and lifecycle update methods.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoEvalsRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoEvalsRepository(dbs);
    // The evals tables only FK-reference workspaces, so seed those.
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  group('DaoEvalsRepository session recordings', () {
    final createdAt = DateTime.utc(2026, 7, 1, 9);

    SessionRecording recording(
      String id,
      String ws, {
      String runLogId = 'log-1',
      String? agentId,
      int hashVersion = 1,
      int eventCount = 0,
      String title = '',
    }) => SessionRecording(
      id: id,
      workspaceId: ws,
      runLogId: runLogId,
      agentId: agentId,
      configHash: 'cfg-$id',
      hashVersion: hashVersion,
      eventCount: eventCount,
      title: title,
      createdAt: createdAt,
    );

    test('upsertRecording + recordingById round-trips the entity', () async {
      await repo.upsertRecording(
        recording(
          'rec-1',
          'w-1',
          agentId: 'a-1',
          title: 'First',
          eventCount: 10,
          hashVersion: 2,
        ),
      );
      final r = await repo.recordingById('w-1', 'rec-1');
      expect(r, isNotNull);
      expect(r!.runLogId, 'log-1');
      expect(r.agentId, 'a-1');
      expect(r.title, 'First');
      expect(r.eventCount, 10);
      expect(r.hashVersion, 2);
      expect(r.configHash, 'cfg-rec-1');
    });

    test('upsertRecording is idempotent on the same id', () async {
      await repo.upsertRecording(recording('rec-1', 'w-1', agentId: 'a-1'));
      await repo.upsertRecording(recording('rec-1', 'w-1', agentId: 'a-2'));
      final r = await repo.recordingById('w-1', 'rec-1');
      expect(r!.agentId, 'a-2');
    });

    test(
      'recordingById does not surface a row from another workspace',
      () async {
        await repo.upsertRecording(recording('rec-1', 'w-1'));
        expect(await repo.recordingById('w-2', 'rec-1'), isNull);
      },
    );

    test('recordingByRunLog matches within the workspace only', () async {
      await repo.upsertRecording(recording('rec-1', 'w-1', runLogId: 'shared'));
      await repo.upsertRecording(recording('rec-2', 'w-2', runLogId: 'shared'));
      expect((await repo.recordingByRunLog('w-1', 'shared'))!.id, 'rec-1');
      expect((await repo.recordingByRunLog('w-2', 'shared'))!.id, 'rec-2');
      expect(await repo.recordingByRunLog('w-1', 'missing'), isNull);
    });

    test('recordings filters by agent and stays workspace-scoped', () async {
      await repo.upsertRecording(recording('r-1', 'w-1', agentId: 'a-x'));
      await repo.upsertRecording(recording('r-2', 'w-1', agentId: 'a-y'));
      await repo.upsertRecording(recording('r-3', 'w-2', agentId: 'a-x'));
      expect((await repo.recordings('w-1')).map((r) => r.id).toSet(), {
        'r-1',
        'r-2',
      });
      expect((await repo.recordings('w-1', agentId: 'a-x')).single.id, 'r-1');
    });

    test('watchRecordings emits only the workspace rows', () async {
      await repo.upsertRecording(recording('r-1', 'w-1'));
      await repo.upsertRecording(recording('r-2', 'w-2'));
      final snap = await repo.watchRecordings('w-1').first;
      expect(snap.single.id, 'r-1');
    });

    test(
      'pruneRecordings deletes older rows and is workspace-scoped',
      () async {
        await repo.upsertRecording(
          SessionRecording(
            id: 'r-old',
            workspaceId: 'w-1',
            runLogId: 'log-old',
            configHash: 'cfg',
            createdAt: DateTime.utc(2023, 1, 1),
          ),
        );
        await repo.upsertRecording(
          SessionRecording(
            id: 'r-new',
            workspaceId: 'w-1',
            runLogId: 'log-new',
            configHash: 'cfg',
            createdAt: DateTime.utc(2025, 1, 1),
          ),
        );
        await repo.upsertRecording(
          SessionRecording(
            id: 'r-other',
            workspaceId: 'w-2',
            runLogId: 'log-other',
            configHash: 'cfg',
            createdAt: DateTime.utc(2023, 1, 1),
          ),
        );
        final deleted = await repo.pruneRecordings(
          'w-1',
          DateTime.utc(2024, 1, 1),
        );
        expect(deleted, 1);
        expect((await repo.recordings('w-1')).single.id, 'r-new');
        expect((await repo.recordings('w-2')).single.id, 'r-other');
      },
    );
  });

  group('DaoEvalsRepository golden sessions', () {
    final blessedAt = DateTime.utc(2026, 6, 1);

    GoldenSession golden(
      String id,
      String ws, {
      String agentId = 'a-1',
      String recordingId = 'rec-1',
      bool enabled = true,
      String name = '',
    }) => GoldenSession(
      id: id,
      workspaceId: ws,
      agentId: agentId,
      recordingId: recordingId,
      enabled: enabled,
      name: name,
      blessedAt: blessedAt,
    );

    test('upsertGolden + goldenById round-trips the entity', () async {
      await repo.upsertGolden(golden('g-1', 'w-1', name: 'baseline'));
      final g = await repo.goldenById('w-1', 'g-1');
      expect(g, isNotNull);
      expect(g!.name, 'baseline');
      expect(g.agentId, 'a-1');
    });

    test('goldenById does not surface a row from another workspace', () async {
      await repo.upsertGolden(golden('g-1', 'w-1'));
      expect(await repo.goldenById('w-2', 'g-1'), isNull);
    });

    test(
      'goldensForAgent returns only enabled goldens, workspace-scoped',
      () async {
        await repo.upsertGolden(golden('g-1', 'w-1', agentId: 'a-1'));
        await repo.upsertGolden(
          golden('g-2', 'w-1', agentId: 'a-1', enabled: false),
        );
        await repo.upsertGolden(golden('g-3', 'w-2', agentId: 'a-1'));
        expect((await repo.goldensForAgent('w-1', 'a-1')).single.id, 'g-1');
      },
    );

    test('goldens lists all rows in the workspace', () async {
      await repo.upsertGolden(golden('g-1', 'w-1'));
      await repo.upsertGolden(golden('g-2', 'w-2'));
      expect((await repo.goldens('w-1')).single.id, 'g-1');
    });

    test('watchGoldens emits only the workspace rows', () async {
      await repo.upsertGolden(golden('g-1', 'w-1'));
      await repo.upsertGolden(golden('g-2', 'w-2'));
      expect((await repo.watchGoldens('w-1').first).single.id, 'g-1');
    });

    test('updateGoldenResult records status and scorecard', () async {
      await repo.upsertGolden(golden('g-1', 'w-1'));
      await repo.updateGoldenResult('w-1', 'g-1', 'pass', '{"p": 1}');
      final g = await repo.goldenById('w-1', 'g-1');
      expect(g!.lastStatus, 'pass');
      expect(g.lastScorecardJson, '{"p": 1}');
    });

    test(
      'updateGoldenResult is workspace-scoped — foreign id is a no-op',
      () async {
        await repo.upsertGolden(golden('g-1', 'w-1'));
        await repo.updateGoldenResult('w-2', 'g-1', 'fail', null);
        expect((await repo.goldenById('w-1', 'g-1'))!.lastStatus, 'unknown');
      },
    );

    test('deleteGolden is scoped — foreign id deletes nothing', () async {
      await repo.upsertGolden(golden('g-1', 'w-1'));
      await repo.deleteGolden('w-2', 'g-1');
      expect(await repo.goldenById('w-1', 'g-1'), isNotNull);
      await repo.deleteGolden('w-1', 'g-1');
      expect(await repo.goldenById('w-1', 'g-1'), isNull);
    });
  });

  group('DaoEvalsRepository eval suites', () {
    final createdAt = DateTime.utc(2026, 5, 1);
    final updatedAt = DateTime.utc(2026, 5, 2);

    EvalSuite suite(
      String id,
      String ws, {
      String name = 'suite',
      String description = '',
      String taskJson = '{}',
      String gradersJson = '[]',
      int defaultBatchSize = 1,
      bool isStarter = false,
    }) => EvalSuite(
      id: id,
      workspaceId: ws,
      name: name,
      description: description,
      taskJson: taskJson,
      gradersJson: gradersJson,
      defaultBatchSize: defaultBatchSize,
      isStarter: isStarter,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    test('upsertSuite + suiteById round-trips the entity', () async {
      await repo.upsertSuite(suite('s-1', 'w-1', name: 'regression'));
      final s = await repo.suiteById('w-1', 's-1');
      expect(s, isNotNull);
      expect(s!.name, 'regression');
    });

    test('suiteByName resolves within the workspace only', () async {
      await repo.upsertSuite(suite('s-1', 'w-1', name: 'shared'));
      await repo.upsertSuite(suite('s-2', 'w-2', name: 'shared'));
      expect((await repo.suiteByName('w-1', 'shared'))!.id, 's-1');
      expect((await repo.suiteByName('w-2', 'shared'))!.id, 's-2');
      expect(await repo.suiteByName('w-1', 'missing'), isNull);
    });

    test('suiteById does not surface a suite from another workspace', () async {
      await repo.upsertSuite(suite('s-1', 'w-1'));
      expect(await repo.suiteById('w-2', 's-1'), isNull);
    });

    test('suites lists all rows in the workspace', () async {
      await repo.upsertSuite(suite('s-1', 'w-1'));
      await repo.upsertSuite(suite('s-2', 'w-2'));
      expect((await repo.suites('w-1')).single.id, 's-1');
    });

    test('watchSuites emits only the workspace rows', () async {
      await repo.upsertSuite(suite('s-1', 'w-1'));
      await repo.upsertSuite(suite('s-2', 'w-2'));
      expect((await repo.watchSuites('w-1').first).single.id, 's-1');
    });

    test('deleteSuite is scoped — foreign id deletes nothing', () async {
      await repo.upsertSuite(suite('s-1', 'w-1'));
      await repo.deleteSuite('w-2', 's-1');
      expect(await repo.suiteById('w-1', 's-1'), isNotNull);
      await repo.deleteSuite('w-1', 's-1');
      expect(await repo.suiteById('w-1', 's-1'), isNull);
    });
  });

  group('DaoEvalsRepository eval runs', () {
    final createdAt = DateTime.utc(2026, 4, 1);

    EvalRun run(
      String id,
      String ws, {
      String suiteId = 's-1',
      String status = 'queued',
    }) => EvalRun(
      id: id,
      workspaceId: ws,
      suiteId: suiteId,
      configHash: 'cfg-$id',
      status: status,
      createdAt: createdAt,
    );

    test('upsertRun + runById round-trips the entity', () async {
      await repo.upsertRun(run('run-1', 'w-1', status: 'running'));
      final r = await repo.runById('w-1', 'run-1');
      expect(r, isNotNull);
      expect(r!.status, 'running');
    });

    test('runById does not surface a run from another workspace', () async {
      await repo.upsertRun(run('run-1', 'w-1'));
      expect(await repo.runById('w-2', 'run-1'), isNull);
    });

    test('runsForSuite is workspace-scoped', () async {
      await repo.upsertRun(run('r-1', 'w-1', suiteId: 's-shared'));
      await repo.upsertRun(run('r-2', 'w-2', suiteId: 's-shared'));
      expect((await repo.runsForSuite('w-1', 's-shared')).single.id, 'r-1');
      expect((await repo.runsForSuite('w-2', 's-shared')).single.id, 'r-2');
    });

    test('watchRunsForSuite emits only the workspace rows', () async {
      await repo.upsertRun(run('r-1', 'w-1', suiteId: 's-shared'));
      await repo.upsertRun(run('r-2', 'w-2', suiteId: 's-shared'));
      expect(
        (await repo.watchRunsForSuite('w-1', 's-shared').first).single.id,
        'r-1',
      );
    });

    test(
      'updateRunResult marks a run terminal and writes its scorecard',
      () async {
        await repo.upsertRun(run('r-1', 'w-1'));
        await repo.updateRunResult(
          'w-1',
          'r-1',
          status: 'done',
          scorecardJson: '{"p": 0.5}',
          passRate: 0.5,
          costCents: 42,
          startedAt: DateTime.utc(2024, 1, 1),
          finishedAt: DateTime.utc(2024, 1, 2),
        );
        final r = await repo.runById('w-1', 'r-1');
        expect(r!.status, 'done');
        expect(r.scorecardJson, '{"p": 0.5}');
        expect(r.passRate, 0.5);
        expect(r.costCents, 42);
        expect(r.startedAt, isNotNull);
        expect(r.finishedAt, isNotNull);
      },
    );

    test(
      'updateRunResult is workspace-scoped — foreign id is a no-op',
      () async {
        await repo.upsertRun(run('r-1', 'w-1'));
        await repo.updateRunResult('w-2', 'r-1', status: 'failed');
        expect((await repo.runById('w-1', 'r-1'))!.status, 'queued');
      },
    );
  });

  group('DaoEvalsRepository agent config versions', () {
    final createdAt = DateTime.utc(2026, 3, 1);

    AgentConfigVersion version(
      String id,
      String ws, {
      String agentId = 'a-1',
      String configHash = 'h',
      String status = 'live',
    }) => AgentConfigVersion(
      id: id,
      workspaceId: ws,
      agentId: agentId,
      configHash: configHash,
      status: status,
      createdAt: createdAt,
    );

    test(
      'upsertConfigVersion + configVersionByHash round-trips the entity',
      () async {
        await repo.upsertConfigVersion(
          version('v-1', 'w-1', configHash: 'hash-a'),
        );
        final v = await repo.configVersionByHash('w-1', 'a-1', 'hash-a');
        expect(v, isNotNull);
        expect(v!.id, 'v-1');
      },
    );

    test(
      'configVersionByHash does not surface a row from another workspace',
      () async {
        await repo.upsertConfigVersion(
          version('v-1', 'w-1', configHash: 'shared'),
        );
        await repo.upsertConfigVersion(
          version('v-2', 'w-2', configHash: 'shared'),
        );
        expect(
          (await repo.configVersionByHash('w-1', 'a-1', 'shared'))!.id,
          'v-1',
        );
        expect(
          (await repo.configVersionByHash('w-2', 'a-1', 'shared'))!.id,
          'v-2',
        );
      },
    );

    test(
      'liveConfigVersion returns the live version, workspace-scoped',
      () async {
        await repo.upsertConfigVersion(
          version('v-canary', 'w-1', configHash: 'h-c', status: 'canary'),
        );
        await repo.upsertConfigVersion(
          version('v-live', 'w-1', configHash: 'h-l', status: 'live'),
        );
        await repo.upsertConfigVersion(
          version('v-other', 'w-2', configHash: 'h-l2', status: 'live'),
        );
        final live = await repo.liveConfigVersion('w-1', 'a-1');
        expect(live, isNotNull);
        expect(live!.id, 'v-live');
        expect(await repo.liveConfigVersion('w-2', 'a-1'), isNotNull);
      },
    );

    test(
      'liveConfigVersion returns null when no live version exists',
      () async {
        await repo.upsertConfigVersion(version('v-1', 'w-1', status: 'canary'));
        expect(await repo.liveConfigVersion('w-1', 'a-1'), isNull);
      },
    );

    test(
      'configVersionsForAgent lists all versions, workspace-scoped',
      () async {
        await repo.upsertConfigVersion(
          version('v-1', 'w-1', configHash: 'h-1'),
        );
        await repo.upsertConfigVersion(
          version('v-2', 'w-1', configHash: 'h-2'),
        );
        await repo.upsertConfigVersion(
          version('v-other', 'w-2', configHash: 'h-3'),
        );
        final rows = await repo.configVersionsForAgent('w-1', 'a-1');
        expect(rows.map((v) => v.id).toSet(), {'v-1', 'v-2'});
      },
    );

    test(
      'setConfigVersionStatus promotes a version within the workspace',
      () async {
        await repo.upsertConfigVersion(version('v-1', 'w-1', status: 'canary'));
        await repo.setConfigVersionStatus(
          'w-1',
          'v-1',
          status: 'live',
          promotedBy: 'sam',
          promotedAt: DateTime.utc(2024, 6, 1),
          scorecardJson: '{"ok": true}',
        );
        final v = await repo.configVersionByHash('w-1', 'a-1', 'h');
        expect(v!.status, 'live');
        expect(v.promotedBy, 'sam');
        expect(v.scorecardJson, '{"ok": true}');
      },
    );

    test('setConfigVersionStatus is scoped — foreign id is a no-op', () async {
      await repo.upsertConfigVersion(version('v-1', 'w-1', status: 'canary'));
      await repo.setConfigVersionStatus('w-2', 'v-1', status: 'live');
      expect(
        (await repo.configVersionByHash('w-1', 'a-1', 'h'))!.status,
        'canary',
      );
    });
  });
}
