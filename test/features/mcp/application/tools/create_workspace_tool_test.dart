import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_mcp/src/tools/create_workspace_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();
  List<String>? lastRepoIds;
  String? lastWorkspaceId;

  List<Workspace> get saved => List.unmodifiable(_workspaces);

  void emit() => _controller.add(List.unmodifiable(_workspaces));

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
    emit();
    return workspace.id;
  }

  @override
  Future<void> delete(String id) async {
    _workspaces.removeWhere((w) => w.id == id);
    emit();
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    return Stream.value(const []);
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {
    lastWorkspaceId = workspaceId;
    lastRepoIds = repoIds;
  }

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async =>
      false;

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {}

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  void dispose() => _controller.close();
}

void main() {
  group('CreateWorkspaceTool', () {
    late _FakeWorkspaceRepository repository;
    late CreateWorkspaceTool tool;

    setUp(() {
      repository = _FakeWorkspaceRepository();
      tool = CreateWorkspaceTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'create_workspace');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
      expect(tool.description, contains('workspace'));
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], contains('name'));
      expect(((schema['properties'] as Map<String, dynamic>)['name'] as Map<String, dynamic>)['type'], 'string');
    });

    test('definition returns correct ToolDef', () {
      final def = tool.definition;
      expect(def.name, 'create_workspace');
    });

    test('creates workspace with name only', () async {
      final result = await tool.call({'name': 'My New Workspace'});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'My New Workspace');
      expect(data['linked_repos'], 0);
    });

    test('creates workspace with repo IDs', () async {
      final result = await tool.call({
        'name': 'Repo WS',
        'repo_ids': ['repo-1', 'repo-2'],
      });

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'Repo WS');
      expect(data['linked_repos'], 2);
      expect(repository.lastRepoIds, ['repo-1', 'repo-2']);
    });

    test('trims whitespace from name', () async {
      final result = await tool.call({'name': '  Padded  '});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'Padded');
    });

    test('persists workspace to repository', () async {
      await tool.call({'name': 'PersistTest'});

      expect(repository.saved.length, 1);
      expect(repository.saved.first.name, 'PersistTest');
    });

    test('generates unique UUID for each workspace', () async {
      await tool.call({'name': 'WS1'});
      await tool.call({'name': 'WS2'});

      expect(repository.saved.length, 2);
      expect(repository.saved[0].id, isNot(repository.saved[1].id));
    });

    test('handles empty repo_ids gracefully', () async {
      final result = await tool.call({
        'name': 'Empty Repos',
        'repo_ids': [],
      });

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['linked_repos'], 0);
    });
  });
}
