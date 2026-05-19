import 'package:cc_persistence/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('PullRequestDao', () {
    test('insert and get PR', () async {
      const wsId = 'ws-pr1';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: wsId,
          name: 'PR Test',
        ),
      );

      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-1',
          workspaceId: wsId,
          title: 'Fix login bug',
          body: 'Fixes #42',
        ),
      );

      final pr = await db.pullRequestDao.getById('pr-1');
      expect(pr, isNotNull);
      expect(pr!.title, 'Fix login bug');
      expect(pr.body, 'Fixes #42');
      expect(pr.status, 'draft');
      expect(pr.createdAt, isNotNull);
    });

    test('watchByWorkspace returns PRs', () async {
      const wsId = 'ws-pr2';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: wsId,
          name: 'PR Watch Test',
        ),
      );

      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-a',
          workspaceId: wsId,
          title: 'First',
          body: 'a',
        ),
      );

      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-b',
          workspaceId: wsId,
          title: 'Second',
          body: 'b',
        ),
      );

      final prs = await db.pullRequestDao.watchByWorkspace(wsId).first;
      expect(prs.length, 2);
      final titles = prs.map((p) => p.title).toSet();
      expect(titles, {'First', 'Second'});
    });

    test('watchByWorkspace returns empty for unknown workspace', () async {
      final prs = await db.pullRequestDao.watchByWorkspace('nonexistent').first;
      expect(prs, isEmpty);
    });

    test('getById returns null for unknown id', () async {
      final pr = await db.pullRequestDao.getById('nonexistent');
      expect(pr, isNull);
    });

    test('deleteById removes PR', () async {
      const wsId = 'ws-pr3';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: wsId,
          name: 'PR Delete',
        ),
      );

      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-del',
          workspaceId: wsId,
          title: 'To delete',
          body: 'x',
        ),
      );

      await db.pullRequestDao.deleteById('pr-del');
      final pr = await db.pullRequestDao.getById('pr-del');
      expect(pr, isNull);
    });
  });

  group('ReviewDraftDao', () {
    test('upsertDraft and getDraft', () async {
      await db.reviewDao.upsertDraft('samuel', 'control-center', 42, 'LGTM');

      final draft = await db.reviewDao.getDraft('samuel', 'control-center', 42);
      expect(draft, 'LGTM');
    });

    test('getDraft returns null for unknown PR', () async {
      final draft = await db.reviewDao.getDraft('unknown', 'repo', 1);
      expect(draft, isNull);
    });

    test('upsertDraft overwrites existing draft', () async {
      await db.reviewDao.upsertDraft(
        'samuel',
        'control-center',
        42,
        'First draft',
      );
      await db.reviewDao.upsertDraft(
        'samuel',
        'control-center',
        42,
        'Updated draft',
      );

      final draft = await db.reviewDao.getDraft('samuel', 'control-center', 42);
      expect(draft, 'Updated draft');
    });

    test('clearDraft removes draft', () async {
      await db.reviewDao.upsertDraft(
        'samuel',
        'control-center',
        42,
        'To clear',
      );

      await db.reviewDao.clearDraft('samuel', 'control-center', 42);
      final draft = await db.reviewDao.getDraft('samuel', 'control-center', 42);
      expect(draft, isNull);
    });

    test('clearDraft is no-op on nonexistent draft', () async {
      await db.reviewDao.clearDraft('nobody', 'norepo', 99);
      final draft = await db.reviewDao.getDraft('nobody', 'norepo', 99);
      expect(draft, isNull);
    });
  });

  group('CacheDao', () {
    test('put and read', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', '{"title":"Hello"}');

      final payload = await db.cacheDao.read('ws-1', 'prDetail', '42');
      expect(payload, '{"title":"Hello"}');
    });

    test('read returns null for unknown entry', () async {
      final payload = await db.cacheDao.read('ws-1', 'prDetail', '99');
      expect(payload, isNull);
    });

    test('put overwrites existing entry', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'old');
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'new');

      final payload = await db.cacheDao.read('ws-1', 'prDetail', '42');
      expect(payload, 'new');
    });

    test('deleteEntry removes single entry', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'payload');
      await db.cacheDao.deleteEntry('ws-1', 'prDetail', '42');

      final payload = await db.cacheDao.read('ws-1', 'prDetail', '42');
      expect(payload, isNull);
    });

    test('deleteEntry is no-op on nonexistent entry', () async {
      await db.cacheDao.deleteEntry('ws-1', 'nope', '0');

      final payload = await db.cacheDao.read('ws-1', 'nope', '0');
      expect(payload, isNull);
    });

    test('deleteKind removes all entries of a kind', () async {
      await db.cacheDao.put('ws-1', 'prDetail', '42', 'a');
      await db.cacheDao.put('ws-1', 'prDetail', '43', 'b');
      await db.cacheDao.put('ws-1', 'prFiles', '42', 'c');

      await db.cacheDao.deleteKind('ws-1', 'prDetail');

      expect(await db.cacheDao.read('ws-1', 'prDetail', '42'), isNull);
      expect(await db.cacheDao.read('ws-1', 'prDetail', '43'), isNull);
      expect(await db.cacheDao.read('ws-1', 'prFiles', '42'), 'c');
    });

    test('deleteKindWithPrefix removes entries matching prefix', () async {
      await db.cacheDao.put('ws-1', 'prDetail', 'pr:42', 'a');
      await db.cacheDao.put('ws-1', 'prDetail', 'pr:43', 'b');
      await db.cacheDao.put('ws-1', 'prDetail', 'other', 'c');
      await db.cacheDao.put('ws-1', 'prFiles', 'pr:42', 'd');

      await db.cacheDao.deleteKindWithPrefix('ws-1', 'prDetail', 'pr:');

      expect(await db.cacheDao.read('ws-1', 'prDetail', 'pr:42'), isNull);
      expect(await db.cacheDao.read('ws-1', 'prDetail', 'pr:43'), isNull);
      expect(await db.cacheDao.read('ws-1', 'prDetail', 'other'), 'c');
      expect(await db.cacheDao.read('ws-1', 'prFiles', 'pr:42'), 'd');
    });

    test('deleteKindWithPrefix is no-op when no keys match', () async {
      await db.cacheDao.put('ws-1', 'prDetail', 'abc', 'payload');

      await db.cacheDao.deleteKindWithPrefix('ws-1', 'prDetail', 'xyz');

      expect(await db.cacheDao.read('ws-1', 'prDetail', 'abc'), 'payload');
    });
  });
}
