import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TodoRepository] scoped by (workspace, space).
class _InMemoryTodoRepo implements TodoRepository {
  final Map<String, List<TodoItem>> _store = {};

  String _key(String ws, String space) => '$ws/$space';

  List<TodoItem> seen(String ws, String space) => _store[_key(ws, space)] ?? [];

  @override
  Future<void> replaceAll(String ws, String space, List<TodoItem> items) async {
    _store[_key(ws, space)] = List.of(items);
  }

  @override
  Future<TodoItem> append(String ws, String space, String content) async {
    final item = TodoItem(
      id: 'x${seen(ws, space).length}',
      workspaceId: ws,
      spaceId: space,
      content: content,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
    _store.putIfAbsent(_key(ws, space), () => []).add(item);
    return item;
  }

  @override
  Future<void> clear(String ws, String space) async =>
      _store.remove(_key(ws, space));

  final Map<String, ConversationGoal> _goals = {};

  @override
  Stream<ConversationGoal?> watchGoal(String ws, String space) =>
      Stream.value(_goals[_key(ws, space)]);

  @override
  Future<void> setGoal(String ws, String space, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      _goals.remove(_key(ws, space));
      return;
    }
    _goals[_key(ws, space)] = ConversationGoal(
      spaceId: space,
      workspaceId: ws,
      title: trimmed,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
  }

  @override
  Future<void> clearGoal(String ws, String space) async =>
      _goals.remove(_key(ws, space));

  @override
  Future<List<TodoItem>> list(String ws, String space) async => seen(ws, space);

  @override
  Future<void> remove(String ws, String space, String id) async =>
      _store[_key(ws, space)]?.removeWhere((t) => t.id == id);

  @override
  Future<void> reorder(String ws, String space, List<String> ids) async {}

  @override
  Future<void> updateStatus(
    String ws,
    String space,
    String id,
    TodoStatus status,
  ) async => {};

  @override
  Stream<List<TodoItem>> watch(String ws, String space) =>
      Stream.value(seen(ws, space));
}

class _FakeMessagingRepo extends Fake implements MessagingRepository {
  _FakeMessagingRepo(this._spaces);
  final List<Space> _spaces;

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(_spaces.where((c) => c.workspaceId == workspaceId).toList());
}

Space _space(String id, String ws) => Space(
  id: id,
  name: id,
  workspaceId: ws,
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
      messagingRepository: _FakeMessagingRepo([_space('c-1', 'w-1')]),
    );
  });

  test('persists the full list for the (workspace, space)', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'space_id': 'c-1',
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
    expect(stored.first.spaceId, 'c-1');
  });

  test('rejects a space in a different workspace', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'space_id': 'c-999', // not a space in w-1
      'todos': [
        {'content': 'x', 'status': 'pending'},
      ],
    });
    expect(result.isError, isTrue);
    expect(todos.seen('w-1', 'c-999'), isEmpty);
  });

  test('rejects a missing workspace_id', () async {
    final result = await tool.run({'space_id': 'c-1', 'todos': const []});
    expect(result.isError, isTrue);
  });

  test('rejects an invalid status', () async {
    final result = await tool.run({
      'workspace_id': 'w-1',
      'space_id': 'c-1',
      'todos': [
        {'content': 'x', 'status': 'bogus'},
      ],
    });
    expect(result.isError, isTrue);
  });

  Future<CallResult> writeList(List<(String, String)> items) => tool.run({
    'workspace_id': 'w-1',
    'space_id': 'c-1',
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
          'space_id': 'c-1',
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
          'space_id': 'c-1',
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
