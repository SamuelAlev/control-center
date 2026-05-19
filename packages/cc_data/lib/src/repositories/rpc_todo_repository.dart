import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_rpc/cc_rpc.dart';

DateTime _parseDate(Object? iso) => iso is String
    ? DateTime.parse(iso)
    : DateTime.fromMillisecondsSinceEpoch(0);

ConversationGoal? _goalFromWire(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final w = raw.cast<String, dynamic>();
  final title = (w['title'] as String? ?? '').trim();
  if (title.isEmpty) {
    return null;
  }
  return ConversationGoal(
    conversationId: w['conversation_id'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    title: title,
    createdAt: _parseDate(w['created_at']),
    updatedAt: _parseDate(w['updated_at']),
  );
}

TodoItem _todoFromWire(Map<String, dynamic> w) => TodoItem(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  conversationId: w['conversation_id'] as String? ?? '',
  content: w['content'] as String? ?? '',
  status: TodoStatus.fromStorage(w['status'] as String?),
  position: (w['position'] as num?)?.toInt() ?? 0,
  createdAt: _parseDate(w['created_at']),
  updatedAt: _parseDate(w['updated_at']),
);

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// A [TodoRepository] backed by the RPC client.
///
/// Reads and mutations both go over the wire (`todos.*` ops + `todos.watch`).
/// `workspace_id` is auto-injected by [RemoteRpcClient]; `conversation_id` is
/// always passed explicitly since it is a per-call filter, not the session
/// binding.
class RpcTodoRepository implements TodoRepository {
  /// Creates an [RpcTodoRepository] over the given client.
  RpcTodoRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<TodoItem>> watch(String workspaceId, String conversationId) =>
      _client
          .subscribe('todos.watch', {
            'workspace_id': workspaceId,
            'conversation_id': conversationId,
          })
          .map(
            (data) =>
                decodeRows(_maps(data['todos']), _todoFromWire, what: 'todo'),
          );

  @override
  Future<List<TodoItem>> list(String workspaceId, String conversationId) async {
    final data = await _client.call('todos.list', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
    });
    return decodeRows(_maps(data['todos']), _todoFromWire, what: 'todo');
  }

  @override
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodoItem> items,
  ) => _client.call('todos.replaceAll', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'todos': [
      for (final t in items)
        {'id': t.id, 'content': t.content, 'status': t.status.storage},
    ],
  });

  @override
  Future<TodoItem> append(
    String workspaceId,
    String conversationId,
    String content,
  ) async {
    final data = await _client.call('todos.append', {
      'workspace_id': workspaceId,
      'conversation_id': conversationId,
      'content': content,
    });
    final todo = data['todo'];
    return _todoFromWire((todo as Map).cast<String, dynamic>());
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String conversationId,
    String id,
    TodoStatus status,
  ) => _client.call('todos.setStatus', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'id': id,
    'status': status.storage,
  });

  @override
  Future<void> remove(String workspaceId, String conversationId, String id) =>
      _client.call('todos.remove', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
        'id': id,
      });

  @override
  Future<void> reorder(
    String workspaceId,
    String conversationId,
    List<String> orderedIds,
  ) => _client.call('todos.reorder', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'ordered_ids': orderedIds,
  });

  @override
  Future<void> clear(String workspaceId, String conversationId) => _client.call(
    'todos.clear',
    {'workspace_id': workspaceId, 'conversation_id': conversationId},
  );

  @override
  Stream<ConversationGoal?> watchGoal(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('todos.watchGoal', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map((data) => _goalFromWire(data['goal']));

  @override
  Future<void> setGoal(
    String workspaceId,
    String conversationId,
    String title,
  ) => _client.call('todos.setGoal', {
    'workspace_id': workspaceId,
    'conversation_id': conversationId,
    'title': title,
  });

  @override
  Future<void> clearGoal(String workspaceId, String conversationId) =>
      _client.call('todos.clearGoal', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      });
}
