import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TodoRepository] scoped by (workspace, conversation).
class _InMemoryTodoRepo implements TodoRepository {
  final Map<String, List<TodoItem>> _store = {};

  String _key(String ws, String conversation) => '$ws/$conversation';

  List<TodoItem> seen(String ws, String conversation) =>
      _store[_key(ws, conversation)] ?? [];

  @override
  Future<void> replaceAll(
    String ws,
    String conversation,
    List<TodoItem> items,
  ) async {
    _store[_key(ws, conversation)] = List.of(items);
  }

  @override
  Future<TodoItem> append(
    String ws,
    String conversation,
    String content,
  ) async {
    final item = TodoItem(
      id: 'x${seen(ws, conversation).length}',
      workspaceId: ws,
      conversationId: conversation,
      content: content,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
    _store.putIfAbsent(_key(ws, conversation), () => []).add(item);
    return item;
  }

  @override
  Future<void> clear(String ws, String conversation) async =>
      _store.remove(_key(ws, conversation));

  final Map<String, ConversationGoal> _goals = {};

  @override
  Stream<ConversationGoal?> watchGoal(String ws, String conversation) =>
      Stream.value(_goals[_key(ws, conversation)]);

  @override
  Future<void> setGoal(String ws, String conversation, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      _goals.remove(_key(ws, conversation));
      return;
    }
    _goals[_key(ws, conversation)] = ConversationGoal(
      conversationId: conversation,
      workspaceId: ws,
      title: trimmed,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
  }

  @override
  Future<void> clearGoal(String ws, String conversation) async =>
      _goals.remove(_key(ws, conversation));

  @override
  Future<List<TodoItem>> list(String ws, String conversation) async =>
      seen(ws, conversation);

  @override
  Future<void> remove(String ws, String conversation, String id) async =>
      _store[_key(ws, conversation)]?.removeWhere((t) => t.id == id);

  @override
  Future<void> reorder(String ws, String conversation, List<String> ids) async {}

  @override
  Future<void> updateStatus(
    String ws,
    String conversation,
    String id,
    TodoStatus status,
  ) async => {};

  @override
  Stream<List<TodoItem>> watch(String ws, String conversation) =>
      Stream.value(seen(ws, conversation));
}

class _FakeConversations extends Fake implements ConversationRepository {
  _FakeConversations(this._conversations);
  final List<Conversation> _conversations;

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    for (final c in _conversations) {
      if (c.id == conversationId && c.workspaceId == workspaceId) {
        return c;
      }
    }
    return null;
  }
}

Conversation _conversation(String id, String ws) => Conversation(
  id: id,
  workspaceId: ws,
  spaceId: 's-1',
  title: id,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

void main() {
  late _InMemoryTodoRepo todos;
  late TodoWriteTool tool;

  setUp(() {
    todos = _InMemoryTodoRepo();
    tool = TodoWriteTool(
      todoRepository: todos,
      conversationRepository: _FakeConversations([_conversation('c-1', 'w-1')]),
    );
  });

  test('persists the full list for the (workspace, conversation)', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'conversation_id': 'c-1',
      'todos': [
        {'content': 'first', 'status': 'completed'},
        {'content': 'second', 'status': 'in_progress'},
        {'content': 'third', 'status': 'pending'},
      ],
    });
    expect(result.isError, isFalse);
    final stored = todos.seen('w-1', 'c-1');
    expect(stored.map((t) => t.content), ['first', 'second', 'third']);
    expect(stored.first.status, TodoStatus.completed);
    expect(stored.first.workspaceId, 'w-1');
    expect(stored.first.conversationId, 'c-1');
  });

  test('rejects a conversation in a different workspace', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'conversation_id': 'c-999', // not a conversation in w-1
      'todos': [
        {'content': 'x', 'status': 'pending'},
      ],
    });
    expect(result.isError, isTrue);
    expect(todos.seen('w-1', 'c-999'), isEmpty);
  });

  test('rejects a missing workspace_id', () async {
    final result = await tool.run({'conversation_id': 'c-1', 'todos': const []});
    expect(result.isError, isTrue);
  });

  test('rejects an invalid status', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'conversation_id': 'c-1',
      'todos': [
        {'content': 'x', 'status': 'bogus'},
      ],
    });
    expect(result.isError, isTrue);
  });

  Future<CallResult> writeList(List<(String, String)> items) => tool.run({
    'workspace_id': 'w-1',
    'conversation_id': 'c-1',
    'todos': [
      for (final (content, status) in items)
        {'content': content, 'status': status},
    ],
  });

  String text(CallResult r) => r.content.map((c) => c.text).join('\n');

  group('identity across writes', () {
    test('an unchanged item keeps its id and createdAt', () async {
      await writeList([
        ('wire the dao', 'pending'),
        ('add the test', 'pending'),
      ]);
      final before = todos.seen('w-1', 'c-1');

      await writeList([
        ('wire the dao', 'in_progress'),
        ('add the test', 'pending'),
      ]);
      final after = todos.seen('w-1', 'c-1');

      expect(after.map((t) => t.id), before.map((t) => t.id));
      expect(after.first.createdAt, before.first.createdAt);
      // The transition itself still lands.
      expect(after.first.status, TodoStatus.inProgress);
    });

    test('only a genuinely new item gets a fresh id', () async {
      await writeList([('a', 'completed')]);
      final firstId = todos.seen('w-1', 'c-1').single.id;

      await writeList([('a', 'completed'), ('b', 'in_progress')]);
      final after = todos.seen('w-1', 'c-1');
      expect(after.first.id, firstId);
      expect(after.last.id, isNot(firstId));
    });

    test(
      'an explicit id claims the row even when the content changed',
      () async {
        await writeList([('draft wording', 'pending')]);
        final id = todos.seen('w-1', 'c-1').single.id;

        await tool.run({
          'workspace_id': 'w-1',
          'conversation_id': 'c-1',
          'todos': [
            {'id': id, 'content': 'final wording', 'status': 'in_progress'},
          ],
        });
        final after = todos.seen('w-1', 'c-1').single;
        expect(after.id, id, reason: 'the row was edited, not replaced');
        expect(after.content, 'final wording');
      },
    );

    test('duplicate contents each claim a distinct row', () async {
      await writeList([('same', 'completed'), ('same', 'pending')]);
      final before = todos.seen('w-1', 'c-1');

      await writeList([('same', 'completed'), ('same', 'in_progress')]);
      final after = todos.seen('w-1', 'c-1');
      expect(after.map((t) => t.id), before.map((t) => t.id));
      expect(after.last.status, TodoStatus.inProgress);
    });

    test(
      'a stale id falls back to a content match instead of erroring',
      () async {
        await writeList([('a', 'pending')]);
        final id = todos.seen('w-1', 'c-1').single.id;

        final result = await tool.run({
          'workspace_id': 'w-1',
          'conversation_id': 'c-1',
          'todos': [
            {'id': 'never-existed', 'content': 'a', 'status': 'completed'},
          ],
        });
        expect(result.isError, isFalse);
        expect(todos.seen('w-1', 'c-1').single.id, id);
      },
    );
  });

  group('hygiene feedback', () {
    test('nudges toward in_progress when nothing is active', () async {
      final r = await writeList([('a', 'completed'), ('b', 'pending')]);
      expect(text(r), contains('Nothing is in_progress'));
      expect(text(r), contains('"b"'));
    });

    test('warns when several items are in_progress at once', () async {
      final r = await writeList([('a', 'in_progress'), ('b', 'in_progress')]);
      expect(text(r), contains('2 items are in_progress'));
    });

    test('stays quiet when exactly one item is in flight', () async {
      final r = await writeList([('a', 'in_progress'), ('b', 'pending')]);
      expect(text(r), isNot(contains('Nothing is in_progress')));
      expect(text(r), isNot(contains('in_progress. Keep exactly one')));
    });

    test('reports an item dropped by a short re-send', () async {
      await writeList([('keep', 'pending'), ('lose', 'pending')]);
      final r = await writeList([('keep', 'in_progress')]);
      expect(text(r), contains('Removed 1 item'));
      expect(text(r), contains('"lose"'));
    });

    test('acknowledges a finished list', () async {
      final r = await writeList([('a', 'completed'), ('b', 'completed')]);
      expect(text(r), contains('Every item is complete'));
    });
  });
}
