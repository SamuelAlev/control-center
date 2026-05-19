import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// [DaoRepoRepository] over the per-workspace databases.
///
/// Repos are workspace-scoped now: the old server-global `repos` table plus its
/// `workspace_repos` join collapsed into one table living inside each
/// workspace's own database file, so every method takes a leading
/// `workspaceId` and that id picks the file before any SQL runs.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoRepoRepository repository;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-1');
    await seedTestWorkspace(global, dbs, 'ws-2');
    repository = DaoRepoRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Repo makeRepo({
    String id = 'r1',
    String name = 'acme/project',
    String path = '/path/to/repo',
    String remoteOwner = 'acme',
    String remoteName = 'project',
  }) {
    final now = DateTime(2026, 5, 18);
    return Repo(
      id: id,
      name: name,
      path: path,
      remoteOwner: remoteOwner,
      remoteName: remoteName,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DaoRepoRepository', () {
    test(
      'watchAll returns empty initially',
      timeout: const Timeout.factor(2),
      () async {
        final repos = await repository.watchAll('ws-1').first;
        expect(repos, isEmpty);
      },
    );

    test('upsert and getById', timeout: const Timeout.factor(2), () async {
      final repo = makeRepo();
      final id = await repository.upsert('ws-1', repo);
      expect(id, 'r1');

      final fetched = await repository.getById('ws-1', 'r1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'r1');
      expect(fetched.name, 'acme/project');
    });

    test(
      'getById returns null for nonexistent',
      timeout: const Timeout.factor(2),
      () async {
        final fetched = await repository.getById('ws-1', 'nonexistent');
        expect(fetched, isNull);
      },
    );

    test(
      'upsert overwrites existing repo',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r1', name: 'original'));
        await repository.upsert('ws-1', makeRepo(id: 'r1', name: 'updated'));

        final fetched = await repository.getById('ws-1', 'r1');
        expect(fetched!.name, 'updated');
      },
    );

    test('delete removes repo', timeout: const Timeout.factor(2), () async {
      await repository.upsert('ws-1', makeRepo(id: 'r1'));
      await repository.delete('ws-1', 'r1');

      final fetched = await repository.getById('ws-1', 'r1');
      expect(fetched, isNull);
    });

    test(
      'delete nonexistent repo does not throw',
      timeout: const Timeout.factor(2),
      () async {
        await repository.delete('ws-1', 'nonexistent');
      },
    );

    test(
      'watchAll emits after upsert',
      timeout: const Timeout.factor(2),
      () async {
        final stream = repository.watchAll('ws-1');
        await repository.upsert('ws-1', makeRepo(id: 'r1'));

        final repos = await stream.first;
        expect(repos.length, 1);
        expect(repos.first.id, 'r1');
      },
    );

    test(
      'watchAll returns all repos',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r1'));
        await repository.upsert('ws-1', makeRepo(id: 'r2', path: '/path/two'));

        final repos = await repository.watchAll('ws-1').first;
        expect(repos.length, 2);
      },
    );

    test(
      'getAll agrees with watchAll',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r1'));
        await repository.upsert('ws-1', makeRepo(id: 'r2', path: '/path/two'));

        final streamed = await repository.watchAll('ws-1').first;
        final oneShot = await repository.getAll('ws-1');
        expect(oneShot.map((r) => r.id), streamed.map((r) => r.id));
      },
    );

    test('repo with all fields', timeout: const Timeout.factor(2), () async {
      final repo = Repo(
        id: 'r-full',
        name: 'full/repo',
        path: '/full/path',
        remoteOwner: 'full-org',
        remoteName: 'full-repo',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repository.upsert('ws-1', repo);

      final fetched = await repository.getById('ws-1', 'r-full');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'full/repo');
      expect(fetched.path, '/full/path');
      expect(fetched.remoteOwner, 'full-org');
      expect(fetched.remoteName, 'full-repo');
      expect(fetched.createdAt, DateTime(2025, 1, 1));
      expect(fetched.updatedAt, DateTime(2026, 1, 1));
    });

    test(
      'watchAll returns domain entities',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r-domain'));
        final repos = await repository.watchAll('ws-1').first;
        expect(repos.first, isA<Repo>());
      },
    );
  });

  group('DaoRepoRepository lookup and order', () {
    /// Repo identity ACROSS workspaces is by path, never by id (each workspace
    /// mints its own id for a checkout), so this is the "is this checkout
    /// already here?" probe.
    test(
      'findByPath resolves the checkout registered at a path',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert(
          'ws-1',
          makeRepo(id: 'r1', path: '/checkout/one'),
        );

        final found = await repository.findByPath('ws-1', '/checkout/one');
        expect(found, isNotNull);
        expect(found!.id, 'r1');
        expect(await repository.findByPath('ws-1', '/checkout/absent'), isNull);
      },
    );

    test(
      'exists is the repo-scoped isolation gate',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r1'));

        expect(await repository.exists('ws-1', 'r1'), isTrue);
        expect(await repository.exists('ws-1', 'r-absent'), isFalse);
        // The gate a repo-scoped tool relies on: `ws-2` must not pass for a repo
        // registered in `ws-1`.
        expect(await repository.exists('ws-2', 'r1'), isFalse);
      },
    );

    /// The `position` column absorbed from the old `workspace_repos` link row:
    /// a newly inserted repo appends to the end of the manual order and
    /// `reorder` is the drag-to-reorder write path behind `watchAll`'s order.
    test(
      'inserts append and reorder re-sequences',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r-a', path: '/a'));
        await repository.upsert('ws-1', makeRepo(id: 'r-b', path: '/b'));
        await repository.upsert('ws-1', makeRepo(id: 'r-c', path: '/c'));

        expect((await repository.getAll('ws-1')).map((r) => r.id), [
          'r-a',
          'r-b',
          'r-c',
        ]);

        await repository.reorder('ws-1', ['r-c', 'r-a', 'r-b']);

        expect((await repository.getAll('ws-1')).map((r) => r.id), [
          'r-c',
          'r-a',
          'r-b',
        ]);
      },
    );

    test(
      'an update does not reshuffle the manual order',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r-a', path: '/a'));
        await repository.upsert('ws-1', makeRepo(id: 'r-b', path: '/b'));

        await repository.upsert(
          'ws-1',
          makeRepo(id: 'r-a', name: 'renamed', path: '/a'),
        );

        expect((await repository.getAll('ws-1')).map((r) => r.id), [
          'r-a',
          'r-b',
        ]);
      },
    );
  });

  group('DaoRepoRepository workspace isolation', () {
    /// The invariant that used to be a `WHERE workspace_id = ?` on the
    /// `workspace_repos` join now holds one layer lower: `ws-1` and `ws-2` are
    /// separate database files, so this proves the repository ROUTES on its
    /// leading `workspaceId` rather than filtering a shared table.
    test(
      'a repo registered in one workspace is invisible from the other',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert(
          'ws-1',
          makeRepo(id: 'r-1', name: 'only in ws-1'),
        );

        expect((await repository.watchAll('ws-1').first).map((r) => r.id), [
          'r-1',
        ]);
        expect(await repository.watchAll('ws-2').first, isEmpty);
        expect(await repository.getAll('ws-2'), isEmpty);
        expect(await repository.getById('ws-2', 'r-1'), isNull);
        expect(await repository.findByPath('ws-2', '/path/to/repo'), isNull);
      },
    );

    test(
      'deleting from the wrong workspace leaves the repo alone',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r-1'));

        await repository.delete('ws-2', 'r-1');

        expect(await repository.getById('ws-1', 'r-1'), isNotNull);
      },
    );

    /// The same checkout added to two workspaces is two independent rows — ids
    /// are per-workspace, so even an identical id must not alias.
    test(
      'the same id in two workspaces is two independent repos',
      timeout: const Timeout.factor(2),
      () async {
        await repository.upsert('ws-1', makeRepo(id: 'r-1', name: 'ws-1 copy'));
        await repository.upsert('ws-2', makeRepo(id: 'r-1', name: 'ws-2 copy'));

        expect((await repository.getById('ws-1', 'r-1'))!.name, 'ws-1 copy');
        expect((await repository.getById('ws-2', 'r-1'))!.name, 'ws-2 copy');

        await repository.delete('ws-1', 'r-1');
        expect(await repository.getById('ws-1', 'r-1'), isNull);
        expect(await repository.getById('ws-2', 'r-1'), isNotNull);
      },
    );
  });
}
