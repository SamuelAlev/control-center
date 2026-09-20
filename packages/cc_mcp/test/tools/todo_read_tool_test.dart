import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_mcp/src/tools/todo_read_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTodos todos;
  late _FakeConversations conversations;
  late TodoReadTool tool;

  setUp(() {
    todos = _FakeTodos();
    conversations = _FakeConversations();
    tool = TodoReadTool(
      todoRepository: todos,
      conversationRepository: conversations,
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'conversation_id': 'conv-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a conversation from another workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-other',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('returns the persisted checklist', () async {
    todos.items = [
      TodoItem(
        id: 't1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        content: 'Ship it',
        status: TodoStatus.completed,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['total'], 1);
    expect(body['completed'], 1);
    expect(body['conversation_id'], 'conv-1');
    expect(((body['todos'] as List).single as Map)['content'], 'Ship it');
  });
}

class _FakeTodos implements TodoRepository {
  List<TodoItem> items = [];

  @override
  Future<List<TodoItem>> list(
    String workspaceId,
    String conversationId,
  ) async => List.unmodifiable(items);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeConversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    if (conversationId != 'conv-1' || workspaceId != 'ws-1') {
      return null;
    }
    return Conversation(
      id: 'conv-1',
      workspaceId: workspaceId,
      spaceId: 'space-1',
      title: 'Work',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
