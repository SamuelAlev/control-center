import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/memory_consolidation_log_dao.dart';
import 'package:cc_persistence/database/daos/working_memory_item_dao.dart';
import 'package:cc_persistence/mappers/working_memory_item_mapper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// DAO-based repository for the hot working-memory tier.
class DaoWorkingMemoryItemRepository implements WorkingMemoryItemRepository {
  /// Creates a [DaoWorkingMemoryItemRepository].
  DaoWorkingMemoryItemRepository(this._dao, this._logDao);

  final WorkingMemoryItemDao _dao;
  final MemoryConsolidationLogDao _logDao;
  final WorkingMemoryItemMapper _mapper = const WorkingMemoryItemMapper();

  static const _uuid = Uuid();

  @override
  Future<void> add(WorkingMemoryItem item) => _dao.upsert(
        db.WorkingMemoryItemsTableCompanion(
          id: Value(item.id),
          workspaceId: Value(item.workspaceId),
          agentId: Value(item.agentId),
          sessionId: Value(item.sessionId),
          content: Value(item.content),
          memoryType: Value(item.memoryType.wireName),
          veracity: Value(item.veracity.wireName),
          importance: Value(item.importance),
          createdAt: Value(item.createdAt),
          expiresAt: Value(item.expiresAt),
        ),
      );

  @override
  Future<List<WorkingMemoryItem>> getForAgent(
    String workspaceId,
    String agentId,
  ) =>
      _dao.getForAgent(workspaceId, agentId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<List<WorkingMemoryItem>> getForWorkspace(String workspaceId) =>
      _dao.getForWorkspace(workspaceId).then(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Stream<List<WorkingMemoryItem>> watchForAgent(
    String workspaceId,
    String agentId,
  ) =>
      _dao.watchForAgent(workspaceId, agentId).map(
            (rows) => rows.map(_mapper.toDomain).toList(),
          );

  @override
  Future<void> deleteByIds(String workspaceId, List<String> ids) =>
      _dao.deleteByIds(workspaceId, ids);

  @override
  Future<int> deleteExpired(String workspaceId, DateTime now) =>
      _dao.deleteExpired(workspaceId, now);

  @override
  Future<void> recordConsolidationPass(ConsolidationPassReport report) =>
      _logDao.insertPass(
        db.MemoryConsolidationLogTableCompanion(
          id: Value(_uuid.v4()),
          workspaceId: Value(report.workspaceId),
          agentId: Value(report.agentId),
          itemsConsidered: Value(report.itemsConsidered),
          factsCreated: Value(report.factsCreated),
          factsUpdated: Value(report.factsUpdated),
          conflictsDetected: Value(report.conflictsDetected),
          evicted: Value(report.evicted),
          startedAt: Value(report.startedAt),
          finishedAt: Value(report.finishedAt),
        ),
      );
}