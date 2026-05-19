import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // Seed workspaces; the Review Studio tables reference only workspace_id
    // (repo_id / pr_external_id are plain text with no FK — they mirror the code
    // graph), so no other FK-referenced rows are required.
  });

  tearDown(() async {
    await db.close();
  });

  // ── Cohorts ──

  ReviewCohortsTableCompanion cohort(
    String id,
    String ws,
    String pr,
    String key,
    String title, {
    Value<int> orderIndex = const Value.absent(),
  }) => ReviewCohortsTableCompanion.insert(
    id: id,
    workspaceId: ws,
    prExternalId: pr,
    cohortKey: key,
    title: title,
    orderIndex: orderIndex,
  );

  group('ReviewStudioDao cohorts', () {
    test(
      'replaceCohortsForPr + cohortsForPr round-trips, in reading order',
      () async {
        await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
          cohort(
            'c-2',
            'w-1',
            'pr-1',
            'k-b',
            'Backend',
            orderIndex: const Value(1),
          ),
          cohort(
            'c-1',
            'w-1',
            'pr-1',
            'k-a',
            'Frontend',
            orderIndex: const Value(0),
          ),
        ]);
        final rows = await db.reviewStudioDao.cohortsForPr('w-1', 'pr-1');
        expect(rows.map((r) => r.title), ['Frontend', 'Backend']);
        expect(rows.map((r) => r.cohortKey), ['k-a', 'k-b']);
      },
    );

    test('replaceCohortsForPr atomically replaces the whole set', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', 'k-a', 'Old'),
      ]);
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-2', 'w-1', 'pr-1', 'k-b', 'New 1'),
        cohort('c-3', 'w-1', 'pr-1', 'k-c', 'New 2'),
      ]);
      final rows = await db.reviewStudioDao.cohortsForPr('w-1', 'pr-1');
      expect(rows.map((r) => r.id), ['c-2', 'c-3']);
    });

    test('replaceCohortsForPr with an empty list clears the set', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', 'k-a', 'X'),
      ]);
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', const []);
      expect(await db.reviewStudioDao.cohortsForPr('w-1', 'pr-1'), isEmpty);
    });

    test('cohorts are workspace-isolated', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', 'k-a', 'W1'),
      ]);
      // Same pr node id, different workspace: must not surface.
      expect(await db.reviewStudioDao.cohortsForPr('w-2', 'pr-1'), isEmpty);
    });

    test('cohorts are PR-isolated within a workspace', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', 'k-a', 'PR1'),
      ]);
      expect(await db.reviewStudioDao.cohortsForPr('w-1', 'pr-2'), isEmpty);
    });

    test('watchCohortsForPr streams the current cohort set', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort(
          'c-1',
          'w-1',
          'pr-1',
          'k-a',
          'Stream',
          orderIndex: const Value(0),
        ),
      ]);
      final rows = await db.reviewStudioDao
          .watchCohortsForPr('w-1', 'pr-1')
          .first;
      expect(rows.map((r) => r.title), ['Stream']);
    });

    test(
      'updateCohortSummary writes back markdown scoped by workspace',
      () async {
        await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
          cohort('c-1', 'w-1', 'pr-1', 'k-a', 'T'),
        ]);
        await db.reviewStudioDao.updateCohortSummary(
          'w-1',
          'c-1',
          '## Summary',
        );
        final row = (await db.reviewStudioDao.cohortsForPr(
          'w-1',
          'pr-1',
        )).single;
        expect(row.summaryMarkdown, '## Summary');
      },
    );

    test(
      'updateCohortSummary is workspace-scoped — foreign ws is a no-op',
      () async {
        await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
          cohort('c-1', 'w-1', 'pr-1', 'k-a', 'T'),
        ]);
        // Writing from w-2 against a w-1 cohort id touches nothing.
        await db.reviewStudioDao.updateCohortSummary('w-2', 'c-1', 'evil');
        final row = (await db.reviewStudioDao.cohortsForPr(
          'w-1',
          'pr-1',
        )).single;
        expect(row.summaryMarkdown, '');
      },
    );

    test('updateCohortDiagrams writes back JSON scoped by workspace', () async {
      await db.reviewStudioDao.replaceCohortsForPr('w-1', 'pr-1', [
        cohort('c-1', 'w-1', 'pr-1', 'k-a', 'T'),
      ]);
      await db.reviewStudioDao.updateCohortDiagrams(
        'w-1',
        'c-1',
        '{"diagram":1}',
      );
      final row = (await db.reviewStudioDao.cohortsForPr('w-1', 'pr-1')).single;
      expect(row.diagramsJson, '{"diagram":1}');
    });
  });

  // ── API contract snapshots ──

  ApiContractSnapshotsTableCompanion contract(
    String id,
    String ws,
    String pr,
    String path, {
    String repoId = 'repo-1',
  }) => ApiContractSnapshotsTableCompanion.insert(
    id: id,
    workspaceId: ws,
    repoId: repoId,
    prExternalId: pr,
    specPath: path,
  );

  group('ReviewStudioDao apiContractSnapshots', () {
    test(
      'upsert + contractSnapshotsForPr round-trips, ordered by specPath',
      () async {
        await db.reviewStudioDao.upsertContractSnapshot(
          contract('s-1', 'w-1', 'pr-1', 'openapi/z.yaml'),
        );
        await db.reviewStudioDao.upsertContractSnapshot(
          contract('s-2', 'w-1', 'pr-1', 'openapi/a.yaml'),
        );
        final rows = await db.reviewStudioDao.contractSnapshotsForPr(
          'w-1',
          'pr-1',
        );
        expect(rows.map((r) => r.specPath), [
          'openapi/a.yaml',
          'openapi/z.yaml',
        ]);
      },
    );

    test('upsert is idempotent on id (PK conflict replaces the row)', () async {
      await db.reviewStudioDao.upsertContractSnapshot(
        ApiContractSnapshotsTableCompanion.insert(
          id: 's-1',
          workspaceId: 'w-1',
          repoId: 'repo-1',
          prExternalId: 'pr-1',
          specPath: 'openapi/a.yaml',
          beforeJson: const Value('{}'),
        ),
      );
      await db.reviewStudioDao.upsertContractSnapshot(
        ApiContractSnapshotsTableCompanion.insert(
          id: 's-1',
          workspaceId: 'w-1',
          repoId: 'repo-1',
          prExternalId: 'pr-1',
          specPath: 'openapi/b.yaml',
          beforeJson: const Value('{"v":2}'),
        ),
      );
      final rows = await db.reviewStudioDao.contractSnapshotsForPr(
        'w-1',
        'pr-1',
      );
      expect(rows, hasLength(1));
      expect(rows.single.specPath, 'openapi/b.yaml');
      expect(rows.single.beforeJson, '{"v":2}');
    });

    test('contract snapshots are workspace-isolated', () async {
      await db.reviewStudioDao.upsertContractSnapshot(
        contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
      );
      expect(
        await db.reviewStudioDao.contractSnapshotsForPr('w-2', 'pr-1'),
        isEmpty,
      );
    });

    test(
      'watchContractSnapshotsForPr streams the current snapshot set',
      () async {
        await db.reviewStudioDao.upsertContractSnapshot(
          contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
        );
        final rows = await db.reviewStudioDao
            .watchContractSnapshotsForPr('w-1', 'pr-1')
            .first;
        expect(rows.map((r) => r.id), ['s-1']);
      },
    );

    test('contractSnapshotById hits within the owning workspace', () async {
      await db.reviewStudioDao.upsertContractSnapshot(
        contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
      );
      final row = await db.reviewStudioDao.contractSnapshotById('w-1', 's-1');
      expect(row?.specPath, 'openapi/a.yaml');
    });

    test('contractSnapshotById returns null in a foreign workspace', () async {
      await db.reviewStudioDao.upsertContractSnapshot(
        contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
      );
      expect(
        await db.reviewStudioDao.contractSnapshotById('w-2', 's-1'),
        isNull,
      );
    });

    test(
      'updateContractChanges writes back JSON scoped by workspace',
      () async {
        await db.reviewStudioDao.upsertContractSnapshot(
          contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
        );
        await db.reviewStudioDao.updateContractChanges(
          'w-1',
          's-1',
          '[{"breaking":true}]',
        );
        final row = await db.reviewStudioDao.contractSnapshotById('w-1', 's-1');
        expect(row?.changesJson, '[{"breaking":true}]');
      },
    );

    test('updateContractChanges from a foreign workspace is a no-op', () async {
      await db.reviewStudioDao.upsertContractSnapshot(
        contract('s-1', 'w-1', 'pr-1', 'openapi/a.yaml'),
      );
      await db.reviewStudioDao.updateContractChanges(
        'w-2',
        's-1',
        '[{"evil":true}]',
      );
      final row = await db.reviewStudioDao.contractSnapshotById('w-1', 's-1');
      expect(row?.changesJson, '[]'); // default, untouched
    });
  });

  // ── Visual diff snapshots ──

  VisualDiffSnapshotsTableCompanion visual(
    String id,
    String ws,
    String pr,
    String componentKey, {
    String repoId = 'repo-1',
  }) => VisualDiffSnapshotsTableCompanion.insert(
    id: id,
    workspaceId: ws,
    repoId: repoId,
    prExternalId: pr,
    componentKey: componentKey,
  );

  group('ReviewStudioDao visualDiffSnapshots', () {
    test(
      'upsert + visualSnapshotsForPr round-trips, ordered by componentKey',
      () async {
        await db.reviewStudioDao.upsertVisualSnapshot(
          visual('v-1', 'w-1', 'pr-1', 'Button'),
        );
        await db.reviewStudioDao.upsertVisualSnapshot(
          visual('v-2', 'w-1', 'pr-1', 'AppBar'),
        );
        final rows = await db.reviewStudioDao.visualSnapshotsForPr(
          'w-1',
          'pr-1',
        );
        expect(rows.map((r) => r.componentKey), ['AppBar', 'Button']);
      },
    );

    test('visual snapshots are workspace-isolated', () async {
      await db.reviewStudioDao.upsertVisualSnapshot(
        visual('v-1', 'w-1', 'pr-1', 'Button'),
      );
      expect(
        await db.reviewStudioDao.visualSnapshotsForPr('w-2', 'pr-1'),
        isEmpty,
      );
    });

    test(
      'watchVisualSnapshotsForPr streams the current snapshot set',
      () async {
        await db.reviewStudioDao.upsertVisualSnapshot(
          visual('v-1', 'w-1', 'pr-1', 'Button'),
        );
        final rows = await db.reviewStudioDao
            .watchVisualSnapshotsForPr('w-1', 'pr-1')
            .first;
        expect(rows.map((r) => r.id), ['v-1']);
      },
    );

    test('updateVisualStatus writes back status scoped by workspace', () async {
      await db.reviewStudioDao.upsertVisualSnapshot(
        visual('v-1', 'w-1', 'pr-1', 'Button'),
      );
      await db.reviewStudioDao.updateVisualStatus('w-1', 'v-1', 'approved');
      final rows = await db.reviewStudioDao.visualSnapshotsForPr('w-1', 'pr-1');
      expect(rows.single.status, 'approved');
    });

    test('updateVisualStatus from a foreign workspace is a no-op', () async {
      await db.reviewStudioDao.upsertVisualSnapshot(
        visual('v-1', 'w-1', 'pr-1', 'Button'),
      );
      await db.reviewStudioDao.updateVisualStatus('w-2', 'v-1', 'evil');
      final rows = await db.reviewStudioDao.visualSnapshotsForPr('w-1', 'pr-1');
      expect(rows.single.status, 'changed'); // default, untouched
    });
  });

  // ── Axis results ──

  ReviewAxisResultsTableCompanion axis(
    String id,
    String ws,
    String pr,
    String axisName,
    String verdict, {
    Value<int> findingsCount = const Value.absent(),
    Value<bool> gated = const Value.absent(),
  }) => ReviewAxisResultsTableCompanion.insert(
    id: id,
    workspaceId: ws,
    prExternalId: pr,
    axis: axisName,
    verdict: verdict,
    findingsCount: findingsCount,
    gated: gated,
  );

  group('ReviewStudioDao reviewAxisResults', () {
    test(
      'upsert + axisResultsForPr round-trips, ordered by axis name',
      () async {
        await db.reviewStudioDao.upsertAxisResult(
          axis('a-1', 'w-1', 'pr-1', 'visual', 'pass'),
        );
        await db.reviewStudioDao.upsertAxisResult(
          axis(
            'a-2',
            'w-1',
            'pr-1',
            'correctness',
            'fail',
            findingsCount: const Value(3),
            gated: const Value(true),
          ),
        );
        final rows = await db.reviewStudioDao.axisResultsForPr('w-1', 'pr-1');
        expect(rows.map((r) => r.axis), ['correctness', 'visual']);
        final correctness = rows.firstWhere((r) => r.axis == 'correctness');
        expect(correctness.verdict, 'fail');
        expect(correctness.findingsCount, 3);
        expect(correctness.gated, isTrue);
      },
    );

    test('upsert is idempotent on id (PK conflict replaces the row)', () async {
      await db.reviewStudioDao.upsertAxisResult(
        axis('a-1', 'w-1', 'pr-1', 'security', 'pass'),
      );
      await db.reviewStudioDao.upsertAxisResult(
        axis('a-1', 'w-1', 'pr-1', 'security', 'fail'),
      );
      final rows = await db.reviewStudioDao.axisResultsForPr('w-1', 'pr-1');
      expect(rows, hasLength(1));
      expect(rows.single.verdict, 'fail');
    });

    test('axis results are workspace-isolated', () async {
      await db.reviewStudioDao.upsertAxisResult(
        axis('a-1', 'w-1', 'pr-1', 'visual', 'pass'),
      );
      expect(await db.reviewStudioDao.axisResultsForPr('w-2', 'pr-1'), isEmpty);
    });

    test('watchAxisResultsForPr streams the current axis set', () async {
      await db.reviewStudioDao.upsertAxisResult(
        axis('a-1', 'w-1', 'pr-1', 'visual', 'pass'),
      );
      final rows = await db.reviewStudioDao
          .watchAxisResultsForPr('w-1', 'pr-1')
          .first;
      expect(rows.map((r) => r.id), ['a-1']);
    });
  });
}
