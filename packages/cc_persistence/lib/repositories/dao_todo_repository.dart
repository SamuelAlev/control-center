import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_persistence/database/daos/conversation_goal_dao.dart';
import 'package:cc_persistence/database/daos/todo_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/conversation_goal_mapper.dart';
import 'package:cc_persistence/mappers/todo_mapper.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed [TodoRepository].
///
/// Todos and the conversation goal both live in the workspace's own database
/// file, so each method resolves its DAO from the `workspaceId` it was given.
class DaoTodoRepository implements TodoRepository {
  /// Creates a [DaoTodoRepository] over the per-workspace databases.
  DaoTodoRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final TodoMapper _mapper = const TodoMapper();
  final ConversationGoalMapper _goalMapper = const ConversationGoalMapper();
  final Uuid _uuid = const Uuid();

  TodoDao _dao(String workspaceId) => _dbs.of(workspaceId).todoDao;

  ConversationGoalDao _goalDao(String workspaceId) =>
      _dbs.of(workspaceId).conversationGoalDao;

  @override
  Stream<List<TodoItem>> watch(String workspaceId, String conversationId) =>
      _dao(workspaceId)
          .watchForConversation(workspaceId, conversationId)
          .map(_mapper.toDomainList);

  @override
  Future<List<TodoItem>> list(
    String workspaceId,
    String conversationId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).getForConversation(workspaceId, conversationId),
  );

  @override
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodoItem> items,
  ) async {
    final now = DateTime.now();
    final companions = [
      for (var i = 0; i < items.length; i++)
        _mapper.toCompanion(
          items[i].copyWith(
            workspaceId: workspaceId,
            conversationId: conversationId,
            position: i,
            updatedAt: now,
          ),
        ),
    ];
    await _dao(workspaceId).replaceAll(workspaceId, conversationId, companions);
  }

  @override
  Future<TodoItem> append(
    String workspaceId,
    String conversationId,
    String content,
  ) async {
    final dao = _dao(workspaceId);
    final existing = await dao.getForConversation(workspaceId, conversationId);
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((r) => r.position).reduce((a, b) => a > b ? a : b) + 1;
    final now = DateTime.now();
    final item = TodoItem(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      conversationId: conversationId,
      content: content,
      status: TodoStatus.pending,
      position: nextPosition,
      createdAt: now,
      updatedAt: now,
    );
    await dao.upsert(_mapper.toCompanion(item));
    return item;
  }

  @override
  Future<void> updateStatus(
    String workspaceId,
    String conversationId,
    String id,
    TodoStatus status,
  ) => _dao(workspaceId)
      .updateStatus(
        workspaceId,
        conversationId,
        id,
        status.storage,
        DateTime.now(),
      )
      .then((_) {});

  @override
  Future<void> remove(String workspaceId, String conversationId, String id) =>
      _dao(
        workspaceId,
      ).deleteById(workspaceId, conversationId, id).then((_) {});

  @override
  Future<void> reorder(
    String workspaceId,
    String conversationId,
    List<String> orderedIds,
  ) async {
    final dao = _dao(workspaceId);
    for (var i = 0; i < orderedIds.length; i++) {
      await dao.updatePosition(workspaceId, conversationId, orderedIds[i], i);
    }
  }

  @override
  Future<void> clear(String workspaceId, String conversationId) =>
      _dao(workspaceId).deleteAll(workspaceId, conversationId).then((_) {});

  @override
  Stream<ConversationGoal?> watchGoal(
    String workspaceId,
    String conversationId,
  ) => _goalDao(workspaceId)
      .watchForConversation(workspaceId, conversationId)
      .map(_goalMapper.toDomainOrNull);

  @override
  Future<void> setGoal(
    String workspaceId,
    String conversationId,
    String title,
  ) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      await clearGoal(workspaceId, conversationId);
      return;
    }
    final now = DateTime.now();
    final goalDao = _goalDao(workspaceId);
    final existing = await goalDao.getForConversation(
      workspaceId,
      conversationId,
    );
    final goal = ConversationGoal(
      conversationId: conversationId,
      workspaceId: workspaceId,
      title: trimmed,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await goalDao.upsert(_goalMapper.toCompanion(goal));
  }

  @override
  Future<void> clearGoal(String workspaceId, String conversationId) => _goalDao(
    workspaceId,
  ).deleteForConversation(workspaceId, conversationId).then((_) {});
}
