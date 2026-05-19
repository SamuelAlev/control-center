import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
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

  group('WorkspaceDao', () {
    test('upsert and get workspace', () async {
      const id = 'ws-1';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: id,
          name: 'Test Workspace',
        ),
      );

      final ws = await db.workspaceDao.getById(id);
      expect(ws, isNotNull);
      expect(ws!.name, 'Test Workspace');
    });

    test('upsert overwrites existing workspace', () async {
      const id = 'ws-upsert';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: id,
          name: 'Original',
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: id,
          name: 'Updated',
        ),
      );

      final ws = await db.workspaceDao.getById(id);
      expect(ws!.name, 'Updated');
    });

    test('getById returns null for nonexistent workspace', () async {
      final ws = await db.workspaceDao.getById('nonexistent');
      expect(ws, isNull);
    });

    test('watchAll returns all workspaces', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-1',
          name: 'Workspace 1',
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-2',
          name: 'Workspace 2',
        ),
      );

      final all = await db.workspaceDao.watchAll().first;
      expect(all.length, 2);
    });

    test('watchAll returns empty list when no workspaces', () async {
      final all = await db.workspaceDao.watchAll().first;
      expect(all, isEmpty);
    });

    test('delete workspace soft-deletes it', () async {
      const id = 'ws-del';
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: id,
          name: 'To Delete',
        ),
      );

      await db.workspaceDao.deleteWorkspace(id);
      final ws = await db.workspaceDao.getById(id);
      expect(ws, isNotNull);
      expect(ws!.deletedAt, isNotNull);
    });

    test('delete nonexistent workspace does not throw', () async {
      await db.workspaceDao.deleteWorkspace('nonexistent');
    });
  });

  group('AgentDao', () {
    test('upsert and get agent', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-1',
          name: 'architect',
          title: 'Software Architect',
          agentMdPath: '.kilo/agent/architect.md',
          skills: 'architecture, design, review',
          workspaceId: 'ws-test',
        ),
      );

      final agent = await db.agentDao.getById('agent-1');
      expect(agent, isNotNull);
      expect(agent!.name, 'architect');
      expect(agent.title, 'Software Architect');
    });

    test('watchAll returns agents sorted by name', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-b',
          name: 'builder',
          title: 'Builder',
          agentMdPath: '.kilo/agent/builder.md',
          skills: 'build',
          workspaceId: 'ws-test',
        ),
      );
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-a',
          name: 'architect',
          title: 'Architect',
          agentMdPath: '.kilo/agent/architect.md',
          skills: 'arch',
          workspaceId: 'ws-test',
        ),
      );

      final agents = await db.agentDao.watchAll().first;
      expect(agents.length, 2);
      expect(agents[0].name, 'architect');
      expect(agents[1].name, 'builder');
    });

    test('delete agent', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-del',
          name: 'deleteme',
          title: 'Delete',
          agentMdPath: '.kilo/agent/del.md',
          skills: 'delete',
          workspaceId: 'ws-test',
        ),
      );

      await db.agentDao.deleteById('agent-del');
      final agent = await db.agentDao.getById('agent-del');
      expect(agent, isNull);
    });

    test('upsert overwrites existing agent', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-up',
          name: 'original',
          title: 'Original',
          agentMdPath: '.kilo/agent/orig.md',
          skills: 'orig',
          workspaceId: 'ws-test',
        ),
      );
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'agent-up',
          name: 'updated',
          title: 'Updated',
          agentMdPath: '.kilo/agent/up.md',
          skills: 'upd',
          workspaceId: 'ws-test',
        ),
      );

      final agent = await db.agentDao.getById('agent-up');
      expect(agent!.name, 'updated');
      expect(agent.title, 'Updated');
    });

    test('getById returns null for nonexistent agent', () async {
      final agent = await db.agentDao.getById('nonexistent');
      expect(agent, isNull);
    });

    test('deleteById does not throw for nonexistent agent', () async {
      await db.agentDao.deleteById('nonexistent');
    });
  });

  group('WorkspaceDao — repo links', () {
    test('linkRepoToWorkspace and watchReposForWorkspace', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-link',
          name: 'Link Repo',
          path: '/path/to/repo-link',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('project'),
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-link',
          name: 'Link WS',
        ),
      );

      await db.workspaceDao.linkRepoToWorkspace('ws-link', 'repo-link');

      final repos = await db.workspaceDao
          .watchReposForWorkspace('ws-link')
          .first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-link');
    });

    test('linkRepoToWorkspace is idempotent', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-idem',
          name: 'Idem Repo',
          path: '/path/to/repo-idem',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('project'),
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-idem',
          name: 'Idem WS',
        ),
      );

      await db.workspaceDao.linkRepoToWorkspace('ws-idem', 'repo-idem');
      await db.workspaceDao.linkRepoToWorkspace('ws-idem', 'repo-idem');

      final repos = await db.workspaceDao
          .watchReposForWorkspace('ws-idem')
          .first;
      expect(repos.length, 1);
    });

    test('unlinkRepoFromWorkspace removes link', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-unlink',
          name: 'Unlink Repo',
          path: '/path/to/repo-unlink',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('project'),
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-unlink',
          name: 'Unlink WS',
        ),
      );
      await db.workspaceDao.linkRepoToWorkspace('ws-unlink', 'repo-unlink');

      await db.workspaceDao.unlinkRepoFromWorkspace('ws-unlink', 'repo-unlink');

      final repos = await db.workspaceDao
          .watchReposForWorkspace('ws-unlink')
          .first;
      expect(repos, isEmpty);
    });

    test('setReposForWorkspace replaces all links', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-a',
          name: 'Repo A',
          path: '/path/to/repo-a',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('a'),
        ),
      );
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-b',
          name: 'Repo B',
          path: '/path/to/repo-b',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('b'),
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-set',
          name: 'Set WS',
        ),
      );
      await db.workspaceDao.linkRepoToWorkspace('ws-set', 'repo-a');

      await db.workspaceDao.setReposForWorkspace('ws-set', ['repo-b']);

      final repos = await db.workspaceDao
          .watchReposForWorkspace('ws-set')
          .first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-b');
    });

    test('setReposForWorkspace with empty list removes all links', () async {
      await db.repoDao.upsertRepo(
        ReposTableCompanion.insert(
          id: 'repo-c',
          name: 'Repo C',
          path: '/path/to/repo-c',
          githubOwner: const Value('acme'),
          githubRepoName: const Value('c'),
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-empty',
          name: 'Empty WS',
        ),
      );
      await db.workspaceDao.linkRepoToWorkspace('ws-empty', 'repo-c');

      await db.workspaceDao.setReposForWorkspace('ws-empty', []);

      final repos = await db.workspaceDao
          .watchReposForWorkspace('ws-empty')
          .first;
      expect(repos, isEmpty);
    });
  });

  group('ReviewDao', () {
    test('upsert and get draft', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'LGTM');

      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, 'LGTM');
    });

    test('clearDraft removes draft', () async {
      await db.reviewDao.upsertDraft('acme', 'repo', 42, 'to clear');
      await db.reviewDao.clearDraft('acme', 'repo', 42);

      final draft = await db.reviewDao.getDraft('acme', 'repo', 42);
      expect(draft, isNull);
    });
  });
}
