import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/repos/data/repositories/dao_repo_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DaoRepoRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
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
    test('upsert and getById', () async {
      final repo = makeRepo();
      final id = await repository.upsert(repo);
      expect(id, 'r1');

      final fetched = await repository.getById('r1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'r1');
      expect(fetched.name, 'acme/project');
    });

    test('getById returns null for nonexistent', () async {
      final fetched = await repository.getById('nonexistent');
      expect(fetched, isNull);
    });

    test('watchAll returns all repos', () async {
      await repository.upsert(makeRepo(id: 'r1'));
      await repository.upsert(makeRepo(id: 'r2'));

      final repos = await repository.watchAll().first;
      expect(repos.length, 2);
    });

    test('watchAll returns empty when no repos', () async {
      final repos = await repository.watchAll().first;
      expect(repos, isEmpty);
    });

    test('upsert overwrites existing repo', () async {
      await repository.upsert(makeRepo(id: 'r1', name: 'original'));
      await repository.upsert(makeRepo(id: 'r1', name: 'updated'));

      final fetched = await repository.getById('r1');
      expect(fetched!.name, 'updated');
    });

    test('delete removes repo', () async {
      await repository.upsert(makeRepo(id: 'r1'));
      await repository.delete('r1');

      final fetched = await repository.getById('r1');
      expect(fetched, isNull);
    });

    test('delete nonexistent repo does not throw', () async {
      await repository.delete('nonexistent');
    });

    test('watchAll emits after upsert', () async {
      final stream = repository.watchAll();
      await repository.upsert(makeRepo(id: 'r1'));

      final repos = await stream.first;
      expect(repos.length, 1);
      expect(repos.first.id, 'r1');
    });

    test('repo with all fields', () async {
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
      expect(fetched!.name, 'full/repo');
      expect(fetched.path, '/full/path');
      expect(fetched.githubOwner, 'full-org');
      expect(fetched.githubRepoName, 'full-repo');
    });

    test('watchAll returns domain entities', () async {
      await repository.upsert(makeRepo(id: 'r-domain'));
      final repos = await repository.watchAll().first;
      expect(repos.first, isA<Repo>());
    });
  });
}
