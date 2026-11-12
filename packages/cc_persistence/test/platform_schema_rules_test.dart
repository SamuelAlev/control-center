import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/imported_authority_hold_dao.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:test/test.dart';

import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

/// The rules the repository, membership and server-global tables state in
/// their schema: natural keys written as one upsert on that key, closed sets
/// and foreign keys that refuse what the code would never write.
void main() {
  final refused = throwsA(isA<SqliteException>());

  group('workspace file', () {
    late WorkspaceDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('a repo written again by path keeps its id and place', () async {
      final first = await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'r-1', name: 'old', path: '/src/a'),
      );
      final again = await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'r-2', name: 'new', path: '/src/a'),
      );

      expect(again.id, 'r-1');
      expect(again.name, 'new');
      expect(again.position, first.position);
      expect(await db.select(db.reposTable).get(), hasLength(1));
    });

    test('a member written again keeps their row and join time', () async {
      final joined = DateTime(2026);
      await db.workspaceMemberDao.upsert(
        WorkspaceMembersTableCompanion.insert(
          id: 'm-1',
          workspaceId: db.workspaceId,
          userId: 'u-1',
          role: const Value('member'),
          joinedAt: Value(joined),
        ),
      );
      await db.workspaceMemberDao.upsert(
        WorkspaceMembersTableCompanion.insert(
          id: 'm-2',
          workspaceId: db.workspaceId,
          userId: 'u-1',
          role: const Value('admin'),
          joinedAt: Value(DateTime(2027)),
        ),
      );

      final row = (await db.select(db.workspaceMembersTable).get()).single;
      expect(row.id, 'm-1');
      expect(row.role, 'admin');
      expect(row.joinedAt, joined);
    });

    test('a repo grant written again is one row per user and repo', () async {
      await seedRepo(db, 'r-1');
      for (final (id, level) in [('g-1', 'read'), ('g-2', 'write')]) {
        await db.workspaceMemberDao.upsertRepoGrant(
          WorkspaceMemberRepoGrantsTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            userId: 'u-1',
            repoId: 'r-1',
            level: Value(level),
          ),
        );
      }

      final row =
          (await db.select(db.workspaceMemberRepoGrantsTable).get()).single;
      expect(row.id, 'g-1');
      expect(row.level, 'write');
    });

    test('a role named like another is refused, not swapped in', () async {
      WorkspaceRolesTableCompanion role(String id) =>
          WorkspaceRolesTableCompanion.insert(
            id: id,
            workspaceId: db.workspaceId,
            name: 'Reviewers',
            basePreset: 'member',
          );
      await db.workspaceRoleDao.upsert(role('role-1'));

      await expectLater(db.workspaceRoleDao.upsert(role('role-2')), refused);
      expect(
        (await db.select(db.workspaceRolesTable).get()).single.id,
        'role-1',
      );
    });

    test('a member role is a preset or a custom role, nothing else', () async {
      Future<void> member(String id, String role) =>
          db.workspaceMemberDao.upsert(
            WorkspaceMembersTableCompanion.insert(
              id: id,
              workspaceId: db.workspaceId,
              userId: id,
              role: Value(role),
            ),
          );
      await member('u-1', 'owner');
      await member('u-2', 'custom:role-1');

      await expectLater(member('u-3', 'superuser'), refused);
      await expectLater(member('u-4', 'custom:'), refused);
    });

    test('a held grant keeps its row as a JSON object', () async {
      final holds = ImportedAuthorityHoldDao(db);
      ImportedAuthorityHoldsTableCompanion hold(String id, String payload) =>
          ImportedAuthorityHoldsTableCompanion.insert(
            id: id,
            kind: 'repo_grant',
            payloadJson: payload,
            importedAt: DateTime(2026),
            sourceInstallId: 'install-1',
          );
      await holds.insert(hold('h-1', '{"user_id":"u-1"}'));

      await expectLater(holds.insert(hold('h-2', '["u-1"]')), refused);
      await expectLater(holds.insert(hold('h-3', '{"user_id":')), refused);
      expect((await holds.all()).single.id, 'h-1');
    });
  });

  group('global database', () {
    late GlobalDatabase global;

    setUp(() async {
      global = createTestGlobalDatabase();
      await seedUser(global, 'u-1');
      await seedWorkspaceRow(global, 'ws-1');
    });
    tearDown(() => global.close());

    test('a route names a declared kind and a registered workspace', () async {
      await global.workspaceRouteDao.put(
        WorkspaceRouteKind.pipelineRun,
        'run-1',
        'ws-1',
      );

      await expectLater(
        global.customStatement(
          'INSERT INTO workspace_routes (kind, key_hash, workspace_id) '
          "VALUES ('mystery', 'k', 'ws-1')",
        ),
        refused,
      );
      await expectLater(
        global.workspaceRouteDao.put(
          WorkspaceRouteKind.pipelineRun,
          'run-2',
          'ws-unknown',
        ),
        refused,
      );
    });

    test('a device and a job carry only declared states', () async {
      await expectLater(
        global.customStatement(
          'INSERT INTO paired_devices (id, user_id, label, psk_ref, status) '
          "VALUES ('d-1', 'u-1', 'Phone', 'file', 'trusted')",
        ),
        refused,
      );
      await expectLater(
        global.customStatement(
          'INSERT INTO jobs (id, workspace_id, kind, status) '
          "VALUES ('j-1', 'ws-1', 'agentRun', 'paused')",
        ),
        refused,
      );
    });

    test('a device goes with its user, and outlives its landing '
        'workspace', () async {
      await global.customStatement(
        'INSERT INTO paired_devices '
        '(id, user_id, landing_workspace_id, label, psk_ref) '
        "VALUES ('d-1', 'u-1', 'ws-1', 'Phone', 'file')",
      );

      await global.customStatement("DELETE FROM workspaces WHERE id = 'ws-1'");
      final device = (await global.pairedDeviceDao.getById('d-1'))!;
      expect(device.landingWorkspaceId, isNull);

      await global.customStatement("DELETE FROM users WHERE id = 'u-1'");
      expect(await global.pairedDeviceDao.getById('d-1'), isNull);
    });

    test('a user who owns a workspace cannot be deleted', () async {
      await global.customStatement(
        "UPDATE workspaces SET owner_user_id = 'u-1' WHERE id = 'ws-1'",
      );

      await expectLater(
        global.customStatement("DELETE FROM users WHERE id = 'u-1'"),
        refused,
      );
    });

    test('a managed rule is one per subject, written in place', () async {
      ManagedActionPoliciesTableCompanion rule(String id, String decision) =>
          ManagedActionPoliciesTableCompanion.insert(
            id: id,
            commandPrefix: const Value('git push'),
            decision: Value(decision),
          );
      await global.managedActionPolicyDao.upsert(rule('p-1', 'prompt'));
      await global.managedActionPolicyDao.upsert(rule('p-2', 'deny'));

      final row = (await global.managedActionPolicyDao.all()).single;
      expect(row.id, 'p-1');
      expect(row.decision, 'deny');

      // A rule names exactly one subject.
      await expectLater(
        global.managedActionPolicyDao.upsert(
          ManagedActionPoliciesTableCompanion.insert(id: 'p-3'),
        ),
        refused,
      );
    });

    test('following a feed twice is the same feed', () async {
      RssFeedsTableCompanion feed(String id, String name) =>
          RssFeedsTableCompanion.insert(
            id: id,
            userId: 'u-1',
            name: name,
            url: 'https://example.com/feed.xml',
          );
      final added = await global.rssDao.addFeed(feed('f-1', 'First'));
      final again = await global.rssDao.addFeed(feed('f-2', 'Second'));
      expect(again.id, added.id);
      expect(again.name, 'First');

      await global.rssDao.upsertFeed(feed('f-3', 'Renamed'));
      final row = (await global.select(global.rssFeedsTable).get()).single;
      expect(row.id, 'f-1');
      expect(row.name, 'Renamed');
    });

    test('a refreshed article keeps its id and the reader state', () async {
      await seedRssFeed(global, 'f-1', userId: 'u-1');
      RssArticlesTableCompanion article(String id, String title) =>
          RssArticlesTableCompanion.insert(
            id: id,
            feedId: 'f-1',
            guid: 'guid-1',
            title: title,
            link: 'https://example.com/1',
          );
      await global.rssDao.upsertArticleFromFeed(article('a-1', 'Draft'));
      await global.customUpdate(
        "UPDATE rss_articles SET saved = 1, read = 1 WHERE id = 'a-1'",
        variables: const <Variable<Object>>[],
      );
      await global.rssDao.upsertArticleFromFeed(article('a-2', 'Final'));

      final row = (await global.select(global.rssArticlesTable).get()).single;
      expect(row.id, 'a-1');
      expect(row.title, 'Final');
      expect(row.saved, isTrue);
      expect(row.read, isTrue);
    });
  });
}
