import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/migration_steps.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase.forTesting', () {
    test('creates an in-memory database', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db, isA<AppDatabase>());
      db.close();
    });

    test('schema version is 27', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 31);
      db.close();
    });

    test('migration strategy exists and has onCreate', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.migration.onCreate, isNotNull);
      expect(db.migration.onUpgrade, isNotNull);
      expect(db.migration.beforeOpen, isNotNull);
      db.close();
    });

    test('all DAOs are accessible', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.workspaceDao, isNotNull);
      expect(db.repoDao, isNotNull);
      expect(db.agentDao, isNotNull);
      expect(db.pullRequestDao, isNotNull);
      expect(db.reviewDao, isNotNull);
      expect(db.cacheDao, isNotNull);
      expect(db.messagingDao, isNotNull);
      expect(db.rssDao, isNotNull);
      db.close();
    });

    test('all tables are defined', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.allTables, isNotEmpty);
      expect(db.allTables.length, greaterThanOrEqualTo(15));
      db.close();
    });

    test('can be closed without error', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.close();
    });

    test('can be closed multiple times', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.close();
      await db.close();
    });

    test('messagingDao watchChannels works', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final channels = await db.messagingDao.watchChannels().first;
      expect(channels, isEmpty);
      await db.close();
    });

    test('agentDao watchAllLogs returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final logs = await db.agentDao.watchAllLogs().first;
      expect(logs, isEmpty);
      await db.close();
    });

    test('rssDao watchFeeds returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final feeds = await db.rssDao.watchFeeds().first;
      expect(feeds, isEmpty);
      await db.close();
    });

    test('rssDao watchAllArticles returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final articles = await db.rssDao.watchAllArticles().first;
      expect(articles, isEmpty);
      await db.close();
    });

    test('rssDao watchSavedArticles returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final saved = await db.rssDao.watchSavedArticles().first;
      expect(saved, isEmpty);
      await db.close();
    });

    test('workspaceDao watchAll returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final workspaces = await db.workspaceDao.watchAll().first;
      expect(workspaces, isEmpty);
      await db.close();
    });

    test('repoDao watchAll returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repos = await db.repoDao.watchAll().first;
      expect(repos, isEmpty);
      await db.close();
    });

    test('pullRequestDao watchByWorkspace returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prs = await db.pullRequestDao.watchByWorkspace('nonexistent').first;
      expect(prs, isEmpty);
      await db.close();
    });

    test('reviewDao upsertDraft and getDraft', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'LGTM');
      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, 'LGTM');
      await db.close();
    });

    test('reviewChannelDao watchByWorkspace returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final assocs = await db.reviewChannelDao
          .watchByWorkspace('nonexistent')
          .first;
      expect(assocs, isEmpty);
      await db.close();
    });

    test('rssDao getEnabledFeeds returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final feeds = await db.rssDao.getEnabledFeeds();
      expect(feeds, isEmpty);
      await db.close();
    });

    test('rssDao getFeedByUrl returns null for unknown', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final feed = await db.rssDao.getFeedByUrl('https://example.com/rss');
      expect(feed, isNull);
      await db.close();
    });

    test('rssDao getArticleById returns null for unknown', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final article = await db.rssDao.getArticleById('nonexistent');
      expect(article, isNull);
      await db.close();
    });

    test('migration strategy has expected structure', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final migration = db.migration;
      expect(migration, isNotNull);
      expect(migration.onCreate, isNotNull);
      expect(migration.onUpgrade, isNotNull);
      db.close();
    });

    test('agentDao watchActiveAgents returns empty', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final agents = await db.agentDao.watchAll().first;
      expect(agents, isEmpty);
      await db.close();
    });

    test('messagingDao insert channel', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.messagingDao.insertChannel(
        ChannelsTableCompanion.insert(id: 'ch-1', name: 'General'),
      );
      final channels = await db.messagingDao.watchChannels().first;
      expect(channels.length, 1);
      expect(channels.first.data.name, 'General');
      await db.close();
    });
  });

  group('MigrationStep', () {
    test('creates with from, to, and migrate function', () {
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
