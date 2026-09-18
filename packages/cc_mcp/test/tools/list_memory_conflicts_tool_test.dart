import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_conflict_repository.dart';
import 'package:cc_mcp/src/tools/list_memory_conflicts_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeConflicts repo;
  late ListMemoryConflictsTool tool;

  setUp(() {
    repo = _FakeConflicts();
    tool = ListMemoryConflictsTool(repository: repo);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run(const {});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('lists unresolved conflicts when asked', () async {
    repo.unresolved = [
      MemoryConflict(
        id: 'c1',
        workspaceId: 'ws-1',
        factAId: 'a',
        factBId: 'b',
        createdAt: DateTime(2026),
      ),
    ];
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'unresolved_only': true,
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect((body['conflicts'] as List).single['id'], 'c1');
  });
}

class _FakeConflicts implements MemoryConflictRepository {
  List<MemoryConflict> unresolved = [];

  @override
  Future<List<MemoryConflict>> getUnresolved(String workspaceId) async =>
      unresolved;

  @override
  Future<List<MemoryConflict>> getByWorkspace(String workspaceId) async =>
      unresolved;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
