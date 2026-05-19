import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/repositories/cache_repository.dart';
import 'package:control_center/core/domain/repositories/isolated_repo_repository.dart';
import 'package:control_center/core/domain/repositories/repo_repository.dart';
import 'package:control_center/core/domain/repositories/review_channel_repository.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
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

    test('contract — delete removes workspace', () async {
      final repo = _TestWorkspaceRepository();
      await repo.upsert(_testWorkspace('ws-1', 'To Delete'));
      await repo.delete('ws-1');

      final ws = repo.getAllSync();
      expect(ws.where((w) => w.id == 'ws-1'), isEmpty);
    });

    test('contract — linkRepoToWorkspace and isRepoLinkedToWorkspace', () async {
      final repo = _TestWorkspaceRepository();
      await repo.linkRepoToWorkspace('ws-1', 'repo-1');
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-1'), isTrue);
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-2'), isFalse);
    });

    test('contract — unlinkRepoFromWorkspace', () async {
      final repo = _TestWorkspaceRepository();
      await repo.linkRepoToWorkspace('ws-1', 'repo-1');
      await repo.unlinkRepoFromWorkspace('ws-1', 'repo-1');
      expect(await repo.isRepoLinkedToWorkspace('ws-1', 'repo-1'), isFalse);
    });

    test('contract — setReposForWorkspace replaces links', () async {
      final repo = _TestWorkspaceRepository();
      await repo.linkRepoToWorkspace('ws-1', 'old-1');
      await repo.linkRepoToWorkspace('ws-1', 'old-2');

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
      final found = await repo.getById('agent-1');

      expect(found, isNotNull);
      expect(found!.id, 'agent-1');
      expect(found.name, 'builder');
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestAgentRepository();
      expect(await repo.getById('nonexistent'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestAgentRepository();
      await repo.upsert(_testAgent('a-1', 'alpha', 'ws-1'));
      await repo.upsert(_testAgent('a-1', 'beta', 'ws-2'));

      final found = await repo.getById('a-1');
      expect(found!.name, 'beta');
      expect(found.workspaceId, 'ws-2');
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
      await repo.delete('a-1');
      expect(await repo.getById('a-1'), isNull);
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

      final id = await repo.upsert(testRepo);
      expect(id, 'repo-1');

      final found = await repo.getById('repo-1');
      expect(found, isNotNull);
      expect(found!.id, 'repo-1');
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestRepoRepository();
      expect(await repo.getById('nonexistent'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestRepoRepository();
      await repo.upsert(_testRepo('r-1', 'old/name'));
      await repo.upsert(_testRepo('r-1', 'new/name'));

      final found = await repo.getById('r-1');
      expect(found!.name, 'new/name');
    });

    test('contract — delete removes repo', () async {
      final repo = _TestRepoRepository();
      await repo.upsert(_testRepo('r-1', 'acme/temp'));
      await repo.delete('r-1');
      expect(await repo.getById('r-1'), isNull);
    });

    test('contract — watchAll emits on upsert', () async {
      final repo = _TestRepoRepository();
      final future = repo.watchAll().first;

      await repo.upsert(_testRepo('r-1', 'acme/proj'));
      final repos = await future;
      expect(repos.any((r) => r.id == 'r-1'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ReviewChannelRepository
  // ---------------------------------------------------------------------------
  group('ReviewChannelRepository', () {
    test('contract — create and watchByPr', () async {
      final repo = _TestReviewChannelRepository();
      final assoc = await repo.create(
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        prNodeId: 'pr-node-42',
        prNumber: 42,
        repoFullName: 'acme/project',
      );

      expect(assoc.channelId, 'ch-1');
      expect(assoc.prNodeId, 'pr-node-42');
      expect(assoc.status, ReviewChannelStatus.requested);

      final stream = repo.watchByPr('ws-1', 'pr-node-42');
      final found = await stream.first;
      expect(found, isNotNull);
      expect(found!.prNodeId, 'pr-node-42');
    });

    test('contract — watchByPr returns null for unmatched', () async {
      final repo = _TestReviewChannelRepository();
      final stream = repo.watchByPr('ws-1', 'nonexistent');
      final found = await stream.first;
      expect(found, isNull);
    });

    test('contract — watchByChannel', () async {
      final repo = _TestReviewChannelRepository();
      await repo.create(
        channelId: 'ch-2',
        workspaceId: 'ws-1',
        prNodeId: 'pr-node-99',
        prNumber: 99,
        repoFullName: 'acme/repo',
      );

      final stream = repo.watchByChannel('ch-2');
      final found = await stream.first;
      expect(found, isNotNull);
      expect(found!.channelId, 'ch-2');
    });

    test('contract — updateStatus', () async {
      final repo = _TestReviewChannelRepository();
      final assoc = await repo.create(
        channelId: 'ch-3',
        workspaceId: 'ws-1',
        prNodeId: 'pr-node-7',
        prNumber: 7,
        repoFullName: 'acme/repo',
      );

      expect(assoc.status, ReviewChannelStatus.requested);
      await repo.updateStatus(assoc.id, ReviewChannelStatus.completed);

      final stream = repo.watchByChannel('ch-3');
      final updated = await stream.first;
      expect(updated!.status, ReviewChannelStatus.completed);
    });

    test('contract — watchByWorkspace returns all for workspace', () async {
      final repo = _TestReviewChannelRepository();
      await repo.create(
        channelId: 'ch-a',
        workspaceId: 'ws-1',
        prNodeId: 'pr-a',
        prNumber: 1,
        repoFullName: 'acme/a',
      );
      await repo.create(
        channelId: 'ch-b',
        workspaceId: 'ws-2',
        prNodeId: 'pr-b',
        prNumber: 2,
        repoFullName: 'acme/b',
      );

      final stream = repo.watchByWorkspace('ws-1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.prNodeId, 'pr-a');
    });
  });

  // ---------------------------------------------------------------------------
  // IsolatedRepoRepository
  // ---------------------------------------------------------------------------
  group('IsolatedRepoRepository', () {
    test('contract — upsert and forUnitRepo', () async {
      final repo = _TestIsolatedRepoRepository();
      final ir = _testIsolatedRepo(
        'ir-1', 'ws-1', 'ch-1', 'repo-1', '/tmp/isolated/repo-1', 'feature/x',
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
      await repo.upsert(_testIsolatedRepo(
        'ir-1', 'ws-1', 'ch-1', 'repo-1', '/old', 'feature/x',
      ));
      await repo.upsert(_testIsolatedRepo(
        'ir-1', 'ws-1', 'ch-1', 'repo-1', '/new', 'feature/y',
      ));

      final found = await repo.forUnitRepo('ws-1', 'ch-1', 'repo-1');
      expect(found!.path, '/new');
      expect(found.branch, 'feature/y');
    });

    test('contract — forChannel returns all for a conversation', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(_testIsolatedRepo('ir-1', 'ws-1', 'ch-1', 'r-1', '/p1', 'b1'));
      await repo.upsert(_testIsolatedRepo('ir-2', 'ws-1', 'ch-1', 'r-2', '/p2', 'b2'));
      await repo.upsert(_testIsolatedRepo('ir-3', 'ws-1', 'ch-2', 'r-3', '/p3', 'b3'));

      final list = await repo.forChannel('ws-1', 'ch-1');
      expect(list.length, 2);
      final ids = list.map((i) => i.id).toSet();
      expect(ids, containsAll(['ir-1', 'ir-2']));
    });

    test('contract — forChannelAcrossWorkspaces', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(_testIsolatedRepo('ir-1', 'ws-a', 'ch-x', 'r-1', '/p', 'b'));

      final list = await repo.forChannelAcrossWorkspaces('ch-x');
      expect(list.length, 1);
      expect(list.first.id, 'ir-1');
    });

    test('contract — forTicket', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(_testIsolatedRepo(
        'ir-1', 'ws-1', 'ch-1', 'r-1', '/p', 'b', ticketId: 'T-42',
      ));

      final list = await repo.forTicket('ws-1', 'T-42');
      expect(list.length, 1);
    });

    test('contract — forTicketAcrossWorkspaces', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(_testIsolatedRepo(
        'ir-1', 'ws-a', 'ch-1', 'r-1', '/p', 'b', ticketId: 'T-99',
      ));

      final list = await repo.forTicketAcrossWorkspaces('T-99');
      expect(list.length, 1);
    });

    test('contract — deleteById', () async {
      final repo = _TestIsolatedRepoRepository();
      await repo.upsert(_testIsolatedRepo('ir-1', 'ws-1', 'ch-1', 'r-1', '/p', 'b'));
      await repo.deleteById('ir-1');

      expect(await repo.forUnitRepo('ws-1', 'ch-1', 'r-1'), isNull);
    });

    test('contract — watchForWorkspace emits', () async {
      final repo = _TestIsolatedRepoRepository();
      final future = repo.watchForWorkspace('ws-1').first;

      await repo.upsert(_testIsolatedRepo('ir-w', 'ws-1', 'ch-1', 'r-1', '/p', 'b'));

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
      final log = _testRunLog('log-1', 'agent-1', 'ws-1', 'conv-1',
          startedAt: _testDate, completedAt: _testDate2);

      await repo.upsert(log);
      final found = await repo.getById('log-1');

      expect(found, isNotNull);
      expect(found!.id, 'log-1');
      expect(found.agentId, 'agent-1');
      expect(found.status, RunStatus.completed);
    });

    test('contract — getById returns null for missing', () async {
      final repo = _TestAgentRunLogRepository();
      expect(await repo.getById('nonexistent'), isNull);
    });

    test('contract — upsert updates existing', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(_testRunLog('log-1', 'a-1', 'ws-1', 'c-1',
          startedAt: _testDate, status: RunStatus.running));
      await repo.upsert(_testRunLog('log-1', 'a-1', 'ws-1', 'c-1',
          startedAt: _testDate, status: RunStatus.error,
          completedAt: _testDate2));

      final found = await repo.getById('log-1');
      expect(found!.status, RunStatus.error);
      expect(found.completedAt, isNotNull);
    });

    test('contract — watchByAgent emits', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(_testRunLog('log-a', 'agent-a', 'ws-1', 'c-1',
          startedAt: _testDate));
      await repo.upsert(_testRunLog('log-b', 'agent-b', 'ws-1', 'c-2',
          startedAt: _testDate2));

      final stream = repo.watchByAgent('ws-1', 'agent-a');
      final logs = await stream.first;
      expect(logs.length, 1);
      expect(logs.first.id, 'log-a');
    });

    test('contract — watchAll emits all logs', () async {
      final repo = _TestAgentRunLogRepository();
      await repo.upsert(_testRunLog('log-1', 'a-1', 'ws-1', 'c-1',
          startedAt: _testDate));

      final stream = repo.watchAll();
      final logs = await stream.first;
      expect(logs.length, 1);
    });

    test('contract — watchActiveByConversation filters completed runs', () async {
      final repo = _TestAgentRunLogRepository();
      // Active run (no completedAt)
      await repo.upsert(_testRunLog('active', 'a-1', 'ws-1', 'conv-1',
          startedAt: _testDate, status: RunStatus.running));
      // Completed run
      await repo.upsert(_testRunLog('done', 'a-1', 'ws-1', 'conv-1',
          startedAt: _testDate, status: RunStatus.completed,
          completedAt: _testDate2));

      final stream = repo.watchActiveByConversation('ws-1', 'conv-1');
      final active = await stream.first;
      expect(active.length, 1);
      expect(active.first.id, 'active');
    });
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
  ) async =>
      _repoLinks.contains('$workspaceId/$repoId');

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {
    _repoLinks.add('$workspaceId/$repoId');
  }

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {
    _repoLinks.remove('$workspaceId/$repoId');
  }
}

class _TestAgentRepository implements AgentRepository {
  final Map<String, Agent> _agents = {};
  final _controller = StreamController<List<Agent>>.broadcast();

  void _emit() => _controller.add(_agents.values.toList());

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _controller.stream.map(
        (agents) => agents.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String id) async => _agents[id];

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
    for (final a in _agents.values) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    _agents[agent.id] = agent;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _agents.remove(id);
    _emit();
  }
}

class _TestRepoRepository implements RepoRepository {
  final Map<String, Repo> _repos = {};
  final _controller = StreamController<List<Repo>>.broadcast();

  void _emit() => _controller.add(_repos.values.toList());

  @override
  Stream<List<Repo>> watchAll() => _controller.stream;

  @override
  Future<Repo?> getById(String id) async => _repos[id];

  @override
  Future<String> upsert(Repo repo) async {
    _repos[repo.id] = repo;
    _emit();
    return repo.id;
  }

  @override
  Future<void> delete(String id) async {
    _repos.remove(id);
    _emit();
  }
}

class _TestReviewChannelRepository implements ReviewChannelRepository {
  final Map<String, ReviewChannelAssociation> _assocs = {};
  int _nextId = 1;

  @override
  Stream<ReviewChannelAssociation?> watchByPr(
    String workspaceId,
    String prNodeId,
  ) {
    final found = _assocs.values.where(
      (a) => a.workspaceId == workspaceId && a.prNodeId == prNodeId,
    );
    return Stream.value(found.isNotEmpty ? found.first : null);
  }

  @override
  Stream<ReviewChannelAssociation?> watchByChannel(String channelId) {
    final found = _assocs.values.where((a) => a.channelId == channelId);
    return Stream.value(found.isNotEmpty ? found.first : null);
  }

  @override
  Stream<List<ReviewChannelAssociation>> watchByWorkspace(
    String workspaceId,
  ) {
    return Stream.value(
      _assocs.values.where((a) => a.workspaceId == workspaceId).toList(),
    );
  }

  @override
  Future<ReviewChannelAssociation> create({
    required String channelId,
    required String workspaceId,
    required String prNodeId,
    required int prNumber,
    required String repoFullName,
  }) async {
    final id = 'rca-${_nextId++}';
    final assoc = ReviewChannelAssociation(
      id: id,
      channelId: channelId,
      workspaceId: workspaceId,
      prNodeId: prNodeId,
      prNumber: prNumber,
      repoFullName: repoFullName,
      status: ReviewChannelStatus.requested,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _assocs[id] = assoc;
    return assoc;
  }

  @override
  Future<void> updateStatus(String id, ReviewChannelStatus status) async {
    final assoc = _assocs[id];
    if (assoc != null) {
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
    String channelId,
    String repoId,
  ) async {
    for (final ir in _repos.values) {
      if (ir.workspaceId == workspaceId &&
          ir.channelId == channelId &&
          ir.repoId == repoId) {
        return ir;
      }
    }
    return null;
  }

  @override
  Future<List<IsolatedRepo>> forChannel(
    String workspaceId,
    String channelId,
  ) async {
    return _repos.values.where(
      (ir) => ir.workspaceId == workspaceId && ir.channelId == channelId,
    ).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    return _repos.values.where(
      (ir) => ir.workspaceId == workspaceId && ir.ticketId == ticketId,
    ).toList();
  }

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(
    String channelId,
  ) async {
    return _repos.values.where((ir) => ir.channelId == channelId).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(
    String ticketId,
  ) async {
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
  Future<void> deleteById(String id) async {
    _repos.remove(id);
    _emit();
  }
}

class _TestAgentRunLogRepository implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async => null;

  final Map<String, AgentRunLog> _logs = {};

  @override
  Future<AgentRunLog?> getById(String id) async => _logs[id];

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
  Stream<List<AgentRunLog>> watchAll() =>
      Stream.value(_logs.values.toList());

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) {
    return Stream.value(
      _logs.values.where(
        (l) =>
            l.workspaceId == workspaceId &&
            l.conversationId == conversationId &&
            l.completedAt == null,
      ).toList(),
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

Workspace _testWorkspace(String id, String name) => Workspace(
      id: id,
      name: name,
      createdAt: _testDate,
      updatedAt: _testDate,
    );

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
      githubOwner: 'acme',
      githubRepoName: name.split('/').last,
      createdAt: _testDate,
      updatedAt: _testDate,
    );

IsolatedRepo _testIsolatedRepo(
  String id,
  String workspaceId,
  String channelId,
  String repoId,
  String path,
  String branch, {
  String? ticketId,
}) =>
    IsolatedRepo(
      id: id,
      workspaceId: workspaceId,
      channelId: channelId,
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
}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      startedAt: startedAt,
      completedAt: completedAt,
      status: status,
      cost: RunCost.zero,
    );
