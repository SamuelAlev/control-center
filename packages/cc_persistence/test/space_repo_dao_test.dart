import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'r-1', name: 'o/r1', path: '/src/r1'),
        );
    await db
        .into(db.reposTable)
        .insert(
          ReposTableCompanion.insert(id: 'r-2', name: 'o/r2', path: '/src/r2'),
        );
    await db
        .into(db.spacesTable)
        .insert(SpacesTableCompanion.insert(id: 'ch-1', name: 'PR #1'));
  });

  tearDown(() async {
    await db.close();
  });

  group('SpaceRepoDao', () {
    test('records and returns a space repo selection in link order', () async {
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1', 'r-2'],
      );
      expect(
        await db.spaceRepoDao.repoIdsForSpace('w-1', 'ch-1'),
        equals(['r-1', 'r-2']),
      );
    });

    test(
      'an empty selection is a no-op (space stays on the all-repos default)',
      () async {
        await db.spaceRepoDao.setReposForSpace(
          workspaceId: 'w-1',
          spaceId: 'ch-1',
          repoIds: const [],
        );
        expect(await db.spaceRepoDao.repoIdsForSpace('w-1', 'ch-1'), isEmpty);
      },
    );

    test('setReposForSpace is idempotent per (space, repo)', () async {
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1'],
      );
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1', 'r-2'],
      );
      expect(
        await db.spaceRepoDao.repoIdsForSpace('w-1', 'ch-1'),
        equals(['r-1', 'r-2']),
      );
    });

    test('reads are scoped by workspaceId (no cross-workspace leak)', () async {
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1'],
      );
      // Same space id, foreign workspace → nothing surfaces.
      expect(await db.spaceRepoDao.repoIdsForSpace('w-2', 'ch-1'), isEmpty);
    });

    test('a repo can pin the branch its worktree is cut from', () async {
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1', 'r-2'],
        branches: const {'r-1': 'release/1.2'},
      );

      // The selection is unchanged — a pinned repo is still just a repo.
      expect(
        await db.spaceRepoDao.repoIdsForSpace('w-1', 'ch-1'),
        equals(['r-1', 'r-2']),
      );
      // Only the pinned one appears: an unpinned repo takes its own default
      // branch, and an entry saying so would be a second way to mean nothing.
      expect(await db.spaceRepoDao.repoBranchesForSpace('w-1', 'ch-1'), {
        'r-1': 'release/1.2',
      });
    });

    test('branch reads are workspace-scoped too', () async {
      await db.spaceRepoDao.setReposForSpace(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        repoIds: ['r-1'],
        branches: const {'r-1': 'release/1.2'},
      );
      expect(
        await db.spaceRepoDao.repoBranchesForSpace('w-2', 'ch-1'),
        isEmpty,
      );
    });
  });
}
