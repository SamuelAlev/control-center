import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // The evals tables only FK-reference workspaces, so seed those.
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionRecordings workspace isolation', () {
    Future<void> putRecording(
      String ws,
      String id, {
      String runLogId = 'log-1',
      String? agentId,
      String configHash = 'cfg',
      DateTime? createdAt,
    }) => db.evalsDao.upsertRecording(
      SessionRecordingsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        runLogId: runLogId,
        configHash: configHash,
        agentId: agentId == null ? const Value.absent() : Value(agentId),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );

    test('upsert + recordingById round-trips the row', () async {
      await putRecording('w-1', 'rec-1', agentId: 'a-1');
      final row = await db.evalsDao.recordingById('w-1', 'rec-1');
      expect(row, isNotNull);
      expect(row!.runLogId, 'log-1');
      expect(row.agentId, 'a-1');
    });

    test('upsert is idempotent — same id replaces in place', () async {
      await putRecording('w-1', 'rec-1', configHash: 'cfg-a');
      await putRecording('w-1', 'rec-1', configHash: 'cfg-b');
      final row = await db.evalsDao.recordingById('w-1', 'rec-1');
      expect(row!.configHash, 'cfg-b');
    });

    test(
      'recordingById does not surface a row from another workspace',
      () async {
        await putRecording('w-1', 'rec-1');
        final row = await db.evalsDao.recordingById('w-2', 'rec-1');
        expect(row, isNull);
      },
    );

    test('recordingByRunLog matches only within the workspace', () async {
      // Same runLogId in both workspaces; the lookup must be ws-scoped.
      await putRecording('w-1', 'rec-1', runLogId: 'shared-log');
      await putRecording('w-2', 'rec-2', runLogId: 'shared-log');
      final inOne = await db.evalsDao.recordingByRunLog('w-1', 'shared-log');
      final inTwo = await db.evalsDao.recordingByRunLog('w-2', 'shared-log');
      expect(inOne!.id, 'rec-1');
      expect(inTwo!.id, 'rec-2');
      expect(await db.evalsDao.recordingByRunLog('w-1', 'nope'), isNull);
    });

    test('recordings filters by agent and orders newest-first', () async {
      final t0 = DateTime.utc(2024, 1, 1);
      final t1 = DateTime.utc(2024, 1, 2);
      final t2 = DateTime.utc(2024, 1, 3);
      await putRecording('w-1', 'r0', agentId: 'a-x', createdAt: t0);
      await putRecording('w-1', 'r1', agentId: 'a-y', createdAt: t1);
      await putRecording('w-1', 'r2', agentId: 'a-x', createdAt: t2);
      final all = await db.evalsDao.recordings('w-1');
      expect(all.map((r) => r.id), ['r2', 'r1', 'r0']);
      final onlyX = await db.evalsDao.recordings('w-1', agentId: 'a-x');
      expect(onlyX.map((r) => r.id), ['r2', 'r0']);
    });

    test('recordings stays scoped to the workspace', () async {
      await putRecording('w-1', 'r1');
      await putRecording('w-2', 'r2');
      expect((await db.evalsDao.recordings('w-1')).single.id, 'r1');
      expect((await db.evalsDao.recordings('w-2')).single.id, 'r2');
    });

    test(
      'watchRecordings emits only the workspace rows and updates live',
      () async {
        final stream = db.evalsDao.watchRecordings('w-1');
        final first = stream.first;
        await Future<void>.delayed(Duration.zero);
        expect(await first, isEmpty);
        await putRecording('w-1', 'r1');
        await putRecording('w-2', 'r2');
        final snapshot = await db.evalsDao.watchRecordings('w-1').first;
        expect(snapshot.single.id, 'r1');
      },
    );

    test(
      'pruneRecordings deletes only rows older than the cutoff, in-scope',
      () async {
        final old = DateTime.utc(2023, 1, 1);
        final recent = DateTime.utc(2025, 1, 1);
        await putRecording('w-1', 'r-old', createdAt: old);
        await putRecording('w-1', 'r-new', createdAt: recent);
        // An old row in w-2 must NOT be touched by a w-1 prune (unique id — the
        // PK is {id}, not (workspaceId, id)).
        await putRecording('w-2', 'r-other', createdAt: old);

        final deleted = await db.evalsDao.pruneRecordings(
          'w-1',
          DateTime.utc(2024, 1, 1),
        );
        expect(deleted, 1);
        final left = await db.evalsDao.recordings('w-1');
        expect(left.single.id, 'r-new');
        // w-2's old row survived a w-1-scoped prune.
        expect((await db.evalsDao.recordings('w-2')).single.id, 'r-other');
      },
    );
  });

  group('GoldenSessions workspace isolation', () {
    Future<void> putGolden(
      String ws,
      String id, {
      String agentId = 'a-1',
      String recordingId = 'rec-1',
      String mode = 'deterministic',
      bool enabled = true,
      String name = '',
    }) => db.evalsDao.upsertGolden(
      GoldenSessionsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        agentId: agentId,
        recordingId: recordingId,
        mode: Value(mode),
        enabled: Value(enabled),
        name: Value(name),
      ),
    );

    test('upsert + goldenById round-trips the row', () async {
      await putGolden('w-1', 'g-1', name: 'baseline');
      final row = await db.evalsDao.goldenById('w-1', 'g-1');
      expect(row, isNotNull);
      expect(row!.name, 'baseline');
      expect(row.lastStatus, 'unknown'); // schema default
    });

    test('goldenById does not surface a row from another workspace', () async {
      await putGolden('w-1', 'g-1');
      expect(await db.evalsDao.goldenById('w-2', 'g-1'), isNull);
    });

    test(
      'goldensForAgent returns only enabled goldens for that agent',
      () async {
        await putGolden('w-1', 'g-1', agentId: 'a-1', enabled: true);
        await putGolden('w-1', 'g-2', agentId: 'a-1', enabled: false);
        await putGolden('w-1', 'g-3', agentId: 'a-2', enabled: true);
        final rows = await db.evalsDao.goldensForAgent('w-1', 'a-1');
        expect(rows.map((g) => g.id), ['g-1']);
      },
    );

    test('goldensForAgent does not leak across workspaces', () async {
      await putGolden('w-1', 'g-1', agentId: 'a-1');
      await putGolden('w-2', 'g-2', agentId: 'a-1');
      final inOne = await db.evalsDao.goldensForAgent('w-1', 'a-1');
      final inTwo = await db.evalsDao.goldensForAgent('w-2', 'a-1');
      expect(inOne.single.id, 'g-1');
      expect(inTwo.single.id, 'g-2');
    });

    test('goldens orders newest-blessed-first within the workspace', () async {
      await db.evalsDao.upsertGolden(
        GoldenSessionsTableCompanion.insert(
          id: 'g-old',
          workspaceId: 'w-1',
          agentId: 'a-1',
          recordingId: 'r',
          blessedAt: Value(DateTime.utc(2024, 1, 1)),
        ),
      );
      await db.evalsDao.upsertGolden(
        GoldenSessionsTableCompanion.insert(
          id: 'g-new',
          workspaceId: 'w-1',
          agentId: 'a-1',
          recordingId: 'r',
          blessedAt: Value(DateTime.utc(2025, 1, 1)),
        ),
      );
      await db.evalsDao.upsertGolden(
        GoldenSessionsTableCompanion.insert(
          id: 'g-other-ws',
          workspaceId: 'w-2',
          agentId: 'a-1',
          recordingId: 'r',
          blessedAt: Value(DateTime.utc(2026, 1, 1)),
        ),
      );
      final rows = await db.evalsDao.goldens('w-1');
      expect(rows.map((g) => g.id), ['g-new', 'g-old']);
    });

    test(
      'watchGoldens emits only the workspace rows and updates live',
      () async {
        await putGolden('w-1', 'g-1');
        await putGolden('w-2', 'g-2');
        final snap = await db.evalsDao.watchGoldens('w-1').first;
        expect(snap.single.id, 'g-1');
      },
    );

    test('updateGoldenResult records the last status and scorecard', () async {
      await putGolden('w-1', 'g-1');
      await db.evalsDao.updateGoldenResult('w-1', 'g-1', 'pass', '{"p":1}');
      final row = await db.evalsDao.goldenById('w-1', 'g-1');
      expect(row!.lastStatus, 'pass');
      expect(row.lastScorecardJson, '{"p":1}');
    });

    test(
      'updateGoldenResult is workspace-scoped — foreign id is a no-op',
      () async {
        await putGolden('w-1', 'g-1');
        await db.evalsDao.updateGoldenResult('w-2', 'g-1', 'fail', null);
        final row = await db.evalsDao.goldenById('w-1', 'g-1');
        expect(row!.lastStatus, 'unknown'); // unchanged
        expect(row.lastScorecardJson, isNull);
      },
    );

    test('deleteGolden is scoped — foreign id deletes nothing', () async {
      await putGolden('w-1', 'g-1');
      await db.evalsDao.deleteGolden('w-2', 'g-1');
      expect(await db.evalsDao.goldenById('w-1', 'g-1'), isNotNull);
      await db.evalsDao.deleteGolden('w-1', 'g-1');
      expect(await db.evalsDao.goldenById('w-1', 'g-1'), isNull);
    });
  });

  group('EvalSuites workspace isolation', () {
    Future<void> putSuite(String ws, String id, {String name = 'suite'}) =>
        db.evalsDao.upsertSuite(
          EvalSuitesTableCompanion.insert(id: id, workspaceId: ws, name: name),
        );

    test('upsert + suiteById round-trips the row', () async {
      await putSuite('w-1', 's-1', name: 'regression');
      final row = await db.evalsDao.suiteById('w-1', 's-1');
      expect(row, isNotNull);
      expect(row!.name, 'regression');
    });

    test('suiteByName resolves within the workspace', () async {
      await putSuite('w-1', 's-1', name: 'regression');
      final row = await db.evalsDao.suiteByName('w-1', 'regression');
      expect(row, isNotNull);
      expect(row!.id, 's-1');
    });

    test(
      'suiteByName does not surface a suite from another workspace',
      () async {
        // Same name in two workspaces; the lookup is (ws, name)-scoped.
        await putSuite('w-1', 's-1', name: 'shared');
        await putSuite('w-2', 's-2', name: 'shared');
        expect((await db.evalsDao.suiteByName('w-1', 'shared'))!.id, 's-1');
        expect((await db.evalsDao.suiteByName('w-2', 'shared'))!.id, 's-2');
      },
    );

    test('suiteById does not surface a suite from another workspace', () async {
      await putSuite('w-1', 's-1');
      expect(await db.evalsDao.suiteById('w-2', 's-1'), isNull);
    });

    test('suites orders by name and stays scoped to the workspace', () async {
      await putSuite('w-1', 's-b', name: 'beta');
      await putSuite('w-1', 's-a', name: 'alpha');
      await putSuite('w-2', 's-c', name: 'alpha');
      final rows = await db.evalsDao.suites('w-1');
      expect(rows.map((s) => s.name), ['alpha', 'beta']);
    });

    test(
      'watchSuites emits only the workspace rows and updates live',
      () async {
        await putSuite('w-1', 's-1', name: 'alpha');
        await putSuite('w-2', 's-2', name: 'alpha');
        final snap = await db.evalsDao.watchSuites('w-1').first;
        expect(snap.single.id, 's-1');
      },
    );

    test('deleteSuite is scoped — foreign id deletes nothing', () async {
      await putSuite('w-1', 's-1');
      await db.evalsDao.deleteSuite('w-2', 's-1');
      expect(await db.evalsDao.suiteById('w-1', 's-1'), isNotNull);
      await db.evalsDao.deleteSuite('w-1', 's-1');
      expect(await db.evalsDao.suiteById('w-1', 's-1'), isNull);
    });
  });

  group('EvalRuns workspace isolation', () {
    Future<void> putRun(
      String ws,
      String id, {
      String suiteId = 's-1',
      String configHash = 'cfg',
      DateTime? createdAt,
      String status = 'queued',
    }) => db.evalsDao.upsertRun(
      EvalRunsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        suiteId: suiteId,
        configHash: configHash,
        status: Value(status),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );

    test('upsert + runById round-trips the row', () async {
      await putRun('w-1', 'run-1', status: 'running');
      final row = await db.evalsDao.runById('w-1', 'run-1');
      expect(row, isNotNull);
      expect(row!.status, 'running');
    });

    test('runById does not surface a run from another workspace', () async {
      await putRun('w-1', 'run-1');
      expect(await db.evalsDao.runById('w-2', 'run-1'), isNull);
    });

    test(
      'runsForSuite filters by suite within the workspace, newest-first',
      () async {
        final t0 = DateTime.utc(2024, 1, 1);
        final t1 = DateTime.utc(2024, 1, 2);
        await putRun('w-1', 'r-a', suiteId: 's-1', createdAt: t0);
        await putRun('w-1', 'r-b', suiteId: 's-1', createdAt: t1);
        await putRun('w-1', 'r-c', suiteId: 's-2', createdAt: t1);
        final rows = await db.evalsDao.runsForSuite('w-1', 's-1');
        expect(rows.map((r) => r.id), ['r-b', 'r-a']);
      },
    );

    test('runsForSuite does not leak across workspaces', () async {
      await putRun('w-1', 'r-1', suiteId: 's-shared');
      await putRun('w-2', 'r-2', suiteId: 's-shared');
      expect(
        (await db.evalsDao.runsForSuite('w-1', 's-shared')).single.id,
        'r-1',
      );
      expect(
        (await db.evalsDao.runsForSuite('w-2', 's-shared')).single.id,
        'r-2',
      );
    });

    test('watchRunsForSuite emits only the workspace rows', () async {
      await putRun('w-1', 'r-1', suiteId: 's-shared');
      await putRun('w-2', 'r-2', suiteId: 's-shared');
      final snap = await db.evalsDao.watchRunsForSuite('w-1', 's-shared').first;
      expect(snap.single.id, 'r-1');
    });

    test(
      'updateRunResult marks a run terminal and writes its scorecard',
      () async {
        await putRun('w-1', 'r-1');
        final started = DateTime.utc(2024, 1, 1);
        final finished = DateTime.utc(2024, 1, 2);
        await db.evalsDao.updateRunResult(
          'w-1',
          'r-1',
          status: 'done',
          scorecardJson: '{"p":0.5}',
          passRate: 0.5,
          costCents: 42,
          startedAt: started,
          finishedAt: finished,
        );
        final row = await db.evalsDao.runById('w-1', 'r-1');
        expect(row!.status, 'done');
        expect(row.scorecardJson, '{"p":0.5}');
        expect(row.passRate, 0.5);
        expect(row.costCents, 42);
        expect(row.startedAt!.toUtc(), started.toUtc());
        expect(row.finishedAt!.toUtc(), finished.toUtc());
      },
    );

    test(
      'updateRunResult with nulls leaves optional fields untouched',
      () async {
        await putRun('w-1', 'r-1');
        await db.evalsDao.upsertRun(
          EvalRunsTableCompanion.insert(
            id: 'r-1',
            workspaceId: 'w-1',
            suiteId: 's-1',
            configHash: 'cfg',
            scorecardJson: const Value('{"p":0.9}'),
            passRate: const Value(0.9),
            status: const Value('running'),
          ),
        );
        await db.evalsDao.updateRunResult('w-1', 'r-1', status: 'done');
        final row = await db.evalsDao.runById('w-1', 'r-1');
        expect(row!.status, 'done');
        // scorecard/passRate were not passed, so they keep their prior values.
        expect(row.scorecardJson, '{"p":0.9}');
        expect(row.passRate, 0.9);
      },
    );

    test(
      'updateRunResult is workspace-scoped — foreign id is a no-op',
      () async {
        await putRun('w-1', 'r-1');
        await db.evalsDao.updateRunResult('w-2', 'r-1', status: 'failed');
        expect((await db.evalsDao.runById('w-1', 'r-1'))!.status, 'queued');
      },
    );
  });

  group('AgentConfigVersions workspace isolation', () {
    Future<void> putVersion(
      String ws,
      String id, {
      String agentId = 'a-1',
      String configHash = 'h',
      String status = 'live',
    }) => db.evalsDao.upsertConfigVersion(
      AgentConfigVersionsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        agentId: agentId,
        configHash: configHash,
        status: Value(status),
      ),
    );

    test('upsert + configVersionByHash round-trips the row', () async {
      await putVersion('w-1', 'v-1', configHash: 'hash-a');
      final row = await db.evalsDao.configVersionByHash('w-1', 'a-1', 'hash-a');
      expect(row, isNotNull);
      expect(row!.id, 'v-1');
    });

    test(
      'configVersionByHash does not surface a row from another workspace',
      () async {
        // Same (agent, hash) in both workspaces; lookup is ws-scoped.
        await putVersion('w-1', 'v-1', configHash: 'shared-hash');
        await putVersion('w-2', 'v-2', configHash: 'shared-hash');
        expect(
          (await db.evalsDao.configVersionByHash(
            'w-1',
            'a-1',
            'shared-hash',
          ))!.id,
          'v-1',
        );
        expect(
          (await db.evalsDao.configVersionByHash(
            'w-2',
            'a-1',
            'shared-hash',
          ))!.id,
          'v-2',
        );
      },
    );

    test('liveConfigVersion returns the live version for the agent', () async {
      await putVersion('w-1', 'v-canary', configHash: 'h-c', status: 'canary');
      await putVersion('w-1', 'v-old', configHash: 'h-o', status: 'retired');
      await putVersion('w-1', 'v-live', configHash: 'h-l', status: 'live');
      final row = await db.evalsDao.liveConfigVersion('w-1', 'a-1');
      expect(row, isNotNull);
      expect(row!.id, 'v-live');
      expect(row.status, 'live');
    });

    test(
      'liveConfigVersion returns null when no live version exists',
      () async {
        await putVersion('w-1', 'v-1', status: 'canary');
        expect(await db.evalsDao.liveConfigVersion('w-1', 'a-1'), isNull);
      },
    );

    test(
      'liveConfigVersion does not surface a version from another workspace',
      () async {
        await putVersion('w-1', 'v-1', status: 'live');
        // w-2 has nothing live for the same agent.
        expect(await db.evalsDao.liveConfigVersion('w-2', 'a-1'), isNull);
      },
    );

    test('configVersionsForAgent lists all versions, newest-first', () async {
      await db.evalsDao.upsertConfigVersion(
        AgentConfigVersionsTableCompanion.insert(
          id: 'v-1',
          workspaceId: 'w-1',
          agentId: 'a-1',
          configHash: 'h-1',
          createdAt: Value(DateTime.utc(2024, 1, 1)),
        ),
      );
      await db.evalsDao.upsertConfigVersion(
        AgentConfigVersionsTableCompanion.insert(
          id: 'v-2',
          workspaceId: 'w-1',
          agentId: 'a-1',
          configHash: 'h-2',
          createdAt: Value(DateTime.utc(2024, 1, 2)),
        ),
      );
      await db.evalsDao.upsertConfigVersion(
        AgentConfigVersionsTableCompanion.insert(
          id: 'v-other-ws',
          workspaceId: 'w-2',
          agentId: 'a-1',
          configHash: 'h-3',
          createdAt: Value(DateTime.utc(2024, 1, 3)),
        ),
      );
      final rows = await db.evalsDao.configVersionsForAgent('w-1', 'a-1');
      expect(rows.map((v) => v.id), ['v-2', 'v-1']);
    });

    test(
      'setConfigVersionStatus promotes a version within the workspace',
      () async {
        await putVersion('w-1', 'v-1', status: 'canary');
        final promotedAt = DateTime.utc(2024, 6, 1);
        await db.evalsDao.setConfigVersionStatus(
          'w-1',
          'v-1',
          status: 'live',
          promotedBy: 'sam',
          promotedAt: promotedAt,
          scorecardJson: '{"ok":true}',
        );
        final row = await db.evalsDao.configVersionByHash('w-1', 'a-1', 'h');
        expect(row!.status, 'live');
        expect(row.promotedBy, 'sam');
        expect(row.promotedAt!.toUtc(), promotedAt.toUtc());
        expect(row.scorecardJson, '{"ok":true}');
      },
    );

    test('setConfigVersionStatus is scoped — foreign id is a no-op', () async {
      await putVersion('w-1', 'v-1', status: 'canary');
      await db.evalsDao.setConfigVersionStatus('w-2', 'v-1', status: 'live');
      final row = await db.evalsDao.configVersionByHash('w-1', 'a-1', 'h');
      expect(row!.status, 'canary');
    });
  });
}
