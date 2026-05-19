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
/// Todos and the space goal both live in the workspace's own database file,
/// so each method resolves its DAO from the `workspaceId` it was given.
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
  Stream<List<TodoItem>> watch(String workspaceId, String spaceId) =>
      _dao(workspaceId)
          .watchForSpace(workspaceId, spaceId)
          .map(_mapper.toDomainList);

  @override
  Future<List<TodoItem>> list(
    String workspaceId,
    String spaceId,
  ) async => _mapper.toDomainList(
    await _dao(workspaceId).getForSpace(workspaceId, spaceId),
  );

  @override
  Future<void> replaceAll(
    String workspaceId,
    String spaceId,
    List<TodoItem> items,
  ) async {
    final now = DateTime.now();
    final companions = [
      for (var i = 0; i < items.length; i++)
        _mapper.toCompanion(
          items[i].copyWith(
            workspaceId: workspaceId,
            spaceId: spaceId,
            position: i,
            updatedAt: now,
          ),
        ),
    ];
    await _dao(workspaceId).replaceAll(workspaceId, spaceId, companions);
  }

  @override
  Future<TodoItem> append(
    String workspaceId,
    String spaceId,
    String content,
  ) async {
    final dao = _dao(workspaceId);
    final existing = await dao.getForSpace(workspaceId, spaceId);
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((r) => r.position).reduce((a, b) => a > b ? a : b) + 1;
    final now = DateTime.now();
    final item = TodoItem(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      spaceId: spaceId,
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
    String spaceId,
    String id,
    TodoStatus status,
  ) => _dao(workspaceId)
      .updateStatus(
        workspaceId,
        spaceId,
        id,
        status.storage,
        DateTime.now(),
      )
      .then((_) {});

  @override
  Future<void> remove(String workspaceId, String spaceId, String id) =>
      _dao(
        workspaceId,
      ).deleteById(workspaceId, spaceId, id).then((_) {});

  @override
  Future<void> reorder(
    String workspaceId,
    String spaceId,
    List<String> orderedIds,
  ) async {
    final dao = _dao(workspaceId);
    // One transaction, not N auto-commits. Each write otherwise cost its own
    // fsync AND re-ran the space's todo watch, so dragging one item in a
    // 20-item list produced 20 commits and 20 list re-emissions.
    await dao.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await dao.updatePosition(workspaceId, spaceId, orderedIds[i], i);
      }
    });
  }

  @override
  Future<void> clear(String workspaceId, String spaceId) =>
      _dao(workspaceId).deleteAll(workspaceId, spaceId).then((_) {});

  @override
  Stream<ConversationGoal?> watchGoal(
    String workspaceId,
    String spaceId,
  ) => _goalDao(workspaceId)
      .watchForSpace(workspaceId, spaceId)
      .map(_goalMapper.toDomainOrNull);

  @override
  Future<void> setGoal(
    String workspaceId,
    String spaceId,
    String title,
  ) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      await clearGoal(workspaceId, spaceId);
      return;
    }
    final now = DateTime.now();
    final goalDao = _goalDao(workspaceId);
    final existing = await goalDao.getForSpace(
      workspaceId,
      spaceId,
    );
    final goal = ConversationGoal(
      spaceId: spaceId,
      workspaceId: workspaceId,
      title: trimmed,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await goalDao.upsert(_goalMapper.toCompanion(goal));
  }

  @override
  Future<void> clearGoal(String workspaceId, String spaceId) => _goalDao(
    workspaceId,
  ).deleteForSpace(workspaceId, spaceId).then((_) {});
}
