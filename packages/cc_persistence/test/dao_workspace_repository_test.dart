import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// [DaoWorkspaceRepository] is the one repository that straddles both halves of
/// the split database: the workspace *registry* lives in `global.db` (so the
/// switcher can list workspaces without opening any of them) while a
/// workspace's repos live inside that workspace's own file.
///
/// Two consequences shape this file:
///
/// * `upsert` also materialises the workspace's database and `delete`
///   soft-deletes the registry row and drops the file — so these tests let the
///   repository register its own workspaces instead of pre-seeding them.
/// * "linking" a repo to a workspace is no longer a join-table row. There is no
///   `workspace_repos` and no `linkRepoToWorkspace`; a repo is in a workspace
///   because its row lives in that workspace's file. Adding one means upserting
///   into `dbs.of(workspaceId).repoDao`.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWorkspaceRepository repository;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    repository = DaoWorkspaceRepository(global.workspaceRegistryDao, dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Workspace makeWorkspace({
    String id = 'ws-1',
    String name = 'Test Workspace',
  }) {
    return Workspace(
      id: id,
      name: name,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );
  }

  /// Registers a repo INTO [workspaceId]'s own database — the replacement for
  /// the deleted `linkRepoToWorkspace`.
  Future<void> addRepo(
    String workspaceId,
    String repoId, {
    String name = 'Repo',
    String path = '/path/repo',
  }) {
    return dbs
        .of(workspaceId)
        .repoDao
        .upsertRepo(
          ReposTableCompanion.insert(
            id: repoId,
            name: name,
            path: path,
            remoteOwner: const Value('acme'),
            remoteName: const Value('project'),
          ),
        );
  }

  group('DaoWorkspaceRepository', () {
    test('upsert and watchAll', () async {
      final ws = makeWorkspace();
      final id = await repository.upsert(ws);
      expect(id, 'ws-1');

      final workspaces = await repository.watchAll().first;
      expect(workspaces.length, 1);
      expect(workspaces.first.id, 'ws-1');
      expect(workspaces.first.name, 'Test Workspace');
    });

    test('upsert materialises the workspace database', () async {
      await repository.upsert(makeWorkspace());

      // `upsert` calls `WorkspaceDatabaseManager.create`, so the schema exists
      // before any reader touches it — the repos table is queryable immediately.
      expect(dbs.openIds, contains('ws-1'));
      expect(await dbs.of('ws-1').repoDao.getAll(), isEmpty);
    });

    test('upsert overwrites existing workspace', () async {
      await repository.upsert(makeWorkspace(name: 'Original'));
      await repository.upsert(makeWorkspace(name: 'Updated'));

      final workspaces = await repository.watchAll().first;
      expect(workspaces.first.name, 'Updated');
    });

    test('watchAll returns empty when no workspaces', () async {
      final workspaces = await repository.watchAll().first;
      expect(workspaces, isEmpty);
    });

    test('getById returns the workspace, null after delete', () async {
      await repository.upsert(makeWorkspace());
      expect((await repository.getById('ws-1'))!.name, 'Test Workspace');

      await repository.delete('ws-1');
      expect(await repository.getById('ws-1'), isNull);
      expect(await repository.getById('never-existed'), isNull);
    });

    /// `delete` soft-deletes the registry row and drops the workspace's file.
    /// The registry row is what the assertion can see — the manager hands out
    /// in-memory executors here, so there is no file to unlink and
    /// `dropAndClose` is a no-op on that half.
    test('delete soft-deletes the registry row', () async {
      await repository.upsert(makeWorkspace());
      await repository.delete('ws-1');

      final workspaces = await repository.watchAll().first;
      expect(workspaces, isEmpty);

      // Soft-deleted, not gone: the row survives (its file still needs
      // sweeping/backing up), it is only hidden from the live lists.
      expect(await global.workspaceRegistryDao.allIdsIncludingDeleted(), [
        'ws-1',
      ]);
    });

    test('delete closes the workspace database', () async {
      await repository.upsert(makeWorkspace());
      expect(dbs.openIds, contains('ws-1'));

      await repository.delete('ws-1');
      expect(dbs.openIds, isNot(contains('ws-1')));
    });

    test('delete nonexistent does not throw', () async {
      await repository.delete('nonexistent');
    });

    test('upsert with logo', () async {
      final ws = Workspace(
        id: 'ws-full',
        name: 'Full WS',
        logoPath: '/path/logo.png',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 5, 18),
      );
      await repository.upsert(ws);

      final fetched = (await repository.watchAll().first).firstWhere(
        (w) => w.id == 'ws-full',
      );
      expect(fetched.logoPath, '/path/logo.png');
    });
  });

  group('DaoWorkspaceRepository repos', () {
    /// The successor to the old `linkRepoToWorkspace` + `watchReposForWorkspace`
    /// pair: a repo is "linked" by having its row in the workspace's own file.
    test('a repo registered in a workspace is watched back', () async {
      await repository.upsert(makeWorkspace());
      await addRepo('ws-1', 'repo-1', name: 'Repo 1');

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-1');
      expect(repos.first.name, 'Repo 1');
    });

    test('isRepoLinkedToWorkspace is the isolation gate', () async {
      await repository.upsert(makeWorkspace());
      await addRepo('ws-1', 'repo-1');

      expect(
        await repository.isRepoLinkedToWorkspace('ws-1', 'repo-1'),
        isTrue,
      );
      expect(
        await repository.isRepoLinkedToWorkspace('ws-1', 'repo-absent'),
        isFalse,
      );
    });

    test('unlinkRepoFromWorkspace removes the repo', () async {
      await repository.upsert(makeWorkspace());
      await addRepo('ws-1', 'repo-1');

      await repository.unlinkRepoFromWorkspace('ws-1', 'repo-1');

      expect(await repository.watchReposForWorkspace('ws-1').first, isEmpty);
      expect(
        await repository.isRepoLinkedToWorkspace('ws-1', 'repo-1'),
        isFalse,
      );
    });

    test('unlinking a repo the workspace does not own is a no-op', () async {
      await repository.upsert(makeWorkspace());
      await addRepo('ws-1', 'repo-1');

      await repository.unlinkRepoFromWorkspace('ws-1', 'repo-absent');

      expect(
        await repository.watchReposForWorkspace('ws-1').first,
        hasLength(1),
      );
    });

    /// `setReposForWorkspace` is now purely the drag-to-reorder write path: it
    /// re-sequences the repos the workspace already owns. It cannot add a repo
    /// (ids are per-workspace, so a repo can't be conjured from an id) and it
    /// does not remove the ones left out of the list.
    test('setReposForWorkspace re-sequences the workspace repos', () async {
      await repository.upsert(makeWorkspace());
      await addRepo('ws-1', 'repo-a', name: 'A', path: '/a');
      await addRepo('ws-1', 'repo-b', name: 'B', path: '/b');
      await addRepo('ws-1', 'repo-c', name: 'C', path: '/c');

      await repository.setReposForWorkspace('ws-1', [
        'repo-c',
        'repo-a',
        'repo-b',
      ]);

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos.map((r) => r.id), ['repo-c', 'repo-a', 'repo-b']);
    });

    test(
      'setReposForWorkspace ignores ids the workspace does not own',
      () async {
        await repository.upsert(makeWorkspace());
        await addRepo('ws-1', 'repo-a', name: 'A', path: '/a');

        await repository.setReposForWorkspace('ws-1', ['ghost', 'repo-a']);

        final repos = await repository.watchReposForWorkspace('ws-1').first;
        expect(repos.map((r) => r.id), ['repo-a']);
      },
    );

    test(
      'watchReposForWorkspace returns empty for workspace with no repos',
      () async {
        await repository.upsert(makeWorkspace());

        final repos = await repository.watchReposForWorkspace('ws-1').first;
        expect(repos, isEmpty);
      },
    );

    /// The isolation invariant, re-proved one layer lower. Before the split a
    /// repo was global and workspace membership was a join row, so this asserted
    /// that a `WHERE workspace_id = ?` was present. Now the repo row lives in
    /// its workspace's own database file, so it asserts that the repository
    /// ROUTES to the right file — a leak would need the wrong file to be opened,
    /// not a forgotten predicate.
    test(
      'a repo added to workspace A is not visible from workspace B',
      () async {
        await repository.upsert(makeWorkspace(id: 'ws-a', name: 'A'));
        await repository.upsert(makeWorkspace(id: 'ws-b', name: 'B'));

        await addRepo('ws-a', 'repo-a', name: 'Only in A', path: '/a');

        final inA = await repository.watchReposForWorkspace('ws-a').first;
        expect(inA.map((r) => r.id), ['repo-a']);

        final inB = await repository.watchReposForWorkspace('ws-b').first;
        expect(inB, isEmpty);
        expect(
          await repository.isRepoLinkedToWorkspace('ws-b', 'repo-a'),
          isFalse,
        );
      },
    );

    /// Repo ids are per-workspace now: the same checkout registered in two
    /// workspaces is two independent rows. Reusing an id in both must not make
    /// either row visible from the other workspace, nor collide.
    test('two workspaces can hold the same repo id independently', () async {
      await repository.upsert(makeWorkspace(id: 'ws-a', name: 'A'));
      await repository.upsert(makeWorkspace(id: 'ws-b', name: 'B'));

      await addRepo('ws-a', 'repo-1', name: 'A copy', path: '/checkout');
      await addRepo('ws-b', 'repo-1', name: 'B copy', path: '/checkout');

      expect(
        (await repository.watchReposForWorkspace('ws-a').first).single.name,
        'A copy',
      );
      expect(
        (await repository.watchReposForWorkspace('ws-b').first).single.name,
        'B copy',
      );
    });
  });

  group('DaoWorkspaceRepository manual order', () {
    Workspace ws(String id, {DateTime? updatedAt}) => Workspace(
      id: id,
      name: id.toUpperCase(),
      createdAt: DateTime(2026, 5, 18),
      updatedAt: updatedAt ?? DateTime(2026, 5, 18),
    );

    Future<List<String>> orderedIds() async =>
        (await repository.watchAll().first).map((w) => w.id).toList();

    test('a new workspace appends to the end of the order', () async {
      await repository.upsert(ws('ws-a'));
      await repository.upsert(ws('ws-b'));
      await repository.upsert(ws('ws-c'));

      expect(await orderedIds(), ['ws-a', 'ws-b', 'ws-c']);
    });

    test('reorderWorkspaces re-sequences to the given id order', () async {
      await repository.upsert(ws('ws-a'));
      await repository.upsert(ws('ws-b'));
      await repository.upsert(ws('ws-c'));

      await repository.reorderWorkspaces(['ws-c', 'ws-a', 'ws-b']);

      expect(await orderedIds(), ['ws-c', 'ws-a', 'ws-b']);
    });

    test('updating a workspace keeps its place in the order', () async {
      await repository.upsert(ws('ws-a'));
      await repository.upsert(ws('ws-b'));

      // A rename bumps updated_at. Under the old updated_at-DESC ordering this
      // yanked the workspace to the top of every switcher; the manual order
      // must not move.
      await repository.upsert(
        (await repository.watchAll().first)
            .firstWhere((w) => w.id == 'ws-a')
            .copyWith(name: 'Renamed', updatedAt: DateTime(2026, 6, 1)),
      );

      expect(await orderedIds(), ['ws-a', 'ws-b']);
    });

    test('getAll agrees with the streamed order', () async {
      await repository.upsert(ws('ws-a'));
      await repository.upsert(ws('ws-b'));
      await repository.reorderWorkspaces(['ws-b', 'ws-a']);

      // The order comes out of the GLOBAL registry now, not a workspace file.
      final rows = await global.workspaceRegistryDao.getAll();
      expect(rows.map((r) => r.id), ['ws-b', 'ws-a']);
      expect((await repository.getAll()).map((w) => w.id), ['ws-b', 'ws-a']);
      expect(await orderedIds(), ['ws-b', 'ws-a']);
    });

    test(
      'a workspace created after a delete cannot claim a live slot',
      () async {
        await repository.upsert(ws('ws-a'));
        await repository.upsert(ws('ws-b'));
        await repository.delete('ws-b');

        await repository.upsert(ws('ws-c'));

        expect(await orderedIds(), ['ws-a', 'ws-c']);
      },
    );
  });
}
