import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
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

    test('watchAll returns repos ordered by updatedAt', () async {
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
    });
  });
}
