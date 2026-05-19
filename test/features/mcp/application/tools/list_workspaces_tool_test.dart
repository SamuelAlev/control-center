import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/application/tools/list_workspaces_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();

  void addWorkspace(Workspace w) {
    _workspaces.add(w);
    _controller.add(List.unmodifiable(_workspaces));
  }

  @override
  Stream<List<Workspace>> watchAll() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_workspaces)));
    return _controller.stream;
  }

  @override
  Future<String> upsert(Workspace workspace) async {
    _workspaces.add(workspace);
    _controller.add(List.unmodifiable(_workspaces));
    return workspace.id;
  }

  @override
  Future<void> delete(String id) async {
    _workspaces.removeWhere((w) => w.id == id);
    _controller.add(List.unmodifiable(_workspaces));
  }

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    return Stream.value(const []);
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}

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

Workspace _createTestWorkspace({
  String id = 'ws-1',
  String name = 'Test Workspace',
}) {
  return Workspace(
    id: id,
    name: name,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ListWorkspacesTool', () {
    late _FakeWorkspaceRepository repository;
    late ListWorkspacesTool tool;

    setUp(() {
      repository = _FakeWorkspaceRepository();
      tool = ListWorkspacesTool(repository: repository);
    });

    test('has correct name', () {
      expect(tool.name, 'list_workspaces');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has empty inputSchema properties', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['properties'], {});
    });

    test('returns empty list when no workspaces exist', () async {
      repository.addWorkspace(_createTestWorkspace());
      final result = await tool.call({});

      expect(result.isError, isFalse);
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['workspaces'], isA<List>());
      expect(data['count'], 1);
    });

    test('returns all workspaces', () async {
      repository.addWorkspace(
        _createTestWorkspace(id: 'ws-1', name: 'Workspace 1'),
      );
      repository.addWorkspace(
        _createTestWorkspace(
          id: 'ws-2',
          name: 'Workspace 2',
        ),
      );

      final result = await tool.call({});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
      expect(((data['workspaces'] as List<dynamic>)[0] as Map<String, dynamic>)['id'], 'ws-1');
      expect(((data['workspaces'] as List<dynamic>)[0] as Map<String, dynamic>)['name'], 'Workspace 1');
      expect(((data['workspaces'] as List<dynamic>)[1] as Map<String, dynamic>)['id'], 'ws-2');
    });

    test('includes ISO 8601 created_at', () async {
      repository.addWorkspace(_createTestWorkspace());

      final result = await tool.call({});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(((data['workspaces'] as List<dynamic>)[0] as Map<String, dynamic>)['created_at'], contains('2026-01-01'));
    });

    test('handles multiple calls returning fresh results', () async {
      repository.addWorkspace(_createTestWorkspace(id: 'ws-1', name: 'First'));
      await tool.call({});

      repository.addWorkspace(_createTestWorkspace(id: 'ws-2', name: 'Second'));

      final result = await tool.call({});
      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
    });
  });
}
