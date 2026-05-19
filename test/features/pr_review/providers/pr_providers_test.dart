import 'package:cc_persistence/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/features/pr_review/providers/pr_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_database.dart';

void main() {
  group('pullRequestsProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when no PRs exist', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider('ws-empty'), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final prs = container.read(pullRequestsProvider('ws-empty')).value;
      expect(prs, isEmpty);
    });

    test('returns pull requests for a workspace', () async {
      const wsId = 'ws-pr';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: wsId, name: 'PR WS'),
      );
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-1',
          workspaceId: wsId,
          title: 'Add feature',
          body: 'Body',
        ),
      );

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider(wsId), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final prs = container.read(pullRequestsProvider(wsId)).value;
      expect(prs?.length, 1);
      expect(prs?.first.id, 'pr-1');
    });

    test('returns only PRs for the specified workspace', () async {
      const wsId1 = 'ws-pr-1';
      const wsId2 = 'ws-pr-2';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: wsId1, name: 'PR WS 1'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: wsId2, name: 'PR WS 2'),
      );
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-a',
          workspaceId: wsId1,
          title: 'PR A',
          body: 'Body A',
        ),
      );
      await db.pullRequestDao.insert(
        PullRequestsTableCompanion.insert(
          id: 'pr-b',
          workspaceId: wsId2,
          title: 'PR B',
          body: 'Body B',
        ),
      );

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider(wsId1), (_, _) {});
      container.listen(pullRequestsProvider(wsId2), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final p1 = container.read(pullRequestsProvider(wsId1)).value;
      final p2 = container.read(pullRequestsProvider(wsId2)).value;
      expect(p1?.length, 1);
      expect(p1?.first.title, 'PR A');
      expect(p2?.length, 1);
      expect(p2?.first.title, 'PR B');
    });
  });
}
