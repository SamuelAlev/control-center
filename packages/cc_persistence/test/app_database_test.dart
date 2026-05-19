import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  group('WorkspaceDatabase.forTesting', () {
    test('creates an in-memory database', () {
      final db = createTestDatabase();
      expect(db, isA<WorkspaceDatabase>());
      db.close();
    });

    test('reports the version the code says it is', () {
      final db = createTestDatabase();
      addTearDown(db.close);
      // The baseline `onCreate` builds the CURRENT shape; `_migrationSteps`
      // carries every bump on top of it for databases that already exist.
      // Pinning the constant rather than a literal keeps the two in lockstep
      // without this test needing an edit per bump.
      expect(db.schemaVersion, WorkspaceDatabase.currentSchemaVersion);
    });

    test('onCreate builds the hot-path composite indexes', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND "
            "name IN ('idx_conversation_messages_space_created', "
            "'idx_agent_run_logs_ws_agent_started')",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names, contains('idx_conversation_messages_space_created'));
      expect(names, contains('idx_agent_run_logs_ws_agent_started'));
    });

    test('baseline onCreate builds the meetings tables', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      // The meetings tables are part of the v1 baseline (createAll) — the whole
      // point of the squash is that a fresh workspace file gets the current
      // schema in one step.
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name IN ('meetings','meeting_transcript_segments',"
            "'meeting_action_items','meeting_decisions')",
          )
          .get();
      expect(tables.map((r) => r.read<String>('name')).toSet(), {
        'meetings',
        'meeting_transcript_segments',
        'meeting_action_items',
        'meeting_decisions',
      });
      await db.close();
    });

    test('migration strategy exists and has onCreate', () {
      final db = createTestDatabase();
      expect(db.migration.onCreate, isNotNull);
      expect(db.migration.onUpgrade, isNotNull);
      expect(db.migration.beforeOpen, isNotNull);
      db.close();
    });

    test('baseline onCreate builds the partial indexes folded in from the '
        'squashed migrations', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      // Force onCreate by touching the schema.
      await db.customStatement('SELECT 1');
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = indexes.map((r) => r.read<String>('name')).toSet();
      // These two indexes are partial (carry a WHERE clause), so they cannot be
      // declared as `@TableIndex` and were historically created only inside
      // migrations. The squash must reproduce them in onCreate.
      expect(names, contains('uq_pipeline_runs_active_dedup'));
      expect(names, contains('uq_tickets_provider_externalKey'));
    });

    test('baseline onCreate builds the FTS5 contentless indexes', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('memory_facts_fts', 'code_symbols_fts')",
          )
          .get();
      final names = tables.map((r) => r.read<String>('name')).toSet();
      expect(names, containsAll(['memory_facts_fts', 'code_symbols_fts']));
    });

    test('the workspace-half DAOs are accessible', () {
      final db = createTestDatabase();
      expect(db.repoDao, isNotNull);
      expect(db.agentDao, isNotNull);
      expect(db.pullRequestDao, isNotNull);
      expect(db.reviewDao, isNotNull);
      expect(db.cacheDao, isNotNull);
      expect(db.messagingDao, isNotNull);
      db.close();
    });

    test('the workspace file knows which workspace it is', () {
      final db = createTestDatabase(workspaceId: 'ws-42');
      expect(db.workspaceId, 'ws-42');
      db.close();
    });

    test('all tables are defined', () {
      final db = createTestDatabase();
      expect(db.allTables, isNotEmpty);
      expect(db.allTables.length, greaterThanOrEqualTo(15));
      db.close();
    });

    test('can be closed without error', () async {
      final db = createTestDatabase();
      await db.close();
    });

    test('can be closed multiple times', () async {
      final db = createTestDatabase();
      await db.close();
      await db.close();
    });

    test('messagingDao watchSpaces works', () async {
      final db = createTestDatabase();
      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces, isEmpty);
      await db.close();
    });

    test('agentDao watchAllLogs returns empty', () async {
      final db = createTestDatabase();
      final logs = await db.agentDao.watchAllLogs().first;
      expect(logs, isEmpty);
      await db.close();
    });

    test('repoDao watchAll returns empty', () async {
      final db = createTestDatabase();
      final repos = await db.repoDao.watchAll().first;
      expect(repos, isEmpty);
      await db.close();
    });

    test('pullRequestDao watchByWorkspace returns empty', () async {
      final db = createTestDatabase();
      final prs = await db.pullRequestDao.watchByWorkspace('nonexistent').first;
      expect(prs, isEmpty);
      await db.close();
    });

    test('reviewDao upsertDraft and getDraft', () async {
      final db = createTestDatabase();
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'LGTM');
      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, 'LGTM');
      await db.close();
    });

    test('reviewSpaceDao watchByWorkspace returns empty', () async {
      final db = createTestDatabase();
      final assocs = await db.reviewSpaceDao
          .watchByWorkspace('nonexistent')
          .first;
      expect(assocs, isEmpty);
      await db.close();
    });

    test('migration strategy has expected structure', () {
      final db = createTestDatabase();
      final migration = db.migration;
      expect(migration, isNotNull);
      expect(migration.onCreate, isNotNull);
      expect(migration.onUpgrade, isNotNull);
      db.close();
    });

    test('agentDao watchActiveAgents returns empty', () async {
      final db = createTestDatabase();
      final agents = await db.agentDao.watchAll().first;
      expect(agents, isEmpty);
      await db.close();
    });

    test('messagingDao insert space', () async {
      final db = createTestDatabase();
      await db.messagingDao.insertSpace(
        SpacesTableCompanion.insert(id: 'ch-1', name: 'General'),
      );
      final spaces = await db.messagingDao.watchSpaces().first;
      expect(spaces.length, 1);
      expect(spaces.first.name, 'General');
      await db.close();
    });
  });

  // The server-global half: the workspace registry, identity, the newsfeed and
  // the fleet queue. It is a separate drift database with its own schema and its
  // own migration chain (see `global_migration_test.dart`).
  group('GlobalDatabase.forTesting', () {
    test('creates an in-memory database at the current schema version', () {
      final db = createTestGlobalDatabase();
      expect(db, isA<GlobalDatabase>());
      // Pinned as a floor, not an equality: a schema change bumps this and the
      // step that comes with it is what earns its own migration test. Asserting
      // the exact number here only ever means editing two files at once.
      expect(db.schemaVersion, greaterThanOrEqualTo(2));
      db.close();
    });

    test('migration strategy exists and has onCreate', () {
      final db = createTestGlobalDatabase();
      expect(db.migration.onCreate, isNotNull);
      expect(db.migration.onUpgrade, isNotNull);
      expect(db.migration.beforeOpen, isNotNull);
      db.close();
    });

    test('the global-half DAOs are accessible', () {
      final db = createTestGlobalDatabase();
      expect(db.workspaceRegistryDao, isNotNull);
      expect(db.userDao, isNotNull);
      expect(db.userPreferenceDao, isNotNull);
      expect(db.pairedDeviceDao, isNotNull);
      expect(db.rssDao, isNotNull);
      expect(db.fleetDao, isNotNull);
      expect(db.workspaceRouteDao, isNotNull);
      db.close();
    });

    test('workspaceRegistryDao watchAll returns empty', () async {
      final db = createTestGlobalDatabase();
      final workspaces = await db.workspaceRegistryDao.watchAll().first;
      expect(workspaces, isEmpty);
      await db.close();
    });

    test('rssDao watchFeeds returns empty', () async {
      final db = createTestGlobalDatabase();
      final feeds = await db.rssDao.watchFeeds('user-1').first;
      expect(feeds, isEmpty);
      await db.close();
    });

    test('rssDao watchAllArticles returns empty', () async {
      final db = createTestGlobalDatabase();
      final articles = await db.rssDao.watchAllArticles('user-1').first;
      expect(articles, isEmpty);
      await db.close();
    });

    test('rssDao watchSavedArticles returns empty', () async {
      final db = createTestGlobalDatabase();
      final saved = await db.rssDao.watchSavedArticles('user-1').first;
      expect(saved, isEmpty);
      await db.close();
    });

    test('rssDao getEnabledFeeds returns empty', () async {
      final db = createTestGlobalDatabase();
      final feeds = await db.rssDao.getEnabledFeeds('user-1');
      expect(feeds, isEmpty);
      await db.close();
    });

    test('rssDao getFeedByUrl returns null for unknown', () async {
      final db = createTestGlobalDatabase();
      final feed = await db.rssDao.getFeedByUrl(
        'user-1',
        'https://example.com/rss',
      );
      expect(feed, isNull);
      await db.close();
    });

    test('rssDao getArticleById returns null for unknown', () async {
      final db = createTestGlobalDatabase();
      final article = await db.rssDao.getArticleById('user-1', 'nonexistent');
      expect(article, isNull);
      await db.close();
    });
  });

  group('MigrationStep', () {
    test('creates with from, to and migrate function', () {
      final step = MigrationStep(10, 11, (Migrator m) async {});
      expect(step.from, 10);
      expect(step.to, 11);
      expect(step.migrate, isNotNull);
    });

    test('from is less than to for normal migrations', () {
      final step = MigrationStep(5, 10, (Migrator m) async {});
      expect(step.from, lessThan(step.to));
    });

    test('consecutive steps chain correctly', () {
      final step1 = MigrationStep(8, 9, (Migrator m) async {});
      final step2 = MigrationStep(9, 10, (Migrator m) async {});
      expect(step1.to, equals(step2.from));
    });
  });
}
