import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('PullRequestDao - insert and getById', () {
    test('insert and read a pull request', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-1',
          workspaceId: 'ws-pr',
          title: 'Add feature X',
          body: 'This implements feature X',
        ),
      );

      final pr = await db.pullRequestDao.getById('pr-1');
      expect(pr, isNotNull);
      expect(pr!.id, 'pr-1');
      expect(pr.title, 'Add feature X');
      expect(pr.body, 'This implements feature X');
      expect(pr.status, 'draft');
      expect(pr.prUrl, isNull);
      expect(pr.prNumber, isNull);
    });

    test('getById returns null for nonexistent PR', () async {
      final pr = await db.pullRequestDao.getById('nonexistent');
      expect(pr, isNull);
    });

    test('insert with all optional fields', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-full',
          workspaceId: 'ws-pr',
          title: 'Full PR',
          body: 'Full body',
          prUrl: const Value('https://github.com/acme/repo/pull/1'),
          prNumber: const Value(1),
          status: const Value('created'),
          diffSummary: const Value('+10/-5'),
        ),
      );

      final pr = await db.pullRequestDao.getById('pr-full');
      expect(pr!.prUrl, 'https://github.com/acme/repo/pull/1');
      expect(pr.prNumber, 1);
      expect(pr.status, 'created');
      expect(pr.diffSummary, '+10/-5');
    });
  });

  group('PullRequestDao - updatePr', () {
    test('updates existing PR fields', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-update',
          workspaceId: 'ws-pr',
          title: 'Original',
          body: 'Original body',
        ),
      );

      final affected = await db.pullRequestDao.updatePr(
        'pr-update',
        const PullRequestsTableCompanion(
          title: Value('Updated'),
          body: Value('Updated body'),
          status: Value('created'),
          prUrl: Value('https://github.com/acme/repo/pull/5'),
          prNumber: Value(5),
        ),
      );

      expect(affected, 1);
      final pr = await db.pullRequestDao.getById('pr-update');
      expect(pr!.title, 'Updated');
      expect(pr.body, 'Updated body');
      expect(pr.status, 'created');
      expect(pr.prNumber, 5);
    });

    test('updatePr on nonexistent PR returns 0', () async {
      final affected = await db.pullRequestDao.updatePr(
        'nonexistent',
        const PullRequestsTableCompanion(
          title: Value('Unset'),
          body: Value('Unset body'),
        ),
      );
      expect(affected, 0);
    });

    test('partial update preserves other fields', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-partial',
          workspaceId: 'ws-pr',
          title: 'Original',
          body: 'Original body',
          status: const Value('draft'),
        ),
      );

      await db.pullRequestDao.updatePr(
        'pr-partial',
        const PullRequestsTableCompanion(status: Value('created')),
      );

      final pr = await db.pullRequestDao.getById('pr-partial');
      expect(pr!.title, 'Original');
      expect(pr.status, 'created');
    });
  });

  group('PullRequestDao - deleteById', () {
    test('deletes a PR', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-del',
          workspaceId: 'ws-pr',
          title: 'To Delete',
          body: 'Delete me',
        ),
      );

      await db.pullRequestDao.deleteById('pr-del');
      final pr = await db.pullRequestDao.getById('pr-del');
      expect(pr, isNull);
    });

    test('deleteById returns 0 for nonexistent PR', () async {
      final affected = await db.pullRequestDao.deleteById('nonexistent');
      expect(affected, 0);
    });
  });

  group('PullRequestDao - watchByWorkspace', () {
    test('returns all PRs for workspace', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-one',
          workspaceId: 'ws-pr',
          title: 'First PR',
          body: 'First',
        ),
      );
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-two',
          workspaceId: 'ws-pr',
          title: 'Second PR',
          body: 'Second',
        ),
      );

      final prs = await db.pullRequestDao.watchByWorkspace('ws-pr').first;
      expect(prs.length, 2);
      final prIds = prs.map((p) => p.id).toSet();
      expect(prIds, contains('pr-one'));
      expect(prIds, contains('pr-two'));
    });

    test('returns empty list for workspace with no PRs', () async {
      final prs = await db.pullRequestDao.watchByWorkspace('no-prs').first;
      expect(prs, isEmpty);
    });

    test('returns only PRs for specific workspace', () async {
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-ws1',
          workspaceId: 'ws-pr',
          title: 'WS1 PR',
          body: 'WS1',
        ),
      );
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-ws2',
          workspaceId: 'ws-other',
          title: 'WS2 PR',
          body: 'WS2',
        ),
      );

      final ws1Prs = await db.pullRequestDao.watchByWorkspace('ws-pr').first;
      expect(ws1Prs.length, 1);
      expect(ws1Prs[0].id, 'pr-ws1');
    });
  });

  group('PullRequestDao - workspace soft-delete', () {
    // The registry row (global.db) and the PR row (the workspace's own file) are
    // in two different databases now, so this group needs both halves.
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;

    setUp(() async {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, 'ws-cascade', name: 'Cascade');
    });

    tearDown(() async {
      await dbs.closeAll();
      await global.close();
    });

    test('PR still exists after workspace soft-delete', () async {
      await dbs
          .of('ws-cascade')
          .pullRequestDao
          .insert(
            PullRequestsTableCompanion.insert(
              id: 'pr-cascade',
              workspaceId: 'ws-cascade',
              title: 'To Cascade',
              body: 'Body',
            ),
          );

      await global.workspaceRegistryDao.deleteWorkspace('ws-cascade');

      // Soft-delete flags the registry row only; the workspace's database file
      // is untouched, so its rows survive and a restore is lossless.
      expect(await global.workspaceRegistryDao.getById('ws-cascade'), isNull);
      final pr = await dbs
          .of('ws-cascade')
          .pullRequestDao
          .getById('pr-cascade');
      expect(pr, isNotNull);
    });
  });
}
