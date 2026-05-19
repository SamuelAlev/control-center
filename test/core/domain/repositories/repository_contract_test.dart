import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:flutter_test/flutter_test.dart';

final _testDate = DateTime(2026, 1, 1);
final _testDate2 = DateTime(2026, 1, 2);

void main() {
  // ---------------------------------------------------------------------------
  // CacheRepository
  // ---------------------------------------------------------------------------
  group('CacheRepository', () {
    test('contract — put, read, deleteEntry', () async {
      final repo = _TestCacheRepository();
      expect(await repo.read('ws-1', 'pr', '42'), isNull);

      await repo.put('ws-1', 'pr', '42', '{"status":"open"}');
      expect(await repo.read('ws-1', 'pr', '42'), '{"status":"open"}');

      await repo.deleteEntry('ws-1', 'pr', '42');
      expect(await repo.read('ws-1', 'pr', '42'), isNull);
    });

    test('contract — scoping by workspace and kind', () async {
      final repo = _TestCacheRepository();
      await repo.put('ws-1', 'pr', 'k1', 'a');
      await repo.put('ws-1', 'issue', 'k1', 'b');
      await repo.put('ws-2', 'pr', 'k1', 'c');

      expect(await repo.read('ws-1', 'pr', 'k1'), 'a');
      expect(await repo.read('ws-1', 'issue', 'k1'), 'b');
      expect(await repo.read('ws-2', 'pr', 'k1'), 'c');
    });

    test('contract — deleteKind', () async {
      final repo = _TestCacheRepository();
      await repo.put('ws-1', 'pr', '1', 'a');
      await repo.put('ws-1', 'pr', '2', 'b');
      await repo.put('ws-1', 'issue', '3', 'c');

      await repo.deleteKind('ws-1', 'pr');
      expect(await repo.read('ws-1', 'pr', '1'), isNull);
      expect(await repo.read('ws-1', 'pr', '2'), isNull);
      expect(await repo.read('ws-1', 'issue', '3'), 'c');
    });

    test('contract — deleteKindWithPrefix', () async {
      final repo = _TestCacheRepository();
      await repo.put('ws-1', 'pr', 'pr-42', 'a');
      await repo.put('ws-1', 'pr', 'pr-43', 'b');
      await repo.put('ws-1', 'pr', 'other', 'c');

      await repo.deleteKindWithPrefix('ws-1', 'pr', 'pr-');
      expect(await repo.read('ws-1', 'pr', 'pr-42'), isNull);
      expect(await repo.read('ws-1', 'pr', 'pr-43'), isNull);
      expect(await repo.read('ws-1', 'pr', 'other'), 'c');
    });

    test('contract — overwrite existing key', () async {
      final repo = _TestCacheRepository();
      await repo.put('ws-1', 'pr', 'k1', 'old');
      await repo.put('ws-1', 'pr', 'k1', 'new');
      expect(await repo.read('ws-1', 'pr', 'k1'), 'new');
    });
  });

  // ---------------------------------------------------------------------------
  // WorkspaceRepository
  // ---------------------------------------------------------------------------
  group('WorkspaceRepository', () {
    test('contract — upsert creates and updates', () async {
      final repo = _TestWorkspaceRepository();
      final ws = _testWorkspace('ws-1', 'My Workspace');

      final id = await repo.upsert(ws);
      expect(id, 'ws-1');

      final updated = _testWorkspace('ws-1', 'Updated');
      await repo.upsert(updated);
    });

    test('contract — watchAll emits on upsert', () async {
      final repo = _TestWorkspaceRepository();
      final future = repo.watchAll().first;

      await repo.upsert(_testWorkspace('ws-a', 'A'));
      final first = await future;
      expect(first.length, 1);
      expect(first.first.id, 'ws-a');
    });

    test('contract — getAll and getById', () async {
      final repo = _TestWorkspaceRepository();
      await repo.upsert(_testWorkspace('ws-1', 'First'));
      await repo.upsert(_testWorkspace('ws-2', 'Second'));

      expect((await repo.getAll()).map((w) => w.id), ['ws-1', 'ws-2']);
      expect((await repo.getById('ws-2'))!.name, 'Second');
      expect(await repo.getById('ws-missing'), isNull);
    });

    test('contract — delete removes workspace', () async {
      final repo = _TestWorkspaceRepository();
      await repo.upsert(_testWorkspace('ws-1', 'To Delete'));
      await repo.delete('ws-1');

      final ws = repo.getAllSync();
      expect(ws.where((w) => w.id == 'ws-1'), isEmpty);
    });

    test(
      'contract — setReposForWorkspace and isRepoLinkedToWorkspace',
      () async {
        final repo = _TestWorkspaceRepository();
        await repo.setReposForWorkspace('ws-1', ['repo-1']);
        expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-1'), isTrue);
        expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-2'), isFalse);
      },
    );

    test('contract — isRepoLinkedToWorkspace is workspace-scoped', () async {
      final repo = _TestWorkspaceRepository();
      await repo.setReposForWorkspace('ws-1', ['repo-1']);

      // Repos are per-workspace: another workspace never inherits the link.
      expect(await repo.isRepoLinkedToWorkspace('ws-2', 'repo-1'), isFalse);
    });

    test('contract — unlinkRepoFromWorkspace', () async {
      final repo = _TestWorkspaceRepository();
      await repo.setReposForWorkspace('ws-1', ['repo-1']);
      await repo.unlinkRepoFromWorkspace('ws-1', 'repo-1');
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-1'), isFalse);
    });

    test('contract — setReposForWorkspace replaces links', () async {
      final repo = _TestWorkspaceRepository();
      await repo.setReposForWorkspace('ws-1', ['old-1', 'old-2']);

      await repo.setReposForWorkspace('ws-1', ['new-1', 'new-2']);
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'new-1'), isTrue);
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'new-2'), isTrue);
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'old-1'), isFalse);
    });

    test('contract — watchReposForWorkspace emits', () async {
      final repo = _TestWorkspaceRepository();
      final stream = repo.watchReposForWorkspace('ws-1');
      final repos = await stream.first;
      expect(repos, isA<List<Repo>>());
    });
  });

  // ---------------------------------------------------------------------------
  // AgentRepository
  // ---------------------------------------------------------------------------
  group('AgentRepository', () {
    test('contract — upsert creates and getById retrieves', () async {
      final repo = _TestAgentRepository();
      final agent = _testAgent('agent-1', 'builder', 'ws-1');

      await repo.upsert(agent);
      final found = await repo.getById('ws-1', 'agent-1');

      expect(found, isNotNull);
      expect(found!.id, 'agent-1');
      expect(found.name, 'builder');
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestAgentRepository();
      expect(await repo.getById('ws-1', 'nonexistent'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'alpha', 'ws-1'));
      await repo.upsert(_testAgent('a-1', 'beta', 'ws-1'));

      final found = await repo.getById('ws-1', 'a-1');
      expect(found!.name, 'beta');
      expect(found.workspaceId, 'ws-1');
    });

    test('contract — getById does not resolve across workspaces', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'alpha', 'ws-1'));

      // The id is a uuid, not an access boundary: the workspace selects where
      // it is looked up, so a foreign workspace finds nothing.
      expect(await repo.getById('ws-2', 'a-1'), isNull);
    });

    test('contract — findByWorkspaceAndName', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'explorer', 'ws-1'));
      await repo.upsert(_testAgent('a-2', 'explorer', 'ws-2'));

      final inWs1 = await repo.findByWorkspaceAndName('ws-1', 'explorer');
      expect(inWs1, isNotNull);
      expect(inWs1!.id, 'a-1');

      final missing = await repo.findByWorkspaceAndName('ws-3', 'explorer');
      expect(missing, isNull);
    });

    test('contract — delete removes agent', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'temp', 'ws-1'));
      await repo.delete('ws-1', 'a-1');
      expect(await repo.getById('ws-1', 'a-1'), isNull);
    });

    test('contract — delete ignores an id from another workspace', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'keep', 'ws-1'));
      await repo.delete('ws-2', 'a-1');
      expect(await repo.getById('ws-1', 'a-1'), isNotNull);
    });

    test('contract — watchAll emits on upsert', () async {
      final repo = _TestAgentRepository();
      final future = repo.watchAll().first;

      await repo.upsert(_testAgent('a-1', 'alpha', 'ws-1'));
      final agents = await future;
      expect(agents.any((a) => a.id == 'a-1'), isTrue);
    });

    test('contract — watchByWorkspace filters', () async {
      final repo = _TestAgentRepository();
      final future = repo.watchByWorkspace('ws-1').first;

      await repo.upsert(_testAgent('a-1', 'alpha', 'ws-1'));
      await repo.upsert(_testAgent('a-2', 'beta', 'ws-2'));

      final agents = await future;
      expect(agents.length, 1);
      expect(agents.first.id, 'a-1');
    });
  });

  // ---------------------------------------------------------------------------
  // RepoRepository
  // ---------------------------------------------------------------------------
  group('RepoRepository', () {
    test('contract — upsert creates and getById retrieves', () async {
      final repo = _TestRepoRepository();
      final testRepo = _testRepo('repo-1', 'acme/project');

      final id = await repo.upsert('ws-1', testRepo);
      expect(id, 'repo-1');

      final found = await repo.getById('ws-1', 'repo-1');
      expect(found, isNotNull);
      expect(found!.id, 'repo-1');
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestRepoRepository();
      expect(await repo.getById('ws-1', 'nonexistent'), isNull);
    });

    test(
      'contract — a repo id does not resolve in another workspace',
      () async {
        final repo = _TestRepoRepository();
        await repo.upsert('ws-1', _testRepo('r-1', 'acme/proj'));

        expect(await repo.getById('ws-2', 'r-1'), isNull);
        expect(await repo.exists('ws-2', 'r-1'), isFalse);
        expect(await repo.getAll('ws-2'), isEmpty);
      },
    );

    test('contract — upsert updates existing', () async {
      final repo = _TestRepoRepository();
      await repo.upsert('ws-1', _testRepo('r-1', 'old/name'));
      await repo.upsert('ws-1', _testRepo('r-1', 'new/name'));

      final found = await repo.getById('ws-1', 'r-1');
      expect(found!.name, 'new/name');
      expect(await repo.getAll('ws-1'), hasLength(1));
    });

    test('contract — findByPath is the cross-workspace identity', () async {
      final repo = _TestRepoRepository();
      // The same checkout registered in two workspaces is two rows with two
      // ids; only the path is stable across them.
      await repo.upsert('ws-1', _testRepo('r-1', 'acme/proj'));
      await repo.upsert('ws-2', _testRepo('r-2', 'acme/proj'));

      expect((await repo.findByPath('ws-1', '/tmp/r-1'))!.id, 'r-1');
      expect(await repo.findByPath('ws-1', '/tmp/r-2'), isNull);
      expect((await repo.findByPath('ws-2', '/tmp/r-2'))!.id, 'r-2');
    });

    test('contract — reorder re-sequences the workspace order', () async {
      final repo = _TestRepoRepository();
      await repo.upsert('ws-1', _testRepo('r-1', 'acme/a'));
      await repo.upsert('ws-1', _testRepo('r-2', 'acme/b'));
      await repo.upsert('ws-1', _testRepo('r-3', 'acme/c'));

      await repo.reorder('ws-1', ['r-3', 'r-1', 'r-2']);
      expect((await repo.getAll('ws-1')).map((r) => r.id), [
        'r-3',
        'r-1',
        'r-2',
      ]);
    });

    test('contract — delete removes repo', () async {
      final repo = _TestRepoRepository();
      await repo.upsert('ws-1', _testRepo('r-1', 'acme/temp'));
      await repo.delete('ws-1', 'r-1');
      expect(await repo.getById('ws-1', 'r-1'), isNull);
    });

    test('contract — watchAll emits on upsert', () async {
      final repo = _TestRepoRepository();
      final future = repo.watchAll('ws-1').first;

      await repo.upsert('ws-1', _testRepo('r-1', 'acme/proj'));
      final repos = await future;
      expect(repos.any((r) => r.id == 'r-1'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ReviewSpaceRepository
  // ---------------------------------------------------------------------------
  group('ReviewSpaceRepository', () {
    test('contract — create and watchByPr', () async {
      final repo = _TestReviewSpaceRepository();
      final assoc = await repo.create(
        spaceId: 'ch-1',
        workspaceId: 'ws-1',
        prExternalId: 'pr-node-42',
        prNumber: 42,
        repoFullName: 'acme/project',
      );

      expect(assoc.spaceId, 'ch-1');
      expect(assoc.prExternalId, 'pr-node-42');
      expect(assoc.status, ReviewSpaceStatus.requested);

      final stream = repo.watchByPr('ws-1', 'pr-node-42');
      final found = await stream.first;
      expect(found, isNotNull);
      expect(found!.prExternalId, 'pr-node-42');
    });

    test('contract — watchByPr returns null for unmatched', () async {
      final repo = _TestReviewSpaceRepository();
      final stream = repo.watchByPr('ws-1', 'nonexistent');
      final found = await stream.first;
      expect(found, isNull);
    });

    test('contract — watchBySpace', () async {
      final repo = _TestReviewSpaceRepository();
      await repo.create(
        spaceId: 'ch-2',
        workspaceId: 'ws-1',
        prExternalId: 'pr-node-99',
        prNumber: 99,
        repoFullName: 'acme/repo',
      );

      final stream = repo.watchBySpace('ws-1', 'ch-2');
      final found = await stream.first;
      expect(found, isNotNull);
      expect(found!.spaceId, 'ch-2');
    });

    test(
      'contract — watchAllBySpace returns every PR for a space',
      () async {
        final repo = _TestReviewSpaceRepository();
        await repo.create(
          spaceId: 'ch-multi',
          workspaceId: 'ws-1',
          prExternalId: 'pr-node-1',
          prNumber: 1,
          repoFullName: 'acme/a',
        );
        await repo.create(
          spaceId: 'ch-multi',
          workspaceId: 'ws-1',
          prExternalId: 'pr-node-2',
          prNumber: 2,
          repoFullName: 'acme/b',
        );
        // A different space must not bleed in.
        await repo.create(
          spaceId: 'ch-other',
          workspaceId: 'ws-1',
          prExternalId: 'pr-node-3',
          prNumber: 3,
          repoFullName: 'acme/c',
        );

        final list = await repo.watchAllBySpace('ws-1', 'ch-multi').first;
        expect(list.length, 2);
        expect(list.map((a) => a.prExternalId).toSet(), {'pr-node-1', 'pr-node-2'});
      },
    );

    test('contract — watchAllBySpace is workspace-scoped', () async {
      final repo = _TestReviewSpaceRepository();
      await repo.create(
        spaceId: 'ch-x',
        workspaceId: 'ws-1',
        prExternalId: 'pr-node-1',
        prNumber: 1,
        repoFullName: 'acme/a',
      );

      // Same space id, different workspace — must not be returned.
      final list = await repo.watchAllBySpace('ws-2', 'ch-x').first;
      expect(list, isEmpty);
    });

    test('contract — updateStatus', () async {
      final repo = _TestReviewSpaceRepository();
      final assoc = await repo.create(
        spaceId: 'ch-3',
        workspaceId: 'ws-1',
        prExternalId: 'pr-node-7',
        prNumber: 7,
        repoFullName: 'acme/repo',
      );

      expect(assoc.status, ReviewSpaceStatus.requested);
      await repo.updateStatus('ws-1', assoc.id, ReviewSpaceStatus.completed);

      final stream = repo.watchBySpace('ws-1', 'ch-3');
      final updated = await stream.first;
      expect(updated!.status, ReviewSpaceStatus.completed);
    });

    test('contract — watchByWorkspace returns all for workspace', () async {
      final repo = _TestReviewSpaceRepository();
      await repo.create(
        spaceId: 'ch-a',
        workspaceId: 'ws-1',
        prExternalId: 'pr-a',
        prNumber: 1,
        repoFullName: 'acme/a',
      );
      await repo.create(
        spaceId: 'ch-b',
        workspaceId: 'ws-2',
        prExternalId: 'pr-b',
        prNumber: 2,
        repoFullName: 'acme/b',
      );

      final stream = repo.watchByWorkspace('ws-1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.prExternalId, 'pr-a');
    });
  });

  // ---------------------------------------------------------------------------
  // IsolatedRepoRepository
  // ---------------------------------------------------------------------------
  group('IsolatedRepoRepository', () {
    test('contract — upsert and forUnitRepo', () async {
      final repo = _TestIsolatedRepoRepository();
      final ir = _testIsolatedRepo(
        'ir-1',
        'ws-1',
        'ch-1',
        'repo-1',
        '/tmp/isolated/repo-1',
        'feature/x',
      );

      await repo.upsert(ir);
      final found = await repo.forUnitRepo('ws-1', 'ch-1', 'repo-1');
      expect(found, isNotNull);
      expect(found!.id, 'ir-1');
      expect(found.branch, 'feature/x');
    });

    test('contract — forUnitRepo returns null for mismatch', () async {
      final repo = _TestIsolatedRepoRepository();
      expect(await repo.forUnitRepo('ws-1', 'ch-1', 'repo-1'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo(
          'ir-1',
          'ws-1',
          'ch-1',
          'repo-1',
          '/old',
          'feature/x',
        ),
      );
      await repo.upsert(
        _testIsolatedRepo(
          'ir-1',
          'ws-1',
          'ch-1',
          'repo-1',
          '/new',
          'feature/y',
        ),
      );

      final found = await repo.forUnitRepo('ws-1', 'ch-1', 'repo-1');
      expect(found!.path, '/new');
      expect(found.branch, 'feature/y');
    });

    test('contract — forSpace returns all for a conversation', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo('ir-1', 'ws-1', 'ch-1', 'r-1', '/p1', 'b1'),
      );
      await repo.upsert(
        _testIsolatedRepo('ir-2', 'ws-1', 'ch-1', 'r-2', '/p2', 'b2'),
      );
      await repo.upsert(
        _testIsolatedRepo('ir-3', 'ws-1', 'ch-2', 'r-3', '/p3', 'b3'),
      );

      final list = await repo.forSpace('ws-1', 'ch-1');
      expect(list.length, 2);
      final ids = list.map((i) => i.id).toSet();
      expect(ids, containsAll(['ir-1', 'ir-2']));
    });

    test('contract — forSpaceAcrossWorkspaces', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo('ir-1', 'ws-a', 'ch-x', 'r-1', '/p', 'b'),
      );

      final list = await repo.forSpaceAcrossWorkspaces('ch-x');
      expect(list.length, 1);
      expect(list.first.id, 'ir-1');
    });

    test('contract — forTicket', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo(
          'ir-1',
          'ws-1',
          'ch-1',
          'r-1',
          '/p',
          'b',
          ticketId: 'T-42',
        ),
      );

      final list = await repo.forTicket('ws-1', 'T-42');
      expect(list.length, 1);
    });

    test('contract — forTicketAcrossWorkspaces', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo(
          'ir-1',
          'ws-a',
          'ch-1',
          'r-1',
          '/p',
          'b',
          ticketId: 'T-99',
        ),
      );

      final list = await repo.forTicketAcrossWorkspaces('T-99');
      expect(list.length, 1);
    });

    test('contract — deleteById', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(
        _testIsolatedRepo('ir-1', 'ws-1', 'ch-1', 'r-1', '/p', 'b'),
      );
      await repo.deleteById('ws-1', 'ir-1');

      expect(await repo.forUnitRepo('ws-1', 'ch-1', 'r-1'), isNull);
    });

    test('contract — watchForWorkspace emits', () async {
      final repo = _TestIsolatedRepoRepository();
      final future = repo.watchForWorkspace('ws-1').first;

      await repo.upsert(
        _testIsolatedRepo('ir-w', 'ws-1', 'ch-1', 'r-1', '/p', 'b'),
      );

      final list = await future;
      expect(list.any((i) => i.id == 'ir-w'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // AgentRunLogRepository
  // ---------------------------------------------------------------------------
  group('AgentRunLogRepository', () {
    test('contract — upsert and getById', () async {
      final repo = _TestAgentRunLogRepository();
      final log = _testRunLog(
        'log-1',
        'agent-1',
        'ws-1',
        'conv-1',
        startedAt: _testDate,
        completedAt: _testDate2,
      );

      await repo.upsert(log);
      final found = await repo.getById('ws-1', 'log-1');

      expect(found, isNotNull);
      expect(found!.id, 'log-1');
      expect(found.agentId, 'agent-1');
      expect(found.status, RunStatus.completed);
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestAgentRunLogRepository();
      expect(await repo.getById('ws-1', 'nonexistent'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(
        _testRunLog(
          'log-1',
          'a-1',
          'ws-1',
          'c-1',
          startedAt: _testDate,
          status: RunStatus.running,
        ),
      );
      await repo.upsert(
        _testRunLog(
          'log-1',
          'a-1',
          'ws-1',
          'c-1',
          startedAt: _testDate,
          status: RunStatus.error,
          completedAt: _testDate2,
        ),
      );

      final found = await repo.getById('ws-1', 'log-1');
      expect(found!.status, RunStatus.error);
      expect(found.completedAt, isNotNull);
    });

    test('contract — watchByAgent emits', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(
        _testRunLog('log-a', 'agent-a', 'ws-1', 'c-1', startedAt: _testDate),
      );
      await repo.upsert(
        _testRunLog('log-b', 'agent-b', 'ws-1', 'c-2', startedAt: _testDate2),
      );

      final stream = repo.watchByAgent('ws-1', 'agent-a');
      final logs = await stream.first;
      expect(logs.length, 1);
      expect(logs.first.id, 'log-a');
    });

    test('contract — watchAll emits all logs', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(
        _testRunLog('log-1', 'a-1', 'ws-1', 'c-1', startedAt: _testDate),
      );

      final stream = repo.watchAll();
      final logs = await stream.first;
      expect(logs.length, 1);
    });

    test(
      'contract — watchActiveByConversation filters completed runs',
      () async {
        final repo = _TestAgentRunLogRepository();
        // Active run (no completedAt)
        await repo.upsert(
          _testRunLog(
            'active',
            'a-1',
            'ws-1',
            'conv-1',
            startedAt: _testDate,
            status: RunStatus.running,
          ),
        );
        // Completed run
        await repo.upsert(
          _testRunLog(
            'done',
            'a-1',
            'ws-1',
            'conv-1',
            startedAt: _testDate,
            status: RunStatus.completed,
            completedAt: _testDate2,
          ),
        );

        final stream = repo.watchActiveByConversation('ws-1', 'conv-1');
        final active = await stream.first;
        expect(active.length, 1);
        expect(active.first.id, 'active');
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Minimal test implementations of each repository interface
// ---------------------------------------------------------------------------

class _TestCacheRepository implements CacheRepository {
  final _store = <String, String>{};

  String _key(String workspaceId, String kind, String key) =>
      '$workspaceId|$kind|$key';

  @override
  Future<String?> read(String workspaceId, String kind, String key) async =>
      _store[_key(workspaceId, kind, key)];

  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {
    _store[_key(workspaceId, kind, key)] = payload;
  }

  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) async {
    _store.remove(_key(workspaceId, kind, key));
  }

  @override
  Future<void> deleteKind(String workspaceId, String kind) async {
    final prefix = '$workspaceId|$kind|';
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async {
    final prefix = '$workspaceId|$kind|$keyPrefix';
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }
}

class _TestWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();
  final Set<String> _repoLinks = {};

  void _emit() => _controller.add(List.unmodifiable(_workspaces));

  List<Workspace> getAllSync() => List.unmodifiable(_workspaces);

  @override
  Stream<List<Workspace>> watchAll() => _controller.stream;

  @override
  Future<List<Workspace>> getAll() async => List.unmodifiable(_workspaces);

  @override
  Future<Workspace?> getById(String id) async =>
      _workspaces.where((w) => w.id == id).firstOrNull;

  @override
  Future<String> upsert(Workspace workspace) async {
    final index = _workspaces.indexWhere((w) => w.id == workspace.id);
    if (index >= 0) {
      _workspaces[index] = workspace;
    } else {
      _workspaces.add(workspace);
    }
    _emit();
    return workspace.id;
  }

  @override
  Future<void> delete(String id) async {
    _workspaces.removeWhere((w) => w.id == id);
    _emit();
  }

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {
    final byId = {for (final w in _workspaces) w.id: w};
    final reordered = [
      for (final id in orderedIds)
        if (byId.remove(id) case final Workspace w) w, ...byId.values,
    ];
    _workspaces
      ..clear()
      ..addAll(reordered);
    _emit();
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {
    _repoLinks.removeWhere((l) => l.startsWith('$workspaceId/'));
    for (final id in repoIds) {
      _repoLinks.add('$workspaceId/$id');
    }
  }

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => _repoLinks.contains('$workspaceId/$repoId');

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {
    _repoLinks.remove('$workspaceId/$repoId');
  }
}

class _TestAgentRepository implements AgentRepository {
  /// Agents keyed by `workspaceId|agentId` — an agent id is unique only inside
  /// its own workspace's database.
  final Map<String, Agent> _agents = {};
  final _controller = StreamController<List<Agent>>.broadcast();

  String _key(String workspaceId, String id) => '$workspaceId|$id';

  void _emit() => _controller.add(_agents.values.toList());

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _controller.stream.map(
        (agents) => agents.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      _agents[_key(workspaceId, id)];

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in _agents.values) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    _agents[_key(agent.workspaceId, agent.id)] = agent;
    _emit();
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.remove(_key(workspaceId, id));
    _emit();
  }
}

class _TestRepoRepository implements RepoRepository {
  /// Repos keyed by workspace, each list in the operator's manual order. A repo
  /// id is per-workspace, so the same checkout in two workspaces is two rows.
  final Map<String, List<Repo>> _repos = {};
  final _controller = StreamController<List<Repo>>.broadcast();

  void _emit(String workspaceId) =>
      _controller.add(List.unmodifiable(_repos[workspaceId] ?? const []));

  @override
  Stream<List<Repo>> watchAll(String workspaceId) => _controller.stream;

  @override
  Future<List<Repo>> getAll(String workspaceId) async =>
      List.unmodifiable(_repos[workspaceId] ?? const []);

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      (_repos[workspaceId] ?? const [])
          .where((r) => r.id == repoId)
          .firstOrNull;

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async =>
      (_repos[workspaceId] ?? const [])
          .where((r) => r.path == path)
          .firstOrNull;

  @override
  Future<bool> exists(String workspaceId, String repoId) async =>
      await getById(workspaceId, repoId) != null;

  @override
  Future<String> upsert(String workspaceId, Repo repo) async {
    final list = _repos.putIfAbsent(workspaceId, () => <Repo>[]);
    final index = list.indexWhere((r) => r.id == repo.id);
    if (index >= 0) {
      list[index] = repo;
    } else {
      list.add(repo);
    }
    _emit(workspaceId);
    return repo.id;
  }

  @override
  Future<void> delete(String workspaceId, String repoId) async {
    _repos[workspaceId]?.removeWhere((r) => r.id == repoId);
    _emit(workspaceId);
  }

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) async {
    final list = _repos[workspaceId];
    if (list == null) {
      return;
    }
    final byId = {for (final r in list) r.id: r};
    final reordered = [
      for (final id in orderedIds)
        if (byId.remove(id) case final Repo r) r, ...byId.values,
    ];
    list
      ..clear()
      ..addAll(reordered);
    _emit(workspaceId);
  }
}

class _TestReviewSpaceRepository implements ReviewSpaceRepository {
  final Map<String, ReviewSpaceAssociation> _assocs = {};
  int _nextId = 1;

  @override
  Stream<ReviewSpaceAssociation?> watchByPr(
    String workspaceId,
    String prExternalId,
  ) {
    final found = _assocs.values.where(
      (a) => a.workspaceId == workspaceId && a.prExternalId == prExternalId,
    );
    return Stream.value(found.isNotEmpty ? found.first : null);
  }

  @override
  Stream<ReviewSpaceAssociation?> watchBySpace(
    String workspaceId,
    String spaceId,
  ) {
    final found = _assocs.values.where(
      (a) => a.workspaceId == workspaceId && a.spaceId == spaceId,
    );
    return Stream.value(found.isNotEmpty ? found.first : null);
  }

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) {
    final found =
        _assocs.values
            .where(
              (a) => a.workspaceId == workspaceId && a.spaceId == spaceId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Stream.value(found);
  }

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) {
    return Stream.value(
      _assocs.values.where((a) => a.workspaceId == workspaceId).toList(),
    );
  }

  @override
  Future<ReviewSpaceAssociation> create({
    required String spaceId,
    required String workspaceId,
    required String prExternalId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final id = 'rca-${_nextId++}';
    final assoc = ReviewSpaceAssociation(
      id: id,
      spaceId: spaceId,
      workspaceId: workspaceId,
      prExternalId: prExternalId,
      prNumber: prNumber,
      repoFullName: repoFullName,
      status: ReviewSpaceStatus.requested,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _assocs[id] = assoc;
    return assoc;
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String id,
    ReviewSpaceStatus status,
  ) async {
    final assoc = _assocs[id];
    if (assoc != null && assoc.workspaceId == workspaceId) {
      _assocs[id] = assoc.copyWith(status: status);
    }
  }
}

class _TestIsolatedRepoRepository implements IsolatedRepoRepository {
  final Map<String, IsolatedRepo> _repos = {};
  final _controller = StreamController<List<IsolatedRepo>>.broadcast();

  void _emit() => _controller.add(_repos.values.toList());

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    for (final ir in _repos.values) {
      if (ir.workspaceId == workspaceId &&
          ir.spaceId == spaceId &&
          ir.repoId == repoId) {
        return ir;
      }
    }
    return null;
  }

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async {
    return _repos.values
        .where(
          (ir) => ir.workspaceId == workspaceId && ir.spaceId == spaceId,
        )
        .toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    return _repos.values
        .where((ir) => ir.workspaceId == workspaceId && ir.ticketId == ticketId)
        .toList();
  }

  @override
  Future<List<IsolatedRepo>> forSpaceAcrossWorkspaces(
    String spaceId,
  ) async {
    return _repos.values.where((ir) => ir.spaceId == spaceId).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async {
    return _repos.values.where((ir) => ir.ticketId == ticketId).toList();
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      _controller.stream.map(
        (list) => list.where((ir) => ir.workspaceId == workspaceId).toList(),
      );

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    _repos[repo.id] = repo;
    _emit();
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    _repos.removeWhere((_, ir) => ir.id == id && ir.workspaceId == workspaceId);
    _emit();
  }
}

class _TestAgentRunLogRepository implements AgentRunLogRepository {
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => _logs.values
      .where(
        (l) =>
            l.workspaceId == workspaceId &&
            l.conversationId == conversationId &&
            l.completedAt == null,
      )
      .toList();

  final Map<String, AgentRunLog> _logs = {};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final log = _logs[id];
    return log != null && log.workspaceId == workspaceId ? log : null;
  }

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];
  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(
        _logs.values
            .where((l) => l.workspaceId == workspaceId && l.agentId == agentId)
            .toList(),
      );

  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value(_logs.values.toList());

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => watchAll().map(
    (logs) => logs.length <= limit ? logs : logs.sublist(0, limit),
  );

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchBySpace(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) {
    return Stream.value(
      _logs.values
          .where(
            (l) =>
                l.workspaceId == workspaceId &&
                l.conversationId == conversationId &&
                l.completedAt == null,
          )
          .toList(),
    );
  }

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String conversationId,
  ) {
    return Stream.value(
      _logs.values
          .where(
            (l) =>
                l.workspaceId == workspaceId &&
                l.conversationId == conversationId &&
                l.completedAt == null,
          )
          .toList(),
    );
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    _logs[log.id] = log;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Workspace _testWorkspace(String id, String name) =>
    Workspace(id: id, name: name, createdAt: _testDate, updatedAt: _testDate);

Agent _testAgent(String id, String name, String workspaceId) => Agent(
  id: id,
  name: name,
  title: name,
  agentMdPath: '/agents/$name.md',
  workspaceId: workspaceId,
  skills: AgentSkills(['coding']),
  createdAt: _testDate,
);

Repo _testRepo(String id, String name) => Repo(
  id: id,
  name: name,
  path: '/tmp/$id',
  remoteOwner: 'acme',
  remoteName: name.split('/').last,
  createdAt: _testDate,
  updatedAt: _testDate,
);

IsolatedRepo _testIsolatedRepo(
  String id,
  String workspaceId,
  String spaceId,
  String repoId,
  String path,
  String branch, {
  String? ticketId,
}) => IsolatedRepo(
  id: id,
  workspaceId: workspaceId,
  spaceId: spaceId,
  repoId: repoId,
  path: path,
  branch: branch,
  backend: RepoIsolationBackend.rift,
  sourcePath: '/tmp/source/$repoId',
  createdAt: _testDate,
  ticketId: ticketId,
);

AgentRunLog _testRunLog(
  String id,
  String agentId,
  String workspaceId,
  String conversationId, {
  required DateTime startedAt,
  DateTime? completedAt,
  RunStatus status = RunStatus.completed,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: workspaceId,
  conversationId: conversationId,
  startedAt: startedAt,
  completedAt: completedAt,
  status: status,
  cost: RunCost.zero,
);
