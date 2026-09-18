import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_mcp/src/tools/todo_read_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTodos todos;
  late _FakeMessaging messaging;
  late TodoReadTool tool;

  setUp(() {
    todos = _FakeTodos();
    messaging = _FakeMessaging();
    tool = TodoReadTool(
      todoRepository: todos,
      messagingRepository: messaging,
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'space_id': 'space-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a space from another workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-other',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('returns the persisted checklist', () async {
    todos.items = [
      TodoItem(
        id: 't1',
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        content: 'Ship it',
        status: TodoStatus.completed,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-1',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['total'], 1);
    expect(body['completed'], 1);
    expect((body['todos'] as List).single['content'], 'Ship it');
  });
}

class _FakeTodos implements TodoRepository {
  List<TodoItem> items = [];

  @override
  Future<List<TodoItem>> list(String workspaceId, String spaceId) async =>
      List.unmodifiable(items);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessaging implements MessagingRepository {
  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value([
        Space(
          id: 'space-1',
          name: 'Work',
          workspaceId: workspaceId,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
