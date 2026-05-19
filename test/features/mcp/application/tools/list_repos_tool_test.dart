import 'dart:convert';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_mcp/src/tools/list_repos_tool.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [RepoRepository] keyed by workspace.
///
/// Repos are workspace-scoped, so a repo id resolves only inside the workspace
/// that registered it. Every read here filters by workspace exactly like the
/// DAO does, which is what makes the isolation assertions below meaningful.
class _FakeRepoRepository implements RepoRepository {
  final Map<String, List<Repo>> _byWorkspace = {};

  /// Registers [r] into [workspaceId].
  void addRepo(String workspaceId, Repo r) =>
      _byWorkspace.putIfAbsent(workspaceId, () => []).add(r);

  List<Repo> _repos(String workspaceId) =>
      _byWorkspace[workspaceId] ?? const <Repo>[];

  @override
  Stream<List<Repo>> watchAll(String workspaceId) =>
      Stream.value(_repos(workspaceId));

  @override
  Future<List<Repo>> getAll(String workspaceId) async => _repos(workspaceId);

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async =>
      _repos(workspaceId).where((r) => r.id == repoId).firstOrNull;

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async =>
      _repos(workspaceId).where((r) => r.path == path).firstOrNull;

  @override
  Future<bool> exists(String workspaceId, String repoId) async =>
      _repos(workspaceId).any((r) => r.id == repoId);

  @override
  Future<String> upsert(String workspaceId, Repo repo) async {
    final repos = _byWorkspace.putIfAbsent(workspaceId, () => []);
    final index = repos.indexWhere((r) => r.id == repo.id);
    if (index >= 0) {
      repos[index] = repo;
    } else {
      repos.add(repo);
    }
    return repo.id;
  }

  @override
  Future<void> delete(String workspaceId, String repoId) async {
    _byWorkspace[workspaceId]?.removeWhere((r) => r.id == repoId);
  }

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) async {
    final repos = _byWorkspace[workspaceId];
    if (repos == null) {
      return;
    }
    // Ids the workspace does not own are ignored: an id cannot conjure a repo.
    final byId = {for (final r in repos) r.id: r};
    final reordered = <Repo>[];
    for (final id in orderedIds) {
      final repo = byId.remove(id);
      if (repo != null) {
        reordered.add(repo);
      }
    }
    _byWorkspace[workspaceId] = [...reordered, ...byId.values];
  }
}

class _FakeIsolatedRepoRepository implements IsolatedRepoRepository {
  final Map<String, IsolatedRepo> _byKey = {};

  void add(IsolatedRepo r) =>
      _byKey['${r.workspaceId}|${r.channelId}|${r.repoId}'] = r;

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async => _byKey['$workspaceId|$channelId|$repoId'];

  @override
  Future<List<IsolatedRepo>> forChannel(
    String workspaceId,
    String channelId,
  ) async => [
    for (final r in _byKey.values)
      if (r.workspaceId == workspaceId && r.channelId == channelId) r,
  ];

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async => const [];

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(
    String channelId,
  ) async => const [];

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async =>
      const [];

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  Future<void> upsert(IsolatedRepo repo) async => add(repo);

  @override
  Future<void> deleteById(String workspaceId, String id) async {}
}

IsolatedRepo _worktree({
  String workspaceId = 'ws-1',
  String channelId = 'conv-1',
  String repoId = 'r-1',
  String path = '/data/ws-1/conversations/conv-1/repos/app',
  String branch = 'conv/abc12345',
}) {
  return IsolatedRepo(
    id: 'iso-$repoId',
    workspaceId: workspaceId,
    channelId: channelId,
    repoId: repoId,
    path: path,
    branch: branch,
    backend: RepoIsolationBackend.rift,
    sourcePath: '/repos/app',
    createdAt: DateTime(2026, 1, 1),
  );
}

Repo _repo({
  String id = 'r-1',
  String name = 'acme/app',
  String path = '/repos/app',
  String owner = 'acme',
  String repoName = 'app',
}) {
  return Repo(
    id: id,
    name: name,
    path: path,
    githubOwner: owner,
    githubRepoName: repoName,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ListReposTool', () {
    late _FakeRepoRepository repoRepo;
    late _FakeIsolatedRepoRepository isolatedRepo;
    late ListReposTool tool;

    setUp(() {
      repoRepo = _FakeRepoRepository();
      isolatedRepo = _FakeIsolatedRepoRepository();
      tool = ListReposTool(
        repoRepository: repoRepo,
        isolatedRepoRepository: isolatedRepo,
      );
    });

    test('has correct name', () {
      expect(tool.name, 'list_repos');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(
        ((schema['properties'] as Map<String, dynamic>)['workspace_id']
            as Map<String, dynamic>)['type'],
        'string',
      );
      expect(schema['required'], contains('workspace_id'));
    });

    test('rejects a call with no workspace_id', () async {
      repoRepo.addRepo('ws-1', _repo(id: 'r-1'));

      final result = await tool.call({});

      expect(result.isError, isTrue);
      expect(
        result.content.first.text,
        'Missing or invalid argument: workspace_id',
      );
    });

    test('lists the workspace\'s repos and nothing else', () async {
      repoRepo.addRepo('ws-1', _repo(id: 'r-1'));
      repoRepo.addRepo('ws-1', _repo(id: 'r-2', name: 'acme/lib'));
      // A repo registered in another workspace lives in another database file.
      repoRepo.addRepo('ws-2', _repo(id: 'r-3', name: 'acme/other'));

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
      expect(
        (data['repos'] as List<dynamic>).map(
          (r) => (r as Map<String, dynamic>)['id'],
        ),
        ['r-1', 'r-2'],
      );
      expect(result.content.first.text, isNot(contains('r-3')));
    });

    test('a workspace with no repos of its own returns nothing', () async {
      repoRepo.addRepo('ws-2', _repo(id: 'r-1'));

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 0);
      expect(data['repos'], isEmpty);
    });

    test('includes repo fields', () async {
      repoRepo.addRepo('ws-1', _repo());

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final repo = (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(repo['full_name'], 'acme/app');
      expect(repo['local_path'], '/repos/app');
    });

    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        repoRepo.addRepo('ws-1', _repo(id: 'r-$i'));
      }

      final result = await tool.call({'workspace_id': 'ws-1', 'limit': 3});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });

    group('conversation scope (agent callers)', () {
      test('local_path is the isolated worktree, never the original', () async {
        repoRepo.addRepo('ws-1', _repo());
        isolatedRepo.add(_worktree());

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'conversation_id': 'conv-1',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        final repo =
            (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
        expect(repo['local_path'], '/data/ws-1/conversations/conv-1/repos/app');
        expect(repo['is_isolated_copy'], isTrue);
        expect(repo['branch'], 'conv/abc12345');
        expect(data['note'], contains('isolated working copy'));
        // The original checkout path appears nowhere in the payload.
        expect(result.content.first.text, isNot(contains('"/repos/app"')));
      });

      test('repo without a worktree reports null local_path — not the '
          'original', () async {
        repoRepo.addRepo('ws-1', _repo());

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'conversation_id': 'conv-1',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        final repo =
            (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
        expect(repo['local_path'], isNull);
        expect(repo['is_isolated_copy'], isFalse);
        expect(result.content.first.text, isNot(contains('"/repos/app"')));
      });

      test('a worktree from another workspace is not resolved', () async {
        repoRepo.addRepo('ws-1', _repo());
        // Same conversation id and repo id, but registered under ws-2.
        isolatedRepo.add(_worktree(workspaceId: 'ws-2'));

        final result = await tool.call({
          'workspace_id': 'ws-1',
          'conversation_id': 'conv-1',
        });

        final data =
            jsonDecode(result.content.first.text) as Map<String, dynamic>;
        final repo =
            (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
        expect(repo['local_path'], isNull);
        expect(repo['is_isolated_copy'], isFalse);
      });

      test(
        'non-GitHub repo full_name does not leak the original path',
        () async {
          repoRepo.addRepo(
            'ws-1',
            _repo(name: 'local-only', owner: '', repoName: ''),
          );
          isolatedRepo.add(_worktree());

          final result = await tool.call({
            'workspace_id': 'ws-1',
            'conversation_id': 'conv-1',
          });

          final data =
              jsonDecode(result.content.first.text) as Map<String, dynamic>;
          final repo =
              (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
          expect(repo['full_name'], 'local-only');
        },
      );

      test(
        'unscoped callers keep the original path (human/inspector surface)',
        () async {
          repoRepo.addRepo('ws-1', _repo());

          final result = await tool.call({'workspace_id': 'ws-1'});

          final data =
              jsonDecode(result.content.first.text) as Map<String, dynamic>;
          final repo =
              (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
          expect(repo['local_path'], '/repos/app');
          expect(data.containsKey('note'), isFalse);
        },
      );

      test('schema declares conversation_id so the call scope injects it', () {
        final props = tool.inputSchema['properties'] as Map<String, dynamic>;
        expect(props.containsKey('conversation_id'), isTrue);
      });
    });
  });
}
