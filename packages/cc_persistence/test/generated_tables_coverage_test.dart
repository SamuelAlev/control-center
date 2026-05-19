import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Drives the generated table code (the bulk of `workspace_database.g.dart` and
/// `global_database.g.dart`) for the large review-studio, eval and fleet table
/// families into coverage. Each table's companion factory, `TableData` factory,
/// and row mapper run when a row is inserted and read back. These tables back
/// DAOs that are already unit-tested at the DAO level; this test exercises the
/// generated companion/data/mapper code paths that those DAO tests reach
/// indirectly.
///
/// Review-studio and eval tables live in the per-workspace database; the fleet
/// tables (workers/jobs/placement log) are server-global, so that group opens the
/// global half instead.
void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async => db.close());

  group('Review-studio generated tables', () {
    test('review cohorts round-trip', () async {
      await db
          .into(db.reviewCohortsTable)
          .insert(
            ReviewCohortsTableCompanion.insert(
              id: 'rc-1',
              workspaceId: 'ws',
              prExternalId: 'PR_1',
              cohortKey: 'auth',
              title: 'Auth changes',
              summaryMarkdown: const Value('# Auth'),
              filePathsJson: const Value('["lib/auth.dart"]'),
              derivation: const Value('graph'),
            ),
          );
      final rows = await (db.select(
        db.reviewCohortsTable,
      )..where((t) => t.id.equals('rc-1'))).get();
      expect(rows, hasLength(1));
      expect(rows.first.title, 'Auth changes');
      expect(rows.first.cohortKey, 'auth');
    });

    test('api contract snapshots round-trip', () async {
      await db
          .into(db.apiContractSnapshotsTable)
          .insert(
            ApiContractSnapshotsTableCompanion.insert(
              id: 'acs-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              prExternalId: 'PR_1',
              specPath: 'openapi.yaml',
              changesJson: const Value('[]'),
            ),
          );
      final row = await (db.select(
        db.apiContractSnapshotsTable,
      )..where((t) => t.id.equals('acs-1'))).getSingle();
      expect(row.specPath, 'openapi.yaml');
      expect(row.repoId, 'repo-1');
    });

    test('visual diff snapshots round-trip', () async {
      await db
          .into(db.visualDiffSnapshotsTable)
          .insert(
            VisualDiffSnapshotsTableCompanion.insert(
              id: 'vds-1',
              workspaceId: 'ws',
              repoId: 'repo-1',
              prExternalId: 'PR_1',
              componentKey: 'LoginScreen',
              componentTitle: const Value('Login'),
              variantsJson: const Value('[]'),
            ),
          );
      final row = await (db.select(
        db.visualDiffSnapshotsTable,
      )..where((t) => t.id.equals('vds-1'))).getSingle();
      expect(row.componentKey, 'LoginScreen');
      expect(row.componentTitle, 'Login');
    });

    test('review axis results round-trip', () async {
      await db
          .into(db.reviewAxisResultsTable)
          .insert(
            ReviewAxisResultsTableCompanion.insert(
              id: 'rar-1',
              workspaceId: 'ws',
              prExternalId: 'PR_1',
              axis: 'security',
              verdict: 'pass',
              note: const Value('clean'),
            ),
          );
      final row = await (db.select(
        db.reviewAxisResultsTable,
      )..where((t) => t.id.equals('rar-1'))).getSingle();
      expect(row.axis, 'security');
      expect(row.verdict, 'pass');
    });
  });

  group('Eval generated tables', () {
    test('eval suites round-trip', () async {
      await db
          .into(db.evalSuitesTable)
          .insert(
            EvalSuitesTableCompanion.insert(
              id: 'es-1',
              workspaceId: 'ws',
              name: 'core-suite',
              description: const Value('core'),
              taskJson: const Value('{}'),
              gradersJson: const Value('[]'),
            ),
          );
      final row = await (db.select(
        db.evalSuitesTable,
      )..where((t) => t.id.equals('es-1'))).getSingle();
      expect(row.name, 'core-suite');
    });

    test('eval runs round-trip', () async {
      await db
          .into(db.evalRunsTable)
          .insert(
            EvalRunsTableCompanion.insert(
              id: 'er-1',
              workspaceId: 'ws',
              suiteId: 'es-1',
              configHash: 'deadbeef',
              batchSize: const Value(3),
              status: const Value('queued'),
            ),
          );
      final row = await (db.select(
        db.evalRunsTable,
      )..where((t) => t.id.equals('er-1'))).getSingle();
      expect(row.suiteId, 'es-1');
      expect(row.configHash, 'deadbeef');
    });

    test('agent config versions round-trip', () async {
      await db
          .into(db.agentConfigVersionsTable)
          .insert(
            AgentConfigVersionsTableCompanion.insert(
              id: 'acv-1',
              workspaceId: 'ws',
              agentId: 'a-1',
              configHash: 'cafebabe',
              configJson: const Value('{}'),
              status: const Value('live'),
            ),
          );
      final row = await (db.select(
        db.agentConfigVersionsTable,
      )..where((t) => t.id.equals('acv-1'))).getSingle();
      expect(row.agentId, 'a-1');
      expect(row.status, 'live');
    });

    test('session recordings round-trip', () async {
      await db
          .into(db.sessionRecordingsTable)
          .insert(
            SessionRecordingsTableCompanion.insert(
              id: 'sr-1',
              workspaceId: 'ws',
              runLogId: 'rl-1',
              configHash: 'feedface',
              title: const Value('A run'),
            ),
          );
      final row = await (db.select(
        db.sessionRecordingsTable,
      )..where((t) => t.id.equals('sr-1'))).getSingle();
      expect(row.runLogId, 'rl-1');
      expect(row.title, 'A run');
    });

    test('golden sessions round-trip', () async {
      await db
          .into(db.goldenSessionsTable)
          .insert(
            GoldenSessionsTableCompanion.insert(
              id: 'gs-1',
              workspaceId: 'ws',
              agentId: 'a-1',
              recordingId: 'sr-1',
              name: const Value('golden'),
            ),
          );
      final row = await (db.select(
        db.goldenSessionsTable,
      )..where((t) => t.id.equals('gs-1'))).getSingle();
      expect(row.agentId, 'a-1');
      expect(row.recordingId, 'sr-1');
    });
  });

  group('Fleet generated tables', () {
    // The fleet scheduler scans the whole queue against every worker, so these
    // three tables are server-global rather than per-workspace.
    late GlobalDatabase global;

    setUp(() {
      global = createTestGlobalDatabase();
    });

    tearDown(() async => global.close());

    test('workers round-trip', () async {
      await global
          .into(global.workersTable)
          .insert(
            WorkersTableCompanion.insert(
              id: 'wk-1',
              name: 'mac-studio',
              platform: const Value('macos'),
            ),
          );
      final row = await (global.select(
        global.workersTable,
      )..where((t) => t.id.equals('wk-1'))).getSingle();
      expect(row.name, 'mac-studio');
      expect(row.platform, 'macos');
    });

    test('jobs round-trip', () async {
      await global
          .into(global.jobsTable)
          .insert(
            JobsTableCompanion.insert(
              id: 'job-1',
              workspaceId: 'ws',
              kind: 'agentRun',
              specJson: const Value('{}'),
              status: const Value('queued'),
            ),
          );
      final row = await (global.select(
        global.jobsTable,
      )..where((t) => t.id.equals('job-1'))).getSingle();
      expect(row.kind, 'agentRun');
      expect(row.workspaceId, 'ws');
    });

    test('placement log round-trip', () async {
      await global
          .into(global.placementLogTable)
          .insert(
            PlacementLogTableCompanion.insert(
              id: 'pl-1',
              workspaceId: 'ws',
              jobId: 'job-1',
              decision: const Value('queued'),
              reason: const Value('no worker yet'),
            ),
          );
      final row = await (global.select(
        global.placementLogTable,
      )..where((t) => t.id.equals('pl-1'))).getSingle();
      expect(row.jobId, 'job-1');
      expect(row.reason, 'no worker yet');
    });
  });
}
