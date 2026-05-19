import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: 'ws-pr',
        name: 'PR Test',
      ),
    );
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
      expect(pr.githubPrUrl, isNull);
      expect(pr.githubPrNumber, isNull);
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
          githubPrUrl: const Value('https://github.com/acme/repo/pull/1'),
          githubPrNumber: const Value(1),
          status: const Value('created'),
          diffSummary: const Value('+10/-5'),
        ),
      );

      final pr = await db.pullRequestDao.getById('pr-full');
      expect(pr!.githubPrUrl, 'https://github.com/acme/repo/pull/1');
      expect(pr.githubPrNumber, 1);
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
          githubPrUrl: Value('https://github.com/acme/repo/pull/5'),
          githubPrNumber: Value(5),
        ),
      );

      expect(affected, 1);
      final pr = await db.pullRequestDao.getById('pr-update');
      expect(pr!.title, 'Updated');
      expect(pr.body, 'Updated body');
      expect(pr.status, 'created');
      expect(pr.githubPrNumber, 5);
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
        const PullRequestsTableCompanion(
          status: Value('created'),
        ),
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
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-other',
          name: 'Other',
        ),
      );

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

  group('PullRequestDao - cascade delete', () {
    test('PR still exists after workspace soft-delete', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-cascade',
          name: 'Cascade',
        ),
      );

      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-cascade',
          workspaceId: 'ws-cascade',
          title: 'To Cascade',
          body: 'Body',
        ),
      );

      await db.workspaceDao.deleteWorkspace('ws-cascade');

      // Soft-delete does not cascade to child records.
      final pr = await db.pullRequestDao.getById('pr-cascade');
      expect(pr, isNotNull);
    });
  });
}
