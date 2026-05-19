import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_isolated_repo_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoIsolatedRepoRepository repository;

  setUp(() async {
    db = createTestDatabase();
    repository = DaoIsolatedRepoRepository(db.isolatedRepoDao);

    // FK constraints: isolated_repos references workspaces(id) and repos(id).
    await _insertWorkspace(db, 'ws1', 'Workspace 1');
    await _insertWorkspace(db, 'ws2', 'Workspace 2');
    await _insertRepo(db, 'repo1', 'acme/project', '/repos/acme');
    await _insertRepo(db, 'repo2', 'acme/other', '/repos/other');
  });

  tearDown(() async {
    await db.close();
  });

  group('DaoIsolatedRepoRepository', () {
    test('forUnitRepo returns null when not found', timeout: const Timeout.factor(2), () async {
      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNull);
    });

    test('upsert and forUnitRepo', timeout: const Timeout.factor(2), () async {
      final repo = _makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      );
      await repository.upsert(repo);

      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNotNull);
      expect(result!.id, 'iso1');
      expect(result.workspaceId, 'ws1');
      expect(result.channelId, 'ch1');
      expect(result.repoId, 'repo1');
      expect(result.path, '/ws1/ch1/repos/acme');
      expect(result.branch, 'feature-x');
      expect(result.backend, RepoIsolationBackend.rift);
      expect(result.sourcePath, '/repos/acme');
    });

    test('forChannel returns matching repos', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso2',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo2',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso3',
        workspaceId: 'ws1',
        channelId: 'ch2',
        repoId: 'repo1',
      ));

      final results = await repository.forChannel('ws1', 'ch1');
      expect(results.length, 2);
      expect(results.every((r) => r.channelId == 'ch1'), isTrue);
    });

    test('forChannel returns empty for non-matching workspace', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      ));

      final results = await repository.forChannel('ws2', 'ch1');
      expect(results, isEmpty);
    });

    test('forTicket returns matching repos', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        ticketId: 'tick1',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso2',
        workspaceId: 'ws1',
        channelId: 'ch2',
        repoId: 'repo2',
        ticketId: 'tick1',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso3',
        workspaceId: 'ws1',
        channelId: 'ch3',
        repoId: 'repo1',
        ticketId: 'tick2',
      ));

      final results = await repository.forTicket('ws1', 'tick1');
      expect(results.length, 2);
      expect(results.every((r) => r.ticketId == 'tick1'), isTrue);
    });

    test('forTicket returns empty when no match', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        ticketId: 'tick1',
      ));

      final results = await repository.forTicket('ws1', 'tick-nonexistent');
      expect(results, isEmpty);
    });

    test('watchForWorkspace returns stream', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      ));

      final results = await repository.watchForWorkspace('ws1').first;
      expect(results.length, 1);
      expect(results.first.id, 'iso1');
    });

    test('watchForWorkspace returns empty for workspace with no isolated repos', timeout: const Timeout.factor(2), () async {
      final results = await repository.watchForWorkspace('ws2').first;
      expect(results, isEmpty);
    });

    test('deleteById removes', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      ));

      await repository.deleteById('iso1');

      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNull);
    });

    test('workspace isolation — repos from other workspace not returned', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws2',
        workspaceId: 'ws2',
        channelId: 'ch1',
        repoId: 'repo1',
      ));

      // forUnitRepo scoped to ws1 should only find ws1's repo
      final ws1Result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(ws1Result, isNotNull);
      expect(ws1Result!.id, 'iso-ws1');

      // forUnitRepo scoped to ws2 finds ws2's repo
      final ws2Result = await repository.forUnitRepo('ws2', 'ch1', 'repo1');
      expect(ws2Result, isNotNull);
      expect(ws2Result!.id, 'iso-ws2');

      // forChannel scoped to ws1 should not include ws2's repos
      final ws1Channels = await repository.forChannel('ws1', 'ch1');
      expect(ws1Channels.length, 1);
      expect(ws1Channels.first.id, 'iso-ws1');

      // watchForWorkspace scoped to ws1 should not include ws2's repos
      final ws1Watched = await repository.watchForWorkspace('ws1').first;
      expect(ws1Watched.length, 1);
      expect(ws1Watched.first.id, 'iso-ws1');
    });

    test('forChannelAcrossWorkspaces returns repos across all workspaces', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws1',
        workspaceId: 'ws1',
        channelId: 'shared-ch',
        repoId: 'repo1',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws2',
        workspaceId: 'ws2',
        channelId: 'shared-ch',
        repoId: 'repo1',
      ));

      final results = await repository.forChannelAcrossWorkspaces('shared-ch');
      expect(results.length, 2);
    });

    test('forTicketAcrossWorkspaces returns repos across all workspaces', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        ticketId: 'shared-ticket',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-ws2',
        workspaceId: 'ws2',
        channelId: 'ch2',
        repoId: 'repo2',
        ticketId: 'shared-ticket',
      ));

      final results = await repository.forTicketAcrossWorkspaces('shared-ticket');
      expect(results.length, 2);
    });

    test('upsert overwrites existing isolated repo', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        branch: 'original-branch',
      ));
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso1',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        branch: 'updated-branch',
      ));

      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNotNull);
      expect(result!.branch, 'updated-branch');
    });

    test('isolated repo with null ticketId', timeout: const Timeout.factor(2), () async {
      await repository.upsert(_makeIsolatedRepo(
        id: 'iso-no-ticket',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        ticketId: null,
      ));

      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNotNull);
      expect(result!.ticketId, isNull);
    });

    test('isolated repo with gitWorktree backend', timeout: const Timeout.factor(2), () async {
      final repo = IsolatedRepo(
        id: 'iso-gwt',
        workspaceId: 'ws1',
        channelId: 'ch1',
        repoId: 'repo1',
        path: '/ws1/ch1/repos/acme',
        branch: 'feature-y',
        backend: RepoIsolationBackend.gitWorktree,
        sourcePath: '/repos/acme',
        createdAt: DateTime(2026, 6, 1),
      );
      await repository.upsert(repo);

      final result = await repository.forUnitRepo('ws1', 'ch1', 'repo1');
      expect(result, isNotNull);
      expect(result!.backend, RepoIsolationBackend.gitWorktree);
    });
  });
}

// -- Helpers --

IsolatedRepo _makeIsolatedRepo({
  required String id,
  required String workspaceId,
  required String channelId,
  required String repoId,
  String? ticketId,
  String branch = 'feature-x',
}) {
  return IsolatedRepo(
    id: id,
    workspaceId: workspaceId,
    channelId: channelId,
    repoId: repoId,
    path: '/$workspaceId/$channelId/repos/acme',
    branch: branch,
    backend: RepoIsolationBackend.rift,
    sourcePath: '/repos/acme',
    ticketId: ticketId,
    createdAt: DateTime(2026, 6, 1),
  );
}

Future<void> _insertWorkspace(AppDatabase db, String id, String name) {
  return db.workspaceDao.upsertWorkspace(
    WorkspacesTableCompanion(
      id: Value(id),
      name: Value(name),
      reviewConcurrency: const Value(3),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    ),
  );
}

Future<void> _insertRepo(
  AppDatabase db,
  String id,
  String name,
  String path,
) {
  return db.repoDao.upsertRepo(
    ReposTableCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      githubOwner: const Value('acme'),
      githubRepoName: const Value('project'),
      createdAt: Value(DateTime(2026, 1, 1)),
      updatedAt: Value(DateTime(2026, 1, 1)),
    ),
  );
}
