import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_repo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoRepoRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = DaoRepoRepository(db.repoDao);
  });

  tearDown(() async {
    await db.close();
  });

  Repo makeRepo({
    String id = 'r1',
    String name = 'acme/project',
    String path = '/path/to/repo',
    String githubOwner = 'acme',
    String githubRepoName = 'project',
  }) {
    final now = DateTime(2026, 5, 18);
    return Repo(
      id: id,
      name: name,
      path: path,
      githubOwner: githubOwner,
      githubRepoName: githubRepoName,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DaoRepoRepository', () {
    test('watchAll returns empty initially', timeout: const Timeout.factor(2), () async {
      final repos = await repository.watchAll().first;
      expect(repos, isEmpty);
    });

    test('upsert and getById', timeout: const Timeout.factor(2), () async {
      final repo = makeRepo();
      final id = await repository.upsert(repo);
      expect(id, 'r1');

      final fetched = await repository.getById('r1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'r1');
      expect(fetched.name, 'acme/project');
    });

    test('getById returns null for nonexistent', timeout: const Timeout.factor(2), () async {
      final fetched = await repository.getById('nonexistent');
      expect(fetched, isNull);
    });

    test('upsert overwrites existing repo', timeout: const Timeout.factor(2), () async {
      await repository.upsert(makeRepo(id: 'r1', name: 'original'));
      await repository.upsert(makeRepo(id: 'r1', name: 'updated'));

      final fetched = await repository.getById('r1');
      expect(fetched!.name, 'updated');
    });

    test('delete removes repo', timeout: const Timeout.factor(2), () async {
      await repository.upsert(makeRepo(id: 'r1'));
      await repository.delete('r1');

      final fetched = await repository.getById('r1');
      expect(fetched, isNull);
    });

    test('delete nonexistent repo does not throw', timeout: const Timeout.factor(2), () async {
      await repository.delete('nonexistent');
    });

    test('watchAll emits after upsert', timeout: const Timeout.factor(2), () async {
      final stream = repository.watchAll();
      await repository.upsert(makeRepo(id: 'r1'));

      final repos = await stream.first;
      expect(repos.length, 1);
      expect(repos.first.id, 'r1');
    });

    test('watchAll returns all repos', timeout: const Timeout.factor(2), () async {
      await repository.upsert(makeRepo(id: 'r1'));
      await repository.upsert(makeRepo(id: 'r2'));

      final repos = await repository.watchAll().first;
      expect(repos.length, 2);
    });

    test('repo with all fields', timeout: const Timeout.factor(2), () async {
      final repo = Repo(
        id: 'r-full',
        name: 'full/repo',
        path: '/full/path',
        githubOwner: 'full-org',
        githubRepoName: 'full-repo',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repository.upsert(repo);

      final fetched = await repository.getById('r-full');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'full/repo');
      expect(fetched.path, '/full/path');
      expect(fetched.githubOwner, 'full-org');
      expect(fetched.githubRepoName, 'full-repo');
      expect(fetched.createdAt, DateTime(2025, 1, 1));
      expect(fetched.updatedAt, DateTime(2026, 1, 1));
    });

    test('watchAll returns domain entities', timeout: const Timeout.factor(2), () async {
      await repository.upsert(makeRepo(id: 'r-domain'));
      final repos = await repository.watchAll().first;
      expect(repos.first, isA<Repo>());
    });
  });
}
