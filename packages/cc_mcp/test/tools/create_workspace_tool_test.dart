import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_mcp/src/tools/create_workspace_tool.dart';
import 'package:test/test.dart';

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
  ) async => false;

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  void dispose() => _controller.close();

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
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
      expect(
        ((schema['properties'] as Map<String, dynamic>)['name']
            as Map<String, dynamic>)['type'],
        'string',
      );
      // A repo cannot be attached by id: ids are per-workspace, so repos are
      // registered from a checkout path after the workspace exists.
      expect(
        (schema['properties'] as Map<String, dynamic>).containsKey('repo_ids'),
        isFalse,
      );
    });

    test('definition returns correct ToolDef', () {
      final def = tool.definition;
      expect(def.name, 'create_workspace');
    });

    test('creates an empty workspace from a name', () async {
      final result = await tool.call({'name': 'My New Workspace'});

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'My New Workspace');
      expect(data['id'], isNotEmpty);
      expect(repository.lastRepoIds, isNull);
    });

    test('ignores repo ids: a repo cannot be attached by id', () async {
      final result = await tool.call({
        'name': 'Repo WS',
        'repo_ids': ['repo-1', 'repo-2'],
      });

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'Repo WS');
      // Repo ids are per-workspace, so an id from anywhere else names nothing
      // here — no repo write is attempted at all.
      expect(repository.lastRepoIds, isNull);
      expect(repository.lastWorkspaceId, isNull);
    });

    test('trims whitespace from name', () async {
      final result = await tool.call({'name': '  Padded  '});

      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
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

    test('handles an empty repo_ids list gracefully', () async {
      final result = await tool.call({'name': 'Empty Repos', 'repo_ids': []});

      expect(result.isError, isFalse);
      final data =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['name'], 'Empty Repos');
      expect(repository.lastRepoIds, isNull);
    });
  });
}
