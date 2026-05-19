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

  group('RepoDao', () {
    test('upsert and get repo by id', () async {
      const id = 'repo-1';
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: id,
          name: 'my-repo',
          path: '/path/to/repo',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('project'),
        ),
      );

      final repo = await db.repoDao.getById(id);
      expect(repo, isNotNull);
      expect(repo!.name, 'my-repo');
      expect(repo.githubOwner, 'acme');
      expect(repo.githubRepoName, 'project');
    });

    test('upsert overwrites existing repo', () async {
      const id = 'repo-upsert';
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: id,
          name: 'original',
          path: '/path/orig',
          githubOwner: const Value('old'),
          githubRepoName: const Value('old-repo'),
        ),
      );
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: id,
          name: 'updated',
          path: '/path/updated',
          githubOwner: const Value('new'),
          githubRepoName: const Value('new-repo'),
        ),
      );

      final repo = await db.repoDao.getById(id);
      expect(repo!.name, 'updated');
      expect(repo.githubOwner, 'new');
    });

    test('getById returns null for nonexistent repo', () async {
      final repo = await db.repoDao.getById('nonexistent');
      expect(repo, isNull);
    });

    test('deleteRepo removes it', () async {
      const id = 'repo-del';
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: id,
          name: 'delete-me',
          path: '/path/del',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('temp'),
        ),
      );

      await db.repoDao.deleteRepo(id);
      final repo = await db.repoDao.getById(id);
      expect(repo, isNull);
    });

    test('deleteRepo returns row count', () async {
      const id = 'repo-del-count';
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: id,
          name: 'count-test',
          path: '/path/count',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('temp'),
        ),
      );

      final count = await db.repoDao.deleteRepo(id);
      expect(count, 1);
    });

    test('deleteRepo returns 0 for nonexistent repo', () async {
      final count = await db.repoDao.deleteRepo('nonexistent');
      expect(count, 0);
    });

    /// `repos` absorbed the old `workspace_repos` link row's `position`, so the
    /// app-wide repo order is now a column on this table: a new repo appends to
    /// the end of the manual order rather than landing on the default `0`.
    test(
      'watchAll returns repos in manual position order, inserts appending',
      () async {
        await db.repoDao.upsertRepo(
          ReposTableCompanion.insert(
            id: 'repo-a',
            name: 'A',
            path: '/path/a',
            githubOwner: const Value('acme'),
            githubRepoName: const Value('a'),
          ),
        );
        await db.repoDao.upsertRepo(
          ReposTableCompanion.insert(
            id: 'repo-b',
            name: 'B',
            path: '/path/b',
            githubOwner: const Value('acme'),
            githubRepoName: const Value('b'),
          ),
        );

        final repos = await db.repoDao.watchAll().first;
        expect(repos.length, 2);
        expect(repos.map((r) => r.id), ['repo-a', 'repo-b']);
        expect(repos.map((r) => r.position), [0, 1]);
      },
    );

    test(
      'reorderRepos re-sequences positions and ignores unknown ids',
      () async {
        for (final id in ['repo-a', 'repo-b', 'repo-c']) {
          await db.repoDao.upsertRepo(
            ReposTableCompanion.insert(id: id, name: id, path: '/path/$id'),
          );
        }

        await db.repoDao.reorderRepos(['repo-c', 'repo-a', 'repo-b', 'ghost']);

        final repos = await db.repoDao.getAll();
        expect(repos.map((r) => r.id), ['repo-c', 'repo-a', 'repo-b']);
      },
    );

    test('exists is the replacement for the old link probe', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-exists',
          name: 'exists',
          path: '/path/exists',
        ),
      );

      expect(await db.repoDao.exists('repo-exists'), isTrue);
      expect(await db.repoDao.exists('repo-absent'), isFalse);
    });

    test('getByPath resolves a checkout by path', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-path',
          name: 'path',
          path: '/path/by-path',
        ),
      );

      final found = await db.repoDao.getByPath('/path/by-path');
      expect(found, isNotNull);
      expect(found!.id, 'repo-path');
      expect(await db.repoDao.getByPath('/nope'), isNull);
    });

    test('update does not reshuffle the manual order', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'repo-a', name: 'A', path: '/a'),
      );
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'repo-b', name: 'B', path: '/b'),
      );

      // A rename of the first repo must not move it.
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(id: 'repo-a', name: 'A renamed', path: '/a'),
      );

      final repos = await db.repoDao.getAll();
      expect(repos.map((r) => r.id), ['repo-a', 'repo-b']);
      expect(repos.first.name, 'A renamed');
    });
  });
}
