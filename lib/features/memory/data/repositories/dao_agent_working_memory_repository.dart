import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/database/daos/agent_working_memory_dao.dart';
import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/features/memory/data/mappers/agent_working_memory_mapper.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:drift/drift.dart';

/// DAO-based repository for agent working memory.
class DaoAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  /// Creates a [DaoAgentWorkingMemoryRepository].
  DaoAgentWorkingMemoryRepository(this._dao);

  final AgentWorkingMemoryDao _dao;
  final AgentWorkingMemoryMapper _mapper = const AgentWorkingMemoryMapper();

  @override
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId) =>
      _dao.watchByAgent(workspaceId, agentId).map(
        (row) => row != null ? _mapper.toDomain(row) : null,
      );

  @override
  Future<AgentWorkingMemory?> getByAgent(String workspaceId, String agentId) =>
      _dao.getByAgent(workspaceId, agentId).then(
        (row) => row != null ? _mapper.toDomain(row) : null,
      );

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
        (rows) => rows.map(_mapper.toDomain).toList(),
      );

  @override
  Future<void> upsert(AgentWorkingMemory memory) => _dao.upsert(
    db.AgentWorkingMemoryTableCompanion(
      id: Value(memory.id),
      workspaceId: Value(memory.workspaceId),
      agentId: Value(memory.agentId),
      content: Value(memory.content),
      updatedAt: Value(memory.updatedAt),
    ),
  );
}
