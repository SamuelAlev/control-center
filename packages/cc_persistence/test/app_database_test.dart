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

    test('schema version is 13', () {
      final db = createTestDatabase();
      addTearDown(db.close);
      // v1 was the squashed split baseline; v2 adds the audit trail's
      // `user_activity.ip` / `country_code` columns. v4 adds the chat
      // bridge's link tables (no v3 step — see workspace_baseline_schema_test).
      // v5 adds the workspace settings KV; v6 adds the notification feed +
      // per-user read marks; v7 gives repos a forge and drops the vendor from
      // the GitHub-named identity columns. v8 adds the enclosure (rig)
      // session table and its attributed action log. v9 adds the browser
      // rig's `current_url` — the address bar's pushed half. v10 adds the
      // Review Hub's deterministic `review_cohorts.insights_json`; v11 the
      // per-PR dependency lockfile diffs; v12 the finalized review-pass
      // snapshots that make a manual re-review delta-aware.
      expect(db.schemaVersion, 13);
    });

    test('onCreate builds the hot-path composite indexes', () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' AND "
            "name IN ('idx_channel_messages_channel_created', "
            "'idx_agent_run_logs_ws_agent_started')",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(names, contains('idx_channel_messages_channel_created'));
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
            "AND name IN ('meetings_table','meeting_transcript_segments_table',"
            "'meeting_action_items_table','meeting_decisions_table')",
          )
          .get();
      expect(tables.map((r) => r.read<String>('name')).toSet(), {
        'meetings_table',
        'meeting_transcript_segments_table',
        'meeting_action_items_table',
        'meeting_decisions_table',
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

    test('messagingDao watchChannels works', () async {
      final db = createTestDatabase();
      final channels = await db.messagingDao.watchChannels().first;
      expect(channels, isEmpty);
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

    test('reviewChannelDao watchByWorkspace returns empty', () async {
      final db = createTestDatabase();
      final assocs = await db.reviewChannelDao
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

    test('messagingDao insert channel', () async {
      final db = createTestDatabase();
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(id: 'ch-1', name: 'General'),
      );
      final channels = await db.messagingDao.watchChannels().first;
      expect(channels.length, 1);
      expect(channels.first.name, 'General');
      await db.close();
    });
  });

  // The server-global half: the workspace registry, identity, the newsfeed and
  // the fleet queue. It is a separate drift database with its own schema and its
  // own (currently empty) migration chain.
  group('GlobalDatabase.forTesting', () {
    test('creates an in-memory database at schema version 5', () {
      final db = createTestGlobalDatabase();
      expect(db, isA<GlobalDatabase>());
      // v5 adds the workspace's opt-in `auto_publish_review` flag.
      expect(db.schemaVersion, 5);
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
