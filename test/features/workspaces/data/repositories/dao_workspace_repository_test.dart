import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/workspaces/data/repositories/dao_workspace_repository.dart';
import 'package:drift/drift.dart' hide Column, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DaoWorkspaceRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DaoWorkspaceRepository(db.workspaceDao);
  });

  tearDown(() async {
    await db.close();
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

    test('delete removes workspace', () async {
      await repository.upsert(makeWorkspace());
      await repository.delete('ws-1');

      final workspaces = await repository.watchAll().first;
      expect(workspaces, isEmpty);
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

    test('linkRepoToWorkspace and watchReposForWorkspace', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-1',
          name: 'Repo 1',
          path: '/path/repo',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('project'),
        ),
      );
      await repository.upsert(makeWorkspace());

      await repository.linkRepoToWorkspace('ws-1', 'repo-1');

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-1');
    });

    test('unlinkRepoFromWorkspace removes link', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-1',
          name: 'Repo',
          path: '/path',
          githubOwner: const Value('org'),
          githubRepoName: const Value('repo'),
        ),
      );
      await repository.upsert(makeWorkspace());
      await repository.linkRepoToWorkspace('ws-1', 'repo-1');

      await repository.unlinkRepoFromWorkspace('ws-1', 'repo-1');

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos, isEmpty);
    });

    test('setReposForWorkspace replaces links', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-a', name: 'A', path: '/a',
          githubOwner: const Value('org'), githubRepoName: const Value('a'),
        ),
      );
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-b', name: 'B', path: '/b',
          githubOwner: const Value('org'), githubRepoName: const Value('b'),
        ),
      );
      await repository.upsert(makeWorkspace());
      await repository.linkRepoToWorkspace('ws-1', 'repo-a');

      await repository.setReposForWorkspace('ws-1', ['repo-b']);

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-b');
    });

    test('watchReposForWorkspace returns empty for workspace with no repos',
        () async {
      await repository.upsert(makeWorkspace());

      final repos = await repository.watchReposForWorkspace('ws-1').first;
      expect(repos, isEmpty);
    });
  });
}
