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

  // The workspace registry moved to `global.db` when the single database split
  // in two, so this group opens the global half. It is the former
  // `WorkspaceDao` minus its repo-link methods (see the `RepoDao` group below).
  group('WorkspaceRegistryDao', () {
    late GlobalDatabase global;

    setUp(() {
      global = createTestGlobalDatabase();
    });

    tearDown(() async {
      await global.close();
    });

    test('upsert and get workspace', () async {
      const id = 'ws-1';
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: id, name: 'Test Workspace'),
      );

      final ws = await global.workspaceRegistryDao.getById(id);
      expect(ws, isNotNull);
      expect(ws!.name, 'Test Workspace');
    });

    test('upsert overwrites existing workspace', () async {
      const id = 'ws-upsert';
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: id, name: 'Original'),
      );
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: id, name: 'Updated'),
      );

      final ws = await global.workspaceRegistryDao.getById(id);
      expect(ws!.name, 'Updated');
    });

    test('getById returns null for nonexistent workspace', () async {
      final ws = await global.workspaceRegistryDao.getById('nonexistent');
      expect(ws, isNull);
    });

    test('watchAll returns all workspaces', () async {
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'Workspace 1'),
      );
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'Workspace 2'),
      );

      final all = await global.workspaceRegistryDao.watchAll().first;
      expect(all.length, 2);
    });

    test('watchAll returns empty list when no workspaces', () async {
      final all = await global.workspaceRegistryDao.watchAll().first;
      expect(all, isEmpty);
    });

    test(
      'delete workspace soft-deletes it (hidden from fetches, row kept)',
      () async {
        const id = 'ws-del';
        await global.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: id, name: 'To Delete'),
        );

        await global.workspaceRegistryDao.deleteWorkspace(id);

        // Every fetch path excludes the soft-deleted workspace, so nothing can
        // resolve it (e.g. the web boot landing on a removed workspace).
        expect(await global.workspaceRegistryDao.getById(id), isNull);
        expect(await global.workspaceRegistryDao.getAll(), isEmpty);
        expect(await global.workspaceRegistryDao.watchAll().first, isEmpty);

        // The row physically remains, marked deleted and maintenance fan-out
        // still sees it — the workspace's database file is still on disk.
        final raw = await (global.select(
          global.workspacesTable,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        expect(raw, isNotNull);
        expect(raw!.deletedAt, isNotNull);
        expect(
          await global.workspaceRegistryDao.allIdsIncludingDeleted(),
          contains(id),
        );
      },
    );

    test('getAll and getById exclude soft-deleted workspaces', () async {
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-live', name: 'Live'),
      );
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-gone', name: 'Gone'),
      );
      await global.workspaceRegistryDao.deleteWorkspace('ws-gone');

      final all = await global.workspaceRegistryDao.getAll();
      expect(all.map((w) => w.id), ['ws-live']);
      expect(await global.workspaceRegistryDao.getById('ws-gone'), isNull);
      expect(await global.workspaceRegistryDao.getById('ws-live'), isNotNull);
    });

    test('delete nonexistent workspace does not throw', () async {
      await global.workspaceRegistryDao.deleteWorkspace('nonexistent');
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

  // `repos` is a workspace-scoped table now: the server-global `repos` plus its
  // `workspace_repos` join collapsed into one table in the workspace's own
  // database file and `WorkspaceDao`'s link/unlink/reorder half moved to
  // [RepoDao]. Registering a repo IS linking it; deleting it IS unlinking it,
  // and no `workspaceId` is threaded because the file is the scope.
  group('RepoDao — the former repo links', () {
    ReposTableCompanion repo(String id, String name, String slug) =>
        ReposTableCompanion.insert(
          id: id,
          name: name,
          path: '/path/to/$id',
          remoteOwner: const Value('acme'),
          remoteName: Value(slug),
        );

    test('upsertRepo registers a repo the workspace then lists', () async {
      await db.repoDao.upsertRepo(repo('repo-link', 'Link Repo', 'project'));

      final repos = await db.repoDao.watchAll().first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-link');
      // `exists` is the successor of the old `isRepoLinkedToWorkspace` probe.
      expect(await db.repoDao.exists('repo-link'), isTrue);
      // Repo identity across workspaces is by path, never by id.
      expect(
        (await db.repoDao.getByPath('/path/to/repo-link'))?.id,
        'repo-link',
      );
    });

    test('upsertRepo is idempotent', () async {
      await db.repoDao.upsertRepo(repo('repo-idem', 'Idem Repo', 'project'));
      await db.repoDao.upsertRepo(repo('repo-idem', 'Idem Repo', 'project'));

      final repos = await db.repoDao.watchAll().first;
      expect(repos.length, 1);
    });

    test('deleteRepo removes the repo from the workspace', () async {
      await db.repoDao.upsertRepo(
        repo('repo-unlink', 'Unlink Repo', 'project'),
      );

      await db.repoDao.deleteRepo('repo-unlink');

      expect(await db.repoDao.watchAll().first, isEmpty);
      expect(await db.repoDao.exists('repo-unlink'), isFalse);
    });

    test('the repo set can be replaced wholesale', () async {
      await db.repoDao.upsertRepo(repo('repo-a', 'Repo A', 'a'));

      await db.repoDao.deleteRepo('repo-a');
      await db.repoDao.upsertRepo(repo('repo-b', 'Repo B', 'b'));

      final repos = await db.repoDao.watchAll().first;
      expect(repos.length, 1);
      expect(repos.first.id, 'repo-b');
    });

    test('removing every repo leaves the list empty', () async {
      await db.repoDao.upsertRepo(repo('repo-c', 'Repo C', 'c'));
      await db.repoDao.upsertRepo(repo('repo-d', 'Repo D', 'd'));

      await db.repoDao.deleteRepo('repo-c');
      await db.repoDao.deleteRepo('repo-d');

      expect(await db.repoDao.watchAll().first, isEmpty);
      expect(await db.repoDao.getAll(), isEmpty);
    });

    test(
      'watchAll honours the manual order absorbed from workspace_repos',
      () async {
        // `position` came over from the join table, so a new repo appends to the
        // end of the operator's manual order instead of jumping to the top.
        await db.repoDao.upsertRepo(repo('repo-1', 'One', 'one'));
        await db.repoDao.upsertRepo(repo('repo-2', 'Two', 'two'));
        await db.repoDao.upsertRepo(repo('repo-3', 'Three', 'three'));
        expect((await db.repoDao.watchAll().first).map((r) => r.id), [
          'repo-1',
          'repo-2',
          'repo-3',
        ]);

        await db.repoDao.reorderRepos(['repo-3', 'repo-1', 'repo-2']);
        expect((await db.repoDao.watchAll().first).map((r) => r.id), [
          'repo-3',
          'repo-1',
          'repo-2',
        ]);
      },
    );
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
