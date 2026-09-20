import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_mcp/src/tools/todo_write_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeTodos todos;
  late _FakeConversations conversations;
  late TodoWriteTool tool;

  setUp(() {
    todos = _FakeTodos();
    conversations = _FakeConversations();
    tool = TodoWriteTool(
      todoRepository: todos,
      conversationRepository: conversations,
    );
  });

  test('refuses a conversation from another workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-other',
      'todos': [
        {'content': 'Do it', 'status': 'pending'},
      ],
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('preserves identity across full-list writes', () async {
    final first = await tool.run({
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
      'todos': [
        {'content': 'Ship it', 'status': 'pending'},
      ],
    });
    expect(first.isError, isFalse);
    final id = todos.items.single.id;
    final createdAt = todos.items.single.createdAt;

    final second = await tool.run({
      'workspace_id': 'ws-1',
      'conversation_id': 'conv-1',
      'todos': [
        {'content': 'Ship it', 'status': 'in_progress'},
      ],
    });
    expect(second.isError, isFalse);
    expect(todos.items, hasLength(1));
    expect(todos.items.single.id, id);
    expect(todos.items.single.createdAt, createdAt);
    expect(todos.items.single.status, TodoStatus.inProgress);
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
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodoItem> next,
  ) async {
    items = List.of(next);
  }

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
