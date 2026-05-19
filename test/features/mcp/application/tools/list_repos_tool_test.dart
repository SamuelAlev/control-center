import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_mcp/src/tools/list_repos_tool.dart';
import 'package:flutter_test/flutter_test.dart';


class _FakeRepoRepository implements RepoRepository {
  final List<Repo> _repos = [];

  void addRepo(Repo r) => _repos.add(r);

  @override
  Stream<List<Repo>> watchAll() => Stream.value(_repos);

  @override
  Future<Repo?> getById(String id) async =>
      _repos.where((r) => r.id == id).firstOrNull;

  @override
  Future<String> upsert(Repo repo) async {
    _repos.add(repo);
    return repo.id;
  }

  @override
  Future<void> delete(String id) async {
    _repos.removeWhere((r) => r.id == id);
  }
}

class _FakeWsRepo implements WorkspaceRepository {
  final Map<String, List<Repo>> _reposByWorkspace = {};

  void setReposForTest(String wsId, List<Repo> repos) {
    _reposByWorkspace[wsId] = repos;
  }

  @override
  Stream<List<Workspace>> watchAll() => Stream.value([]);

  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(_reposByWorkspace[workspaceId] ?? []);

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) async {}

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async =>
      false;

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {}

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) async {}
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
    late _FakeWsRepo workspaceRepo;
    late ListReposTool tool;

    setUp(() {
      repoRepo = _FakeRepoRepository();
      workspaceRepo = _FakeWsRepo();
      tool = ListReposTool(
        repoRepository: repoRepo,
        workspaceRepository: workspaceRepo,
      );
    });

    test('has correct name', () {
      expect(tool.name, 'list_repos');
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(((schema['properties'] as Map<String, dynamic>)['workspace_id'] as Map<String, dynamic>)['type'], 'string');
    });

    test('returns all repos when no workspace filter', () async {
      repoRepo.addRepo(_repo(id: 'r-1'));
      repoRepo.addRepo(_repo(id: 'r-2', name: 'acme/lib'));

      final result = await tool.call({});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
      expect(((data['repos'] as List<dynamic>)[0] as Map<String, dynamic>)['id'], 'r-1');
    });

    test('filters by workspace_id', () async {
      workspaceRepo.setReposForTest('ws-1', [
        _repo(id: 'r-1'),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['repos'] as List<dynamic>)[0] as Map<String, dynamic>)['linked_to_workspace'], isTrue);
    });

    test('includes repo fields', () async {
      repoRepo.addRepo(_repo());

      final result = await tool.call({});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final repo = (data['repos'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(repo['full_name'], 'acme/app');
      expect(repo['local_path'], '/repos/app');
    });

    test('respects limit', () async {
      for (var i = 0; i < 10; i++) {
        repoRepo.addRepo(_repo(id: 'r-$i'));
      }

      final result = await tool.call({'limit': 3});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 3);
    });
  });
}
